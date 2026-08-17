// Phase 18 — Optical air-gap transfer (AirQR): collecting and reassembling.
//
// The receiver is fed every raw string the camera decodes, in whatever order
// they arrive, with duplicates, with foreign QR codes mixed in. Its job is to
// be unshakeable about that:
//   * a frame it already has is a no-op (the sender loops, so most scans are
//     duplicates by design);
//   * a frame that arrives before the manifest is still kept;
//   * a foreign or damaged QR is reported and otherwise ignored, never fatal;
//   * a manifest for a *different* transfer restarts collection cleanly.
//
// It holds no timer and no Flutter import, so the dropped-frame behaviour is
// fully unit-testable without a camera.
//
// Nothing here logs frame content.
library;

import 'dart:typed_data';

import 'package:sreerajp_textapp/airqr/airqr_codec.dart';
import 'package:sreerajp_textapp/airqr/airqr_constants.dart';
import 'package:sreerajp_textapp/airqr/airqr_payload.dart';

/// What happened to one offered scan.
enum AirqrOfferOutcome {
  /// A frame we did not have. Progress moved.
  accepted,

  /// A frame we already had. Normal and expected — the sender loops.
  duplicate,

  /// The manifest, seen for the first time.
  manifest,

  /// Not one of our frames, or damaged. [AirqrOfferResult.message] says why.
  rejected,

  /// A manifest for a different transfer. Collection restarted.
  restarted,
}

/// The outcome of offering one scanned string.
class AirqrOfferResult {
  final AirqrOfferOutcome outcome;

  /// User-safe explanation, set only when [outcome] is
  /// [AirqrOfferOutcome.rejected].
  final String? message;

  const AirqrOfferResult(this.outcome, [this.message]);

  bool get movedForward =>
      outcome == AirqrOfferOutcome.accepted ||
      outcome == AirqrOfferOutcome.manifest;
}

/// Collects frames until a transfer is complete.
class AirqrReceiver {
  AirqrManifest? _manifest;

  /// Chunks by index. Sparse until the last frame lands.
  final Map<int, Uint8List> _chunks = {};

  /// Total frame count, learned from either the manifest or any data frame —
  /// whichever we see first.
  int? _declaredTotal;

  /// Timestamps of accepted scans, for the live frames-per-second readout.
  final List<DateTime> _scanTimes = [];

  /// When the first frame of this transfer arrived, for the time estimate.
  DateTime? _startedAt;

  AirqrManifest? get manifest => _manifest;

  /// How many distinct data frames we hold.
  int get framesReceived => _chunks.length;

  /// How many we need in total, or null while it is still unknown.
  int? get totalFrames => _declaredTotal;

  bool get hasManifest => _manifest != null;

  /// True once every data frame is in hand and the manifest has been seen.
  bool get isComplete {
    final total = _declaredTotal;
    if (total == null || _manifest == null) return false;
    return _chunks.length >= total;
  }

  /// True when the transfer is sealed and a session code will be needed.
  bool get needsCode => _manifest?.encrypted ?? false;

  /// 0.0 to 1.0. Returns 0 while the total is unknown.
  double get progress {
    final total = _declaredTotal;
    if (total == null || total == 0) return 0;
    return (_chunks.length / total).clamp(0.0, 1.0);
  }

  /// The frame indexes still missing, in order. Used to tell the user how much
  /// longer to hold the camera up.
  List<int> get missingFrames {
    final total = _declaredTotal;
    if (total == null) return const [];
    return [
      for (var i = 0; i < total; i++)
        if (!_chunks.containsKey(i)) i,
    ];
  }

  /// Frames per second over the last few seconds, or 0 before there is enough
  /// history. Shown live so the user can tell whether moving the phone closer
  /// or steadier is helping.
  double get framesPerSecond {
    _trimScanWindow();
    if (_scanTimes.length < 2) return 0;
    final span = _scanTimes.last.difference(_scanTimes.first).inMilliseconds;
    if (span <= 0) return 0;
    return (_scanTimes.length - 1) * 1000 / span;
  }

