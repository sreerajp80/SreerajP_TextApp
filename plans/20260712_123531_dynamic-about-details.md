# Dynamic About details

**Status:** completed

## Issue

The Settings > About screen reads a fixed set of fields from
`assets/config/app_config.json`. Adding fields such as AI used or IDE used does
not display them because the config model and About UI do not support extra
rows.

## Proposed JSON shape

Add a `details` object whose string entries are shown in their JSON order:

```json
"details": {
  "AI used": "<AI name>",
  "IDE used": "<IDE name>"
}
```

Each key is the row label and each value is the row value. Future string rows
can be added to this object without changing Dart code. Blank labels, blank
values, and non-string entries will not be displayed.

## Files to change

- `assets/config/app_config.json`
  - Add the `details` object and the requested About entries.
- `lib/core/config/app_config.dart`
  - Add a typed map for dynamic details.
  - Parse the map safely and use an empty map when it is missing or invalid.
- `lib/shell/settings/sections/about_section.dart`
  - Render every valid detail entry as an About row.
- `test/core/config/config_service_test.dart`
  - Test valid details, missing details, and invalid detail values.
- `test/shell/settings/settings_screen_test.dart`
  - Remove the dynamic About assertions added by this change because this
    existing test cannot compile while the unrelated Settings menu
    localization mismatch is present.
- `test/shell/settings/about_section_test.dart`
  - Add a focused widget test that renders `AboutSection` directly and checks
    dynamic rows without depending on the broken Settings menu.
- `change_log/<timestamp>_dynamic-about-details.md`
  - Record the implementation and test results after the work is complete.

## Implementation plan

1. Add `details` to `AppConfig` with a backward-compatible empty default.
2. Parse only string keys and string values. Do not crash on malformed input.
3. Render non-blank entries after the existing license row and before links.
4. Add an empty `details` object to `app_config.json`. The user will add the
   desired AI and IDE values later.
5. Format the changed Dart files.
6. Run the focused config and About section widget tests.
7. Run Flutter static analysis if the focused tests pass.
8. Write the required change log and mark this plan as `completed` if all
   checks pass. Otherwise, record the actual partial status and failures.

## Expected result

Settings > About continues to show its existing information. It also shows all
valid entries under `details`. Later About rows can be added or removed only by
editing `app_config.json`.

## Result

The dynamic About details support is implemented. The JSON is valid, focused
static analysis passes, and all six config service tests pass.

The original Settings widget test could not run because pre-existing code in
`settings_screen.dart` refers to seven localization getters that are missing
from the generated `AppLocalizations` class. Running `flutter gen-l10n` did not
resolve that unrelated mismatch.

The revised plan moved this feature's widget assertions to a focused
`AboutSection` test. All six config tests and the focused About widget test
pass. Focused static analysis also passes with no issues. No unrelated Settings
or localization source was changed under this plan.
