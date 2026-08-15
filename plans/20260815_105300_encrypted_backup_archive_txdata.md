# Plan: Implement Feature 12 — Zero-Knowledge Encrypted Backup Archive (.txdata)

**Status:** ready for review

## Issue

Feature 12 from `docs/feature_analysis_and_roadmap.md` is not yet implemented. Users need the ability to export and restore selected files, recents, favorites, bookmarks, and settings into a single password-encrypted AES-256 backup bundle (`.txdata`) with zero-knowledge encryption (PBKDF2-HMAC-SHA256 with 200,000 iterations and 16-byte random salt, AES-256-GCM encryption with password verification upon import).

## Plan

### 1. New Module: `lib/core/backup/`

Create a dedicated backup subsystem following clean architecture and existing crypto patterns:

- `backup_constants.dart`:
  - Magic header bytes: `TXDATA\x01`
  - PBKDF2 iterations: `200000`
  - Salt length: `16` bytes
  - Nonce/IV length: `12` bytes
  - File extension: `.txdata`
  - Default MIME type: `application/octet-stream`

- `backup_models.dart`:
  - `BackupManifest`: metadata including app id, format version, creation timestamp, counts of files, recents, favorites, bookmarks, settings, and file entry list.
  - `BackupFileEntry`: filename, relative path in archive, size, sha256 checksum, MIME type.
  - `BackupExportOptions`: toggles for what to include (files, recents, favorites, bookmarks, settings) and file list.
  - `BackupPreview`: parsed manifest and counts shown to user before confirming restore.
  - `BackupRestoreOptions`: user selections for what to restore, plus merge/replace strategy.
  - `BackupRestoreResult`: summary of restored items and any warnings.

- `backup_crypto.dart`:
  - Pure Dart cryptographic routines using `pointycastle` and `encrypt`:
    - `deriveKey(password, salt, iterations)`: PBKDF2-HMAC-SHA256
    - `encryptArchive(payloadBytes, password)`: generates 16-byte salt and 12-byte nonce, derives AES-256 key, seals payload with AES-256-GCM, prefixes binary header (`TXDATA\x01` + iterations + salt + nonce + ciphertext).
    - `decryptArchive(encryptedBytes, password)`: validates magic header, extracts parameters, derives key, decrypts ciphertext, validates AES-GCM authentication tag (throwing user-safe `BackupCryptoException` on bad password or corrupted archive).

- `backup_bundle_service.dart`:
  - Uses `archive` package (`ZipEncoder` / `ZipDecoder`) to package/unpackage unencrypted payload containing:
    - `backup_manifest.json`
    - `recents.json`
    - `favorites.json`
    - `bookmarks.json`
    - `settings.json` (filtered non-sensitive settings)
    - `files/<filename>`

- `backup_service.dart`:
  - Orchestrates export:
    - Gathers data from `RecentsRepository`, `FavoritesRepository`, `BookmarksRepository`, `KeyValueStore`, and selected open tabs / attached files.
    - Builds bundle with `BackupBundleService`.
    - Encrypts bundle with `BackupCrypto`.
    - Returns encrypted `.txdata` bytes.
  - Orchestrates import / restore:
    - Inspects / decrypts `.txdata` bytes with `BackupCrypto` and returns `BackupPreview`.
    - Executes restore: writes records to SQLite database, applies non-sensitive settings to `KeyValueStore`, optionally restores or outputs documents.
    - Records audit log event if audit logging is enabled.

- `backup_providers.dart`:
  - Riverpod providers for `BackupBundleService`, `BackupService`.

- `ui/backup_screen.dart`, `ui/backup_export_dialog.dart`, `ui/backup_restore_dialog.dart`:
  - Material 3 UI for managing backups:
    - Export card/action: toggle checkboxes for recents, favorites, bookmarks, settings, and open documents; password input with confirmation; save via SAF (`SafService.createDocument`) or share via `ShareService`.
    - Restore card/action: pick `.txdata` file via SAF (`SafService.pickFile`), enter password, view preview breakdown (creation date, counts), select items to restore, execute restore with progress indicator and friendly feedback.

### 2. Core Storage Integration

- Modify `lib/core/storage/preferences_store.dart`:
  - Add `getAllNonSensitive(Set<String> sensitiveKeys)`: extracts all stored keys excluding sensitive keys.
  - Add `restoreAll(Map<String, Object?> values, Set<String> sensitiveKeys)`: restores preferences.
- Modify `lib/core/storage/key_value_store.dart`:
  - Expose `getAllNonSensitiveSettings()` and `restoreNonSensitiveSettings()`.

### 3. Settings UI Integration

- Create `lib/shell/settings/sections/backup_section.dart`:
  - Backup & Restore card section.
- Modify `lib/shell/settings/settings_screen.dart`:
  - Add `Backup & Restore` card to the main settings list.

### 4. Localization

- Add strings to `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` for all backup & restore titles, options, validation errors, dialogs, and snackbars.

### 5. Documentation & Roadmap

- Update `docs/feature_analysis_and_roadmap.md` to mark Feature 12 as DELIVERED ✅.

### 6. Tests

- `test/core/backup/backup_crypto_test.dart`:
  - Test PBKDF2 derivation with 200,000 iterations.
  - Test AES-256-GCM encryption & decryption roundtrip.
  - Test wrong password rejection (GCM tag verification failure).
  - Test corrupted payload / header validation.
- `test/core/backup/backup_bundle_service_test.dart`:
  - Test inner ZIP packing and unpacking with manifest, recents, favorites, bookmarks, settings, and files.
- `test/core/backup/backup_service_test.dart`:
  - Test full backup export and restore lifecycle with fake database / preferences store.
  - Test selective restore options (e.g. restore only favorites or only settings).
  - Assert that sensitive keys (`device_key`, `app_lock_pin`, `app_lock_recovery`) are NEVER exported or imported.

## Files to Change

- NEW: `lib/core/backup/backup_constants.dart`
- NEW: `lib/core/backup/backup_models.dart`
- NEW: `lib/core/backup/backup_crypto.dart`
- NEW: `lib/core/backup/backup_bundle_service.dart`
- NEW: `lib/core/backup/backup_service.dart`
- NEW: `lib/core/backup/backup_providers.dart`
- NEW: `lib/core/backup/ui/backup_screen.dart`
- NEW: `lib/core/backup/ui/backup_export_dialog.dart`
- NEW: `lib/core/backup/ui/backup_restore_dialog.dart`
- NEW: `lib/shell/settings/sections/backup_section.dart`
- NEW: `test/core/backup/backup_crypto_test.dart`
- NEW: `test/core/backup/backup_bundle_service_test.dart`
- NEW: `test/core/backup/backup_service_test.dart`
- MODIFY: `lib/core/storage/preferences_store.dart`
- MODIFY: `lib/core/storage/key_value_store.dart`
- MODIFY: `lib/shell/settings/settings_screen.dart`
- MODIFY: `lib/l10n/app_en.arb`
- MODIFY: `lib/l10n/app_ml.arb`
- MODIFY: `docs/feature_analysis_and_roadmap.md`
