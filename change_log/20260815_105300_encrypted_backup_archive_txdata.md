# Change Log: Implement Feature 12 — Zero-Knowledge Encrypted Backup Archive (.txdata)

**Plan:** `plans/20260815_105300_encrypted_backup_archive_txdata.md`  
**Date:** 2026-08-15

## Summary of Changes

Implemented **Feature 12: Zero-Knowledge Encrypted Backup Archive (`.txdata`) (Ecosystem Synergy)**, allowing users to export and restore selected files, recents, favorites, bookmarks, and settings into a single password-sealed AES-256 backup bundle.

### 1. New Core Backup Module (`lib/core/backup/`)
- `backup_constants.dart`: Binary magic header `TXDATA\x01`, PBKDF2 iteration count (200,000), 16-byte random salt length, 12-byte random nonce length, `.txdata` file extension.
- `backup_models.dart`: Structured models for `BackupManifest`, `BackupFileEntry`, `BackupExportOptions`, `BackupPreview`, `BackupRestoreOptions`, and `BackupRestoreResult`.
- `backup_crypto.dart`: Zero-knowledge crypto routines with PBKDF2-HMAC-SHA256 (200,000 iterations) and AES-256-GCM encryption/decryption with password verification and tamper-detection.
- `backup_bundle_service.dart`: Inner ZIP container packing and unpacking of manifest, recents, favorites, bookmarks, settings, and attached document files.
- `backup_service.dart`: Orchestration service gathering repository and settings data, exporting encrypted `.txdata` archives, and restoring data with merge/replace strategies.
- `backup_providers.dart`: Riverpod providers for `BackupBundleService` and `BackupService`.

### 2. UI & Settings Integration
- `lib/core/backup/ui/backup_screen.dart`: Dedicated backup management screen with hero card, export flow, restore flow, and zero-knowledge security note.
- `lib/core/backup/ui/backup_export_dialog.dart`: Component selector checklist and password input with confirmation and minimum length validation.
- `lib/core/backup/ui/backup_restore_dialog.dart`: Password decryption prompt, decrypted preview inspection, and selective restore checkboxes with merge toggle.
- `lib/shell/settings/sections/backup_section.dart`: Settings section card for Backup & Restore.
- `lib/shell/settings/settings_screen.dart`: Added Backup & Restore card to the settings menu.

### 3. Core Storage Integration
- `lib/core/storage/preferences_store.dart`: Added `getAllNonSensitive` and `restoreAll` methods to safely extract and restore non-sensitive preferences while strictly ignoring sensitive keys.
- `lib/core/storage/key_value_store.dart`: Exposed `getAllNonSensitiveSettings` and `restoreNonSensitiveSettings`.
- `lib/core/storage/favorites_repository.dart` & `lib/core/storage/bookmarks_repository.dart`: Added `clear()` methods for replace-mode restores.

### 4. Localization
- Updated `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` with full English and Malayalam localization strings.

### 5. Tests & Quality
- Added unit and integration tests:
  - `test/core/backup/backup_crypto_test.dart`
  - `test/core/backup/backup_bundle_service_test.dart`
  - `test/core/backup/backup_service_test.dart`
- Verified `flutter analyze` (zero issues found).
- Verified `flutter test` (all 1,072 tests passed).
