# Phase 13 — Security, Accessibility, Localization, Polish (+ production keystore)

**Status:** completed

> **Note:** Stage B was re-scoped after user feedback to add **biometric unlock** and a
> **recovery code** (approved 2026-07-11). All five stages (A–E) are implemented and green;
> change log: `change_log/20260712_103940_phase-13-security-a11y-l10n-polish.md`. Stage D
> (localization) was taken all the way to **full extraction** of every user-facing string
> across all formats and screens. Owed items are on-device manual checks only.

This plan implements **Phase 13** of [implementation-plan.md](../docs/implementation-plan.md)
(tasks 13.1–13.5) and adds a **production release keystore** wiring. It is one plan,
implemented and reviewed in **five stages** so the diff stays reviewable.

Read before working: [CLAUDE.md](../CLAUDE.md), [security-rules.md](../docs/security-rules.md)
(before any security-sensitive edit), [workflow-rules.md](../docs/workflow-rules.md).

---

## 1. What the issue is

Phase 13 is the dedicated hardening and finishing pass. Today:

- **13.1 Security** — the code is already fairly clean (only one guarded `debugPrint`,
  `Random.secure()` confirmed in sync crypto), but there is **no formal audit record** and
  **no targeted rule-by-rule tests**.
- **13.2 App-lock + screenshot** — `SecuritySettings` stores two toggles
  (`app_lock_enabled`, `screenshot_protection`) but **nothing enforces them**: no launch
  lock gate, no `FLAG_SECURE`, no PIN entry. There is a single TODO hook in
  `lib/sync/ui/sync_host_screen.dart`.
- **13.3 Accessibility** — **zero** explicit `Semantics`/`semanticLabel` in `lib/`; icon-only
  buttons, the QR image, and the scanner have no labels.
- **13.4 Localization** — **no** l10n infrastructure at all (no `flutter_localizations`, no
  `intl`, no `.arb`, no delegates). Every user-facing string is a hardcoded literal.
- **13.5 Error / empty-state polish** — each format has a failure path, but there is no
  consistency pass over the friendly-message / empty-state / snackbar patterns.
- **Keystore** — `android/app/build.gradle.kts` release build signs with the **debug key**
  (stock TODO). No `signingConfigs`, no `key.properties`, no `.jks`.

**Decisions taken (from the user):**
1. Keystore: **wire Gradle to read a gitignored `key.properties` + provide a generation
   script/instructions**. No keystore or password ever touches the repo or the AI.
2. Localization: **full extraction** — every user-facing string moves into `.arb`.
3. Delivery: **one plan, staged implementation** (review between stages).

---

## 2. Stages & order

| Stage | Task(s) | Why this order |
|---|---|---|
| A | 13.1 Security audit + tests, **+ keystore wiring** | Lowest risk; establishes the security baseline and unblocks release signing. |
| B | 13.2 App-lock + screenshot protection | New Kotlin channel + launch gate; self-contained. |
| C | 13.3 Accessibility | Cross-cutting labels; no logic change. |
| D | 13.4 Localization (full extraction) | Largest; touches the most files; done after the UI is otherwise settled. |
| E | 13.5 Error / empty-state polish | Final consistency sweep, done last so it sees final strings. |

Each stage ends with `flutter analyze` + `flutter test` green and this plan's progress
noted. I will pause for your review at the end of each stage.

---

## 3. Files to be changed (by stage)

### Stage A — Security hardening + keystore

- **New:** `docs/security-audit-phase13.md` — the audit record: each rule from
  [security-rules.md](../docs/security-rules.md) with a pass/note and the evidence
  (file:line). Output of the `/security-review` run summarized here.
- **New tests** under `test/security/`:
  - `no_secret_logging_test.dart` — source-scan test asserting no `print(`/`developer.log(`
    in `lib/sync/` and that `lib/` has no unguarded `debugPrint` of payload/secret/key/code.
  - `random_secure_test.dart` — asserts `sync_crypto.dart` uses `Random.secure()` (guards a
    regression to `Random()`), and pairing-code entropy/alphabet invariants.
  - `sync_caps_test.dart` — collects the bounded-read / payload-cap / timeout tests into one
    rule-guard suite (may re-export existing sync tests; no logic change).
- **Keystore wiring:**
  - `android/app/build.gradle.kts` — add a `signingConfigs.release` block that loads
    `../key.properties` **only if it exists** (so debug/CI without the file still builds),
    and point `buildTypes.release.signingConfig` at it, falling back to debug when the
    properties file is absent.
  - `android/key.properties.example` — **new**, a committed template (no real secrets):
    `storeFile=`, `storePassword=`, `keyAlias=`, `keyPassword=`.
  - `android/.gitignore` — confirm `key.properties` and `*.jks`/`*.keystore` are ignored
    (add `*.jks`/`*.keystore` if missing; `key.properties` already listed).
  - **New:** `docs/release-signing.md` — the exact `keytool` command to generate
    `upload-keystore.jks`, how to fill `key.properties`, and how to build a signed release.
    No real passwords; placeholders only.

  I will **not** generate the `.jks` or handle any password. You run the documented
  `keytool` command yourself.

