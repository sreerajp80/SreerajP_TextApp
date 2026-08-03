# Change log: same file no longer opens in two tabs

Implements [plans/20260730_105440_duplicate-tab-same-file.md](../plans/20260730_105440_duplicate-tab-same-file.md).

## What was wrong

`TabsController.openFile` checked "is this file already open?" using the **content
fingerprint** only. A tab keeps the fingerprint it had when it was opened (drafts and
reading positions are keyed to it), so after the file was edited and saved the tab's
fingerprint no longer matched the bytes on disk. Re-opening the same file found no
match and added a **second tab for the same file**.

The same check also collapsed two **different** files with identical bytes (for example
two empty files) into one tab, showing the wrong file.

## What changed

**[lib/shell/tabs/tabs_controller.dart](../lib/shell/tabs/tabs_controller.dart)**

The "already open" check now runs in two steps:

1. Same **SAF URI** → focus that tab. This is the real fix: the file location does not
   change when the content does.
2. Otherwise, same **fingerprint and same display name** → focus that tab. This keeps
   the old good case (the same file reached through a second URI) while stopping two
   different files with identical bytes from sharing a tab.

Nothing else changed. The tab's `fingerprint` field is still set once at open time, so
drafts, reading positions, and bookmarks work exactly as before. Tab ids stay unique,
so the per-format session managers (keyed by tab id) are untouched.

**[test/shell/tabs_controller_test.dart](../test/shell/tabs_controller_test.dart)**

Three new tests:

- re-opening a file whose content changed focuses the existing tab (no duplicate) and
  the tab keeps its original fingerprint;
- two different files with identical content get their own tabs;
- the same file reached through a second URI focuses the same tab.

## Checks run

- `flutter test test/shell/tabs_controller_test.dart` — 13 tests pass.
- `flutter test` — full suite, 567 tests pass.

## Known limit (not changed)

If the file changed on disk after the tab was opened, focusing the existing tab shows
the content already loaded in that tab. Reloading changed files is separate work,
because it must not risk unsaved edits.
