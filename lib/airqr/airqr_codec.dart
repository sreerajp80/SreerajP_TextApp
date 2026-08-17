// Phase 18 — Optical air-gap transfer (AirQR): the frame codec.
//
// This is the whole wire format, and it is pure Dart with no Flutter import so
// it can be tested without a device or a camera.
//
// Sending  : envelope JSON → gzip → AES-256-GCM seal → base64url → N chunks,
//            plus one manifest frame describing the set.
// Receiving: parse each frame strictly → collect chunks → join → unseal →
//            gunzip → verify SHA-256 → parse the envelope.
//
// Security model (mirrors lib/sync/, security-rules):
//   * The session code is the out-of-band secret. It is shown on the sending
//     screen and typed on the receiving one. It is NEVER inside a frame.
//   * The key is PBKDF2-HMAC-SHA256 over the code with a per-session random
//     salt. The salt is not secret and rides in the manifest frame.
//   * Every chunk is sealed with AES-256-GCM. A wrong code derives a wrong key,
//     the GCM tag fails, and unsealing throws — that failure IS the
//     authentication.
//   * A QR stream is visible to anyone who can see the screen. Sealing is what
//     makes a recorded stream useless without the code.
//
// Nothing here logs the code, the key, the salt, or any content.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'package:sreerajp_textapp/airqr/airqr_constants.dart';
import 'package:sreerajp_textapp/airqr/airqr_payload.dart';
import 'package:sreerajp_textapp/sync/sync_crypto.dart';

/// Thrown when a scanned string is not a usable frame. The message is user-safe
/// — the receive screen shows it and keeps scanning.
class AirqrFrameException implements Exception {
  final String message;
  const AirqrFrameException(this.message);
  @override
  String toString() => 'AirqrFrameException: $message';
}

/// The manifest frame: what this transfer is, and how to check it.
class AirqrManifest {
  /// How many data frames make up the payload.
  final int totalFrames;

  /// [AirqrConstants.kindSnippet] or [AirqrConstants.kindDocument].
  final String kind;

  /// PBKDF2 salt. Empty when the transfer is not sealed.
  final Uint8List salt;

  /// Lower-case hex SHA-256 of the plaintext envelope bytes. Checked after the
  /// payload is fully reassembled and unsealed, so it verifies the whole chain.
  final String digest;

  final bool gzipped;
  final bool encrypted;

  const AirqrManifest({
    required this.totalFrames,
    required this.kind,
    required this.salt,
    required this.digest,
    required this.gzipped,
    required this.encrypted,
  });
}

/// One data frame: its position in the set, and its slice of the payload.
class AirqrDataFrame {
  final int index;
  final int totalFrames;
  final Uint8List bytes;

  const AirqrDataFrame({
    required this.index,
    required this.totalFrames,
    required this.bytes,
  });
}

/// A parsed frame is either a manifest or a data frame, never both.
class AirqrParsedFrame {
  final AirqrManifest? manifest;
  final AirqrDataFrame? data;

  const AirqrParsedFrame.manifest(AirqrManifest this.manifest) : data = null;
  const AirqrParsedFrame.data(AirqrDataFrame this.data) : manifest = null;

  bool get isManifest => manifest != null;
}

/// A complete encoded transfer, ready to be shown frame by frame.
class AirqrEncoded {
  /// The manifest frame string. Shown first, and again on every pass, because
  /// the receiver may start scanning late.
  final String manifestFrame;

  /// The data frame strings, in order.
  final List<String> dataFrames;

  /// Size of the plaintext envelope, for the progress and time estimate.
  final int payloadBytes;

  /// Size actually being transmitted after gzip and sealing.
  final int wireBytes;

  const AirqrEncoded({
    required this.manifestFrame,
    required this.dataFrames,
    required this.payloadBytes,
    required this.wireBytes,
  });

  int get totalFrames => dataFrames.length;