### Stage B — App-lock (PIN + biometric + recovery code) + screenshot protection (13.2)

**Scope (updated after user feedback):** PIN **and** biometric unlock, with a **recovery
code** as the forgot-PIN fallback that unlocks and forces a new PIN.

**Introduces (package):** `local_auth` (BSD-3, open source — CLAUDE.md §3.1) for
fingerprint/face unlock. Android needs `USE_BIOMETRIC` permission and `MainActivity` must
extend `FlutterFragmentActivity` (local_auth requirement).

**Secrets model (security-rules — none of this ever syncs or is logged):**
- The PIN is never stored in the clear. We store a **salted hash**: PBKDF2-HMAC-SHA256 of
  (PIN + per-install random salt), plus the salt, under the reserved Keystore-backed secure
  key `app_lock_pin` (via `SecureStore` / `flutter_secure_storage`).
- The **recovery code** is generated once with `Random.secure()` (reuse the sync alphabet —
  no look-alike chars), shown to the user **once** at setup to save, and only its **salted
  hash** is stored (secure key `app_lock_recovery`). We never keep the plaintext.
- Biometric is a convenience gate only; the PIN/recovery hashes remain the source of truth.
- `app_lock_pin` and `app_lock_recovery` are already in `SyncConstants.neverSyncKeys` /
  sensitive keys, so they can never reach a sync payload.

**Files:**
- **New Kotlin:** `.../WindowSecurityChannel.kt` — method channel `app/window_security` with
  `setSecure(bool)` toggling `WindowManager.LayoutParams.FLAG_SECURE` (main-thread safe).
- `MainActivity.kt` — register the channel; change base class to `FlutterFragmentActivity`.
- `android/app/src/main/AndroidManifest.xml` — add `USE_BIOMETRIC` permission.
- **New Dart:** `lib/core/security/window_security.dart` — thin injectable wrapper over the
  channel (`WindowSecurity.setSecure(bool)`).
- **New Dart:** `lib/core/security/app_lock_hasher.dart` — pure PBKDF2 hash + verify + salt
  gen (reuses `SyncCrypto.randomBytes`/`deriveKey` primitives); fully unit-testable, no
  platform.
- **New Dart:** `lib/core/security/app_lock_repository.dart` — reads/writes the PIN and
  recovery hashes in `SecureStore`; `hasPin`, `setPin`, `verifyPin`, `setRecovery`,
  `verifyRecovery`, `clearAll`.
- **New Dart:** `lib/core/security/biometric_service.dart` — injectable wrapper over
  `local_auth` (`isAvailable`, `authenticate`); returns a plain enum so it is fakeable.
- **New Dart:** `lib/core/security/app_lock_controller.dart` — Riverpod state: locked/unlocked
  for this session; reads `securitySettingsProvider`; enable-app-lock flow (set PIN → show
  recovery code once), unlock via PIN / biometric / recovery code, change PIN, disable.
  Enabling app-lock without a PIN is impossible (guarded).
- **New Dart:** `lib/core/security/app_lock_gate.dart` — wraps the app: when `appLockEnabled`
  and locked, shows the lock screen (PIN pad + "Use biometric" if available + "Forgot PIN?"
  → recovery flow → forced new-PIN); unlocks on success; re-locks on resume from background
  (lifecycle listener).
- **New Dart:** `lib/core/security/lock_screen.dart`, `set_pin_screen.dart`,
  `recovery_code_screen.dart` — the small UI surfaces (PIN entry, set/confirm PIN, show/enter
  recovery code). Kept simple and localizable (Stage D will extract strings).
- `lib/app.dart` — wrap `home:` with `AppLockGate`; drive `FLAG_SECURE` globally when
  `screenshotProtection` is on (safe default; covers the sync/QR screen).
- `lib/sync/ui/sync_host_screen.dart` — replace the TODO: ensure `FLAG_SECURE` while the
  code/QR is shown, and suppress idle auto-lock while the sync screen is open.
- `lib/shell/settings/sections/security_section.dart` — make the toggles real: enabling
  app-lock runs set-PIN → show-recovery; add "Change PIN", "Show/Regenerate recovery code",
  and a biometric-unlock toggle (only if the device supports it); drop the "later update"
  subtitles.
- `pubspec.yaml` — add `local_auth`.

**Tests:**
- `test/core/security/app_lock_hasher_test.dart` — hash/verify round-trip, wrong PIN fails,
  different salts → different hashes, recovery-code path.
- `test/core/security/app_lock_controller_test.dart` — enable requires a PIN; unlock via PIN,
  via recovery code (then forces a new PIN + regenerates recovery), wrong PIN/recovery
  rejected; biometric success/failure via a fake `BiometricService`; disable clears secrets.
- `test/core/security/app_lock_gate_widget_test.dart` — gate blocks entry when locked; a fake
  `WindowSecurity` receives `setSecure(true)` when screenshot protection is on.

### Stage C — Accessibility (13.3)

