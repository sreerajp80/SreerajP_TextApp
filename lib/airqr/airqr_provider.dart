// Phase 18 — Optical air-gap transfer (AirQR): state orchestration.
//
// Two [ChangeNotifier]s, one per direction. They own the clock, the session
// code, and the phase machine; the screens only render what they expose. This
// is the same shape `lib/sync/sync_provider.dart` uses, and it keeps every
// decision out of the widgets (CLAUDE.md §4).
//
// Neither controller touches a repository or the database. A transfer is
// entirely in memory until the user chooses to save the result, so there is
// nothing to persist and nothing to clean up but a timer.
//
// Nothing here logs the code, the key, or any content (security-rules).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/airqr/airqr_codec.dart';
import 'package:sreerajp_textapp/airqr/airqr_constants.dart';
import 'package:sreerajp_textapp/airqr/airqr_payload.dart';
import 'package:sreerajp_textapp/airqr/airqr_receiver.dart';
import 'package:sreerajp_textapp/airqr/airqr_sender.dart';

/// Where a receive session has got to.
enum AirqrReceivePhase {
  /// Camera running, frames being collected.
  scanning,

  /// Every frame is in hand; waiting for the user to type the session code.
  needCode,

  /// Reassembling, unsealing, and verifying.
  assembling,

  /// A payload is ready for the user to use or save.
  done,

  /// Failed in a way the user must acknowledge.
  error,
}

/// Drives the animated QR on the sending device.
class AirqrSendController extends ChangeNotifier {
  final AirqrPayload payload;

  Timer? _timer;
  AirqrSender? _sender;
  AirqrEncoded? _encoded;
  String? _code;
  String? _errorMessage;

  int _fps = AirqrConstants.defaultFps;
  int _chunkBytes = AirqrConstants.frameChunkBytes;
  bool _disposed = false;

  AirqrSendController({required this.payload, bool encrypt = true}) {
    _code = encrypt ? AirqrCodec.generateSessionCode() : null;
    _rebuild();
  }

  /// The session code the user reads to the other device, or null when this
  /// transfer is deliberately unsealed.
  String? get code => _code;

  /// The code grouped for display (`ABC-DEF`).
  String? get formattedCode =>
      _code == null ? null : AirqrCodec.formatCode(_code!);

  bool get isEncrypted => _code != null;

  /// The frame to draw right now, or null if the payload could not be encoded.
  String? get currentFrame => _sender?.currentFrame;

  int get totalFrames => _encoded?.totalFrames ?? 0;
  int get passesCompleted => _sender?.passesCompleted ?? 0;
  int get payloadBytes => _encoded?.payloadBytes ?? 0;
  int get fps => _fps;
  int get chunkBytes => _chunkBytes;
  bool get isRunning => _timer != null;

  /// User-safe failure message, or null.
  String? get errorMessage => _errorMessage;

  /// Roughly how long one full pass takes. Shown so the user knows how long to
  /// hold the devices steady; a real transfer usually needs more than one pass.
  Duration get onePassDuration {
    final frames = (_encoded?.allFrames.length ?? 0);
    if (frames == 0 || _fps == 0) return Duration.zero;
    return Duration(milliseconds: (frames * 1000 / _fps).round());
  }

  /// Starts (or restarts) the animation.
  void start() {
    if (_encoded == null) return;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: (1000 / _fps).round()), (_) {
      _sender?.advance();
      _safeNotify();
    });
    _safeNotify();
  }

  /// Stops the animation but keeps the encoded frames, so it can resume.
  void stop() {
    _timer?.cancel();
    _timer = null;
    _safeNotify();
  }

  /// Changes the animation speed, restarting the timer if it is running.
  void setFps(int value) {
    final clamped = value.clamp(AirqrConstants.minFps, AirqrConstants.maxFps);
    if (clamped == _fps) return;
    _fps = clamped;
    if (isRunning) {
      start();
    } else {
      _safeNotify();
    }
  }

  /// Changes how much payload each frame carries. A smaller chunk makes a
  /// sparser, easier-to-scan QR but needs more frames, so this re-encodes.
  void setChunkBytes(int value) {
    final clamped = value.clamp(
      AirqrConstants.minChunkBytes,
      AirqrConstants.maxChunkBytes,
    );
    if (clamped == _chunkBytes) return;
    _chunkBytes = clamped;
    final wasRunning = isRunning;
    _rebuild();
    if (wasRunning) start();
  }

  void _rebuild() {
    try {
      final encoded = AirqrCodec.encode(
        payload: payload,
        code: _code,
        chunkBytes: _chunkBytes,
      );
      _encoded = encoded;
      _sender = AirqrSender(encoded);
      _errorMessage = null;
    } on AirqrPayloadException catch (e) {
      _encoded = null;
      _sender = null;
      _errorMessage = e.message;
    }
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}

