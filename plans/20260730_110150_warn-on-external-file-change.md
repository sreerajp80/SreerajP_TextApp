# Warn when the open file changed on disk, with a Reload option

**Status:** completed

## The issue

A tab holds the content it loaded when it was opened. If the file changes on disk
afterwards — another app edits it, the user syncs it, or a second copy of the app writes
it — the tab keeps showing the **old** content and says nothing. The user has no way to
know, and no way to load the fresh content without closing and re-opening the tab.

There is no external-change detection anywhere today. Every session
(`TxtDocumentSession`, `MdDocumentSession`, `JsonDocumentSession`,
`CsvDocumentSession`, `XmlDocumentSession`) reads the bytes once in `load()` and never
looks at the file again.

## The fix

Detect the change, **warn** with a banner above the document, and offer **Reload**.

### 1. How a change is detected

At load time the session remembers the file's **last-modified time** from SAF
(`SafService.modifiedTime`, which already exists). Later, it asks SAF again: a
different value means the file changed on disk.

- If the provider does not report a modified time (`null`), detection is **skipped**
  — no banner. A missing timestamp must never produce a false warning.
- After a successful save, the baseline is re-captured, so the app never warns about
  its **own** write.
- Only the timestamp is compared. No re-reading of the bytes, so the check stays cheap
  even for a large file.

### 2. When the check runs

- When the app comes back to the **foreground** (the common case: the user edits the
  file in another app and returns).
- When a tab is **focused** — switching to it, or re-opening the same file from Home
  (this is the case left open by the previous fix,
  [plans/20260730_105440_duplicate-tab-same-file.md](20260730_105440_duplicate-tab-same-file.md)).

The check runs for the **active tab only**, so a workspace of open tabs does not fire a
burst of platform calls.

### 3. What the user sees

A banner above the document (styled like the existing `ReadOnlyBanner`):

> ⚠ This file changed on disk. **Reload**  ✕

- **Reload** — loads the fresh content from disk.
  - If the tab has **unsaved edits**, a confirm dialog comes first: reloading throws
    those edits away, so the user must agree (CLAUDE.md §3.6 — never lose edits
    silently). The dialog offers Cancel / Reload and discard.
  - After reload the tab is clean, undo history is cleared (the reload itself is not
    undoable), and the crash-recovery draft is discarded, so a stale draft is not
    offered later.
  - A failed read leaves the tab exactly as it was and shows a snackbar.
- **✕** — dismisses the banner and accepts the current content. The baseline is
  re-captured so the same change is not reported again; a *later* change warns again.

### 4. Not in this change (worth its own plan)

**Saving over a file that changed on disk.** Right now the save would silently replace
the other app's changes. Warning before that overwrite touches `AtomicSaver`, the save
result type, and all five format save paths, so it belongs in its own plan. This change
only warns and offers reload. I recommend doing it next.

## Files to change

### New

| File | What it holds |
| --- | --- |
| `lib/core/editor/external_change.dart` | `ExternalChangeMixin` on `ChangeNotifier`: remembers the disk timestamp, `captureDiskBaseline()`, `checkForExternalChange()`, `externalChangeDetected`, `dismissExternalChange()`, and an abstract `reloadFromDisk()` each format implements. Also the small `ReloadableDocument` interface the shell talks to, so the banner does not need to know the format. |
| `lib/shell/tabs/file_changed_banner.dart` | The banner widget, its Reload / dismiss actions, and the "discard unsaved edits?" confirm dialog. |
| `test/core/editor/external_change_test.dart` | Detection logic: changed timestamp flags a change; same timestamp does not; a `null` timestamp never flags; dismiss and reload re-capture the baseline. |
| `test/shell/file_changed_banner_widget_test.dart` | Banner shows when a change is flagged, Reload on a clean tab reloads straight away, Reload on a dirty tab asks first, dismiss hides the banner. |

### Changed

| File | Change |
| --- | --- |
| [lib/formats/txt/txt_document_session.dart](../lib/formats/txt/txt_document_session.dart) | Use the mixin; capture the baseline in `load()` and after a successful save; implement `reloadFromDisk()` (re-read, decode, replace the editor text in place, reset the saved baseline, clear history, drop the draft). |
| [lib/formats/markdown/md_document_session.dart](../lib/formats/markdown/md_document_session.dart) | Same, plus refresh the preview/outline from the new text. |
| [lib/formats/json/json_document_session.dart](../lib/formats/json/json_document_session.dart) | Same, plus re-parse the tree and stats. |
| [lib/formats/xml/xml_document_session.dart](../lib/formats/xml/xml_document_session.dart) | Same, plus re-parse the tree. |
| [lib/formats/csv/csv_document_session.dart](../lib/formats/csv/csv_document_session.dart) | Same, plus re-detect the dialect, re-parse the table, clear the table undo stack, and refresh metadata rows. |
| [lib/shell/tabs/tabs_workspace.dart](../lib/shell/tabs/tabs_workspace.dart) | Resolve the active tab's session as a `ReloadableDocument` (same pattern as the existing `_saverFor`), run the check on foreground + on focus, and show the banner above the document body. |
| [lib/l10n/app_en.arb](../lib/l10n/app_en.arb), [lib/l10n/app_ml.arb](../lib/l10n/app_ml.arb) | New strings: banner text, Reload, Dismiss, confirm-dialog title/body/buttons, reload-failed message. Then `flutter gen-l10n` to refresh the generated files. |
| [test/support/test_support.dart](../test/support/test_support.dart) | `FakeSafService`: a settable modified time per URI and mutable contents, so a test can simulate "the file changed on disk". |
| [test/formats/txt/txt_document_session_test.dart](../test/formats/txt/txt_document_session_test.dart) | Session-level tests: change on disk is detected; reload swaps in the new text and clears the dirty flag; a save does not warn about the app's own write. |

## Risks and how they are handled

- **False warnings** would be worse than no warning. Handled by skipping detection when
  the timestamp is unknown, and by re-capturing the baseline after every save, reload,
  and dismiss.
- **Losing edits on reload.** Reload always confirms first when the tab is dirty, and a
  failed read changes nothing.
- **Five sessions to touch.** The shared logic lives in one mixin; each session only
  adds its own small `reloadFromDisk()` body.

## How it will be checked

- `flutter test` (full suite) plus the new tests above.
- `flutter analyze`.
- Manual check on a device: open a file, change it from another app, return to the app →
  banner appears → Reload shows the new content; repeat with unsaved edits to see the
  confirm dialog.
