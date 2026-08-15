# Per-Document Biometric Vault (.txvault) & P2P Direct Document File Transfer

Implemented Per-Document Biometric Vault encryption at rest and P2P Direct Document File Payload Transfer over local encrypted sockets.

References plan: `plans/20260815_111800_vault-and-p2p-file-transfer.md`

---

## 1. Summary of Changes

### A. Per-Document Biometric Vault (`.txvault`)
* Created authenticated binary container format with magic header `TXVAULT\x01` and AES-256-GCM encryption.
* Generated and securely persisted hardware-backed Master Vault Key in `flutter_secure_storage` (`SecureStore`), unlocked on demand via biometric authentication (`local_auth`).
* Implemented `VaultCrypto`, `VaultService`, and `vaultServiceProvider`.
* Created `VaultUnlockView` to prompt biometric unlock when opening `.txvault` files in the multi-tab workspace, dynamically rendering the underlying decrypted format (TXT, CSV, JSON, Markdown, XML).
* Added `showVaultLockDialog` accessible from format toolbars to lock and encrypt any open document into `.txvault`.
* Added `DocumentFormat.vault` format detector and file extension routing.

### B. P2P Direct Document File Payload Transfer
* Created `FileTransferPayload` with robust security guards (50 MB size cap, path traversal / filename sanitization, JSON structure validation).
* Extended `SyncConstants` and `SyncController` (`lib/sync/sync_provider.dart`) to stream and receive full document files across peers.
* Created `P2pFileTransferTab` in `SyncHostScreen` enabling users to stream device files or open tabs to a connected peer.
* Built `_ReceivedFileView` in `SyncClientScreen` to preview and save received document files to device storage using the SAF picker.

---

## 2. Files Created and Modified

### Created:
* `lib/core/vault/vault_constants.dart`
* `lib/core/vault/vault_models.dart`
* `lib/core/vault/vault_crypto.dart`
* `lib/core/vault/vault_service.dart`
* `lib/core/vault/vault_providers.dart`
* `lib/core/vault/ui/vault_unlock_view.dart`
* `lib/core/vault/ui/vault_lock_dialog.dart`
* `lib/sync/file_transfer_payload.dart`
* `lib/sync/ui/p2p_file_transfer_tab.dart`
* `test/core/vault/vault_crypto_test.dart`
* `test/sync/file_transfer_payload_test.dart`

### Modified:
* `lib/core/storage/key_value_store.dart` — added `vault_master_key` to sensitive keys list.
* `lib/formats/format_dispatch.dart` — added `DocumentFormat.vault` detection.
* `lib/shell/tabs/tabs_workspace.dart` — added `VaultUnlockView` routing for `.txvault` tabs.
* `lib/sync/sync_constants.dart` — added file transfer payload types and size constants.
* `lib/sync/sync_provider.dart` — added `pushDocumentFile` and incoming file transfer reception.
* `lib/sync/ui/sync_host_screen.dart` — integrated Document Transfer tab.
* `lib/sync/ui/sync_client_screen.dart` — integrated received file preview and SAF save view.
* `lib/formats/txt/txt_toolbar.dart` & `lib/formats/markdown/md_toolbar.dart` — added "Lock in Biometric Vault" menu actions.
* `lib/l10n/app_en.arb` & `lib/l10n/app_ml.arb` — added localization entries.
* `docs/feature_analysis_and_roadmap.md` — updated roadmap status.

---

## 3. Verification & Results

* Unit tests: All vault crypto tests and file transfer payload tests passing.
* Test suite: Full test suite executed with `flutter test` — **1,086 passed (0 failures)**.
* Static analysis: `flutter analyze` — **No issues found!**
* Code formatting: `dart format lib test` executed cleanly.
