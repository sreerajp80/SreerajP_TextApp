import 'dart:typed_data';

/// Technical constants for the Per-Document Biometric Vault (.txvault)
/// subsystem (Feature 4.5; security enhancements).
class VaultConstants {
  VaultConstants._();

  /// Magic header prefix at the start of every `.txvault` file:
  /// ASCII `TXVAULT` followed by format version `0x01` (8 bytes total).
  static final Uint8List magicBytes = Uint8List.fromList([
    0x54, 0x58, 0x56, 0x41, 0x55, 0x4C, 0x54, 0x01, // TXVAULT\x01
  ]);

  /// Current binary envelope format version.
  static const int formatVersion = 1;

  /// Application identifier embedded in vault metadata.
  static const String appId = 'in.sreerajp.TextAPP';

  /// Length of the random salt in bytes (16 bytes = 128 bits).
  static const int saltLength = 16;

  /// Length of the AES-GCM nonce (IV) in bytes (12 bytes = 96 bits).
  static const int nonceLength = 12;

  /// Length of the AES-256 key in bytes (32 bytes = 256 bits).
  static const int keyLengthBytes = 32;

  /// File extension for encrypted document vault files.
  static const String fileExtension = '.txvault';

  /// Default MIME type for the encrypted vault file.
  static const String mimeType = 'application/octet-stream';

  /// Secure storage key where the hardware-backed Master Vault Key is held.
  static const String masterVaultKeyStorageKey = 'vault_master_key';

  /// Maximum file size supported for in-memory vault encryption/decryption (50 MB).
  static const int maxVaultSizeBytes = 50 * 1024 * 1024;
}
