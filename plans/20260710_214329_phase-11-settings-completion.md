# Plan — Phase 11: Settings completion

**Status:** completed

Implements Phase 11 of [docs/implementation-plan.md](../docs/implementation-plan.md)
("Settings completion") and the Settings design in
[docs/architecture.md](../docs/architecture.md) §8. Written in simple English.

---

## 1. What this phase is

Build **one Settings screen** with all seven sections the app now needs. Every
feature added in Phases 2–12 gets a place to change its preference. The screen is
already a top-level navigation destination (`ShellDestination.settings` →
`SettingsScreen`); today it only shows an Appearance stub.

The seven sections (arch §8):

1. Appearance
2. Editor
3. Files & Tabs
4. Speech (TTS)
5. Sync
6. Security
7. About

---

## 2. What the issue is

The current `lib/shell/settings/settings_screen.dart` shows **only** theme mode,
font size, and line spacing, then a placeholder line saying the rest "arrive in a
later phase." Most of the backing state exists but is not reachable from Settings,
and a few preferences do not exist at all yet.

State that already exists and just needs UI:
- **Appearance:** `ThemeController` (mode, font scale, line spacing, font family).
- **Files & Tabs:** `TabsController` (over-limit behavior setter already persists;
  cap mode / fixed cap are *read* at startup but never *written*), and
  `TabsPersistence` (restore-on-relaunch bool, not exposed).
- **Sync:** Phase 12 is done (`lib/sync/`), so the Sync section can bind to real
  categories and open the sync flow.
- **About:** `appConfigProvider` (from `assets/config/app_config.json`) is ready.

State that does **not** exist yet and must be added:
- **Appearance:** a "default word wrap" preference (word wrap is per-session,
  hard-coded, today).
- **Editor:** default encoding / line-ending behavior (preserve vs a chosen
  default), confirm-before-overwrite, auto-save/draft interval, open-read-only-by-
  default. Today the auto-save interval is hard-coded to 5 s and never threaded
  through the session managers; the other three do not exist.
- **Speech:** a persisted English on/off and Malayalam on/off preference, plus a
  guided-install path for the Malayalam `ml-IN` voice (no launcher exists yet).
- **Security:** app-lock and screenshot-protection toggles (no code yet).

### Decisions taken (from the user)

- **Security section (11.6):** build the **toggles and persisted preferences
  only**. The real enforcement (a lock gate on launch, `FLAG_SECURE` wiring) is
  left to Phase 13.2. The UI clearly says enforcement arrives in a later update, so
  no control silently does nothing without a note.
- **TTS install (11.4):** use a **custom Kotlin method channel** (matching the
  existing SAF platform channel), not a new package.

### Known issue found while planning (flagged, not fixed here)

Phase 12's `SyncConstants.syncableSettingKeys` uses **un-namespaced** keys
(`theme_mode`, `font_scale`, `default_word_wrap`, `max_open_tabs`,
`over_limit_close_lru`, `restore_tabs_on_relaunch`, …). The app's real preference
keys are **namespaced** (`appearance.theme_mode`, `tabs.fixed_cap`,
`tabs.over_limit`, …). Because the names do not match, settings-sync currently
exports nothing. Phase 11 keeps the existing namespaced convention for all new
keys (safer than renaming stored keys) and **does not change sync behavior**.
Reconciling the allow-list is noted as a small follow-up for Phase 13/14.

---

## 3. The plan (per section)

### 11.1 Appearance
- Keep theme mode, font size, line spacing (already there).
- Add a **font family** picker (a dropdown: "Default" plus a few common families);
  bind to `ThemeController.setFontFamily`.
- Add a **default word wrap** switch. Add `bool wordWrap` (default `true`) to
  `ThemeSettings` with key `appearance.word_wrap`, plus a `setWordWrap` setter on
  `ThemeController`. Text formats read it as their initial wrap state: wire into
  `TxtDocumentSession` and `MdDocumentSession` initial `_wordWrap`. Structured
  formats (CSV/JSON/XML) keep wrap off by default (format-appropriate) — noted.

### 11.2 Editor  (new `EditorSettings` + controller)
Create `lib/core/editor/editor_settings.dart` (immutable value + keys + small
enums) and `editor_settings_controller.dart` (`Notifier<EditorSettings>` +
`editorSettingsProvider`), following the `ThemeController` pattern (sync hydrate in
`build()`, state-first + fire-and-forget writes). Fields / keys:
- `lineEndingDefault` — enum `LineEndingDefault { preserve, lf, crlf }`, default
  `preserve`. Key `editor.line_ending_default`.
- `encodingDefault` — enum `EncodingDefault { preserve, utf8, utf8Bom }`, default
  `preserve`. Key `editor.encoding_default`.
- `confirmOverwrite` — bool, default `true`. Key `editor.confirm_overwrite`.
- `autoSaveSeconds` — int (0 = off; else 2/5/10/30), default 5. Key
  `editor.autosave_seconds`.
- `openReadOnlyByDefault` — bool, default `false`. Key `editor.read_only_default`.

