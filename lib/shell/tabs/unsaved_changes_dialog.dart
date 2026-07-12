import 'package:flutter/material.dart';

import '../../core/editor/unsaved_changes.dart';
import '../../l10n/app_localizations.dart';

/// Shows the Save / Save as a copy / Discard prompt for a document with unsaved
/// edits and returns the chosen [UnsavedChangesAction] (architecture.md §6,
/// CLAUDE.md §3.6).
///
/// Dismissing the dialog (tap-outside or back) counts as [UnsavedChangesAction.
/// cancel], so the user never loses edits by accident. The read-only case has no
/// "Save"; pass [canOverwrite] `false` to hide it and offer only "Save a copy".
Future<UnsavedChangesAction> showUnsavedChangesDialog(
  BuildContext context, {
  required String fileName,
  bool canOverwrite = true,
}) async {
  final action = await showDialog<UnsavedChangesAction>(
    context: context,
    barrierDismissible: true,
    builder: (context) => _UnsavedChangesDialog(
      fileName: fileName,
      canOverwrite: canOverwrite,
    ),
  );
  return action ?? UnsavedChangesAction.cancel;
}

class _UnsavedChangesDialog extends StatelessWidget {
  final String fileName;
  final bool canOverwrite;

  const _UnsavedChangesDialog({
    required this.fileName,
    required this.canOverwrite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      key: const Key('unsaved-changes-dialog'),
      title: Text(l10n.unsavedTitle),
      content: Text(l10n.unsavedBody(fileName)),
      actions: [
        TextButton(
          key: const Key('unsaved-discard'),
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.discard),
          child: Text(l10n.actionDiscard),
        ),
        TextButton(
          key: const Key('unsaved-cancel'),
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.cancel),
          child: Text(l10n.unsavedKeepEditing),
        ),
        TextButton(
          key: const Key('unsaved-save-copy'),
          onPressed: () =>
              Navigator.of(context).pop(UnsavedChangesAction.saveAsCopy),
          child: Text(l10n.exportSaveCopy),
        ),
        if (canOverwrite)
          FilledButton(
            key: const Key('unsaved-save'),
            onPressed: () =>
                Navigator.of(context).pop(UnsavedChangesAction.save),
            child: Text(l10n.actionSave),
          ),
      ],
    );
  }
}
