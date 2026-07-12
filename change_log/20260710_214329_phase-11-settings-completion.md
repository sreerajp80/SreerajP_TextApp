# Change log — Phase 11: Settings completion

Implements the plan `plans/20260710_214329_phase-11-settings-completion.md`
(Phase 11 of `docs/implementation-plan.md`). Written in simple English.

**Result:** `flutter analyze` clean; `flutter test` green (500 tests, 26 new).

---

## What changed

Built **one complete Settings screen** with seven sections. The old screen
showed only the Appearance stub; now every preference the app added has a home.

The screen is now `lib/shell/settings/settings_screen.dart` composing seven
section widgets in `lib/shell/settings/sections/`.

### 11.1 Appearance
- Added a **font-family** picker (Default / Sans-serif / Serif / Monospace) bound
  to the existing `ThemeController.setFontFamily`.
- Added a **default word-wrap** preference: new `wordWrap` field + key
  `appearance.word_wrap` on `ThemeSettings` / `ThemeController`. The TXT session
  reads it as its initial wrap state. (MD/CSV/JSON/XML use a fixed wrap in their
  editor surface, so the default applies to the TXT toggle only — noted.)

### 11.2 Editor  (new controller)
- New `EditorSettings` value + `EditorSettingsController`
  (`editorSettingsProvider`): default line-ending (`preserve`/`lf`/`crlf`),
  default encoding (`preserve`/`utf8`/`utf8Bom`), confirm-before-overwrite,
  auto-save interval seconds (0 = off), open-read-only-by-default.
- Wired into all five session managers (TXT/MD/CSV/JSON/XML): auto-save interval
  and the encoding / line-ending save defaults now come from the setting. Added
  an "auto-save off when interval ≤ 0" guard to the TXT/MD/JSON/XML sessions (CSV
  already had it).
- `TabsController.openFile` now opens a new tab read-only when the setting is on.
- New `confirm_overwrite.dart` helper (`confirmOverwriteIfNeeded`) shows an
  overwrite confirm dialog when the setting is on; wired into every format's
  overwrite Save path (the five `*_save_options_sheet.dart`).

### 11.3 Files & Tabs
- Added `TabsController` setters + getters: `setCapModeAuto`, `setFixedCap`,
  `capMode`, `fixedCap`, `restoreOnRelaunch`, `setRestoreOnRelaunch`.
- The section shows an Auto/Fixed switch (Auto shows "Auto — N" from device RAM),
  a fixed-cap dropdown, the over-limit dropdown (existing setter), and the
  restore-on-relaunch switch.

### 11.4 Speech (TTS)  (new controller + native channel)
- New `TtsSettings` + controller (`ttsSettingsProvider`): English on/off,
  Malayalam on/off.
- New `TtsInstaller` (`ttsInstallerProvider`) over a **new Kotlin method channel**
  `app/tts_install` (`TtsInstallChannel.kt`, registered in `MainActivity.kt`):
  fires `ACTION_INSTALL_TTS_DATA` and opens system TTS settings. Added a matching
  `<queries>` entry in `AndroidManifest.xml`. No new package.
- The Malayalam toggle checks the voice via `TtsService.availability`: ready →
  ok; needs-install → shows Install / Open-settings / Check-again buttons;
  unavailable → auto-disables the toggle with a notice. Never a dead button.

### 11.5 Sync  (binds to Phase 12)
- New `SyncSharePrefs` + controller (`syncSharePrefsProvider`): which record
  categories are pre-checked when sharing (`sync.share.<category>`). The host
  share chooser now takes an `initialCategories` and reads these prefs.
- The section lists the three categories as toggles, a plain note that only
  non-sensitive settings sync (never keys / PIN / pairing code), and an
  "Open sync" button into the existing sync flow.

### 11.6 Security  (toggles + prefs only)
- New `SecuritySettings` + controller (`securitySettingsProvider`): app-lock and
  screenshot-protection toggles. Preferences persist now; the actual enforcement
  (launch gate + `FLAG_SECURE`) is left to Phase 13.2, and the captions say so.

### 11.7 About
- New About section reads `appConfigProvider` (from `assets/config/app_config.json`)
  and shows app name, description, version+build, author, contact, license note,
  and tappable links (via `url_launcher`). Editing the config changes the screen
  with no code change.

---

## Files

**New**
- `lib/core/editor/editor_settings.dart`, `editor_settings_controller.dart`,
  `confirm_overwrite.dart`
- `lib/core/tts/tts_settings.dart`, `tts_installer.dart`
- `lib/sync/sync_share_prefs.dart`
- `lib/shell/settings/security_settings.dart`
- `lib/shell/settings/sections/`: `settings_widgets.dart`, `appearance_section.dart`,
  `editor_section.dart`, `files_tabs_section.dart`, `speech_section.dart`,
  `sync_section.dart`, `security_section.dart`, `about_section.dart`
- `android/app/src/main/kotlin/in/zohomail/sreerajp/text_data/TtsInstallChannel.kt`
- Tests: `test/core/editor/editor_settings_test.dart`,
  `test/core/editor/confirm_overwrite_test.dart`,
  `test/core/tts/tts_settings_test.dart`,
  `test/shell/settings/security_settings_test.dart`,
  `test/shell/settings/settings_screen_test.dart`,
  `test/shell/settings/speech_section_test.dart`,
  `test/sync/sync_share_prefs_test.dart`,
  `test/shell/tabs/tabs_settings_test.dart`

**Modified**
- `lib/shell/settings/settings_screen.dart` (composes the seven sections)
- `lib/core/theme/theme_settings.dart`, `theme_controller.dart` (word wrap)
- `lib/shell/tabs/tabs_controller.dart` (cap-mode / restore setters, read-only
  default on open)
- `lib/formats/{txt,markdown,json,csv,xml}/*_document_session.dart` +
  `*_session_manager.dart` (auto-save interval + encoding / line-ending defaults;
  TXT initial word wrap)
- `lib/formats/{txt,markdown,json,csv,xml}/*_save_options_sheet.dart`
  (confirm-before-overwrite)
- `lib/sync/ui/share_chooser.dart`, `sync_host_screen.dart` (initial share
  selection from prefs)
- `android/app/src/main/kotlin/in/zohomail/sreerajp/text_data/MainActivity.kt`,
  `android/app/src/main/AndroidManifest.xml` (TTS install channel + query)
- `docs/implementation-progress.md`

---

## Tests

500 tests pass (26 new). New coverage: `EditorSettings` round-trip / defaults /
clamps / resolve; auto-save-off; read-only-default on open; tab cap-mode / fixed
/ restore setters; `TtsSettings` round-trip; the Speech section's install / auto
-disable flow; `SyncSharePrefs` round-trip; `SecuritySettings` round-trip;
confirm-overwrite dialog (on/off, confirm/cancel); the settings screen (seven
headers render, confirm-overwrite toggle persists); About shows config values and
follows a changed config with no code change.

---

## Known limits / follow-ups

- Word-wrap default applies to the TXT wrap toggle; the other formats use a fixed
  wrap in their editor surface.
- Security toggles persist but do not yet enforce — enforcement is Phase 13.2.
- Phase 12's `SyncConstants.syncableSettingKeys` are un-namespaced and do not
  match the app's namespaced preference keys, so settings-sync exports nothing
  yet. Reconciling the allow-list is a small follow-up for Phase 13/14.
- Manual on-device pass still owed (see the progress note).
