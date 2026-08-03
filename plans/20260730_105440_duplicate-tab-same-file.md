# Fix: same file opens in two tabs

**Status:** completed

## The issue

When the user opens a file that is already open, the app sometimes adds a **second
tab for the same file** instead of moving to the tab that is already open.

Why it happens:

- `TabsController.openFile` decides "already open?" by comparing the **content
  fingerprint** only ([tabs_controller.dart:166](../lib/shell/tabs/tabs_controller.dart#L166)).
- The fingerprint is a hash of the file's **bytes**
  ([content_fingerprint.dart](../lib/core/fingerprint/content_fingerprint.dart)).
- A tab keeps the fingerprint it had when it was opened. It is never updated,
  because drafts, saved reading positions, and bookmarks are keyed to that value.
- So as soon as the file content changes, the tab's stored fingerprint is stale.
  Re-opening the same file reads the **new** bytes, gets a **new** fingerprint, finds
  no match, and adds a new tab.

Easiest way to see it: open a file, edit it, save it, go Home, open the same file
again → two tabs for one file.

There is a second, related bug in the same check: two **different** files with
**identical** bytes (for example two empty files) share one fingerprint, so opening
the second one silently focuses the first — the wrong file is shown.

## The fix

Match an already-open tab by **file location (SAF URI) first**, and keep a
narrow content match as a fallback.

New rule inside `openFile`:

1. If a tab has the **same `uri`** → focus that tab. (Fixes the duplicate.)
2. Otherwise, if a tab has the **same fingerprint *and* the same `displayName`** →
   focus that tab. (Keeps the old good case: the same file reached through a second
   URI. The name check stops two different empty files from collapsing into one tab.)
3. Otherwise → open a new tab, as today.

Nothing else changes:

- The tab's `fingerprint` field is still set once, at open time, so drafts, reading
  positions, and bookmarks keep working exactly as before.
- Tab ids stay unique, so the per-format session managers (keyed by tab id) are
  unaffected.

Known limit left as-is (not part of this fix): if the file changed on disk after the
tab was opened, focusing the existing tab shows the already-loaded content. Reloading
changed files is separate work and would risk unsaved edits.

## Files to change

| File | Change |
| --- | --- |
| [lib/shell/tabs/tabs_controller.dart](../lib/shell/tabs/tabs_controller.dart) | Replace the fingerprint-only "already open" check with the URI-first rule above; update the doc comment. |
| [test/shell/tabs_controller_test.dart](../test/shell/tabs_controller_test.dart) | Add tests: (a) same URI + **changed** fingerprint focuses the existing tab, no duplicate; (b) same fingerprint + different name opens a separate tab; (c) same fingerprint + same name but different URI still focuses the existing tab. Keep the existing re-open test passing. |

## How it will be checked

- `flutter test test/shell/tabs_controller_test.dart` and then the full `flutter test`
  suite, to be sure no other tab test depended on fingerprint-only matching.