Wiring (apply the TXT pattern to all five formats):
- **Auto-save interval:** each `*_session_manager.dart` reads
  `editorSettingsProvider` and passes `autoSaveInterval` into the session
  constructor (0 s → auto-save disabled). CSV already guards `<= Duration.zero`;
  add the same guard to the other sessions' `_startAutoSave`.
- **Open read-only by default:** when a tab is created in
  `TabsController.openFile`, set the new tab's `isReadOnly` from the pref.
- **Default encoding / line ending:** when a session finishes loading, if the pref
  is not `preserve`, set the save encoding / line ending to the chosen default
  (still overridable per document in the existing encoding/line-ending choosers).
- **Confirm before overwrite:** add a shared helper
  `lib/core/editor/confirm_overwrite.dart` (`Future<bool> confirmOverwriteIfNeeded(
  BuildContext, WidgetRef)`) that shows a confirm dialog only when the pref is on
  and the save is an overwrite (not save-as-copy). Call it in each format's
  Save action before `session.save()`.

### 11.3 Files & Tabs
- **Max open tabs:** add setters to `TabsController` — `setCapModeAuto()` and
  `setFixedCap(int)` — that write `capModeKey` / `fixedCapKey` and then re-resolve
  the live cap (`resolveCap()` / `applyCap`). The UI shows an Auto/Fixed switch;
  Auto shows the computed value as "Auto — N" (read via
  `deviceMemoryProvider.autoTabCapForDevice()`); Fixed shows a stepper.
- **Over-limit behavior:** bind a segmented control to the existing
  `setOverLimitBehavior` (`OverLimitBehavior` enum, already persists).
- **Restore tabs on relaunch:** expose `restoreEnabled` getter and a
  `setRestoreOnRelaunch(bool)` method on `TabsController` (delegating to
  `TabsPersistence`); bind a switch.
- Acceptance check: lowering a fixed cap below the number of open tabs closes the
  extra tabs by the over-limit rule on the next open (rule already exists).

### 11.4 Speech (TTS)
- New `lib/core/tts/tts_settings.dart` (+ controller `ttsSettingsProvider`):
  `englishEnabled` (default true, key `tts.english_enabled`), `malayalamEnabled`
  (default false, key `tts.malayalam_enabled`).
- New `lib/core/tts/tts_installer.dart` — a thin Dart wrapper over a **method
  channel** `app/tts_install` with `openInstallTtsData()`
  (`ACTION_INSTALL_TTS_DATA`) and `openTtsSettings()` (system Text-to-speech
  settings). Behind an interface so the Settings widget stays testable.
- Native side: add the channel handler in
  `android/app/src/main/kotlin/.../MainActivity.kt` (fires the two intents; returns
  a clear result if no activity can handle them). The manifest already has a
  `<queries>` entry for `TTS_SERVICE`.
- Settings UI: English on/off switch; Malayalam on/off switch. When Malayalam is
  turned on, ask `TtsService.availability(TtsLanguage.malayalam)`:
  `ready` → done; `needsInstall` → show "Install voice data" / "Open TTS settings"
  buttons (guided install); `unavailable` → auto-disable the switch with a friendly
  note. Never a dead button (idea Risks).

### 11.5 Sync  (binds to Phase 12)
- New `lib/sync/sync_share_prefs.dart` (+ controller `syncSharePrefsProvider`):
  which of the three categories (favorites / bookmarks / recents) are **pre-checked
  by default** when the user starts a share. Bools keyed `sync.share.<category>`,
  default all true.
- `lib/sync/ui/share_chooser.dart` reads these prefs for its initial selection
  (falls back to all-selected).
- Settings UI (Sync section): one switch per syncable category (the default share
  selection), a read-only note that only non-sensitive settings sync and that
  security/identity data is never shared, and an "Open sync" button that starts the
  existing sync flow (`SyncLandingScreen`). No sensitive/identity state is listed
  (arch §8, security-rules).

### 11.6 Security  (toggles + prefs only)
- New `lib/shell/settings/security_settings.dart` (+ controller
  `securitySettingsProvider`): `appLockEnabled` (bool, key
  `security.app_lock_enabled`, default false), `screenshotProtection` (bool, key
  `security.screenshot_protection`, default true).
- Settings UI: two switches, each with a short caption saying enforcement
  (launch gate / `FLAG_SECURE`) is delivered in a later update (Phase 13.2). The
  preferences persist now so Phase 13 can read them. No PIN entry UI in this phase.

### 11.7 About
- New About section widget that watches `appConfigProvider` (handles loading /
  error `AsyncValue`) and shows app name, description, version+build, author,
  email, license note, and tappable links (privacy / support) via `url_launcher`
  (already a dependency). Editing `app_config.json` changes the screen with no code
  change (arch §12 config test).

