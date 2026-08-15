# Change log — Tamper-Evident Workspace Audit Log (Feature 8)

**Implements:** `plans/20260815_100100_tamper_evident_audit_log.md`
**Date:** 2026-08-15

---

## 1. What was built

Implemented a cryptographically chained SHA-256 hash log capturing every document edit,
file export, P2P sync, AirQR optical transfer, and security event within TextData.

1. **Cryptographic Chain Hashing**: Every log entry computes a SHA-256 hash chaining from
   the previous entry's hash using `package:crypto`. Field boundaries are strictly delimited
   with a separator character to prevent collision shifts.
2. **Database Migration**: Schema bumped from v2 to v3 in `AppDatabase`, adding the
   `audit_log` table with indexed timestamp and fingerprint columns. Migration is additive-only.
3. **Live UI & Verification Badge**:
   - `AuditLogScreen`: Full-screen reverse-chronological log with a live verification status
     banner, paginated scrolling, manual verification trigger, certificate export, and log clearing.
   - `AuditBadge`: Compact chip widget showing chain status (verified, corrupted, empty, verifying).
   - `AuditSection`: Settings card with toggle, chain status badge, view log button, and clear log dialog.
4. **Signed Audit Certificates**: One-tap export generating a signed JSON certificate
   containing all entries in insertion order along with an HMAC-SHA256 signature keyed by a
   device-specific 256-bit key stored securely in `FlutterSecureStore`.
5. **Integration Hooks**:
   - 5 format session managers (TXT, Markdown, CSV, JSON, XML) fire save audit entries with before/after state hashes.
   - `OpenFileAction` records file open events.
   - `SyncController` records P2P sync send and receive events.
   - `AirqrReceiveController` records AirQR optical transfer receive events.
   - `AppLockController` records app-lock enable/disable and PIN changes.
   - `EphemeralWiper` scrubs audit entries for burned documents as part of the self-destruct sequence.

---

## 2. Files added

### `lib/core/audit/`

| File | Holds |
|------|-------|
| `audit_constants.dart` | `AuditEventType` event type constants, genesis hash (64 hex zeros), page size, and hash separator |
| `audit_models.dart` | `AuditEntry`, `AuditChainStatus`, `AuditVerificationResult` immutable models |
| `audit_hasher.dart` | Pure Dart SHA-256 chain hash computation and verification logic |
| `audit_repository.dart` | SQLite repository with transactional chaining, paginated queries, and batched chain verification |
| `audit_service.dart` | High-level facade with enable/disable checks and best-effort exception safety |
| `audit_hooks.dart` | Static fire-and-forget helpers matching the `WorkspaceIndexHooks` pattern |
| `audit_providers.dart` | Riverpod providers for repository, service, and chain status |
| `audit_settings.dart` | `AuditSettings` notifier for `audit.enabled` setting |
| `audit_export.dart` | JSON certificate builder with HMAC-SHA256 device key signing and verification |
| `ui/audit_badge.dart` | `AuditBadge` status chip widget |
| `ui/audit_log_screen.dart` | `AuditLogScreen` full viewer with verification banner and actions |

### `lib/shell/settings/sections/`

| File | Holds |
|------|-------|
| `audit_section.dart` | Settings section for Audit Log |

### `test/core/audit/`

| File | Holds |
|------|-------|
| `audit_hasher_test.dart` | Determinism, field sensitivity, and null field handling tests |
| `audit_repository_test.dart` | Append, chaining, corruption detection, pagination, clear, and fingerprint wipe tests |
| `audit_service_test.dart` | Enable/disable gates, clearLog genesis replacement, and trace wipe tests |
| `audit_export_test.dart` | Certificate structure, HMAC generation, valid verification, and tamper detection tests |

---

## 3. Files changed

| File | Change |
|------|--------|
| `lib/core/storage/app_database.dart` | Schema bumped to v3; `createAuditLogSchema` added |
| `lib/core/constants/app_constants.dart` | Registered `audit` namespace and `audit_export_key` secure key |
| `lib/shell/settings/settings_screen.dart` | Added Audit Log settings card |
| `lib/formats/txt/txt_session_manager.dart` | Added audit save hook |
| `lib/formats/csv/csv_session_manager.dart` | Added audit save hook |
| `lib/formats/json/json_session_manager.dart` | Added audit save hook |
| `lib/formats/markdown/md_session_manager.dart` | Added audit save hook |
| `lib/formats/xml/xml_session_manager.dart` | Added audit save hook |
| `lib/shell/open_file_action.dart` | Added audit file open hook |
| `lib/sync/sync_provider.dart` | Added onSent/onApplied audit hooks |
| `lib/core/security/app_lock_controller.dart` | Added security event audit hooks |
| `lib/core/ephemeral/ephemeral_wiper.dart` | Added audit log clearance step to document wipe |
| `lib/core/ephemeral/ephemeral_controller.dart` | Passed `auditService` to `EphemeralWiper` |
| `lib/l10n/app_en.arb` | Added 26 localization strings |
| `lib/l10n/app_ml.arb` | Added Malayalam translations for all 26 strings |
| `test/shell/settings/settings_screen_test.dart` | Updated for 9 settings cards and topic card tapping |

---

## 4. Verification

- `flutter analyze` — **zero issues**.
- `flutter test` — **1,058 tests pass** (all existing and 17 new audit tests pass).
- `dart format lib test` — formatted.
- **No new dependency** added (`package:crypto` reused).
