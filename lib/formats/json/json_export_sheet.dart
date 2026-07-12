import 'package:flutter/material.dart';

import '../../core/export/export_service.dart';
import '../../core/export/export_target.dart';
import '../../l10n/app_localizations.dart';
import 'json_document_session.dart';
import 'json_output_actions.dart';

/// Lets the user pick an export target for a JSON document, runs the conversion,
/// then offers to share or save the produced file (task 8.6).
Future<void> showJsonExportSheet(
  BuildContext context,
  JsonDocumentSession session,
  JsonOutputActions actions,
  ExportService export,
) async {
  final target = await showModalBottomSheet<ExportTarget>(
    context: context,
    showDragHandle: true,
    builder: (context) => _ExportTargetList(
      targets: export.supportedTargets(JsonOutputActions.formatId),
    ),
  );
  if (target == null || !context.mounted) return;

  final result = await actions.runExport(context, session, target);
  if (result == null || !context.mounted) return;

  final next = await showModalBottomSheet<_ExportNext>(
    context: context,
    showDragHandle: true,
    builder: (context) => _ExportDoneList(name: result.suggestedName),
  );
  if (next == null || !context.mounted) return;

  switch (next) {
    case _ExportNext.share:
      await actions.shareExport(context, result);
      break;
    case _ExportNext.save:
      await actions.saveExport(context, result);
      break;
  }
}

class _ExportTargetList extends StatelessWidget {
  final Set<ExportTarget> targets;
  const _ExportTargetList({required this.targets});

  @override
  Widget build(BuildContext context) {
    final ordered = [
      for (final t in ExportTarget.values)
        if (targets.contains(t)) t,
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(AppLocalizations.of(context).exportAsTitle,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final t in ordered)
            ListTile(
              leading: Icon(_iconFor(t)),
              title: Text(t.label),
              onTap: () => Navigator.of(context).pop(t),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(ExportTarget t) {
    switch (t) {
      case ExportTarget.pdf:
        return Icons.picture_as_pdf_outlined;
      case ExportTarget.docx:
        return Icons.description_outlined;
      case ExportTarget.html:
        return Icons.html_outlined;
      case ExportTarget.markdown:
        return Icons.notes_outlined;
      case ExportTarget.plainText:
        return Icons.text_snippet_outlined;
      case ExportTarget.csv:
        return Icons.grid_on_outlined;
      case ExportTarget.yaml:
        return Icons.data_object_outlined;
      case ExportTarget.json:
        return Icons.data_object_outlined;
      case ExportTarget.xlsx:
        return Icons.table_chart_outlined;
    }
  }
}

enum _ExportNext { share, save }

class _ExportDoneList extends StatelessWidget {
  final String name;
  const _ExportDoneList({required this.name});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.exportCreated(name),
                style: Theme.of(context).textTheme.titleMedium),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.actionShare),
            onTap: () => Navigator.of(context).pop(_ExportNext.share),
          ),
          ListTile(
            leading: const Icon(Icons.save_alt_outlined),
            title: Text(l10n.exportSaveCopy),
            onTap: () => Navigator.of(context).pop(_ExportNext.save),
          ),
        ],
      ),
    );
  }
}