### Screen composition
Split the sections into small widgets under
`lib/shell/settings/sections/` (`appearance_section.dart`, `editor_section.dart`,
`files_tabs_section.dart`, `speech_section.dart`, `sync_section.dart`,
`security_section.dart`, `about_section.dart`) and rebuild `settings_screen.dart`
as a `ListView` that composes them. Reuse the existing `_SectionHeader` /
`_SliderTile` (promote to shared widgets in the sections folder).

---

## 4. Files to change / create

**New**
- `lib/core/editor/editor_settings.dart`
- `lib/core/editor/editor_settings_controller.dart`
- `lib/core/editor/confirm_overwrite.dart`
- `lib/core/tts/tts_settings.dart` (+ controller)
- `lib/core/tts/tts_installer.dart`
- `lib/sync/sync_share_prefs.dart`
- `lib/shell/settings/security_settings.dart` (+ controller)
- `lib/shell/settings/sections/appearance_section.dart`
- `lib/shell/settings/sections/editor_section.dart`
- `lib/shell/settings/sections/files_tabs_section.dart`
- `lib/shell/settings/sections/speech_section.dart`
- `lib/shell/settings/sections/sync_section.dart`
- `lib/shell/settings/sections/security_section.dart`
- `lib/shell/settings/sections/about_section.dart`
- `lib/shell/settings/sections/settings_widgets.dart` (shared `_SectionHeader` /
  `_SliderTile`)
- Tests: `test/core/editor/editor_settings_test.dart`,
  `test/core/tts/tts_settings_test.dart`,
  `test/shell/settings/security_settings_test.dart`,
  `test/sync/sync_share_prefs_test.dart`,
  `test/shell/tabs/tabs_cap_setters_test.dart`,
  `test/shell/settings/settings_screen_test.dart`,
  `test/shell/settings/about_section_test.dart`

**Modified**
- `lib/core/theme/theme_settings.dart`, `lib/core/theme/theme_controller.dart`
  (add `wordWrap`)
- `lib/shell/settings/settings_screen.dart` (compose all sections)
- `lib/shell/tabs/tabs_controller.dart` (cap-mode / fixed-cap / restore setters;
  read-only-default on open)
- `lib/formats/txt/txt_session_manager.dart`,
  `lib/formats/markdown/md_session_manager.dart`,
  `lib/formats/json/json_session_manager.dart`,
  `lib/formats/csv/csv_session_manager.dart`,
  `lib/formats/xml/xml_session_manager.dart` (thread auto-save interval, encoding /
  line-ending default)
- `lib/formats/txt/txt_document_session.dart`,
  `lib/formats/markdown/md_document_session.dart` (initial word wrap;
  auto-save-off guard)
- the five format Save actions/toolbars (call `confirmOverwriteIfNeeded`)
- `lib/sync/ui/share_chooser.dart` (initial selection from share prefs)
- `android/app/src/main/kotlin/.../MainActivity.kt` (+ `AndroidManifest.xml` if a
  new `<queries>`/intent entry is needed) — TTS install method channel
- `docs/implementation-progress.md` (mark Phase 11 tasks done)

---

## 5. Tests (acceptance)

- **11.1** widget: changing font family / word-wrap updates state and persists
  (in-memory store round-trip); unit: `ThemeSettings.wordWrap` default + copyWith.
- **11.2** unit: `EditorSettings` round-trip + defaults + clamps; a session built
  with `autoSaveSeconds = 0` starts no auto-saver; a new tab opens read-only when
  the pref is on.
- **11.3** unit: `setFixedCap` / `setCapModeAuto` write the right keys and change
  the live cap; `setRestoreOnRelaunch` persists.
- **11.4** unit: `TtsSettings` round-trip; Settings flow calls the installer only
  on `needsInstall` and auto-disables on `unavailable` (fake `TtsService` +
  fake installer).
- **11.5** unit: share prefs round-trip; the chooser's initial selection follows
  the prefs (fake store).
- **11.6** unit: `SecuritySettings` round-trip + defaults.
- **11.7** widget: About shows values from an overridden `appConfigProvider`;
  changing the config value changes the rendered text (no code change).
- Whole screen: `flutter analyze` clean and `flutter test` green.

---

## 6. Rules honored

- **Open source only** (CLAUDE.md §3.1): no new package — TTS install uses a native
  method channel; `url_launcher` is already present.
- **Offline-first / scoped storage:** unchanged; no new permissions except the TTS
  intents (system-provided).
- **Never crash on bad input:** TTS availability, config load, and the install
  channel all degrade to friendly states; About uses the existing safe fallback.
- **No sensitive state in the Sync section** (security-rules): only the three
  categories + the "won't share security/identity" note.
- **Simple English** throughout the UI copy and this plan.

---

## 7. Out of scope / follow-ups

- Real security enforcement (app-lock gate, `FLAG_SECURE`) — Phase 13.2.
- Reconciling Phase 12's un-namespaced `syncableSettingKeys` with the app's
  namespaced keys so settings actually sync — small follow-up (Phase 13/14).
- Manual on-device pass (theme/family look, real TTS voice install, sync from
  Settings) — recorded as owed in the change log, like earlier phases.
