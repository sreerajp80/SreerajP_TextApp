import 'dart:typed_data';

/// Technical constants for the Zero-Knowledge Encrypted Backup Archive (.txdata)
/// subsystem (Feature 12; ecosystem synergy).
class BackupConstants {
  BackupConstants._();

  /// Magic header prefix at the start of every `.txdata` backup file:
  /// ASCII `TXDATA` followed by format version `0x01` (7 bytes total).
  static final Uint8List magicBytes = Uint8List.fromList([
    0x54, 0x58, 0x44, 0x41, 0x54, 0x41, 0x01, // TXDATA\x01
  ]);

  /// Current binary envelope format version.
  static const int formatVersion = 1;

  /// Application identifier embedded in backup manifests.
  static const String appId = 'in.sreerajp.TextAPP';

  /// Number of PBKDF2 iterations for password-based key derivation (200,000).
  static const int pbkdf2Iterations = 200000;

  /// Length of the random salt in bytes (16 bytes = 128 bits).
  static const int saltLength = 16;

  /// Length of the AES-GCM nonce (IV) in bytes (12 bytes = 96 bits).
  static const int nonceLength = 12;

  /// Length of the derived AES-256 key in bytes (32 bytes = 256 bits).
  static const int keyLengthBytes = 32;

  /// Minimum password length allowed for creating an encrypted backup.
  static const int minPasswordLength = 6;

  /// File extension for encrypted backup archives.
  static const String fileExtension = '.txdata';

  /// Default MIME type for the backup archive.
  static const String mimeType = 'application/octet-stream';

  /// In-archive file names.
  static const String manifestFileName = 'backup_manifest.json';
  static const String recentsFileName = 'recents.json';
  static const String favoritesFileName = 'favorites.json';
  static const String bookmarksFileName = 'bookmarks.json';
  static const String settingsFileName = 'settings.json';
  static const String filesDirectory = 'files';
}
