import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;

import 'package:text_data/core/backup/backup_constants.dart';

/// Exception thrown when a `.txdata` archive cannot be decrypted or is malformed.
/// Never contains secret keys or plaintext.
class BackupCryptoException implements Exception {
  final String message;
  const BackupCryptoException(this.message);

  @override
  String toString() => 'BackupCryptoException: $message';
}

/// Zero-knowledge cryptographic operations for `.txdata` backup archives.
///
/// Implements:
/// - PBKDF2-HMAC-SHA256 key derivation with 200,000 iterations and 16-byte salt.
/// - AES-256-GCM authenticated encryption and decryption.
/// - Tamper-evident binary container layout with magic header verification.
class BackupCrypto {
  BackupCrypto._();

  static final Random _secure = Random.secure();

  /// Generates [n] cryptographically secure random bytes.
  static Uint8List randomBytes(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _secure.nextInt(256);
    }
    return out;
  }

  /// Derives a 256-bit (32-byte) AES key from [password] and [salt] using
  /// PBKDF2-HMAC-SHA256 with [iterations].
  static Uint8List deriveKey(
    String password,
    Uint8List salt, {
    int iterations = BackupConstants.pbkdf2Iterations,
  }) {
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(
        pc.Pbkdf2Parameters(salt, iterations, BackupConstants.keyLengthBytes),
      );
    return derivator.process(Uint8List.fromList(utf8.encode(password)));
  }

  /// Encrypts unencrypted [payloadBytes] into a `.txdata` binary archive using
  /// AES-256-GCM and a key derived from [password].
  static Uint8List encryptArchive(Uint8List payloadBytes, String password) {
    if (password.length < BackupConstants.minPasswordLength) {
      throw const BackupCryptoException(
        'Password must be at least 6 characters.',
      );
    }

    final salt = randomBytes(BackupConstants.saltLength);
    final nonce = randomBytes(BackupConstants.nonceLength);
    final keyBytes = deriveKey(password, salt);

    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm),
    );

    final encrypted = encrypter.encryptBytes(payloadBytes, iv: enc.IV(nonce));

    final magic = BackupConstants.magicBytes;
    const headerLen =
        7 +
        4 +
        BackupConstants.saltLength +
        BackupConstants.nonceLength; // 39 bytes
    final totalLen = headerLen + encrypted.bytes.length;

    final out = Uint8List(totalLen);
    var offset = 0;

    // 1. Magic bytes (7 bytes)
    out.setRange(offset, offset + magic.length, magic);
    offset += magic.length;

    // 2. Iterations (4 bytes big-endian)
    final bd = ByteData.sublistView(out, offset, offset + 4);
    bd.setUint32(0, BackupConstants.pbkdf2Iterations, Endian.big);
    offset += 4;

    // 3. Salt (16 bytes)
    out.setRange(offset, offset + salt.length, salt);
    offset += salt.length;

    // 4. Nonce / IV (12 bytes)
    out.setRange(offset, offset + nonce.length, nonce);
    offset += nonce.length;

    // 5. Ciphertext + GCM auth tag
    out.setRange(offset, offset + encrypted.bytes.length, encrypted.bytes);

    return out;
  }

  /// Decrypts a `.txdata` binary archive using [password].
  ///
  /// Throws [BackupCryptoException] if:
  /// - The header does not match `TXDATA\x01`.
  /// - The archive is truncated or corrupted.
  /// - The password is wrong (failing AES-GCM tag authentication).
  static Uint8List decryptArchive(Uint8List archiveBytes, String password) {
    final magic = BackupConstants.magicBytes;
    const minHeaderLen =
        7 +
        4 +
        BackupConstants.saltLength +
        BackupConstants.nonceLength; // 39 bytes
    const minTagLen = 16;

    if (archiveBytes.length < minHeaderLen + minTagLen) {
      throw const BackupCryptoException(
        'Archive file is too small or truncated.',
      );
    }

    // 1. Validate magic header
    for (var i = 0; i < magic.length; i++) {
      if (archiveBytes[i] != magic[i]) {
        throw const BackupCryptoException(
          'Not a valid TextData (.txdata) backup archive.',
        );
      }
    }

    var offset = magic.length;

    // 2. Read iterations
    final bd = ByteData.sublistView(archiveBytes, offset, offset + 4);
    final iterations = bd.getUint32(0, Endian.big);
    offset += 4;

    if (iterations < 1000 || iterations > 5000000) {
      throw const BackupCryptoException(
        'Invalid iteration count in archive header.',
      );
    }

    // 3. Read salt (16 bytes)
    final salt = archiveBytes.sublist(
      offset,
      offset + BackupConstants.saltLength,
    );
    offset += BackupConstants.saltLength;

    // 4. Read nonce (12 bytes)
    final nonce = archiveBytes.sublist(
      offset,
      offset + BackupConstants.nonceLength,
    );
    offset += BackupConstants.nonceLength;

    // 5. Ciphertext + GCM Tag
    final ciphertextWithTag = archiveBytes.sublist(offset);

    // 6. Derive key & decrypt with AES-256-GCM
    final keyBytes = deriveKey(password, salt, iterations: iterations);
    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm),
    );

    try {
      final decrypted = encrypter.decryptBytes(
        enc.Encrypted(ciphertextWithTag),
        iv: enc.IV(nonce),
      );
      return Uint8List.fromList(decrypted);
    } catch (_) {
      throw const BackupCryptoException(
        'Invalid password or corrupted backup archive.',
      );
    }
  }
}
