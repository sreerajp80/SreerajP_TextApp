# Phase 1 — Data & platform foundation

**Status:** completed

Implements **Phase 1** of [implementation-plan.md](../docs/implementation-plan.md).
Read together with [architecture.md](../docs/architecture.md) (arch §2, §4, §8, §10),
[security-rules.md](../docs/security-rules.md), and [CLAUDE.md](../CLAUDE.md).

---

## 1. What this phase is (goal)

Build the **bottom layer** of the app: how it reaches files, remembers them, stores
settings and secrets, and reads its own config and the device's memory. Nothing above this
layer (the shell, the editor, the formats) can open or remember a file without it.

**Depends on:** Phase 0 (done). **This phase is pure plumbing — no user-facing screens.**
The placeholder home stays as it is; we only add code the later phases will call.

---

## 2. The issue / why

After Phase 0 the app is an empty Material 3 shell. It cannot:

- pick a file through the system picker and **keep the right to re-open it** later,
- tell one file from another in a stable way (a "fingerprint"),
- save settings, or save secrets safely,
- remember recent files, bookmarks, or favorites,
- read its own About values from a config file,
- know how much RAM the device has (needed later for the tab limit).

Phase 1 adds all six, as plain, testable Dart with a thin Android native part only where
Android forces it (file access and RAM).

---

## 3. Key decisions (please confirm these)

