# Added Split array help topic to Settings

## Plan

Implemented
[`plans/20260712_125834_split-array-help-card.md`](../plans/20260712_125834_split-array-help-card.md).

## What changed

- Added a **Help** card to the main Settings screen.
- Added a Help detail page with a nested **Split array** card.
- Explained that Split array works on a top-level JSON array, asks for the
  number of items per part, creates numbered JSON files, may create a smaller
  final part, asks where to save each file, and does not change the original.
- Added localized English strings for the Help card and Split array topic.
- Regenerated the Dart localization files.
- Updated the Settings screen widget tests for eight cards and added coverage
  for the Split array help topic.

## Checks run

- `dart format` on the changed Dart files — passed.
- `flutter gen-l10n` — passed.
- `flutter test test/shell/settings/settings_screen_test.dart` — all 6 tests
  passed.
- `flutter analyze` on the changed Settings and test files — no issues found.

## Note

Git diff checks could not run because the existing `.git` folder is not
recognized as a valid Git repository in this workspace.
