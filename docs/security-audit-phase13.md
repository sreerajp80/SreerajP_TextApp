# Security audit — Phase 13.1

**Date:** 2026-07-11
**Scope:** the whole app, rule by rule against
[security-rules.md](security-rules.md).
**Result:** No violations found. The findings below record the evidence for each
rule and the tests that now guard it.

This is the Phase 13.1 hardening record. It is a point-in-time audit; the
rule-guard tests under `test/security/` (plus the existing sync tests) keep these
properties from regressing.

---

## How to re-run the machine checks

```powershell
flutter test test/security/ test/sync/
flutter analyze
```

The `/security-review` command can be run for a fresh automated pass; any new
finding should be triaged and added below.

---

## Rule-by-rule findings

### 1. Treat every opened file as untrusted input

**Pass.** Parsers are tolerant and never throw to the UI on bad input:
- CSV `CsvParse` pads ragged rows and never throws; failure-path tested
  (`test/formats/csv/csv_parse_test.dart`).
- JSON has a lenient reader + strict validity gate; invalid input reports an
  error line, not a crash (`test/formats/json/json_parser_test.dart`).
- XML well-formedness check reports the error line; entity round-trip preserves
  text (`test/formats/xml/xml_parser_test.dart`).
- TXT encoding failure path shows a friendly state
  (`test/formats/txt/txt_content_sniff_test.dart`).
- Large/oversized files are classified **before** opening and dropped into a
  read-only degraded view (`lib/core/large_file/`, Phase 10).

File contents are only sent out on an explicit user action (share / export /
sync); there is no implicit upload.

### 2. P2P sync security lives at the payload layer

**Pass.** See `lib/sync/sync_crypto.dart` and `lib/sync/sync_constants.dart`:
- Fresh per-session pairing code, 64 chars over a 31-symbol alphabet ≈ **317
  bits** (`SyncConstants.codeLength`); entropy asserted in
  `test/security/random_secure_test.dart`.
- The code moves **out of band** (QR or typed). It is placed in the QR URI only
  (`buildQrUri`) and is **never** written to the socket — the transport sends the
  salt (clear), then AES-GCM-sealed handshake words.
- Key derivation is **PBKDF2-HMAC-SHA256**, 200 000 iterations, per-session
  random salt (`deriveKey`, `SyncConstants.pbkdf2Iterations`).
- Every wire message is **AES-256-GCM** sealed (`encryptWire`/`decryptWire`); a
  wrong code fails the GCM tag and aborts — round-trip, wrong-key, and tamper
  tests in `test/sync/sync_crypto_test.dart`.
- The random TCP port is conflict-avoidance only (`SyncConstants.portRangeStart`
  comment), not a security boundary.

### 3. Harden against a hostile peer

**Pass.**
- Bounded reads with separate caps: `handshakeLineCap` (8 KB) vs `payloadLineCap`
  (16 MB) in `BoundedLineReader`; over-cap line rejected
  (`test/sync/bounded_line_reader_test.dart`).
- Connect / socket / payload-wait timeouts (`SyncConstants.connectTimeout`,
  `socketTimeout`, `payloadWaitTimeout`).
- Payload caps enforced **before** ingestion: `maxRecordsPerCategory`,
  `maxFieldLength`, `maxSettingsEntries`; `validateAndParse` treats input as
  hostile (`test/sync/payload_test.dart`).
- Single client at a time + idle auto-stop in `SyncHost`
  (`test/sync/sync_transport_test.dart`).
- Strict QR parsing rejects foreign/malformed URIs (`parseQrUri`;
  `test/sync/sync_crypto_test.dart`).

### 4. Merge is add-only, client-wins; settings allow-list only

**Pass.** `mergeRecords` is add-only, client-wins on natural keys;
`mergeSettings` is full=all / incremental=fill-only. Only
`SyncConstants.syncableSettingKeys` may cross the wire; `validateAndParse` drops
any non-allow-listed setting and rejects protected keys
(`SyncConstants.neverSyncKeys` = `device_key`, `app_lock_pin`). Security/identity
state is never synced. Tested in `test/sync/payload_test.dart`.

### 5. Secret lifecycle

**Pass.** `SecretResealer` re-seals device-key → session-key (wire only) →
device-key (at rest on the receiver); round-trip tested in
`test/sync/sync_crypto_test.dart`. The device key is provisioned once with
`Random.secure()` and lives in `flutter_secure_storage` (`lib/core/storage/
secure_store.dart`); it is never synced or logged. No live secret-bearing
category exists yet, so the machinery is built and tested but not wired to a live
category (documented in the Phase 12 change log).

### 6. Never log secrets

**Pass.** Whole-`lib/` scan finds only one logging call — a `kDebugMode`-guarded
`debugPrint` in `lib/core/config/config_service.dart:47` that prints only the app
version/build mismatch (no secret material). Guards:
- `test/security/logging_audit_test.dart` — fails on any new logging in `lib/`
  outside a tiny reviewed allow-list.
- `test/sync/no_secret_logging_test.dart` — forbids **any** logging in
  `lib/sync`.

Error messages are user-safe: `SyncCryptoException` and `QrParseResult.fail`
carry no secret material by construction.

### 7. Random.secure() for all security randomness

**Pass.** `sync_crypto.dart` seeds a single `Random.secure()` used for
`randomBytes`, the pairing code (rejection-sampled to avoid modulo bias), and GCM
nonces. Guarded by `test/security/random_secure_test.dart` (source has
`Random.secure()` and no bare `Random(`).

### 8. App-lock / screenshot protection on the pairing-code screen

**Delivered in Phase 13.2** (next stage of this plan). At audit time the toggles
exist (`SecuritySettings`) but enforcement — the launch lock gate and
`FLAG_SECURE` on the QR/code screen — is implemented in task 13.2. This item is
tracked there, not a violation of the current rules.

---

## Scoped-storage, atomic-save, permissions (CLAUDE.md §3)

- **Scoped storage only.** File access is via the SAF platform channel
  (`lib/core/storage/saf_service.dart`); no broad storage permission and no
  in-app file browser. Persistable URI permissions are taken for recents.
- **Atomic saves.** `AtomicSaver` + `SafSaveTarget` write to a temp file and
  verify, then replace; an interrupted save leaves the original intact
  (`test/core/editor/atomic_saver_test.dart`).
- **Least-privilege permissions.** Sync adds only `INTERNET`,
  `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CAMERA` (local sockets + QR scan).
  Reviewed again at Phase 14.3.

---

## Owed manual/device checks

Recorded for Phase 14.2 / release:
- Real screenshot block (`FLAG_SECURE`) on the sync code/QR screen (after 13.2).
- App-lock on a real relaunch/resume.
- A real two-device LAN transfer (the Phase 14.2 gate).
