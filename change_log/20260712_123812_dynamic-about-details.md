# Dynamic About details

**Plan:** `plans/20260712_123531_dynamic-about-details.md`

## Changes

- Added an optional `details` string map to `AppConfig`.
- Added safe parsing for the `details` map. Missing, malformed, and non-string
  values are ignored without crashing.
- Made Settings > About render each non-blank detail label and value.
- Added an empty `details` object to `assets/config/app_config.json` for the user
  to fill with AI, IDE, or other About information.
- Added config parsing and About rendering test cases for dynamic details.
- Added a focused `AboutSection` widget test that does not depend on the
  unrelated Settings menu localization mismatch.

## Verification

- `dart format` completed for all changed Dart files.
- `dart analyze lib/core/config/app_config.dart lib/shell/settings/sections/about_section.dart`
  passed with no issues.
- `flutter test test/core/config/config_service_test.dart test/shell/settings/about_section_test.dart`
  passed all seven tests.
- Focused static analysis of the changed source and test files passed with no
  issues.
- PowerShell JSON parsing confirmed that `assets/config/app_config.json` is
  valid JSON.
- The original Settings widget test was attempted but could not compile because
  `settings_screen.dart` already uses seven localization getters missing from
  the generated `AppLocalizations` output. `flutter gen-l10n` was attempted and
  did not resolve this unrelated issue. The approved revised plan verified the
  feature through a direct `AboutSection` widget test instead.

## Status

The requested feature and its focused verification are complete. The unrelated
Settings menu localization mismatch was left unchanged.
