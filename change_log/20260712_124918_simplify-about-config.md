# Simplify About config

Implemented the approved plan in
`plans/20260712_124700_simplify-about-config.md`.

## Changes

- Removed the unused `links` section from `assets/config/app_config.json` and the
  `AppConfig` model.
- Moved Author, Email, and License into the dynamic `details` object.
- Kept `mailto:` behavior for a detail with the label `Email`, matched without regard to
  letter case.
- Added the centered `Made with ❤ from India` footer to the About screen.
- Updated the architecture document for the new config shape.
- Updated config, About widget, and settings test fixtures for the simplified model.
- Added checks for the email tile action and centered footer.

## Verification

- `dart format` completed for all changed Dart files.
- Config and About tests passed: 7 tests.
- Targeted `dart analyze` completed with no issues.
- PowerShell JSON parsing confirmed the config is valid, the legacy top-level fields and
  `links` are absent, and the moved detail values are present.

The existing `settings_screen_test.dart` could not compile because
`settings_screen.dart` references seven localization getters that are missing from the
current localization API (`appearCardSubtitle`, `editorCardSubtitle`,
`filesTabsCardSubtitle`, `speechCardSubtitle`, `syncCardSubtitle`,
`securityCardSubtitle`, and `aboutCardSubtitle`). Running `flutter gen-l10n` did not fix
that existing mismatch. It is outside this About config change.
