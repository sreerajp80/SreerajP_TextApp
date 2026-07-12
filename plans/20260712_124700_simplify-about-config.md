# Simplify About config

**Status:** completed

## Issue

The About config has a separate `links` section that is not needed. Author, email, and
license information are also fixed top-level fields even though the About screen already
supports flexible entries through `details`. The About screen is missing the requested
country footer.

## Files to change

- `assets/config/app_config.json`
- `lib/core/config/app_config.dart`
- `lib/shell/settings/sections/about_section.dart`
- `test/core/config/config_service_test.dart`
- `test/shell/settings/about_section_test.dart`
- `test/shell/settings/settings_screen_test.dart`
- `docs/architecture.md`
- `change_log/<timestamp>_simplify-about-config.md` after implementation

## Plan

1. Remove the `links` object from `app_config.json` and from the typed `AppConfig` model.
2. Move Author, Email, and License into the config's `details` object.
3. Render all three through the existing dynamic details list.
4. Keep special email behavior by making the detail whose label is `Email`
   (case-insensitive) open its value through a `mailto:` link when tapped.
5. Add `Made with ❤ from India` at the bottom center of the About screen.
6. Update the architecture document to describe the new config shape.
7. Update focused unit and widget tests. Test config parsing, dynamic details, the footer,
   and the email tile's tap behavior.
8. Run Dart formatting, focused tests, and static analysis.
9. Write the required change log and set this plan status to `completed` when all checks
   pass. If work cannot be completed, use the matching workflow status instead.
