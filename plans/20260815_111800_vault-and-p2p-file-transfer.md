# Per-Document Biometric Vault (.txvault) & P2P Direct Document File Transfer

**Status:** completed

---

## 1. Overview & Goals

This plan adds two major security and connectivity features to TextData:

1. **Per-Document Biometric Vault (`.txvault`)**:
   - Allows users to encrypt individual sensitive files (TXT, CSV, JSON, Markdown, XML) with **AES-256-GCM** at rest.
   - Encryption keys are secured using hardware-backed keystore storage (`flutter_secure_storage`) and unlocked via biometric authentication (`local_auth` fingerprint/face) or PIN fallback.
   - Any external app or file manager trying to open `.txvault` files will only see scrambled ciphertext.
   - When opened in TextData, biometric authentication decrypts the document in memory and launches the corresponding format viewer/editor seamlessly.

2. **P2P Direct Document File Payload Transfer**:
   - Expands the offline LAN P2P subsystem from syncing app metadata (recents, favorites, bookmarks, settings) to **streaming complete document files** directly between devices over local sockets.
   - End-to-end encrypted with **AES-256-GCM** over local TCP sockets using a 64-character pairing code / QR handshake.
   - Fully compliant with Android Scoped Storage: the receiving device saves the incoming document through the system file picker (SAF).

---

## 2. Architecture & Design Details

### Feature A: Per-Document Biometric Vault (`.txvault`)

#### 2.1 Binary Container Specification
The `.txvault` format uses a tamper-evident authenticated binary envelope:
- **Magic Bytes (7 bytes):** `TXVAULT` (`0x54, 0x58, 0x56, 0x41, 0x55, 0x4C, 0x54`)
- **Format Version (1 byte):** `0x01`
- **Salt (16 bytes):** Cryptographically secure random salt (`Random.secure()`).
- **Nonce / IV (12 bytes):** Standard AES-GCM 12-byte initialization vector.
- **Ciphertext (Variable bytes):** AES-256-GCM encrypted payload containing JSON metadata + raw document bytes:
  - `fileName`: Original file name (e.g. `financials.csv`)
  - `mimeType`: Original MIME type / format identifier
  - `content`: Document content string or base64 binary
  - `encoding`: Character encoding name (e.g. `utf-8`)
  - `createdAt`: ISO-8601 timestamp

#### 2.2 Key Hierarchy & Biometric Authentication
- A hardware-backed **Master Vault Key** is generated on first vault creation and stored in `SecureStore` (`flutter_secure_storage`).
- Opening or locking a vault file triggers `BiometricService.authenticate(reason: 'Unlock Document Vault')`.
- Upon successful biometric verification, the vault key is retrieved to decrypt the payload in memory.
- When editing a `.txvault` file, saves are performed atomically: the modified content is re-encrypted with a fresh random nonce and written using `AtomicSaver`.

#### 2.3 User Experience & Format Routing
- **Locking a File:** In any document viewer (TXT, CSV, JSON, Markdown, XML), the user can tap **"Lock with Biometric Vault"** from the overflow/export menu. The app requests biometric auth, encrypts the document, and saves the new `.txvault` file via SAF.
- **Opening a Vault File:** When opening a `.txvault` file from the SAF picker or Recents list:
  - `detectFormat()` identifies `DocumentFormat.vault`.
  - The UI presents a dedicated **Vault Unlock Screen** showing the file name, lock icon, and "Unlock with Biometrics" button.
  - Upon unlocking, the session resolves the inner format and renders the full interactive editor.

---

### Feature B: P2P Direct Document File Payload Transfer

#### 2.1 Transport & Wire Protocol
- Extends the existing `SyncHost` / `SyncClient` socket protocol ([lib/sync/sync_transport.dart](lib/sync/sync_transport.dart)):
  - **Handshake:** Uses existing pairing code / QR handshake with PBKDF2-HMAC-SHA256 and AES-256-GCM.
  - **Payload Packet:** A new payload type `SyncFilePayload` carrying:
    - `type`: `file_transfer`
    - `fileName`: Target file name
    - `mimeType`: Target MIME type
    - `fileSizeBytes`: Byte length
    - `fileContent`: Encrypted text / base64 payload
    - `encoding`: Detected encoding
