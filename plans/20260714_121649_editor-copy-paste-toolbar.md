# Fix: cannot copy / cut / paste text in the editor

**Status:** completed

## What is the issue

The user cannot copy, cut, or paste content from a file that is open in the editor.

The editor is built on the bundled `re_editor` package
(`third_party/re_editor`). On Android (touch), when the user long-presses to
select text, `re_editor` tries to show the Copy / Cut / Paste popup by calling
the `toolbarController` that was passed to the `CodeEditor` widget. See
`third_party/re_editor/lib/src/code_editor.dart:386-421` — `onShowToolbar`
calls `widget.toolbarController?.show(...)`.

None of the app's editor surfaces pass a `toolbarController`. So the popup is
never shown, and on a touch-only device there is no way to trigger copy / cut /
paste. The clipboard logic inside `re_editor` itself is fine
(`third_party/re_editor/lib/src/_code_line.dart:933-960`); it just never gets
called because the menu never appears.

Confirmed: all 5 `CodeEditor` call sites omit `toolbarController`:
- `lib/formats/txt/txt_editor_surface.dart:38`
- `lib/formats/json/json_editor_surface.dart:38`
- `lib/formats/xml/xml_editor_surface.dart:38`
- `lib/formats/markdown/md_editor_surface.dart:38`
- `lib/formats/csv/csv_raw_view.dart:36`

## The plan for the fix

1. Add a new small shared file, `lib/core/editor/editor_selection_toolbar.dart`,
   that builds a reusable `SelectionToolbarController`:
   - Use `re_editor`'s `MobileSelectionToolbarController(builder: ...)`.
   - Inside the builder, return Flutter's standard
     `AdaptiveTextSelectionToolbar` (Material 3, matches the rest of the app).
   - Build the button list from the controller state:
     - **Cut** and **Copy** only when there is a non-empty selection AND the
       editor is not read-only.
     - **Paste** only when the editor is not read-only (and, where cheap to
       check, when the clipboard has text).
     - **Select all** always.
   - Each button calls the matching `CodeLineEditingController` method
     (`cut()`, `copy()`, `paste()`, `selectAll()`), then dismisses the toolbar.
   - Expose it as a simple factory/helper so every surface uses the same menu.

2. Wire the controller into all 5 editor surfaces by passing
   `toolbarController:` to each `CodeEditor`:
   - `lib/formats/txt/txt_editor_surface.dart`
   - `lib/formats/json/json_editor_surface.dart`
   - `lib/formats/xml/xml_editor_surface.dart`
   - `lib/formats/markdown/md_editor_surface.dart`
   - `lib/formats/csv/csv_raw_view.dart`

   Each surface knows its own `readOnly` state, so Cut/Paste are hidden in
   read-only (view) mode; Copy and Select-all still work there.

3. Keep the controller lifecycle correct: create it once per surface (e.g. a
   `StatefulWidget` field or a cached final) so it is not rebuilt on every
   frame, and dispose if the API needs it.

4. Verify by building and, if possible, running the app: open a TXT file,
   long-press to select, and confirm Copy / Cut / Paste / Select all appear and
   work in both edit and read-only modes. Repeat a quick check on JSON/XML/MD/
   CSV raw view.

## Files to be changed

- `lib/core/editor/editor_selection_toolbar.dart` — **new** shared toolbar
  controller.
- `lib/formats/txt/txt_editor_surface.dart` — pass `toolbarController`.
- `lib/formats/json/json_editor_surface.dart` — pass `toolbarController`.
- `lib/formats/xml/xml_editor_surface.dart` — pass `toolbarController`.
- `lib/formats/markdown/md_editor_surface.dart` — pass `toolbarController`.
- `lib/formats/csv/csv_raw_view.dart` — pass `toolbarController`.

## Notes / risks

- No new dependency: `AdaptiveTextSelectionToolbar` is in Flutter, and
  `MobileSelectionToolbarController` is already in the bundled `re_editor`.
- No security-rule impact: copy/paste uses the normal system clipboard; this
  does not touch P2P, crypto, storage, or opened-file parsing. FLAG_SECURE is
  unrelated (it blocks screenshots, not the clipboard).
- Labels can use existing localized strings if present; otherwise use the
  platform default labels from `AdaptiveTextSelectionToolbar.buttonItems`
  helpers where possible to stay consistent with the OS.
