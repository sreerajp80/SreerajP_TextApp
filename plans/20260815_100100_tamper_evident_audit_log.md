# Plan: Implement Feature 8 — Tamper-Evident Workspace Audit Log

**Status:** completed

## Issue

Feature 8 from `docs/feature_analysis_and_roadmap.md` is not yet implemented. The app
needs a cryptographically chained SHA-256 hash log capturing every document edit, file
export, P2P sync, and security event.

## Plan

### New module: `lib/core/audit/`

Create the audit log module following the same patterns as `lib/core/index/` and
`lib/core/ephemeral/`:

- `audit_constants.dart` — event type constants, genesis hash, settings key
- `audit_models.dart` — `AuditEntry`, `AuditChainStatus`, `AuditVerificationResult`
- `audit_hasher.dart` — pure Dart SHA-256 chain hash computation
- `audit_repository.dart` — SQLite CRUD with transactional chaining
- `audit_service.dart` — higher-level facade, enabled check, best-effort
- `audit_hooks.dart` — static fire-and-forget helpers (like `WorkspaceIndexHooks`)
- `audit_providers.dart` — Riverpod providers
- `audit_export.dart` — JSON certificate builder with HMAC-SHA256
- `audit_settings.dart` — on/off notifier
- `ui/audit_log_screen.dart` — full screen with chain verification banner
- `ui/audit_badge.dart` — status chip widget

### Database

- Bump `app_database.dart` schema to v3, add `audit_log` table

### Integration hooks

- 5 format session managers (`onSaved` callback)
- `open_file_action.dart` (file open)
- `export_service.dart` (file export)
- `sync_provider.dart` (P2P sync send/receive)
- `airqr_provider.dart` (AirQR send/receive)
- `app_lock_controller.dart` (security events)
- `ephemeral_wiper.dart` (document burn + per-fingerprint clear)

### Settings

- New `audit_section.dart` settings section
- Add card to `settings_screen.dart`

### Constants

- Register `audit` namespace and `audit_export_key` secure key in `app_constants.dart`

### Localization

- Add ~25 keys to `app_en.arb` and `app_ml.arb`

### Tests

- `test/core/audit/audit_hasher_test.dart`
- `test/core/audit/audit_repository_test.dart`
- `test/core/audit/audit_service_test.dart`
- `test/core/audit/audit_export_test.dart`

## Files changed

- NEW: `lib/core/audit/audit_constants.dart`
- NEW: `lib/core/audit/audit_models.dart`
- NEW: `lib/core/audit/audit_hasher.dart`
- NEW: `lib/core/audit/audit_repository.dart`
- NEW: `lib/core/audit/audit_service.dart`
- NEW: `lib/core/audit/audit_hooks.dart`
- NEW: `lib/core/audit/audit_providers.dart`
- NEW: `lib/core/audit/audit_export.dart`
- NEW: `lib/core/audit/audit_settings.dart`
- NEW: `lib/core/audit/ui/audit_log_screen.dart`
- NEW: `lib/core/audit/ui/audit_badge.dart`
- NEW: `lib/shell/settings/sections/audit_section.dart`
- NEW: `test/core/audit/audit_hasher_test.dart`
- NEW: `test/core/audit/audit_repository_test.dart`
- NEW: `test/core/audit/audit_service_test.dart`
- NEW: `test/core/audit/audit_export_test.dart`
- MODIFY: `lib/core/storage/app_database.dart`
- MODIFY: `lib/core/constants/app_constants.dart`
- MODIFY: `lib/core/storage/storage_providers.dart`
- MODIFY: `lib/shell/settings/settings_screen.dart`
- MODIFY: `lib/formats/csv/csv_session_manager.dart`
- MODIFY: `lib/formats/json/json_session_manager.dart`
- MODIFY: `lib/formats/markdown/md_session_manager.dart`
- MODIFY: `lib/formats/txt/txt_session_manager.dart`
- MODIFY: `lib/formats/xml/xml_session_manager.dart`
- MODIFY: `lib/shell/open_file_action.dart`
- MODIFY: `lib/core/export/export_service.dart`
- MODIFY: `lib/sync/sync_provider.dart`
- MODIFY: `lib/airqr/airqr_provider.dart`
- MODIFY: `lib/core/security/app_lock_controller.dart`
- MODIFY: `lib/core/ephemeral/ephemeral_wiper.dart`
- MODIFY: `lib/l10n/app_en.arb`
- MODIFY: `lib/l10n/app_ml.arb`
