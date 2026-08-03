# Change log: warn when the open file changed on disk, with a Reload option

Implements [plans/20260730_110150_warn-on-external-file-change.md](../plans/20260730_110150_warn-on-external-file-change.md).

## What was wrong

A tab kept the content it loaded when it was opened. If the file changed on disk after
that — another app edited it, or the user synced it — the tab went on showing the **old**
content and said nothing. There was no way to load the fresh content except closing the
tab and opening the file again.

## What changed

### New: shared external-change logic

**[lib/core/editor/external_change.dart](../lib/core/editor/external_change.dart)**

- `ReloadableDocument` — the small interface the shell talks to, so the warning works for
  any format without knowing which one is open.
- `ExternalChangeMixin` — the shared logic. At load time a session remembers the file's
  last-modified time (`SafService.modifiedTime`, which already existed). A later check
  asks for the timestamp again; a different value means another app wrote the file. Only
  the timestamp is compared, so the check is cheap even for a large file.

Two rules keep the warning trustworthy:

- If the provider reports **no** modified time, detection is skipped. A missing timestamp
  never produces a false warning.
- The baseline is re-captured after every **save**, **reload**, and **dismiss**, so the
  app never warns about its own write.

### New: the warning banner

**[lib/shell/tabs/file_changed_banner.dart](../lib/shell/tabs/file_changed_banner.dart)**

A strip above the document, styled like the existing read-only banner: "This file changed
on disk." with **Reload** and a dismiss ✕.

- **Reload** loads the fresh content. If the tab has unsaved edits, a confirm dialog comes
  first (CLAUDE.md §3.6 — never lose edits silently). A failed read leaves the tab exactly
  as it was and shows a snackbar.
- **✕** accepts the current content and hides the warning. The baseline moves forward, so
  the same change is not reported again, but a *later* change warns again.

The check runs when the app returns to the **foreground** and when a tab is **focused**
(switched to, or re-opened from Home — the case left open by the earlier duplicate-tab
fix). Only the active tab is checked, so a full workspace does not fire a burst of
platform calls. The session is resolved after the frame, because the document body creates
its session while building.

### Changed: the five format sessions

[txt](../lib/formats/txt/txt_document_session.dart),
[markdown](../lib/formats/markdown/md_document_session.dart),
[json](../lib/formats/json/json_document_session.dart),
[csv](../lib/formats/csv/csv_document_session.dart),
[xml](../lib/formats/xml/xml_document_session.dart) each now:

- use `ExternalChangeMixin` and capture the baseline in `load()` and after a successful
  save;
- implement `reloadFromDisk()`: re-read, re-decode, replace the content **in place** (the
  editor controller is not rebuilt, so nothing else has to be re-wired), reset the saved
  baseline and dirty flag, clear undo history (the reload itself is not undoable), discard
  the crash-recovery draft (it belonged to content that is gone), and refresh the file
  metadata.

Per-format extras: Markdown re-parses front matter, AST, TOC and stats and re-syncs
heading keys; JSON and XML re-parse their trees; CSV re-detects the dialect, re-parses the
table, clears the table undo stack, drops the row selection, and drops hidden columns and
a sort column that no longer fit the new shape.

### Changed: shell and strings

- [lib/shell/tabs/tabs_workspace.dart](../lib/shell/tabs/tabs_workspace.dart) — shows the
  banner under the toolbar for the active tab.
- [lib/l10n/app_en.arb](../lib/l10n/app_en.arb),
  [lib/l10n/app_ml.arb](../lib/l10n/app_ml.arb) — eight new strings (banner, Reload,
  Dismiss, reload-failed, and the confirm dialog); generated files refreshed.

### Tests

- **New** [test/core/editor/external_change_test.dart](../test/core/editor/external_change_test.dart)
  — 6 tests on the detection logic: quiet while untouched, a newer timestamp warns once,
  a provider with no timestamp never warns, dismiss and reload move the baseline forward.
- **New** [test/shell/file_changed_banner_widget_test.dart](../test/shell/file_changed_banner_widget_test.dart)
  — 5 tests: nothing shows until a change is spotted, reload on a clean tab is immediate,
  reload on a dirty tab asks first (Cancel keeps the edits), dismiss hides the warning, a
  failed reload reports it and keeps the warning.
- [test/formats/txt/txt_document_session_test.dart](../test/formats/txt/txt_document_session_test.dart)
  — 4 session-level tests: a change by another app is detected (content untouched until
  reload), reload swaps in the new text and clears the dirty flag, a failed read changes
  nothing, and a save never warns about itself.
- [test/support/test_support.dart](../test/support/test_support.dart) — `FakeSafService`
  gained per-URI modified times and `changeOnDisk(...)`; its contents map is now
  modifiable. The TXT test's own `RecordingSafService` got the same.

`FileChangedBanner` takes an optional `resolveDocument` callback as a test seam; the app
leaves it null and the banner asks the format session managers.

## Checks run

- `flutter analyze` — no issues.
- `flutter test` — full suite, 582 tests pass (567 before, 15 new).

Still to do manually before release: on a device, open a file, change it from another app,
return to the app and confirm the banner appears and Reload shows the new content.

## Known limit (next plan)

Saving over a file that changed on disk still replaces the other app's changes without
asking. Warning at that point touches `AtomicSaver`, the save-result type, and all five
save paths, so it is its own change.
