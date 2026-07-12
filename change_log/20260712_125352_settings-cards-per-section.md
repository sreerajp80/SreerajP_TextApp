# Settings cards and detail pages

Implemented the approved plan in
[`plans/20260712_122606_settings-cards-per-section.md`](../plans/20260712_122606_settings-cards-per-section.md).

## What changed

- Replaced the long Settings screen with seven cards: Appearance, Editor,
  Files & Tabs, Speech, Sync, Security, and About.
- Made each card open a separate page containing that section's settings.
- Added an optional `showHeader` setting to each section so the page title is
  not repeated inside the page.
- Added short localized descriptions for all seven cards and regenerated the
  Flutter localization classes.
- Updated the Settings screen tests to open the required card before checking
  its content.
- Added a test that checks that tapping a card opens its settings page.

## Checks run

- `flutter test test/shell/settings/settings_screen_test.dart` — passed, 5 tests.
- `flutter analyze` — passed with no issues.
- `flutter build apk --debug` — passed.

The debug APK is at `build/app/outputs/flutter-apk/app-debug.apk`.
