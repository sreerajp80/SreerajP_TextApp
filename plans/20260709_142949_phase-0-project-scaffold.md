# Phase 0 — Project scaffold

**Status:** completed

Implements **Phase 0** of [implementation-plan.md](../docs/implementation-plan.md).

---

## 1. What this phase is (goal)

Create a running, empty Flutter app with the agreed folder structure, Riverpod state
management, and a Material 3 base — so every later phase has a home. Nothing here opens or
edits files yet; it is only the skeleton.

**Depends on:** nothing. **Introduces package:** `flutter_riverpod` only.

---

## 2. The issue / why

The repo today has only docs, plans, and change logs. There is **no Flutter project** at
all (no `pubspec.yaml`, no `lib/`, no `android/`, no `test/`). We cannot build or run
anything. Phase 0 lays the ground so Phase 1 and later have somewhere to live.

Tooling is already correct: Flutter 3.41.9 and Dart 3.11.5 are installed, matching the
project minimums (CLAUDE.md §2).

---

## 3. Files to be created / changed

Created by `flutter create`, then adjusted:

- `pubspec.yaml` — project name, SDK constraints (Dart ≥ 3.11.5, Flutter ≥ 3.41.9),
  add `flutter_riverpod`, register `assets/config/`.
- `lib/main.dart` — `ProviderScope` wrapping the app.
- `lib/app.dart` — `MaterialApp` with `useMaterial3: true`, theme, and a placeholder home
  route.
- `android/app/build.gradle` (or `build.gradle.kts`) — set `minSdk 26`.
- `analysis_options.yaml` — enable `flutter_lints`.
- `test/smoke_test.dart` — one passing widget/smoke test.

Module folder tree (arch §4), each with a `.gitkeep` or placeholder Dart file so imports
resolve and `flutter analyze` is clean:

```
lib/core/config/        lib/core/theme/         lib/core/editor/
lib/core/search/        lib/core/tts/           lib/core/export/
lib/core/print/         lib/core/share/         lib/core/zip/
lib/core/metadata/      lib/core/storage/       lib/core/fingerprint/
lib/formats/txt/        lib/formats/markdown/   lib/formats/csv/
lib/formats/json/       lib/formats/xml/
lib/shell/home/         lib/shell/onboarding/   lib/shell/tabs/
lib/shell/settings/
lib/sync/
assets/config/
test/sync/              test/formats/           test/core/editor/
```

Placeholder Dart files with no code (empty libraries or a single doc comment) are used
instead of bare `.gitkeep` where a Dart file is more natural, because empty folders alone
are not tracked and add nothing for `analyze`. Final choice per folder made during work;
either satisfies the "imports resolve, analyze passes" acceptance.

---

## 4. The plan (task by task)

Follows the four Phase 0 tasks in [implementation-plan.md](../docs/implementation-plan.md).

**0.1 Create the project and pin tool versions.**
- Run `flutter create` in place with an appropriate org and project name (Kotlin Android,
  no iOS/web/desktop unless trivially included; Android is the target).
- Pin SDK constraints in `pubspec.yaml`.
- Set `minSdk 26` in the Android Gradle config.
- Acceptance: `flutter run` shows a blank Material 3 home on an Android emulator.
  (Emulator run is verified manually by the user; the automated gate is analyze + test.)

**0.2 Lay out the module folders.**
- Create the arch §4 tree above with placeholder files so nothing is empty/untracked.
- Acceptance: `flutter analyze` passes.

**0.3 Wire Riverpod + base Material 3 app.**
- `lib/main.dart`: `runApp(const ProviderScope(child: TextApp()))`.
- `lib/app.dart`: `TextApp` → `MaterialApp` with `useMaterial3: true`, a seeded
  `ColorScheme`, and a simple placeholder `HomePage` (e.g. an `AppBar` + centered text).
- Acceptance: a widget test finds the home widget.

**0.4 Lint, format, test scaffolding.**
- `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`.
- `test/smoke_test.dart`: pumps `ProviderScope(child: TextApp())` and asserts the home
  widget is present.
- Acceptance: `flutter analyze` and `flutter test` both green.

---

## 5. How we know it is done (acceptance for the phase)

- `flutter analyze` → **zero** issues.
- `flutter test` → green (smoke test passes).
- `lib/` matches the arch §4 tree; imports resolve.
- App builds and shows a blank Material 3 home (manual emulator check by the user).
- Only new package added is `flutter_riverpod` (open source — BSD-3; satisfies CLAUDE.md
  §3.1).

---

## 6. Out of scope (later phases)

- No file access, storage, DB, config loading, themes-switcher, tabs, or editor — those
  are Phase 1+.
- The placeholder home is throwaway; Phase 2 replaces it with the real shell.

---

## 7. Risks / notes

- `flutter create` generates many Android/Gradle files; I will keep the default template
  and only change `minSdk`. I will not hand-edit generated files beyond what the tasks
  require.
- Running an emulator is not possible from this non-interactive session; the automated
  gates (`analyze`, `test`) stand in, and the user does the one-time emulator smoke check.

---

## 8. Change log

On completion, write `change_log/<ts>_phase-0-project-scaffold.md` referencing this plan,
and mark this plan's Status `completed`.