- **Caps & Guards:** Maximum file size cap of 50 MB to prevent memory exhaustion on mobile devices.

#### 2.2 UI & User Flow
- **Sender Flow:**
  - Option 1: In the **P2P Sync Screen**, a new **"Send Document File"** tab/mode allows picking an open tab or browsing a file to transfer.
  - Option 2: Directly from an open document tab's toolbar -> **Share / Send via LAN P2P**.
  - Displays the 64-char pairing code and QR code.
- **Receiver Flow:**
  - In the P2P Sync Screen, receiver selects **"Receive P2P File"**, scans QR / enters code.
  - Handshake completes and receives the incoming file stream.
  - Displays file preview (name, size, type) and prompts user to **"Save to Device"** via SAF picker, then immediately opens the document in TextData.

---

## 3. Files to Create and Modify

### New Files:
1. `lib/core/vault/vault_constants.dart` — Magic bytes, header sizes, version constants.
2. `lib/core/vault/vault_crypto.dart` — AES-256-GCM encryption/decryption, binary packaging, key derivation.
3. `lib/core/vault/vault_service.dart` — Vault key management in SecureStore and biometric authorization coordination.
4. `lib/core/vault/vault_models.dart` — `VaultEnvelope`, `VaultPayload`.
5. `lib/core/vault/ui/vault_unlock_view.dart` — Biometric unlock card/screen for `.txvault` tabs.
6. `lib/core/vault/ui/vault_lock_dialog.dart` — Confirmation dialog to encrypt and save as `.txvault`.
7. `lib/sync/file_transfer_payload.dart` — Document payload packaging, serialization, and size validation.
8. `lib/sync/ui/p2p_file_transfer_tab.dart` — Dedicated UI for sender and receiver direct file transfers.
9. `test/core/vault/vault_crypto_test.dart` — Unit tests for vault envelope packaging, encryption roundtrips, wrong key / corrupted header rejections.
10. `test/sync/file_transfer_payload_test.dart` — Unit tests for direct file transfer payloads and limits.

### Modified Files:
1. `lib/formats/format_dispatch.dart` — Add `DocumentFormat.vault` detection for `.txvault` extension.
2. `lib/shell/tabs/tabs_workspace.dart` — Render `VaultUnlockView` when a vault tab is locked, swapping to format editor upon unlock.
3. `lib/sync/sync_constants.dart` — Add constants for file transfer mode and packet headers.
4. `lib/sync/sync_provider.dart` — Add direct document streaming state and actions.
5. `lib/sync/ui/sync_screen.dart` — Add navigation/tab for P2P Document File Transfer.
6. `lib/formats/txt/txt_toolbar.dart` (and other format toolbars) — Add "Lock in Biometric Vault" and "Send via LAN P2P" actions.
7. `lib/l10n/app_en.arb` & `lib/l10n/app_ml.arb` — Add localization strings for Vault and P2P File Transfer.
8. `docs/feature_analysis_and_roadmap.md` — Mark items as implemented.

---

## 4. Verification & Testing

1. **Vault Unit Tests:**
   - Test encryption/decryption round-trip with arbitrary text, CSV, JSON, and binary buffers.
   - Verify corrupted magic bytes, invalid nonce length, truncated headers, or invalid keys throw user-safe exceptions.
   - Verify ciphertext has zero plaintext leaks.
2. **P2P File Transfer Unit & Integration Tests:**
   - Loopback TCP tests streaming documents up to 10 MB between mock host and client.
   - Test rejection of payload exceeding 50 MB cap.
   - Verify correct MIME type, file name, and character encoding preservation.
3. **Format & Analysis Checks:**
   - `dart format lib test`
   - `flutter analyze` (zero issues)
   - `flutter test` (all tests passing)