- Add `Semantics` / `semanticLabel` / `tooltip` to icon-only controls and images across the
  primary screens: `lib/shell/app_shell.dart`, `lib/shell/home/*`, `lib/shell/settings/*`,
  `lib/sync/ui/*` (QR image gets a label; scanner viewport labeled), and the per-format
  toolbars' `IconButton`s.
- Confirm system font scaling is respected (no fixed `textScaleFactor` overrides); fix any
  found.
- **Test:** `test/a11y/semantics_test.dart` — asserts primary actions expose a semantics
  label (finder by label on home/settings/sync), per plan 13.3.

### Stage D — Localization, full extraction (13.4)

- `pubspec.yaml` — add `flutter_localizations` (SDK) + `intl`; set `flutter: generate: true`.
- **New:** `l10n.yaml` at project root (arb dir `lib/l10n`, template `app_en.arb`, output
  `AppLocalizations`).
- **New:** `lib/l10n/app_en.arb` — every extracted string with a key + description; plural/
  placeholder syntax where needed (counts, filenames).
- `lib/app.dart` — add `localizationsDelegates` (incl. `AppLocalizations.delegate` +
  `GlobalMaterial/Widgets/CupertinoLocalizations`) and `supportedLocales`.
- **Every screen/widget with user-facing text** under `lib/` — replace hardcoded literals
  with `AppLocalizations.of(context)!.<key>`. This spans `lib/shell/`, `lib/formats/*/`,
  `lib/sync/`, `lib/core/**` UI strings, dialogs, snackbars, empty states.
  - Approach: extract per area in a fixed order (shell → settings → sync → txt → md → csv →
    json → xml → core dialogs), running `flutter gen-l10n` + `flutter analyze` after each
    area so breakage is localized and reviewable.
  - Non-UI strings (log/debug text, constants, keys) are **not** extracted.
- **Test:** build with the delegate (`test/l10n/localization_test.dart` — `AppLocalizations`
  resolves for `en`, a sample screen renders localized text); a guard that no obvious
  hardcoded user string remains in the migrated new UI.

> Note on scale: full extraction touches many files. I will do it area-by-area and keep each
> area green, reporting progress. If mid-way you want to stop at "core areas done", we can
> mark 13.4 `partial_completion`.

### Stage E — Error / empty-state polish (13.5)

- Sweep every format's failure/empty screens for a consistent friendly message, icon, and a
  clear recovery action; make snackbars non-blocking (`SnackBarBehavior.floating`, no stacked
  blocking dialogs) via a shared helper if one does not exist.
- **New (if absent):** `lib/core/ui/friendly_error_view.dart` / `empty_state_view.dart` —
  shared widgets so all formats look the same; migrate ad-hoc error/empty widgets to them.
- **Test:** run the existing parser failure-path suites; add a widget test that the shared
  error/empty views render and expose their action.

---

## 4. Testing (per CLAUDE.md §6 and plan acceptance)

- Stage A: `/security-review` clean (or every finding triaged in the audit doc);
  logging-scan, `Random.secure()`, and caps tests green; `flutter build` still works with no
  `key.properties` (debug fallback) and the documented signed build works when it is present.
- Stage B: app-lock gate blocks entry when locked; `FLAG_SECURE` set via a fake channel;
  enable-without-PIN guarded. (Real screenshot-block verified manually on a device.)
- Stage C: semantics labels present on primary actions (widget test).
- Stage D: `AppLocalizations` resolves; migrated screens render localized strings;
  `flutter analyze` green.
- Stage E: failure-path suites green; shared error/empty views tested.
- Whole phase: `flutter analyze` zero issues, `flutter test` green.

**Owed manual/device checks** (recorded in the change log): real screenshot block on the
sync screen, app-lock on real relaunch/resume, TalkBack pass, and a signed release install.

---

## 5. Risks / non-goals

- Full l10n extraction is large and mechanical; risk is churn/typos in keys. Mitigated by
  area-by-area migration with `flutter analyze` after each.
- App-wide `FLAG_SECURE` (when protection on) blocks screenshots everywhere, not only the
  sync screen. This is the safe default and matches the setting's intent; can be narrowed to
  the sync screen only if you prefer — tell me and I will scope it that way.
- No keystore or password is generated or handled by me (user decision).
- App-lock uses PIN **+ biometric** (`local_auth`) with a **recovery code** fallback that
  unlocks and forces a new PIN. Only salted hashes are stored (Keystore-backed
  `app_lock_pin` / `app_lock_recovery`); plaintext PIN and recovery code are never stored or
  logged, and both keys are on the never-sync list. Biometric adds the `local_auth` package
  and requires `MainActivity` to extend `FlutterFragmentActivity` — a low-risk base-class
  change validated by the build.

---

## 6. Change log

On completion, write `change_log/<timestamp>_phase-13-security-a11y-l10n-polish.md`
referencing this plan, and update
[implementation-progress.md](../docs/implementation-progress.md) (Phase 13 rows + summary).
If we stop after some stages, mark this plan `partial_completion` and record which stages
landed.
