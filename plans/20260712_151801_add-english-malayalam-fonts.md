# Add open-source English + Malayalam fonts

**Status:** completed

## What the user asked

Add more beautiful, open-source fonts for **English** and **Malayalam** to the
Appearance settings, replacing the current bare list of Android generic names.

## The issue (today's state)

- The "Font family" dropdown offers only `Default`, `Sans-serif`, `Serif`,
  `Monospace`. These are Android **generic family names**, not bundled fonts —
  no real font files ship with the app.
- `fontFamily` flows one way from `ThemeSettings` into:
  - the app theme ([lib/core/theme/app_themes.dart](../lib/core/theme/app_themes.dart), `ThemeData.fontFamily`), and
  - all four code-editor surfaces (`CodeEditorStyle.fontFamily`) in
    [lib/formats/txt/txt_editor_surface.dart](../lib/formats/txt/txt_editor_surface.dart),
    [.../json/json_editor_surface.dart](../lib/formats/json/json_editor_surface.dart),
    [.../markdown/md_editor_surface.dart](../lib/formats/markdown/md_editor_surface.dart),
    [.../xml/xml_editor_surface.dart](../lib/formats/xml/xml_editor_surface.dart).
- A Latin font has **no Malayalam glyphs**, so bundling only English fonts would
  break Malayalam text. Malayalam needs its own face applied as a fallback.

## Decisions (confirmed with the user)

- **Font set — "Recommended curated set":**
  - English: **Inter** (sans), **Lora** (serif), **JetBrains Mono** (mono).
  - Malayalam: **Manjari** (traditional), **Rachana** (classic traditional
    orthography), and **Noto Sans Malayalam**.
  - All are SIL Open Font License (OFL) → satisfies CLAUDE.md §3.1 (open source only).
- **UX — separate pickers:** two dropdowns in Appearance — one for the English
  face, one for the Malayalam face. The chosen Malayalam face is applied as the
  font fallback everywhere, so Malayalam text always renders in a real Malayalam
  font regardless of the English choice.

## Confirmed technical facts

- `ThemeData` (Flutter 3.41.9) supports `fontFamilyFallback` — verified in SDK.
- `re_editor` 0.10.0 `CodeEditorStyle` supports `fontFamilyFallback` — verified.
  So both the app theme and the code editors can take the Malayalam fallback.

## Plan for the fix

### 1. Add the font files

- Create `fonts/` at the project root and add the TTF files (Regular + Bold for
  each; Manjari also has Thin). Files come from official OFL sources
  (Google Fonts / rit-git / smc.org.in). During implementation I will download
  them from those official sources; if the network blocks it, I will stop and ask
  the user to drop the TTF files into `fonts/`.
- Add the licence text for each family under `fonts/licenses/` (OFL requires the
  licence to ship with the font).

### 2. Declare the fonts — [pubspec.yaml](../pubspec.yaml)

Add a `fonts:` block under `flutter:` for families: `Inter`, `Lora`,
`JetBrains Mono`, `Manjari`, `Rachana`, `Noto Sans Malayalam` (with the right
weight descriptors). No new Dart package is added.

### 3. Central font registry — new file `lib/core/theme/app_fonts.dart`

- One place that lists the English choices (label → family, `Default` = null)
  and the Malayalam choices (label → family, `Default` = null). Keeps the
  settings UI and the theme in sync and avoids magic strings.

### 4. Settings model — [lib/core/theme/theme_settings.dart](../lib/core/theme/theme_settings.dart)

- Add `String? malayalamFontFamily` field + `malayalamFontFamilyKey`
  (`appearance.malayalam_font_family`).
- Wire it through the constructor, `copyWith` (with the same `_noChange`
  sentinel so it can be cleared), `==`, and `hashCode`.

### 5. Controller — [lib/core/theme/theme_controller.dart](../lib/core/theme/theme_controller.dart)

- Hydrate `malayalamFontFamily` in `_load()`.
- Add `setMalayalamFontFamily(String?)` mirroring `setFontFamily` (null/empty
  clears + removes the key).

### 6. Apply the fallback — [lib/core/theme/app_themes.dart](../lib/core/theme/app_themes.dart)

- In `_build`, pass `fontFamilyFallback: [malayalamFontFamily]` when set (else
  null) so Malayalam glyphs resolve to the chosen Malayalam face app-wide.

### 7. Apply the fallback in editors — the four `*_editor_surface.dart` files

- Add `fontFamilyFallback: appearance.malayalamFontFamily != null ? [..] : null`
  next to the existing `fontFamily:` in each `CodeEditorStyle`. (Extract a tiny
  shared helper so the same list logic is not copy-pasted four times.)

### 8. Settings UI — [lib/shell/settings/sections/appearance_section.dart](../lib/shell/settings/sections/appearance_section.dart)

- Replace the hard-coded `_fontChoices` map with the registry from step 3.
- Show two dropdowns: **Font family** (English) and **Malayalam font**. Each row
  reuses the existing label + `DropdownButton` layout.

### 9. Localization — [lib/l10n/app_en.arb](../lib/l10n/app_en.arb)

- Add `appearMalayalamFontFamily` = "Malayalam font" (+ description). Re-run
  `flutter gen-l10n` so `AppLocalizations` picks it up.

### 10. Tests — [test/core/theme/theme_controller_test.dart](../test/core/theme/theme_controller_test.dart)

- Add cases: set/clear `malayalamFontFamily` persists and hydrates; default is
  null.

## Files to be changed / added

- **Add:** `fonts/*.ttf`, `fonts/licenses/*`, `lib/core/theme/app_fonts.dart`
- **Edit:** `pubspec.yaml`, `lib/core/theme/theme_settings.dart`,
  `lib/core/theme/theme_controller.dart`, `lib/core/theme/app_themes.dart`,
  `lib/formats/{txt,json,markdown,xml}/*_editor_surface.dart`,
  `lib/shell/settings/sections/appearance_section.dart`,
  `lib/l10n/app_en.arb`, `test/core/theme/theme_controller_test.dart`

## Behaviour note

- When English = `Default` and a Malayalam font is chosen, Latin text uses the
  Malayalam face's own Latin glyphs (Manjari/Noto both include Latin). This is
  acceptable; picking an English face avoids it. I will confirm the look by
  running the app after the change.

## Testing

- `flutter analyze` and `flutter test` (the new controller tests + existing).
- Manual: open the Appearance screen, switch English and Malayalam fonts, open a
  file containing mixed English + Malayalam text, confirm both render correctly
  in the editor and across TXT/MD/JSON/XML.

## Out of scope

- No app UI translation to Malayalam (only English arb exists today).
- No per-document font override; this stays a global appearance setting.
