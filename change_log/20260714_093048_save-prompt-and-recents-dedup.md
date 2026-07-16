# Change log: Direct Save (no per-save prompt) + one Recent entry per file

**Implements plan:** [plans/20260714_093048_save-prompt-and-recents-dedup.md](../plans/20260714_093048_save-prompt-and-recents-dedup.md)

**Date:** 2026-07-14

## Why

Two problems the user reported:

1. **Save asked for the encoding and line ending on every save.** The toolbar Save
   button opened a bottom sheet with encoding + line-ending dropdowns before every save,
   even though the defaults just preserve what the file was opened with.
2. **Each edited file showed up in Recent as a new file.** Recents are keyed by the file's
   content fingerprint (a hash of its bytes). Editing and saving changes the bytes, so the
   fingerprint changes, and re-opening the file added a second Recent row for the same file.

## What changed

### 1. Save is now a direct save; the options moved to "Save as…"

For all five formats (TXT, Markdown, JSON, CSV, XML):

- The toolbar **Save** button now saves directly, preserving the file's encoding and line
  ending (and, for JSON/XML, indentation), with the existing read-only → "Save as a copy"
  fallback and the same result snackbar. It no longer opens the options sheet.
- A new **"Save as…"** item was added to each format's overflow menu. It opens the same
  options sheet as before, so the user can still change the encoding, line ending
  (and indentation / reformat where they apply) and choose *Save* or *Save as a copy*.
- Each `*_save_options_sheet.dart` gained a `save<Format>Direct(context, session)` helper
  and a shared `_reportSaveResult(...)` function, so the direct save and the sheet show
  identical outcome messages.
- Added a new localized string `actionSaveAs` ("Save as…") in English and Malayalam and
  regenerated the localization Dart files.

Files:
- `lib/formats/txt/txt_toolbar.dart`, `lib/formats/txt/txt_save_options_sheet.dart`
- `lib/formats/markdown/md_toolbar.dart`, `lib/formats/markdown/md_save_options_sheet.dart`
- `lib/formats/json/json_toolbar.dart`, `lib/formats/json/json_save_options_sheet.dart`
- `lib/formats/csv/csv_toolbar.dart`, `lib/formats/csv/csv_save_options_sheet.dart`
- `lib/formats/xml/xml_toolbar.dart`, `lib/formats/xml/xml_save_options_sheet.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, and generated `lib/l10n/app_localizations*.dart`

### 2. One Recent entry per file location

- Added `RecentsRepository.removeOtherUris(uri, keepFingerprint)`
  (`DELETE FROM recents WHERE uri = ? AND fingerprint != ?`) in
  `lib/core/storage/recents_repository.dart`.
- `RecentsController.recordOpen` now calls `removeOtherUris(file.uri, fingerprint)` before
  the upsert, so opening a file first clears any older rows that point at the same location
  (their content, and so their fingerprint, changed after an edit) and keeps exactly one
  Recent row per file. No database schema change or migration; content fingerprints stay
  the primary key, so bookmarks, drafts, and reading positions are unaffected.

Files:
- `lib/core/storage/recents_repository.dart`
- `lib/shell/home/recents_controller.dart`

## Tests

- Added a `removeOtherUris` test to `test/core/storage/repositories_test.dart` (a same-URI
  row with a different fingerprint is removed; the kept row and unrelated files stay).
- `flutter analyze` on `lib` and `test`: no issues.
- `flutter test`: all 556 tests pass.

## Note

Changing the line ending on a normal save now lives under **"Save as…"** rather than being
asked on every save. This was called out in the plan and approved.
