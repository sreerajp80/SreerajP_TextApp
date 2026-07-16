# Change log: fix copy / cut / paste in the editor

Implements plan
`plans/20260714_121649_editor-copy-paste-toolbar.md`.

## Problem

The user could not copy, cut, or paste text in an open file. The `re_editor`
[CodeEditor] only shows the Copy / Cut / Paste popup when it is given a
`toolbarController`. None of the app's five editor surfaces passed one, so on a
touch device the selection popup never appeared and there was no way to trigger
those actions.

## What changed

- **New file** `lib/core/editor/editor_selection_toolbar.dart`:
  `createEditorSelectionToolbar(bool Function() isReadOnly)` builds a shared
  `SelectionToolbarController` (a `MobileSelectionToolbarController`) whose menu
  is Flutter's standard `AdaptiveTextSelectionToolbar`. It shows:
  - **Cut** and **Copy** when text is selected (Cut only when not read-only),
  - **Paste** when not read-only,
  - **Select all** always.

  `isReadOnly` is read each time the menu opens, so Cut/Paste stay hidden in
  view (read-only) mode while Copy and Select-all still work.

- **Wired the controller into all five editor surfaces** by passing
  `toolbarController:` to each `CodeEditor`. Each surface was changed from a
  `ConsumerWidget` to a `ConsumerStatefulWidget` so the controller instance
  stays stable for the life of the editor (the controller holds the live
  overlay entry that `hide()` removes; a fresh instance per rebuild would leak
  the popup). Files:
  - `lib/formats/txt/txt_editor_surface.dart`
  - `lib/formats/json/json_editor_surface.dart`
  - `lib/formats/xml/xml_editor_surface.dart`
  - `lib/formats/markdown/md_editor_surface.dart`
  - `lib/formats/csv/csv_raw_view.dart`

The public constructor of each surface is unchanged, so no call sites needed
updating.

## Notes

- No new dependency: `AdaptiveTextSelectionToolbar` ships with Flutter and
  `MobileSelectionToolbarController` is already in the bundled `re_editor`.
- No security-rule impact: this uses the normal system clipboard and does not
  touch P2P, crypto, storage, or opened-file parsing. FLAG_SECURE is unrelated
  (it blocks screenshots, not the clipboard).
- Button labels come from the platform via `ContextMenuButtonType`, so they are
  localized by the OS automatically.

## Verification

- `flutter analyze` on all six changed/added files: no issues.
- Manual check recommended before release: open a TXT file, long-press to
  select, and confirm Copy / Cut / Paste / Select all appear and work in both
  edit and read-only modes; spot-check JSON / XML / MD / CSV raw view.