  /// Rough seconds remaining, from the rate at which new frames are landing.
  /// Null while there is not enough information to guess honestly.
  Duration? get estimatedRemaining {
    final total = _declaredTotal;
    final started = _startedAt;
    if (total == null || started == null || _chunks.isEmpty) return null;
    final remaining = total - _chunks.length;
    if (remaining <= 0) return Duration.zero;
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    if (elapsed <= 0) return null;
    final msPerFrame = elapsed / _chunks.length;
    return Duration(milliseconds: (msPerFrame * remaining).round());
  }

  /// Feeds one raw scanned string in. Never throws.
  AirqrOfferResult offer(String raw) {
    AirqrParsedFrame parsed;
    try {
      parsed = AirqrCodec.parseFrame(raw);
    } on AirqrFrameException catch (e) {
      return AirqrOfferResult(AirqrOfferOutcome.rejected, e.message);
    }

    if (parsed.isManifest) {
      return _offerManifest(parsed.manifest!);
    }
    return _offerData(parsed.data!);
  }

  AirqrOfferResult _offerManifest(AirqrManifest incoming) {
    final current = _manifest;
    if (current == null) {
      // A data frame may already have told us the total. If the manifest
      // disagrees, the frames we hold belong to something else — drop them.
      if (_declaredTotal != null && _declaredTotal != incoming.totalFrames) {
        _chunks.clear();
      }
      _manifest = incoming;
      _declaredTotal = incoming.totalFrames;
      _startedAt ??= DateTime.now();
      return const AirqrOfferResult(AirqrOfferOutcome.manifest);
    }
    if (current.digest == incoming.digest) {
      return const AirqrOfferResult(AirqrOfferOutcome.duplicate);
    }
    // A different transfer is now on screen. Start it cleanly rather than
    // mixing two payloads together.
    reset();
    _manifest = incoming;
    _declaredTotal = incoming.totalFrames;
    _startedAt = DateTime.now();
    return const AirqrOfferResult(AirqrOfferOutcome.restarted);
  }

  AirqrOfferResult _offerData(AirqrDataFrame frame) {
    final total = _declaredTotal;
    if (total != null && frame.totalFrames != total) {
      // This frame belongs to a different transfer than the one in progress.
      return const AirqrOfferResult(
        AirqrOfferOutcome.rejected,
        'That frame is from a different transfer.',
      );
    }
    _declaredTotal ??= frame.totalFrames;
    if (_chunks.containsKey(frame.index)) {
      return const AirqrOfferResult(AirqrOfferOutcome.duplicate);
    }
    if (_chunks.length >= AirqrConstants.maxFrames) {
      return const AirqrOfferResult(
        AirqrOfferOutcome.rejected,
        'That transfer is too large.',
      );
    }
    _chunks[frame.index] = frame.bytes;
    _startedAt ??= DateTime.now();
    _scanTimes.add(DateTime.now());
    _trimScanWindow();
    return const AirqrOfferResult(AirqrOfferOutcome.accepted);
  }

  /// Rebuilds the payload. Call only when [isComplete] is true. [code] is the
  /// session code the user typed; it is required when [needsCode] is set.
  ///
  /// Throws [AirqrFrameException] (wrong code, damage, digest mismatch) or
  /// [AirqrPayloadException] (bad envelope). Both messages are user-safe.
  AirqrPayload assemble({String? code}) {
    final manifest = _manifest;
    if (manifest == null || !isComplete) {
      throw const AirqrFrameException('The transfer is not complete yet.');
    }
    final ordered = <Uint8List>[
      for (var i = 0; i < manifest.totalFrames; i++) _chunks[i]!,
    ];
    return AirqrCodec.assemble(
      manifest: manifest,
      orderedChunks: ordered,
      code: code,
    );
  }

  /// Forgets everything and starts over.
  void reset() {
    _manifest = null;
    _chunks.clear();
    _declaredTotal = null;
    _scanTimes.clear();
    _startedAt = null;
  }

  /// Keeps the frames-per-second window to the last few seconds so the readout
  /// reflects what is happening now, not the whole session average.
  void _trimScanWindow() {
    final cutoff = DateTime.now().subtract(const Duration(seconds: 3));
    _scanTimes.removeWhere((t) => t.isBefore(cutoff));
  }
}
