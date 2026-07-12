import 'package:flutter/material.dart';

import '../../core/export/export_service.dart';
import '../../core/export/export_target.dart';
import '../../l10n/app_localizations.dart';
import 'csv_document_session.dart';
import 'csv_output_actions.dart';

/// Which rows an export covers (task 7.6).
enum CsvExportScope { all, filtered, selected }

/// Lets the user pick an export scope (all / filtered / selected rows) and a
/// target format, runs the conversion, then offers to share or save the result.
Future<void> showCsvExportSheet(
  BuildContext context,
  CsvDocumentSession session,
  CsvOutputActions actions,
  ExportService export,
) async {
  final choice = await showModalBottomSheet<_ExportChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _ExportPicker(
      session: session,
      targets: export.supportedTargets(CsvOutputActions.formatId),
    ),
  );
  if (choice == null || !context.mounted) return;

  final content = switch (choice.scope) {
    CsvExportScope.all => session.textContent,
    CsvExportScope.filtered =>
      session.textContentForRows(session.visibleRowIndices),
    CsvExportScope.selected => session.textContentForRows(
        session.selectedRows.toList()..sort(),
      ),
  };

  final result =
      await actions.runExport(context, session, choice.target, content: content);
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

class _ExportChoice {
  final CsvExportScope scope;
  final ExportTarget target;
  const _ExportChoice(this.scope, this.target);
}

class _ExportPicker extends StatefulWidget {
  final CsvDocumentSession session;
  final Set<ExportTarget> targets;

  const _ExportPicker({required this.session, required this.targets});

  @override
  State<_ExportPicker> createState() => _ExportPickerState();
}

class _ExportPickerState extends State<_ExportPicker> {
  CsvExportScope _scope = CsvExportScope.all;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasSelection = widget.session.selectedRows.isNotEmpty;
    final filtered = widget.session.filterQuery.trim().isNotEmpty;
    final ordered = [
      for (final t in ExportTarget.values)
        if (widget.targets.contains(t)) t,
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.exportSheetTitle, style: theme.textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<CsvExportScope>(
              segments: [
                ButtonSegment(
                    value: CsvExportScope.all,
                    label: Text(l10n.exportAllRows)),
                if (filtered)
                  ButtonSegment(
                      value: CsvExportScope.filtered,
                      label: Text(l10n.exportFilteredRows)),
                if (hasSelection)
                  ButtonSegment(
                      value: CsvExportScope.selected,
                      label: Text(l10n.exportSelectedRows)),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
          ),
          const SizedBox(height: 8),
          for (final t in ordered)
            ListTile(
              leading: Icon(_iconFor(t)),
              title: Text(t.label),
              onTap: () =>
                  Navigator.of(context).pop(_ExportChoice(_scope, t)),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(ExportTarget t) {
    switch (t) {
      case ExportTarget.pdf:
        return Icons.picture_as_pdf_outlined;
      case ExportTarget.json:
        return Icons.data_object_outlined;
      case ExportTarget.html:
        return Icons.html_outlined;
      case ExportTarget.xlsx:
        return Icons.table_chart_outlined;
      case ExportTarget.docx:
        return Icons.description_outlined;
      case ExportTarget.markdown:
        return Icons.notes_outlined;
      case ExportTarget.plainText:
        return Icons.text_snippet_outlined;
      case ExportTarget.csv:
        return Icons.grid_on_outlined;
      case ExportTarget.yaml:
        return Icons.data_object_outlined;
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
