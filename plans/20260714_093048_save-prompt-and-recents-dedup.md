# Fix: Save should not ask encoding/line-ending every time; edited files should not duplicate in Recent

**Status:** completed

## What the issues are

Two separate problems reported by the user:

### Issue 1 — Save asks for encoding and line ending every time
When the user opens an existing file, edits it, and taps **Save**, the app shows a
bottom sheet asking for the **encoding** and **line ending** before saving. This happens
on *every* save, which is annoying. The defaults already just preserve what the file was
opened with, so a normal save should not need to ask anything.

Cause: the Save button in every format toolbar calls the "save options" bottom sheet,
which always shows the two dropdowns and then saves.
- [lib/formats/txt/txt_toolbar.dart:85](../lib/formats/txt/txt_toolbar.dart#L85) → `showSaveOptionsSheet`
- [lib/formats/markdown/md_toolbar.dart:114](../lib/formats/markdown/md_toolbar.dart#L114) → `showMdSaveOptionsSheet`
- [lib/formats/json/json_toolbar.dart:150](../lib/formats/json/json_toolbar.dart#L150) → `showJsonSaveOptionsSheet`
- [lib/formats/csv/csv_toolbar.dart:127](../lib/formats/csv/csv_toolbar.dart#L127) → `showCsvSaveOptionsSheet`
- [lib/formats/xml/xml_toolbar.dart:137](../lib/formats/xml/xml_toolbar.dart#L137) → `showXmlSaveOptionsSheet`

### Issue 2 — Each edited file shows in Recent as a new file
Recent files are stored keyed by the file's **content fingerprint** (a SHA-256 hash of the
file bytes), not by the file location (URI). See
[lib/shell/open_file_action.dart:74](../lib/shell/open_file_action.dart#L74) and
[lib/core/storage/app_database.dart:61](../lib/core/storage/app_database.dart#L61)
(`fingerprint` is the primary key of the `recents` table).

When the user edits and saves a file, its bytes change, so its fingerprint changes. The
next time the same file is opened, `recordOpen` inserts a **new** row with the new
fingerprint, and the old row (old content) stays behind. Result: the same file location
appears multiple times in Recent. Bookmarks/drafts/reading-position are *meant* to be
keyed by content fingerprint (architecture §11), but the **Recent list** is really a list
of file *locations* and should show one entry per file.

## The plan for the fix

### Fix 1 — Direct save; move the options to a separate "Save as…" action

1. **Save button = direct save (no sheet).** Change each format's toolbar Save button to
   call a new small helper that just runs `session.save()` (with the existing read-only →
   `saveAsCopy` fallback) and shows the same result snackbar. The encoding and line ending
   keep their current defaults, which preserve the file's original values (CLAUDE.md §3.5).

2. **Keep the encoding/line-ending picker reachable via "Save as…".** Add a new overflow
   menu item **"Save as…"** to each format toolbar that opens the *existing* save-options
   sheet (the one that lets the user pick encoding + line ending and choose
   *Save* / *Save as a copy*). Nothing about that sheet's behaviour changes; it just is no
   longer the default path for a plain Save.

   This keeps every capability (change encoding on save, change line ending on save, save a
   copy) but stops the prompt from appearing on an ordinary save. (For TXT the encoding can
   also still be changed from the existing **Encoding** menu item.)

3. Implementation detail: the snackbar-reporting logic currently lives inside
   `showSaveOptionsSheet`. Extract the "run save + report outcome" part into a reusable
   function per sheet file (e.g. `saveTxtDirect(context, session)`), and have both the
   Save button and the sheet's own buttons use it, so the outcome messages stay identical.

### Fix 2 — One Recent entry per file location

1. Add a repository method to remove stale rows that point at the same file location:
   `Future<void> removeOtherUris(String uri, String keepFingerprint)` in
   [lib/core/storage/recents_repository.dart](../lib/core/storage/recents_repository.dart),
   running `DELETE FROM recents WHERE uri = ? AND fingerprint != ?`.

2. In `RecentsController.recordOpen`
   ([lib/shell/home/recents_controller.dart:54](../lib/shell/home/recents_controller.dart#L54)),
   call `removeOtherUris(file.uri, fingerprint)` right before the `upsert`, so opening a
   file first clears any older rows for that same location, then records the current one.
   The result: exactly one Recent row per file, always reflecting the latest open.

   No database schema change or migration is needed. Content fingerprints stay the primary
   key, so bookmarks, drafts, and reading positions are unaffected.

## Files to change

- `lib/formats/txt/txt_toolbar.dart` — Save button → direct save; add "Save as…" menu item + handler.
- `lib/formats/txt/txt_save_options_sheet.dart` — extract a `saveTxtDirect(...)` helper; keep the sheet.
- `lib/formats/markdown/md_toolbar.dart` — same as txt.
- `lib/formats/markdown/md_save_options_sheet.dart` — same as txt.
- `lib/formats/json/json_toolbar.dart` — same as txt.
- `lib/formats/json/json_save_options_sheet.dart` — same as txt.
- `lib/formats/csv/csv_toolbar.dart` — same as txt.
- `lib/formats/csv/csv_save_options_sheet.dart` — same as txt.
- `lib/formats/xml/xml_toolbar.dart` — same as txt.
- `lib/formats/xml/xml_save_options_sheet.dart` — same as txt.
- `lib/l10n/app_localizations*.dart` (+ the `.arb` source) — add one new string, e.g.
  `actionSaveAs` ("Save as…"), in English and Malayalam.
- `lib/core/storage/recents_repository.dart` — add `removeOtherUris`.
- `lib/shell/home/recents_controller.dart` — call `removeOtherUris` in `recordOpen`.

## Tests

- Update/extend `test/core/storage/repositories_test.dart` to cover `removeOtherUris`
  (same URI with a different fingerprint is removed; the kept fingerprint stays).
- Add a recents-dedup test: recording an open for a URI that already has an older
  fingerprint leaves exactly one row for that URI.
- Existing save-options tests: adjust so the toolbar Save path no longer expects the sheet,
  and the new "Save as…" path still opens it. Keep the sheet's own save/save-as-copy tests.
- Run `flutter analyze` and `flutter test`.

## Notes / open choices

- The Save button becoming a direct save means the user loses the *inline* chance to change
  line ending on a normal save. That choice now lives under **"Save as…"**. If you would
  rather keep a single Save button that always shows the sheet but *remembers* the last
  choice, tell me and I will adjust the plan.
