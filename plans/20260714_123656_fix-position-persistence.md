# Fix file position persistence (restore does not scroll the view)

**Status:** completed

## The issue

The app is meant to return you to the last place you were reading inside a file.
It saves the position, but when you reopen the file the view stays at the top.

Root cause: the restore runs too early.

- Each text session (TXT, MD, JSON, XML) calls `_restorePosition()` inside
  `load()`, before the `CodeEditor` widget is built.
- Restoring the scroll needs the editor's render object. At load time that render
  is not attached yet, so `code.makePositionCenterIfInvisible(...)`
  (`_render?.…`) does nothing.
- JSON/XML/MD restore only set `code.selection` and never ask to scroll at all.
- The editor mounts with `autofocus: false`, so it does not reveal the saved
  caret on its own.

Result: the caret line is set, but the screen does not move to it.

Secondary points (in scope only where noted):
- The position is written **only in `dispose()`**. If the app is killed without
  the tab being disposed, the position is never saved. (In scope — add a
  lifecycle-based save.)
- CSV writes its sort column to `_positionKey` but nothing reads it back.
  (Out of scope for the scroll fix; noted only.)

## Files to change

Text sessions (move restore to after the editor mounts; restore once):
- `lib/formats/txt/txt_document_session.dart`
- `lib/formats/markdown/md_document_session.dart`
- `lib/formats/json/json_document_session.dart`
- `lib/formats/xml/xml_document_session.dart`

Editor surfaces (trigger the restore after the first frame):
- `lib/formats/txt/txt_editor_surface.dart`
- the matching surface widgets for MD, JSON, XML (the ones that build `CodeEditor`)

Tests:
- `test/` — add/extend session tests for save + restore of the position.

## The fix

1. In each text session:
   - Remove the `_restorePosition()` call from `load()`.
   - Add a `bool _positionRestored = false;` guard.
   - Add a public `restorePositionIntoView()` that runs once: read the saved
     position, clamp it, set `code.selection`, then call
     `code.makePositionCenterIfInvisible(selection.base)` so the view scrolls.
     re_editor's own post-frame retry then handles any remaining layout timing.
   - For JSON/XML/MD, add the `makePositionCenterIfInvisible(...)` call they are
     currently missing.

2. In each editor surface `initState`, schedule
   `WidgetsBinding.instance.addPostFrameCallback((_) => session.restorePositionIntoView())`
   so the restore runs after the `CodeEditor` render is attached. The `once`
   guard keeps a later rebuild or tab switch from yanking the user back.

3. Save the position more reliably: also call `persistPosition()` when the app is
   paused/detached (app lifecycle), not just in `dispose()`. Keep the `dispose()`
   call too.

4. Leave CSV's sort-column behaviour as is for now; note the dead read path as a
   follow-up.

## Testing

- Unit test each session: set a caret line, call `persistPosition()`, build a new
  session for the same fingerprint, and confirm `restorePositionIntoView()`
  restores the same line.
- Manual: open a long file, scroll down, close the tab, reopen — the view should
  return to the same place. Repeat after fully restarting the app.
- Confirm a fresh file (no saved position) still opens at the top.
