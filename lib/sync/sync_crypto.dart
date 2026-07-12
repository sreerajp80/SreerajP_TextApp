// Phase 12 — P2P LAN sync: all crypto and the strict QR URI codec.
//
// Security model (architecture.md §9.1, security-rules):
//   * The pairing code is fresh per session, ~320 bits, from Random.secure().
//   * The code moves OUT OF BAND (QR or typed). It never goes on the wire.
//   * Both sides derive an AES-256 key from the code with PBKDF2-HMAC-SHA256
//     using a per-session random salt (the salt is not secret; it is sent in
//     the clear over the socket, NOT in the QR).
//   * Every wire message is sealed with AES-256-GCM. A wrong code derives a
//     wrong key, the GCM tag fails, and decryption throws — that failure IS the
//     authentication.
//
// Nothing here logs the code, keys, salt, or plaintext.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

import 'sync_constants.dart';

/// Thrown when a wire message cannot be decrypted or is malformed. Carries no
/// secret material — the message is user-safe.
class SyncCryptoException implements Exception {
  final String message;
  const SyncCryptoException(this.message);
  @override
  String toString() => 'SyncCryptoException: $message';
}

/// A pairing target parsed from a QR (or built for one). The [code] is the
/// out-of-band secret; [host]/[port] say where to connect.
class QrPairing {
  final String host;
  final int port;
  final String code;
  const QrPairing({required this.host, required this.port, required this.code});
}

/// Result of parsing a scanned QR. Either [pairing] is set, or [error] explains
/// (in user-safe words) why the QR was rejected. Never throws to the UI.
class QrParseResult {
  final QrPairing? pairing;
  final String? error;
  const QrParseResult.ok(this.pairing) : error = null;
  const QrParseResult.fail(this.error) : pairing = null;
  bool get isOk => pairing != null;
}

/// Pure crypto helpers for sync. Static because they hold no state.
class SyncCrypto {
  SyncCrypto._();

  static final Random _secure = Random.secure();

