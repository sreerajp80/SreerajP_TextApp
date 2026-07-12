# Change log — Phase 0: Project scaffold

**Implements plan:** [plans/20260709_142949_phase-0-project-scaffold.md](../plans/20260709_142949_phase-0-project-scaffold.md)
**Phase:** 0 of [docs/implementation-plan.md](../docs/implementation-plan.md)
**Date:** 2026-07-09

---

## What changed

Created the Flutter project from scratch (the repo had only docs before) and set up the
agreed structure, Riverpod, and a Material 3 base.

### Project creation
- Ran `flutter create` in place: org `in.zohomail.sreerajp`, package name `text_data`,
  Android-only platform, Kotlin. This generated `android/`, `lib/`, `test/`, `pubspec.yaml`,
  `analysis_options.yaml`, and related files.

### Dependencies (`pubspec.yaml`)
- Added `flutter_riverpod: ^3.3.2` (BSD-3, open source — the only new package this phase,
  per CLAUDE.md §3.1).
- Updated the project `description` to describe TextData.
- Pinned SDK constraints: `sdk: ^3.11.5` (generated) and added `flutter: ">=3.41.9"`.
- Registered `assets/config/` under the `flutter.assets` section (used from Phase 1).

### Android (`android/app/build.gradle.kts`)
- Set `minSdk = 26` (Android 8.0), replacing `flutter.minSdkVersion`, per CLAUDE.md §2.

### App entry point
- `lib/main.dart`: wraps the app in `ProviderScope` and runs `TextDataApp`.
- `lib/app.dart`: new `TextDataApp` — a `MaterialApp` with `useMaterial3: true`, a seeded
  `ColorScheme` (indigo), and a throwaway `_PlaceholderHome` screen ("TextData — scaffold
  ready"). This placeholder is replaced by the real shell in Phase 2.

### Module folder tree (arch §4)
- Created all module folders with `.gitkeep` placeholders so the tree exists and imports
  resolve:
  - `lib/core/`: config, theme, editor, search, tts, export, print, share, zip, metadata,
    storage, fingerprint.
  - `lib/formats/`: txt, markdown, csv, json, xml.
  - `lib/shell/`: home, onboarding, tabs, settings.
  - `lib/sync/`.
  - `assets/config/`.
  - `test/`: sync, formats, core/editor.

### Lint + tests
- `analysis_options.yaml` (generated) keeps `package:flutter_lints/flutter.yaml` active.
- Removed the default `test/widget_test.dart` (counter demo).
- Added `test/smoke_test.dart`: pumps `ProviderScope(child: TextDataApp())` and asserts the
  `MaterialApp` and placeholder home text are present.

---

## Verification

- `flutter analyze` → **No issues found!**
- `flutter test` → **All tests passed!** (smoke test).
- Tooling confirmed: Flutter 3.41.9, Dart 3.11.5 (meet the project minimums).

**Manual step still owed by the user:** run `flutter run` on an Android emulator/device
(minSdk 26) once to confirm the blank Material 3 home shows. This cannot be done from the
non-interactive session; the automated gates above stand in until then.

---

## Result

Phase 0 is complete. The app builds, analyzes clean, and has a passing test. The structure
is ready for Phase 1 (data & platform foundation).
