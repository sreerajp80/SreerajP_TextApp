import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:text_data/core/vault/vault_constants.dart';
import 'package:text_data/core/vault/vault_models.dart';

/// Exception thrown when a `.txvault` file cannot be decrypted or is malformed.
/// Never contains secret keys or plaintext.
class VaultCryptoException implements Exception {
  final String message;
  const VaultCryptoException(this.message);

  @override
  String toString() => 'VaultCryptoException: $message';
}

/// Zero-knowledge cryptographic operations for Per-Document Biometric Vault (`.txvault`).
///
/// Implements:
/// - Tamper-evident authenticated binary envelope packaging (`TXVAULT\x01`).
/// - AES-256-GCM authenticated encryption and decryption.
/// - Random nonce and key generation via cryptographically secure RNG.
class VaultCrypto {
  VaultCrypto._();

  static final Random _secure = Random.secure();

  /// Header length: Magic (8) + Salt (16) + Nonce (12) = 36 bytes.
  static const int headerLength =
      8 + VaultConstants.saltLength + VaultConstants.nonceLength;

  /// Generates [n] cryptographically secure random bytes.
  static Uint8List randomBytes(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _secure.nextInt(256);
    }
    return out;
  }

  /// Generates a fresh 256-bit (32-byte) Master Vault Key.
  static Uint8List generateMasterKey() {
    return randomBytes(VaultConstants.keyLengthBytes);
  }

  /// Encrypts a [VaultPayload] into binary `.txvault` file bytes using AES-256-GCM.
  static Uint8List encryptVaultFile(VaultPayload payload, Uint8List keyBytes) {
    if (keyBytes.length != VaultConstants.keyLengthBytes) {
      throw const VaultCryptoException('Invalid key length for AES-256 vault.');
    }

    final payloadJson = payload.toWireJson();
    final payloadBytes = Uint8List.fromList(utf8.encode(payloadJson));

    final salt = randomBytes(VaultConstants.saltLength);
    final nonce = randomBytes(VaultConstants.nonceLength);

    final encrypter = enc.Encrypter(
      enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm),
    );

    final encrypted = encrypter.encryptBytes(payloadBytes, iv: enc.IV(nonce));

    final magic = VaultConstants.magicBytes;
    final totalLength = headerLength + encrypted.bytes.length;

    final out = Uint8List(totalLength);
    var offset = 0;

    // 1. Magic bytes (8 bytes)
    out.setRange(offset, offset + magic.length, magic);
    offset += magic.length;

    // 2. Salt (16 bytes)
    out.setRange(offset, offset + salt.length, salt);
    offset += salt.length;

    // 3. Nonce / IV (12 bytes)
    out.setRange(offset, offset + nonce.length, nonce);
    offset += nonce.length;

    // 4. Ciphertext + GCM Tag
    out.setRange(offset, totalLength, encrypted.bytes);

    return out;
  }

  /// Decrypts binary `.txvault` file bytes into a [VaultPayload] using AES-256-GCM.
  static VaultPayload decryptVaultFile(
    Uint8List fileBytes,
    Uint8List keyBytes,
  ) {
    if (keyBytes.length != VaultConstants.keyLengthBytes) {
      throw const VaultCryptoException('Invalid key length for AES-256 vault.');
    }

    if (fileBytes.length < headerLength) {
      throw const VaultCryptoException(
        'File is too small to be a valid .txvault document.',
      );
    }

    // 1. Validate magic header
    final magic = VaultConstants.magicBytes;
    for (var i = 0; i < magic.length; i++) {
      if (fileBytes[i] != magic[i]) {
        throw const VaultCryptoException(
          'Invalid or corrupted .txvault header.',
        );
      }
    }

    var offset = magic.length;

    // 2. Read Salt (16 bytes)
    final salt = Uint8List.sublistView(
      fileBytes,
      offset,
      offset + VaultConstants.saltLength,
    );
    offset += salt.length;

    // 3. Read Nonce (12 bytes)
    final nonce = Uint8List.sublistView(
      fileBytes,
      offset,
      offset + VaultConstants.nonceLength,
    );
    offset += nonce.length;

    // 4. Read Ciphertext
    final ciphertext = Uint8List.sublistView(fileBytes, offset);

    // 5. Decrypt AES-256-GCM
    try {
      final encrypter = enc.Encrypter(
        enc.AES(enc.Key(keyBytes), mode: enc.AESMode.gcm),
      );

      final decryptedBytes = encrypter.decryptBytes(
        enc.Encrypted(ciphertext),
        iv: enc.IV(nonce),
      );

      final payloadJson = utf8.decode(decryptedBytes);
      return VaultPayload.fromWireJson(payloadJson);
    } catch (e) {
      if (e is VaultCryptoException) rethrow;
      throw const VaultCryptoException(
        'Decryption failed. Authentication error or corrupted data.',
      );
    }
  }

  /// Returns true if [fileBytes] starts with the `.txvault` magic signature.
  static bool hasVaultMagic(Uint8List fileBytes) {
    final magic = VaultConstants.magicBytes;
    if (fileBytes.length < magic.length) return false;
    for (var i = 0; i < magic.length; i++) {
      if (fileBytes[i] != magic[i]) return false;
    }
    return true;
  }
}
