import 'package:flutter/material.dart';
import 'package:re_editor/re_editor.dart';

import 'package:text_data/core/editor/column_selection_sheet.dart';
import 'package:text_data/l10n/app_localizations.dart';

/// Builds the Copy / Cut / Paste / Select-all popup for the `re_editor`
/// [CodeEditor]. Without a [SelectionToolbarController] the editor shows no
/// selection popup on touch devices, so the user cannot copy, cut, or paste.
///
/// Pass the result as `toolbarController:` to a [CodeEditor]. Keep the returned
/// instance stable for the life of the editor (create it once in `initState`,
/// not in `build`), because the controller holds the live overlay entry that
/// `hide()` removes.
///
/// [isReadOnly] is read each time the menu is shown, so Cut, Paste, and Column
/// edits are hidden while the editor is in read-only (view) mode; Copy and
/// Select-all still work.
///
/// [onSendSelection] is optional. When a format passes it, the popup gains a
/// "Send selection by QR" entry for the selected text (optical air-gap
/// transfer). It is a callback rather than a direct call so this file stays out
/// of navigation — the caller decides what sending means.
///
/// [onColumnEdit] is optional. When not provided, it defaults to opening
/// [ColumnSelectionSheet].
SelectionToolbarController createEditorSelectionToolbar(
  bool Function() isReadOnly, {
  void Function(String selectedText)? onSendSelection,
  void Function(BuildContext context, CodeLineEditingController controller)?
  onColumnEdit,
}) {
  return MobileSelectionToolbarController(
    builder:
        ({
          required BuildContext context,
          required TextSelectionToolbarAnchors anchors,
          required CodeLineEditingController controller,
          required VoidCallback onDismiss,
          required VoidCallback onRefresh,
        }) {
          final bool readOnly = isReadOnly();
          final bool hasSelection =
              !controller.selection.isCollapsed &&
              controller.selectedText.isNotEmpty;

          final items = <ContextMenuButtonItem>[];

          if (hasSelection && !readOnly) {
            items.add(
              ContextMenuButtonItem(
                type: ContextMenuButtonType.cut,
                onPressed: () {
                  controller.cut();
                  onDismiss();
                },
              ),
            );
          }
          if (hasSelection) {
            items.add(
              ContextMenuButtonItem(
                type: ContextMenuButtonType.copy,
                onPressed: () {
                  controller.copy();
                  onDismiss();
                },
              ),
            );
          }
          if (!readOnly) {
            items.add(
              ContextMenuButtonItem(
                type: ContextMenuButtonType.paste,
                onPressed: () {
                  controller.paste();
                  onDismiss();
                },
              ),
            );
          }
          items.add(
            ContextMenuButtonItem(
              type: ContextMenuButtonType.selectAll,
              onPressed: () {
                controller.selectAll();
                onRefresh();
              },
            ),
          );
          // Column & multi-cursor edit (bulk multi-line tools)
          if (!readOnly) {
            items.add(
              ContextMenuButtonItem(
                label: AppLocalizations.of(context).columnSelectionAction,
                onPressed: () {
                  onDismiss();
                  if (onColumnEdit != null) {
                    onColumnEdit(context, controller);
                  } else {
                    ColumnSelectionSheet.show(
                      context: context,
                      controller: controller,
                    );
                  }
                },
              ),
            );
          }
          // Sending a selection works in read-only mode too: it copies text
          // out, it never changes the document.
          if (hasSelection && onSendSelection != null) {
            final selected = controller.selectedText;
            items.add(
              ContextMenuButtonItem(
                label: AppLocalizations.of(context).airqrSendSelectionByQr,
                onPressed: () {
                  onDismiss();
                  onSendSelection(selected);
                },
              ),
            );
          }

          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: anchors,
            buttonItems: items,
          );
        },
  );
}
