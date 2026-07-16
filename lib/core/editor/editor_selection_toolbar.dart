import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

/// Builds the Copy / Cut / Paste / Select-all popup for the `re_editor`
/// [CodeEditor]. Without a [SelectionToolbarController] the editor shows no
/// selection popup on touch devices, so the user cannot copy, cut, or paste.
///
/// Pass the result as `toolbarController:` to a [CodeEditor]. Keep the returned
/// instance stable for the life of the editor (create it once in `initState`,
/// not in `build`), because the controller holds the live overlay entry that
/// `hide()` removes.
///
/// [isReadOnly] is read each time the menu is shown, so Cut and Paste are hidden
/// while the editor is in read-only (view) mode; Copy and Select-all still work.
SelectionToolbarController createEditorSelectionToolbar(
  bool Function() isReadOnly,
) {
  return MobileSelectionToolbarController(
    builder: ({
      required BuildContext context,
      required TextSelectionToolbarAnchors anchors,
      required CodeLineEditingController controller,
      required VoidCallback onDismiss,
      required VoidCallback onRefresh,
    }) {
      final bool readOnly = isReadOnly();
      final bool hasSelection =
          !controller.selection.isCollapsed && controller.selectedText.isNotEmpty;

      final items = <ContextMenuButtonItem>[];

      if (hasSelection && !readOnly) {
        items.add(ContextMenuButtonItem(
          type: ContextMenuButtonType.cut,
          onPressed: () {
            controller.cut();
            onDismiss();
          },
        ));
      }
      if (hasSelection) {
        items.add(ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () {
            controller.copy();
            onDismiss();
          },
        ));
      }
      if (!readOnly) {
        items.add(ContextMenuButtonItem(
          type: ContextMenuButtonType.paste,
          onPressed: () {
            controller.paste();
            onDismiss();
          },
        ));
      }
      items.add(ContextMenuButtonItem(
        type: ContextMenuButtonType.selectAll,
        onPressed: () {
          controller.selectAll();
          onRefresh();
        },
      ));

      return AdaptiveTextSelectionToolbar.buttonItems(
        anchors: anchors,
        buttonItems: items,
      );
    },
  );
}