/// Collects frames on the receiving device and reassembles the payload.
class AirqrReceiveController extends ChangeNotifier {
  final AirqrReceiver _receiver = AirqrReceiver();

  AirqrReceivePhase _phase = AirqrReceivePhase.scanning;
  String? _errorMessage;

  /// The most recent rejection, shown briefly so the user knows a QR was seen
  /// but was not ours. Never fatal.
  String? _lastRejection;

  AirqrPayload? _result;
  bool _disposed = false;

  AirqrReceivePhase get phase => _phase;
  String? get errorMessage => _errorMessage;
  String? get lastRejection => _lastRejection;
  AirqrPayload? get result => _result;

  int get framesReceived => _receiver.framesReceived;
  int? get totalFrames => _receiver.totalFrames;
  double get progress => _receiver.progress;
  double get framesPerSecond => _receiver.framesPerSecond;
  Duration? get estimatedRemaining => _receiver.estimatedRemaining;
  bool get hasManifest => _receiver.hasManifest;
  int get missingCount => _receiver.missingFrames.length;

  /// Feeds one scanned string in. Safe to call at camera rate; most scans are
  /// duplicates by design, because the sender loops.
  void onScan(String raw) {
    if (_phase != AirqrReceivePhase.scanning) return;

    final result = _receiver.offer(raw);
    if (result.outcome == AirqrOfferOutcome.rejected) {
      _lastRejection = result.message;
      _safeNotify();
      return;
    }
    _lastRejection = null;

    if (_receiver.isComplete) {
      if (_receiver.needsCode) {
        _phase = AirqrReceivePhase.needCode;
        _safeNotify();
        return;
      }
      _assemble(null);
      return;
    }
    _safeNotify();
  }

  /// Supplies the session code once every frame has arrived.
  void submitCode(String raw) {
    if (_phase != AirqrReceivePhase.needCode) return;
    _assemble(AirqrCodec.normalizeCode(raw));
  }

  void _assemble(String? code) {
    _phase = AirqrReceivePhase.assembling;
    _safeNotify();
    try {
      _result = _receiver.assemble(code: code);
      _phase = AirqrReceivePhase.done;
      _errorMessage = null;
    } on AirqrFrameException catch (e) {
      _errorMessage = e.message;
      // A wrong code is worth another try without rescanning every frame — the
      // frames are still in hand, only the code was wrong.
      _phase = _receiver.needsCode
          ? AirqrReceivePhase.needCode
          : AirqrReceivePhase.error;
    } on AirqrPayloadException catch (e) {
      _errorMessage = e.message;
      _phase = AirqrReceivePhase.error;
    }
    _safeNotify();
  }

  /// Throws away everything and scans again from scratch.
  void restart() {
    _receiver.reset();
    _phase = AirqrReceivePhase.scanning;
    _errorMessage = null;
    _lastRejection = null;
    _result = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// The receive controller, scoped to the receive screen.
///
/// `autoDispose` matters here: a half-finished transfer holds the frames it has
/// collected in memory, and leaving the screen must drop them rather than leak
/// a stranger's partial document into the next session.
final airqrReceiveControllerProvider =
    Provider.autoDispose<AirqrReceiveController>((ref) {
      final controller = AirqrReceiveController();
      ref.onDispose(controller.dispose);
      return controller;
    });
