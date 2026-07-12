# Create a new supported document

Implemented plan: `plans/20260712_131042_create-new-document.md`.

## What changed

- Added a localized **New document** action to Home and kept **Open a file**
  available in the Home app bar and empty state.
- Added a scrollable Material 3 picker for TXT, Markdown, CSV, JSON, and XML.
- Added fixed UTF-8 starter definitions with the right suggested extensions and
  MIME types. JSON starts as `{}` and XML starts with a UTF-8 declaration and a
  valid `root` element.
- Reused the existing Android Storage Access Framework create-document method.
  No storage permission, in-app file browser, dependency, or native Android
  change was added.
- Exposed the existing shared open-file coordinator so a created file follows
  the same fingerprint, Recents, tab-cap, read-only-setting, error, and editor
  navigation path as a picked file.
- Extended the fake SAF service and added tests for all starter definitions,
  successful creation, picker cancellation, SAF errors, the five-format UI, and
  the existing accessibility checks.
- Added and generated the new English localization strings.

## Checks

- `flutter gen-l10n` — passed.
- `dart format` on changed Dart files — passed.
- Focused create-document, Home, and accessibility tests — 12 passed.
- `flutter analyze` — passed with no issues.
- Full `flutter test` — 543 tests passed and one unrelated existing test failed:
  `test/shell/theme_switch_widget_test.dart` looks for `Dark` immediately after
  opening Settings, but the current Settings UI requires opening the Appearance
  card first. The failure also reproduces when that test runs alone. This feature
  did not change Settings or that test.

## Manual check still owed

Create each of the five formats on a real Android device with a real document
provider. Confirm the system picker controls name/location, the correct editor
opens, and the new file appears in Recents.