1. **File access = a small custom SAF platform channel, not `file_picker`.**
   The plan lists `file_picker`, but `file_picker` copies the file to a cache and **cannot
   take a persistable URI permission**, which is a hard rule (CLAUDE.md §3.3: "Take
   persistable URI permissions for recent files"). So I will write a small Kotlin
   `MethodChannel` that does exactly what we need: open a document
   (`ACTION_OPEN_DOCUMENT`), **take the persistable URI permission**, read/write bytes,
   check if a saved URI is still reachable, and release a permission. This is
   self-contained, adds no third-party dependency, and no license to vet.

2. **Local DB = `sqflite` (+ `sqflite_common_ffi` for host tests), not `drift`.**
   `sqflite` is lighter and needs no code generation. `sqflite_common_ffi` lets the DB tests
   run on the computer with an **in-memory** database (the plan's test says "in-memory DB"),
   so no device is needed for tests.

3. **Device RAM = `system_info2` package** (I will confirm its license is open source
   before adding it; if it is not clearly open source I will fall back to a tiny RAM method
   on the same platform channel from decision 1). The **auto-cap maths is pure Dart** and
   fully tested; only the raw RAM number comes from the platform.

4. **Hashing for the fingerprint = the `crypto` package** (Dart team, BSD-3). Hashed as a
   stream so a large file does not load fully into memory.

5. **Native code cannot be verified in this session (no device/emulator).** As in Phase 0,
   the automated gate is `flutter analyze` + `flutter test`; the Kotlin SAF/RAM behaviour is
   left for a **manual device check** by you, recorded in the change log. All Dart logic
   (error mapping, fingerprint, stores, DB, config, auto-cap) **is** covered by unit tests
   that run here.

If you prefer `drift` over `sqflite`, `file_picker` kept in some role, or a platform channel
for RAM instead of `system_info2`, tell me and I will revise before starting.

---

## 4. New packages (all must be open source — CLAUDE.md §3.1)

| Package | Why | License (to confirm at add time) |
|---|---|---|
| `flutter_secure_storage` | secrets at rest (Keystore-backed) | BSD-3 |
| `shared_preferences` | non-sensitive settings | BSD-3 |
| `sqflite` | local DB (recents/bookmarks/favorites/drafts index) | MIT/BSD |
| `sqflite_common_ffi` (dev) | run DB tests in-memory on the host | MIT |
| `crypto` | SHA-256 for the content fingerprint | BSD-3 |
| `package_info_plus` | app version/build, cross-checked with config | BSD-3 |
| `system_info2` | total device RAM (license confirmed before add) | to verify |

No third-party file-picker package (custom platform channel instead — decision 1).
**No new Android runtime permissions** are added: SAF `ACTION_OPEN_DOCUMENT` and reading RAM
via `ActivityManager` need none. This keeps least-privilege (arch §10).

---

## 5. Files to be created / changed

### 5.1 SAF file access (task 1.1)
- `lib/core/storage/saf_service.dart` — Dart wrapper over the platform channel: `pickFile`,
  `readBytes(uri)`, `writeBytes(uri, bytes)`, `isAccessible(uri)`, `releasePermission(uri)`,
  `persistedUris()`. Returns typed results.
- `lib/core/storage/saf_exceptions.dart` — `SafException` types: `SafPermissionDenied`,
  `SafUriStale`, `SafCancelled`, `SafIoFailure`. Every native error maps to one of these —
  **never** an uncaught crash (CLAUDE.md §3.4).
- `android/app/src/main/kotlin/.../MainActivity.kt` (+ a `SafChannel.kt` handler) — Kotlin
  side: `ACTION_OPEN_DOCUMENT`, `takePersistableUriPermission`, `ContentResolver` read/write
  via `openFileDescriptor`, `checkUriPermission`/access probe, `releasePersistableUriPermission`.
  Error → a stable error code string the Dart side maps to an exception.

### 5.2 Content fingerprint (task 1.2)
- `lib/core/fingerprint/content_fingerprint.dart` — `ContentFingerprint` value type
  (`size` + `sha256` hex) with `==`/`hashCode`; `fromBytes(...)` and a streaming
  `fromStream(...)`. Same bytes → same fingerprint; one byte changed → different (arch §11:
  a modified file is a new document).

### 5.3 Preferences + secure storage (task 1.3)
- `lib/core/storage/preferences_store.dart` — thin wrapper over `shared_preferences`
  (get/set string/bool/int/double, with defaults).
- `lib/core/storage/secure_store.dart` — thin wrapper over `flutter_secure_storage`
  (get/set/delete/clear), behind an interface so tests can inject an in-memory fake.
- `lib/core/storage/key_value_store.dart` — a facade that hides the split: a fixed map of
  which keys are sensitive routes them to secure storage, the rest to prefs. This is the one
  thing the rest of the app calls.
- Riverpod providers for each.

### 5.4 Local DB + repositories (task 1.4)
- `lib/core/storage/app_database.dart` — opens the DB, sets `version`, creates tables in
  `onCreate`, handles `onUpgrade` (migration path ready even if empty for v1).
- Tables: `recents`, `bookmarks`, `favorites`, `drafts_index` — keyed by fingerprint where
  it makes sense (arch §11), each row also storing the persisted SAF URI as the fast path.
- `lib/core/storage/recents_repository.dart`, `bookmarks_repository.dart`,
  `favorites_repository.dart`, `drafts_index_repository.dart` — CRUD each.
- Small model classes (`RecentFile`, `Bookmark`, `Favorite`, `DraftIndexEntry`) alongside.
- Riverpod providers for the DB and each repository.

### 5.5 ConfigService + app_config.json (task 1.5)
- `assets/config/app_config.json` — the real About values (arch §8.1 shape: appName,
  description, version, build, author, email, licenseNote, links).
- `lib/core/config/app_config.dart` — typed `AppConfig` model with `fromJson` and a
  **safe hardcoded fallback** so a missing/broken file never crashes the app.
- `lib/core/config/config_service.dart` — loads the JSON via `rootBundle`, parses to
  `AppConfig`, cross-checks `version`/`build` against `package_info_plus` (logs a non-fatal
  note on mismatch, no secret data), returns the fallback on any parse error.
- Riverpod provider.

### 5.6 Device-memory reader + tab cap (task 1.6)
- `lib/core/storage/device_memory.dart` — `DeviceMemory` interface with
  `totalPhysicalBytes()`; a `system_info2`-backed implementation (or platform-channel
  fallback). Behind an interface so tests inject sample RAM values.
- `lib/core/storage/tab_cap.dart` — **pure function** `autoTabCap(totalBytes) -> int` that
  maps RAM bands to a tab count (e.g. ≤2 GB → 3, ≤4 GB → 5, ≤6 GB → 6, >6 GB → 8; exact
  bands finalised in code and documented). Used by Phase 2's "Auto — N tabs".
- Riverpod provider for `DeviceMemory`.

### 5.7 Tests (all run on the host — no device)
- `test/core/fingerprint/content_fingerprint_test.dart` — same/different bytes; stream ==
  bytes.
- `test/core/storage/saf_service_test.dart` — mock the `MethodChannel`; each native error
  code maps to the right `SafException`; a cancelled pick is not an error.
- `test/core/storage/key_value_store_test.dart` — round-trip a non-sensitive key (real
  `shared_preferences` mock) and a sensitive key (in-memory secure fake); the facade routes
  correctly.
- `test/core/storage/repositories_test.dart` — `sqflite_common_ffi` in-memory: insert / read
  / delete on each repository; a simple migration bump keeps data.
- `test/core/config/config_service_test.dart` — a valid JSON parses to the right values; a
  malformed JSON returns the safe fallback with no throw.
- `test/core/storage/tab_cap_test.dart` — sample RAM values map to the expected caps.

### 5.8 Config / manifest
- `pubspec.yaml` — add the packages from §4. (`assets/config/` is already registered.)
- No `AndroidManifest.xml` permission additions in Phase 1 (see §4).

---

## 6. Task-by-task plan (matches the 6 plan tasks)

- **1.1 SAF + persistable URIs** — build the Dart wrapper + typed errors + Kotlin channel;
  a stale/denied URI returns a clear error, never a crash. Native path flagged for manual
  device check.
- **1.2 Fingerprint** — size + streamed SHA-256; value type with equality.
- **1.3 Prefs + secure storage** — two wrappers + a routing facade.
- **1.4 Local DB** — schema + migration + four repositories, fingerprint-keyed.
- **1.5 ConfigService** — load + typed model + safe fallback + version cross-check.
- **1.6 Device RAM + tab cap** — RAM reader behind an interface + pure auto-cap function.

Each task's acceptance is the one written in the plan; each listed test guards it.

---

## 7. How we know the phase is done (acceptance)

- `flutter analyze` → **zero** issues.
- `flutter test` → green, including every new test in §5.7.
- Only open-source packages added (§4), licenses confirmed at add time; no new runtime
  permissions.
- Dart-level acceptance for all six tasks met and tested on the host.
- **Owed manual check (you):** on a real device — pick a file, confirm it re-opens after an
  app restart (persistable URI works), and a revoked/stale URI shows a clean error. Recorded
  in the change log. (Same pattern as Phase 0's emulator smoke check.)

---

## 8. Out of scope (later phases)

- No Home/Recent **screen**, no tabs UI, no Settings UI — those read this layer in Phase 2.
- No editor, encoding, or save flow — Phase 3 (atomic save uses the SAF `writeBytes` here).
- No sync — Phase 12.

---

## 9. Risks / notes

- **Native code is unverified here.** Mitigation: all logic that *can* be tested on the host
  is; the Kotlin SAF/RAM parts are thin and flagged for your device check.
- **SAF atomic replace** (temp-write-then-replace) is Phase 3's job; Phase 1 only exposes the
  `writeBytes` primitive the atomic saver will build on.
- **`system_info2` license** — confirmed open source before adding; platform-channel fallback
  ready if not.
- **No secret logging** anywhere (security-rules): the secure store, config cross-check, and
  SAF errors never log key material, file contents, or URIs' contents.

---

## 10. Change log

On completion, write `change_log/<ts>_phase-1-data-platform-foundation.md` referencing this
plan, update [implementation-progress.md](../docs/implementation-progress.md) (Phase 1 tasks
→ ✅ with the change-log filename), and set this plan's Status to `completed` (or
`partial_completion` if any task is left owing only the manual device check).