  /// Every frame in display order: the manifest, then the data frames. The
  /// sender loops this list (see [AirqrSender]).
  List<String> get allFrames => [manifestFrame, ...dataFrames];
}

/// Pure encode / decode. Static because it holds no state.
class AirqrCodec {
  AirqrCodec._();

  /// A fresh session code of [length] characters, drawn from the same
  /// look-alike-free alphabet LAN sync uses.
  static String generateSessionCode({
    int length = AirqrConstants.shortCodeLength,
  }) {
    // SyncCrypto.generatePairingCode() is fixed at 64 characters, so sample the
    // shared alphabet directly here. Rejection sampling keeps the distribution
    // flat (no modulo bias), exactly as SyncCrypto does.
    const alphabet = AirqrConstants.codeAlphabet;
    const n = alphabet.length;
    const limit = 256 - (256 % n);
    final buf = StringBuffer();
    while (buf.length < length) {
      final b = SyncCrypto.randomBytes(1)[0];
      if (b >= limit) continue;
      buf.write(alphabet[b % n]);
    }
    return buf.toString();
  }

  /// Groups the code for display only (`ABC-DEF`). Does not change its value.
  static String formatCode(String code) {
    const g = AirqrConstants.codeDisplayGroup;
    final parts = <String>[];
    for (var i = 0; i < code.length; i += g) {
      parts.add(code.substring(i, i + g > code.length ? code.length : i + g));
    }
    return parts.join('-');
  }