  /// [n] cryptographically secure random bytes (security-rules: use
  /// Random.secure() for all security randomness).
  static Uint8List randomBytes(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _secure.nextInt(256);
    }
    return out;
  }

  // --- Pairing code ---------------------------------------------------------

  /// A fresh pairing code: [SyncConstants.codeLength] characters drawn
  /// uniformly (rejection-sampled to avoid modulo bias) from the reduced
  /// alphabet.
  static String generatePairingCode() {
    const alphabet = SyncConstants.codeAlphabet;
    final n = alphabet.length; // 31
    // Largest multiple of n that fits in a byte, for unbiased sampling.
    final limit = 256 - (256 % n);
    final buf = StringBuffer();
    while (buf.length < SyncConstants.codeLength) {
      final b = _secure.nextInt(256);
      if (b >= limit) continue; // reject to keep the distribution flat
      buf.write(alphabet[b % n]);
    }
    return buf.toString();
  }

  /// Cleans a typed or scanned code: upper-case and drop the separators used
  /// for display (spaces, dashes, tabs, newlines).
  ///
  /// The alphabet deliberately has no look-alike characters (`0 O 1 I L` are
  /// all excluded), so there is no safe substitution to make here — any such
  /// character a person mistypes is simply invalid and is caught by
  /// [isValidCode].
  static String normalizeCode(String raw) {
    return raw
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// Groups the code for display only (e.g. `ABCD-EFGH-...`). Does not change
  /// the code's value.
  static String formatCode(String code) {
    final g = SyncConstants.codeDisplayGroup;
    final parts = <String>[];
    for (var i = 0; i < code.length; i += g) {
      parts.add(code.substring(i, i + g > code.length ? code.length : i + g));
    }
    return parts.join('-');
  }

  /// True if [code] is exactly the right length and every character is in the
  /// alphabet.
  static bool isValidCode(String code) {
    if (code.length != SyncConstants.codeLength) return false;
    for (final ch in code.split('')) {
      if (!SyncConstants.codeAlphabet.contains(ch)) return false;
    }
    return true;
  }

  // --- Key derivation -------------------------------------------------------

  /// Derives the AES-256 key from the pairing [code] and a per-session [salt]
  /// with PBKDF2-HMAC-SHA256.
  static Uint8List deriveKey(String code, Uint8List salt) {
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(
        salt,
        SyncConstants.pbkdf2Iterations,
        SyncConstants.keyLengthBytes,
      ));
    return derivator.process(Uint8List.fromList(utf8.encode(code)));
  }

  // --- AES-256-GCM wire sealing --------------------------------------------

  /// Seals [plaintext] (UTF-8) under [key] and returns one base64 line:
  /// `base64(nonce(12) || ciphertext+tag)`.
  static String encryptWire(List<int> key, String plaintext) {
    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(Uint8List.fromList(key)), mode: enc.AESMode.gcm),
    );
    final nonce = randomBytes(SyncConstants.gcmNonceLength);
    final sealed = encrypter.encryptBytes(
      utf8.encode(plaintext),
      iv: enc.IV(nonce),
    );
    final out = Uint8List(nonce.length + sealed.bytes.length)
      ..setRange(0, nonce.length, nonce)
      ..setRange(nonce.length, nonce.length + sealed.bytes.length, sealed.bytes);
    return base64.encode(out);
  }

  /// Opens a wire line produced by [encryptWire]. Throws
  /// [SyncCryptoException] if the line is malformed or the GCM tag fails
  /// (wrong key). The message never contains secret material.
  static String decryptWire(List<int> key, String wire) {
    late final Uint8List raw;
    try {
      raw = base64.decode(wire.trim());
    } catch (_) {
      throw const SyncCryptoException('malformed wire line');
    }
    final nonceLen = SyncConstants.gcmNonceLength;
    if (raw.length <= nonceLen) {
      throw const SyncCryptoException('wire line too short');
    }
    final nonce = raw.sublist(0, nonceLen);
    final body = raw.sublist(nonceLen);
    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(Uint8List.fromList(key)), mode: enc.AESMode.gcm),
    );
    try {
      final bytes = encrypter.decryptBytes(enc.Encrypted(body), iv: enc.IV(nonce));
      return utf8.decode(bytes);
    } catch (_) {
      // A wrong key or a tampered message fails the GCM tag here.
      throw const SyncCryptoException('decryption failed (wrong code?)');
    }
  }

  // --- Strict QR URI codec --------------------------------------------------

  /// Builds the pairing QR URI. It carries where to connect and the code; the
  /// QR is the out-of-band channel, so the code belongs here (never on the
  /// socket).
  static String buildQrUri(QrPairing p) {
    final uri = Uri(
      scheme: SyncConstants.qrScheme,
      host: SyncConstants.qrHost,
      queryParameters: {
        'v': SyncConstants.protocolVersion.toString(),
        'h': p.host,
        'p': p.port.toString(),
        'c': p.code,
      },
    );
    return uri.toString();
  }

  /// Parses a scanned string strictly. Rejects a foreign or malformed QR with a
  /// user-safe message instead of throwing.
  static QrParseResult parseQrUri(String raw) {
    Uri uri;
    try {
      uri = Uri.parse(raw.trim());
    } catch (_) {
      return const QrParseResult.fail('This is not a valid pairing code.');
    }
    if (uri.scheme != SyncConstants.qrScheme || uri.host != SyncConstants.qrHost) {
      return const QrParseResult.fail('This QR is not from this app.');
    }
    final v = int.tryParse(uri.queryParameters['v'] ?? '');
    if (v != SyncConstants.protocolVersion) {
      return const QrParseResult.fail('This pairing code is a different version.');
    }
    final host = uri.queryParameters['h'];
    final port = int.tryParse(uri.queryParameters['p'] ?? '');
    final code = uri.queryParameters['c'];
    if (host == null || host.isEmpty) {
      return const QrParseResult.fail('The pairing code is missing the address.');
    }
    if (port == null || port < 1 || port > 65535) {
      return const QrParseResult.fail('The pairing code has a bad port.');
    }
    if (code == null || !isValidCode(code)) {
      return const QrParseResult.fail('The pairing code is malformed.');
    }
    return QrParseResult.ok(QrPairing(host: host, port: port, code: code));
  }
}

/// Re-seals a secret so it is only ever session-key-encrypted on the wire, and
/// device-key-encrypted at rest on both ends (architecture.md §9.5).
///
/// No sync category holds a per-record secret today, so this machinery is built
/// and tested for correctness but not yet wired to a live category. The round
/// trip device-key → session-key → device-key must return the original bytes.
class SecretResealer {
  SecretResealer._();

  /// Host side: take a secret stored under the device key and re-seal it under
  /// the session key for the wire.
  static String toSession({
    required String deviceKeyWire,
    required List<int> deviceKey,
    required List<int> sessionKey,
  }) {
    final plain = SyncCrypto.decryptWire(deviceKey, deviceKeyWire);
    return SyncCrypto.encryptWire(sessionKey, plain);
  }

  /// Client side: take a secret received under the session key and re-encrypt
  /// it under this device's own key before storage.
  static String toDevice({
    required String sessionKeyWire,
    required List<int> sessionKey,
    required List<int> deviceKey,
  }) {
    final plain = SyncCrypto.decryptWire(sessionKey, sessionKeyWire);
    return SyncCrypto.encryptWire(deviceKey, plain);
  }
}
