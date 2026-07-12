# Change log — Phase 1: Data & platform foundation

Implements the plan
[plans/20260709_152131_phase-1-data-platform-foundation.md](../plans/20260709_152131_phase-1-data-platform-foundation.md),
covering **Phase 1** of [docs/implementation-plan.md](../docs/implementation-plan.md).

**Date:** 2026-07-09. **Result:** all six tasks done at the Dart level; `flutter analyze`
clean; `flutter test` green (38 tests). One manual on-device check is still owed (see §5).

---

## 1. What was added

The bottom (data / platform) layer of the app. No screens — only code the later phases call.

### 1.1 SAF file access + persistable URIs
- `lib/core/storage/saf_service.dart` — Dart wrapper over a platform channel:
  `pickFile`, `readBytes`, `writeBytes`, `isAccessible`, `releasePermission`,
  `persistedUris`, plus a `SafFile` model and a `safServiceProvider`.
- `lib/core/storage/saf_exceptions.dart` — sealed `SafException` types
  (`SafCancelled`, `SafPermissionDenied`, `SafUriStale`, `SafIoFailure`,
  `SafUnknownFailure`). Every native error maps to one of these; a bad/revoked URI never
  crashes (CLAUDE.md §3.4).
- Android native (Kotlin):
  - `android/app/src/main/kotlin/in/zohomail/sreerajp/text_data/SafChannel.kt` — a
    `FlutterPlugin`/`ActivityAware` method-channel handler doing `ACTION_OPEN_DOCUMENT`,
    `takePersistableUriPermission`, `ContentResolver` read/write (`openInputStream` /
    `openOutputStream("rwt")`), an access probe, permission release, and a persisted-URI
    list. Returns stable error codes; logs no file contents.
  - `MainActivity.kt` — registers `SafChannel`.
- No new Android runtime permission (SAF picker needs none) — keeps least privilege.

### 1.2 Content fingerprint
- `lib/core/fingerprint/content_fingerprint.dart` — `ContentFingerprint` (size + SHA-256),
  with `fromBytes`, streaming `fromStream` (bounded memory), a `key` form, `tryParse`, and
  value equality. A modified file yields a new fingerprint (architecture.md §11).

### 1.3 Preferences + secure storage
- `lib/core/storage/preferences_store.dart` — `shared_preferences` wrapper (non-sensitive).
- `lib/core/storage/secure_store.dart` — `SecureStore` interface, a Keystore-backed
  `FlutterSecureStore`, and an `InMemorySecureStore` fake for tests.
- `lib/core/storage/key_value_store.dart` — `KeyValueStore` facade routing an allow-list of
  **sensitive** keys to secure storage and everything else to preferences, so a secret can
  never land in plain prefs. `keyValueStoreProvider` builds it.

### 1.4 Local DB + repositories
- `lib/core/storage/app_database.dart` — opens SQLite (`sqflite`), sets `version = 1`,
  creates the schema (`recents`, `bookmarks`, `favorites`, `drafts_index`), and has an
  `onUpgrade` migration path ready. Accepts a `DatabaseFactory` so tests use FFI in-memory.
- `lib/core/storage/storage_models.dart` — `RecentFile`, `Bookmark`, `Favorite`,
  `DraftIndexEntry` with row mappers.
- Repositories: `recents_repository.dart`, `bookmarks_repository.dart`,
  `favorites_repository.dart`, `drafts_index_repository.dart` — CRUD, fingerprint-keyed.
- `lib/core/storage/storage_providers.dart` — DB + repository providers (uses sqflite's
  default databases dir; no `path_provider`, no extra permission).

### 1.5 ConfigService + app_config.json
- `assets/config/app_config.json` — real About values (architecture.md §8.1 shape).
- `lib/core/config/app_config.dart` — typed `AppConfig` with a safe `fallback`; missing or
  wrong-typed fields fill from the fallback rather than throwing.
- `lib/core/config/config_service.dart` — loads via `rootBundle`, degrades to the fallback
  on any error, and `loadAndVerify` cross-checks version/build with `package_info_plus`
  (debug-only note on mismatch, no secret data). `configServiceProvider` + `appConfigProvider`.

### 1.6 Device-memory reader + tab cap
- `lib/core/storage/tab_cap.dart` — pure `autoTabCap(bytes)` mapping RAM bands to a tab
  count (2 GB→3 … >8 GB→10; unknown→3).
- `lib/core/storage/device_memory.dart` — `DeviceMemory` interface, `system_info2`-backed
  `SystemInfoDeviceMemory`, a `FakeDeviceMemory` for tests, and `deviceMemoryProvider`.

---

## 2. Packages added (all open source — licenses confirmed in the pub cache)

`flutter_secure_storage` (BSD-3), `shared_preferences` (BSD/Flutter Authors), `sqflite`
(BSD-2), `crypto` (BSD/Dart Authors), `package_info_plus` (BSD/Chromium), `system_info2`
(BSD-style). Dev: `sqflite_common_ffi` (BSD-2) for host DB tests.

No third-party file picker was used: `file_picker` cannot take a persistable URI permission,
so a small custom SAF platform channel replaces it (plan §3, decision 1).

---

## 3. Tests added (all run on the host — no device)

- `test/core/fingerprint/content_fingerprint_test.dart` — same/different/empty bytes, stream
  == in-memory, key round-trip, malformed key rejection.
- `test/core/storage/saf_service_test.dart` — mocked channel: each error code → the right
  exception; cancelled/null pick; happy `pickFile`; `isAccessible` false-on-error;
  `persistedUris`; missing plugin.
- `test/core/storage/key_value_store_test.dart` — non-sensitive → prefs, sensitive → secure,
  a sensitive key never reaches prefs, remove, typed helpers.
- `test/core/storage/repositories_test.dart` — FFI in-memory CRUD on all four repositories +
  schema version.
- `test/core/config/config_service_test.dart` — valid parse, malformed/missing/non-object
  degrade to fallback, partial fill, wrong types ignored.
- `test/core/storage/tab_cap_test.dart` — RAM bands → caps, boundaries, unknown fallback,
  `FakeDeviceMemory`.

**Gate:** `flutter analyze` → no issues; `flutter test` → 38 passed.

---

## 4. Security notes (security-rules.md)

- Secrets route only to `flutter_secure_storage`; the facade blocks secrets reaching prefs.
- No file contents, keys, or URIs' contents are logged, in Dart or Kotlin.
- Untrusted config input degrades safely; SAF errors are user-safe and never crash.
- No new runtime permissions; least privilege kept.

---

## 5. Owed manual check (on a real device)

Native SAF/RAM code cannot run in this session (no device/emulator; same as Phase 0). Please
verify on a device: pick a file, restart the app, confirm it re-opens from the saved URI
(persistable permission works), and that a revoked/stale URI shows a clean error. Record the
result here or in a follow-up log.

---

## 6. Progress

[docs/implementation-progress.md](../docs/implementation-progress.md) updated: Phase 1 tasks
1.1–1.6 → ✅, phase status → Done, summary table updated. Plan status → `completed`.