  /// Cleans a typed code: upper-case, separators dropped. The alphabet has no
  /// look-alike characters, so there is no safe substitution to make.
  static String normalizeCode(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');

  /// True when [code] is a plausible session code: right kind of characters,
  /// and at least the short length.
  static bool isValidCode(String code) {
    if (code.length < AirqrConstants.shortCodeLength) return false;
    if (code.length > AirqrConstants.longCodeLength) return false;
    for (final ch in code.split('')) {
      if (!AirqrConstants.codeAlphabet.contains(ch)) return false;
    }
    return true;
  }

  // --- Encode ---------------------------------------------------------------

  /// Turns [payload] into a manifest frame plus data frames.
  ///
  /// [code] is the session code; pass null to send unsealed (the UI warns
  /// loudly when it does). [chunkBytes] is the payload budget per frame.
  static AirqrEncoded encode({
    required AirqrPayload payload,
    String? code,
    int chunkBytes = AirqrConstants.frameChunkBytes,
    bool compress = true,
  }) {
    final clampedChunk = chunkBytes.clamp(
      AirqrConstants.minChunkBytes,
      AirqrConstants.maxChunkBytes,
    );

    final plain = Uint8List.fromList(payload.toWireBytes());
    if (plain.length > AirqrConstants.hardCapBytes) {
      throw const AirqrPayloadException(
        'This is too large to send by QR code. Use LAN sync instead.',
      );
    }
    // The digest covers the plaintext envelope, so verifying it at the end
    // proves the whole chain (frames → unseal → gunzip) was faithful.
    final digest = sha256.convert(plain).toString();

    var body = plain;
    if (compress) {
      body = Uint8List.fromList(gzip.encode(plain));
    }

    var salt = Uint8List(0);
    if (code != null) {
      salt = SyncCrypto.randomBytes(16);
      final key = SyncCrypto.deriveKey(code, salt);
      // encryptWire takes and returns text, so the compressed bytes ride as
      // base64 inside it. The double base64 costs ~33% of the compressed size,
      // which gzip has already more than paid for.
      final sealed = SyncCrypto.encryptWire(key, base64.encode(body));
      body = Uint8List.fromList(utf8.encode(sealed));
    }

    final wire = base64Url.encode(body).replaceAll('=', '');
    final dataFrames = <String>[];
    // Chunk the base64url text, not the bytes, so every chunk is already
    // URI-safe and no frame needs percent-encoding.
    for (var i = 0; i < wire.length; i += clampedChunk) {
      final end = i + clampedChunk > wire.length
          ? wire.length
          : i + clampedChunk;
      dataFrames.add(wire.substring(i, end));
    }
    if (dataFrames.isEmpty) {
      throw const AirqrPayloadException('There is nothing to send.');
    }
    if (dataFrames.length > AirqrConstants.maxFrames) {
      throw const AirqrPayloadException(
        'This is too large to send by QR code. Use LAN sync instead.',
      );
    }

    final total = dataFrames.length;
    final manifest = Uri(
      scheme: AirqrConstants.scheme,
      host: AirqrConstants.hostManifest,
      queryParameters: {
        AirqrConstants.keyVersion: '${AirqrConstants.protocolVersion}',
        AirqrConstants.keyTotal: '$total',
        AirqrConstants.keyKind: payload.kind,
        AirqrConstants.keyDigest: digest,
        AirqrConstants.keyGzip: compress ? '1' : '0',
        AirqrConstants.keyEncrypted: code != null ? '1' : '0',
        if (code != null)
          AirqrConstants.keySalt: base64Url.encode(salt).replaceAll('=', ''),
      },
    ).toString();

    final frames = <String>[];
    for (var i = 0; i < total; i++) {
      frames.add(
        Uri(
          scheme: AirqrConstants.scheme,
          host: AirqrConstants.hostFrame,
          queryParameters: {
            AirqrConstants.keyVersion: '${AirqrConstants.protocolVersion}',
            AirqrConstants.keyIndex: '$i',
            AirqrConstants.keyTotal: '$total',
            AirqrConstants.keyData: dataFrames[i],
          },
        ).toString(),
      );
    }

    return AirqrEncoded(
      manifestFrame: manifest,
      dataFrames: frames,
      payloadBytes: plain.length,
      wireBytes: wire.length,
    );
  }

  // --- Decode ---------------------------------------------------------------

  /// Parses one scanned string strictly. Throws [AirqrFrameException] with a
  /// user-safe message for anything that is not one of our frames — the receive
  /// screen shows it and keeps the camera running.
  static AirqrParsedFrame parseFrame(String raw) {
    final trimmed = raw.trim();
    if (trimmed.length > AirqrConstants.maxRawFrameLength) {
      throw const AirqrFrameException('That QR code is not from this app.');
    }
    Uri uri;
    try {
      uri = Uri.parse(trimmed);
    } catch (_) {
      throw const AirqrFrameException('That QR code could not be read.');
    }
    if (uri.scheme != AirqrConstants.scheme) {
      throw const AirqrFrameException('That QR code is not from this app.');
    }
    final version = int.tryParse(
      uri.queryParameters[AirqrConstants.keyVersion] ?? '',
    );
    if (version != AirqrConstants.protocolVersion) {
      throw const AirqrFrameException(
        'That transfer uses a different version of this app.',
      );
    }
    if (uri.host == AirqrConstants.hostManifest) {
      return AirqrParsedFrame.manifest(_parseManifest(uri));
    }
    if (uri.host == AirqrConstants.hostFrame) {
      return AirqrParsedFrame.data(_parseDataFrame(uri));
    }
    throw const AirqrFrameException('That QR code is not from this app.');
  }

  static AirqrManifest _parseManifest(Uri uri) {
    final q = uri.queryParameters;
    final total = int.tryParse(q[AirqrConstants.keyTotal] ?? '');
    if (total == null || total < 1 || total > AirqrConstants.maxFrames) {
      throw const AirqrFrameException('That transfer looks damaged.');
    }
    final kind = q[AirqrConstants.keyKind];
    if (kind == null || !AirqrConstants.allKinds.contains(kind)) {
      throw const AirqrFrameException(
        'That transfer type is not supported here.',
      );
    }
    final digest = q[AirqrConstants.keyDigest];
    if (digest == null || !RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
      throw const AirqrFrameException('That transfer looks damaged.');
    }
    final encrypted = q[AirqrConstants.keyEncrypted] == '1';
    var salt = Uint8List(0);
    if (encrypted) {
      final rawSalt = q[AirqrConstants.keySalt];
      if (rawSalt == null || rawSalt.isEmpty) {
        throw const AirqrFrameException('That transfer looks damaged.');
      }
      try {
        salt = Uint8List.fromList(base64Url.decode(_repad(rawSalt)));
      } catch (_) {
        throw const AirqrFrameException('That transfer looks damaged.');
      }
    }
    return AirqrManifest(
      totalFrames: total,
      kind: kind,
      salt: salt,
      digest: digest,
      gzipped: q[AirqrConstants.keyGzip] == '1',
      encrypted: encrypted,
    );
  }

  static AirqrDataFrame _parseDataFrame(Uri uri) {
    final q = uri.queryParameters;
    final index = int.tryParse(q[AirqrConstants.keyIndex] ?? '');
    final total = int.tryParse(q[AirqrConstants.keyTotal] ?? '');
    final data = q[AirqrConstants.keyData];
    if (total == null || total < 1 || total > AirqrConstants.maxFrames) {
      throw const AirqrFrameException('That transfer looks damaged.');
    }
    if (index == null || index < 0 || index >= total) {
      throw const AirqrFrameException('That transfer looks damaged.');
    }
    if (data == null || data.isEmpty) {
      throw const AirqrFrameException('That transfer looks damaged.');
    }
    // Keep the chunk as text; it is joined with the others before decoding, so
    // an individual chunk is not required to be valid base64 on its own.
    return AirqrDataFrame(
      index: index,
      totalFrames: total,
      bytes: Uint8List.fromList(utf8.encode(data)),
    );
  }

  /// Rebuilds the payload from a complete, ordered set of chunks.
  ///
  /// Throws [AirqrFrameException] when the data does not survive the round trip
  /// (wrong code, corrupt frame, digest mismatch) and [AirqrPayloadException]
  /// when the envelope itself is bad. Both messages are user-safe.
  static AirqrPayload assemble({
    required AirqrManifest manifest,
    required List<Uint8List> orderedChunks,
    String? code,
  }) {
    if (orderedChunks.length != manifest.totalFrames) {
      throw const AirqrFrameException('The transfer is not complete yet.');
    }
    final joined = StringBuffer();
    for (final chunk in orderedChunks) {
      joined.write(utf8.decode(chunk, allowMalformed: true));
    }

    Uint8List body;
    try {
      body = Uint8List.fromList(base64Url.decode(_repad(joined.toString())));
    } catch (_) {
      throw const AirqrFrameException(
        'The transfer was damaged. Please try again.',
      );
    }

    if (manifest.encrypted) {
      if (code == null || code.isEmpty) {
        throw const AirqrFrameException('This transfer needs a code.');
      }
      final key = SyncCrypto.deriveKey(code, manifest.salt);
      try {
        final opened = SyncCrypto.decryptWire(key, utf8.decode(body));
        body = Uint8List.fromList(base64.decode(opened));
      } on SyncCryptoException {
        // A wrong code fails the GCM tag here. This is the authentication.
        throw const AirqrFrameException(
          'That code did not match this transfer.',
        );
      } catch (_) {
        throw const AirqrFrameException(
          'The transfer was damaged. Please try again.',
        );
      }
    }

    if (manifest.gzipped) {
      try {
        body = Uint8List.fromList(gzip.decode(body));
      } catch (_) {
        throw const AirqrFrameException(
          'The transfer was damaged. Please try again.',
        );
      }
    }

    if (sha256.convert(body).toString() != manifest.digest) {
      throw const AirqrFrameException(
        'The transfer failed its integrity check. Please try again.',
      );
    }

    return AirqrPayload.validateAndParse(
      utf8.decode(body, allowMalformed: true),
    );
  }

  /// base64url without padding is what travels; Dart's decoder wants the
  /// padding back.
  static String _repad(String s) {
    final remainder = s.length % 4;
    if (remainder == 0) return s;
    return s + ('=' * (4 - remainder));
  }
}
