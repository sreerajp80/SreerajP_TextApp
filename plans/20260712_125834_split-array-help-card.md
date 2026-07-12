# Add Split array help topic to Settings

**Status:** completed

## What the issue is

The Settings screen does not have a Help card. Users can see the **Split array**
action in the JSON menu, but the app does not explain what it does or how the
saved parts are created.

The requested layout is a **Help** card on the main Settings page. Opening Help
should show a second card for the **Split array** topic. That topic card should
contain a clear description of the feature.

## Plan for the change

1. Add a `HelpSection` widget for the Help detail page.
2. Show a nested **Split array** card inside `HelpSection`. The card will explain:
   - it works on a top-level JSON array;
   - the user chooses how many items go into each part;
   - the app creates numbered files such as `name.part1.json`;
   - the user chooses where to save every part;
   - the last part can contain fewer items;
   - the original file is not changed.
3. Add a **Help** card to the main Settings card list. Tapping it will open the
   existing `SettingsDetailScreen`, with the nested Split array topic card in
   its body.
4. Add English localization strings for the Help card, topic title, and topic
   description. Regenerate the Dart localization files with `flutter gen-l10n`.
5. Update Settings widget tests to expect eight main cards and verify that the
   Help card opens and displays the Split array explanation.
6. Run formatting, localization generation, the Settings widget tests, and
   static analysis for the changed code.
7. Write the required change log and mark this plan as completed after all
   checks pass.

## Files to be changed

- `lib/shell/settings/settings_screen.dart` — add the main Help card.
- `lib/shell/settings/sections/help_section.dart` — new Help detail content with
  a nested Split array card.
- `lib/l10n/app_en.arb` — add Help and Split array help text.
- `lib/l10n/app_localizations.dart` — regenerated localization API.
- `lib/l10n/app_localizations_en.dart` — regenerated English localization.
- `test/shell/settings/settings_screen_test.dart` — update the card count and
  test the nested Help topic.
- `plans/20260712_125834_split-array-help-card.md` — keep plan status current.
- `change_log/<timestamp>_split-array-help-card.md` — record the completed work.

## Scope notes

- This change adds help content only. It does not change how Split array works.
- No package or permission changes are needed.
- The UI uses Material 3 widgets already used by the Settings screen.
