# Change log — Add open-source English + Malayalam fonts

**Implements:** [plans/20260712_151801_add-english-malayalam-fonts.md](../plans/20260712_151801_add-english-malayalam-fonts.md)
**Date:** 2026-07-12

## What changed

Added real, bundled, beautiful open-source fonts for English and Malayalam, and
split the Appearance "Font family" control into two independent pickers — one for
the English (Latin) face and one for the Malayalam face. The chosen Malayalam
face is applied as a font fallback everywhere, so Malayalam text always renders
in a proper Malayalam font no matter which English font is picked.

Before this change the dropdown only offered Android generic names
(`sans-serif`, `serif`, `monospace`) and no font files shipped with the app.

## Fonts bundled (all open source — CLAUDE.md §3.1)

- **English:** Inter (sans), Lora (serif), JetBrains Mono (mono) — OFL 1.1.
- **Malayalam:** Manjari (OFL 1.1), Rachana (OFL 1.1 / GPLv3+ with font
  exception), Noto Sans Malayalam (OFL 1.1).
- The `*-Variable.ttf` files (Inter, Lora, JetBrains Mono, Noto Sans Malayalam)
  are variable fonts, so one file covers all weights. Manjari and Rachana use
  static Regular + Bold (weight 700) files.
- Licence text for every family lives in `fonts/licenses/`; sources are listed in
  `fonts/README.md`. Total added asset size ≈ 2.7 MB.

## Files added

- `fonts/Inter-Variable.ttf`, `fonts/Lora-Variable.ttf`,
  `fonts/JetBrainsMono-Variable.ttf`, `fonts/NotoSansMalayalam-Variable.ttf`,
  `fonts/Manjari-Regular.ttf`, `fonts/Manjari-Bold.ttf`,
  `fonts/Rachana-Regular.ttf`, `fonts/Rachana-Bold.ttf`
- `fonts/licenses/*` (one licence file per family)
- `fonts/README.md` (families, licences, sources)
- `lib/core/theme/app_fonts.dart` — central font registry (English + Malayalam
  choices, the Malayalam-fallback helper, and the label lookup).

## Files edited

- `pubspec.yaml` — declared the six font families under `flutter: fonts:`.
- `lib/core/theme/theme_settings.dart` — new `malayalamFontFamily` field +
  `malayalamFontFamilyKey`, wired through constructor, `copyWith` (with the
  `_noChange` sentinel so it can be cleared), `==`, and `hashCode`.
- `lib/core/theme/theme_controller.dart` — hydrate `malayalamFontFamily` and new
  `setMalayalamFontFamily(String?)` setter (null/empty clears + removes the key).
- `lib/core/theme/app_themes.dart` — `ThemeData.fontFamilyFallback` set from the
  chosen Malayalam face (via `AppFonts.malayalamFallback`).
- `lib/formats/{txt,json,markdown,xml}/*_editor_surface.dart` — added
  `fontFamilyFallback` to each `CodeEditorStyle` so the code editors render
  Malayalam in the chosen face too.
- `lib/shell/settings/sections/appearance_section.dart` — replaced the single
  hard-coded font dropdown with a shared `_fontRow` builder and two rows
  (English "Font family" + "Malayalam font"), sourced from `AppFonts`.
- `lib/l10n/app_en.arb` — new `appearMalayalamFontFamily` = "Malayalam font"
  (localizations regenerated).
- `test/core/theme/theme_controller_test.dart` — new cases: default is null,
  set persists, clear removes the key; plus a null-check in the defaults test.

## Verification

- `flutter analyze lib test` → **No issues found**.
- `flutter test test/core/theme/` → all pass (7 tests, including the 2 new).
- `flutter test test/shell/settings/` → all pass (11 tests), confirming the
  reworked Appearance section and settings navigation still render.
- Font files validated as real TrueType (0x00010000 signature) and downloaded
  from official sources (google/fonts, github.com/smc/Rachana).

## Known unrelated test failures (not from this change)

Two tests failed in the full run — `test/a11y/semantics_test.dart` (home-screen
icon semantics) and `test/shell/theme_switch_widget_test.dart` (app-level
navigate-to-Settings-then-tap-Dark flow). Both concern home/navigation UI that a
**parallel, in-progress change** is modifying; neither touches fonts, and the
font/settings/theme unit + widget tests all pass.

## Deferred

- On-device visual confirmation (open a mixed English + Malayalam file, switch
  each font, check TXT/MD/JSON/XML) was **not** run, to avoid a build clash with
  the parallel work in progress. Should be done on a device before release.

## Behaviour note

When English = "Default" and a Malayalam font is chosen, Latin text uses that
Malayalam face's own Latin glyphs (Manjari/Rachana/Noto all include Latin).
Picking an English face avoids this. This matches the approved plan.
