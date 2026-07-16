import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/editor_providers.dart';
import '../../core/output/output_providers.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import '../../shell/tabs/read_only_lock_button.dart';
import 'csv_columns_sheet.dart';
import 'csv_document_session.dart';
import 'csv_export_sheet.dart';
import 'csv_info_sheet.dart';
import 'csv_insights_sheet.dart';
import 'csv_output_actions.dart';
import 'csv_save_options_sheet.dart';
import 'csv_session_manager.dart';
import 'csv_split_merge_actions.dart';

/// The action bar for an open CSV document (tasks 7.2–7.6): the table / raw
/// toggle, undo / redo, row filter (table) or find (raw), jump-to-row, columns &
/// view options, insights, save, and an overflow menu with file info, dedup,
/// split / merge, and the output services.
class CsvToolbar extends ConsumerStatefulWidget {
  final DocumentTab tab;

  const CsvToolbar({super.key, required this.tab});

  @override
  ConsumerState<CsvToolbar> createState() => _CsvToolbarState();
}

class _CsvToolbarState extends ConsumerState<CsvToolbar> {
  final TextEditingController _search = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(csvSessionManagerProvider).sessionFor(widget.tab);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final ready = session.status == CsvLoadStatus.ready;
        final canEdit = ready && !widget.tab.isReadOnly;
        final isTable = session.mode == CsvViewMode.table;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('csv-table-raw-toggle'),
                    tooltip: isTable ? l10n.csvShowRawText : l10n.csvShowTable,
                    isSelected: !isTable,
                    icon: const Icon(Icons.grid_on_outlined),
                    selectedIcon: const Icon(Icons.code),
                    onPressed: ready
                        ? () => session.setViewMode(
                            isTable ? CsvViewMode.raw : CsvViewMode.table)
                        : null,
                  ),
                  if (canEdit) ...[
                    IconButton(
                      tooltip: l10n.actionUndo,
                      icon: const Icon(Icons.undo),
                      onPressed: session.canUndo ? session.undo : null,
                    ),
                    IconButton(
                      tooltip: l10n.actionRedo,
                      icon: const Icon(Icons.redo),
                      onPressed: session.canRedo ? session.redo : null,
                    ),
                  ],
                  if (isTable)
                    IconButton(
                      tooltip: l10n.csvFilterRows,
                      isSelected: _showSearch,
                      icon: const Icon(Icons.search),
                      onPressed: ready
                          ? () => setState(() => _showSearch = !_showSearch)
                          : null,
                    )
                  else
                    IconButton(
                      tooltip: l10n.actionFind,
                      icon: const Icon(Icons.search),
                      onPressed: ready ? () => session.find?.findMode() : null,
                    ),
                  if (isTable)
                    IconButton(
                      tooltip: l10n.csvJumpToRow,
                      icon: const Icon(Icons.numbers),
                      onPressed:
                          ready ? () => _jumpToRow(context, session) : null,
                    ),
                  IconButton(
                    tooltip: l10n.csvColumnsView,
                    icon: const Icon(Icons.view_column_outlined),
                    onPressed: ready
                        ? () => showCsvColumnsSheet(context, session,
                            editable: canEdit)
                        : null,
                  ),
                  IconButton(
                    tooltip: l10n.csvInsights,
                    icon: const Icon(Icons.insights_outlined),
                    onPressed:
                        ready ? () => showCsvInsightsSheet(context, session) : null,
                  ),
                  IconButton(
                    key: const Key('csv-save-button'),
                    tooltip: l10n.actionSave,
                    icon: const Icon(Icons.save_outlined),
                    onPressed:
                        ready ? () => saveCsvDirect(context, session) : null,
                  ),
                  _OverflowMenu(
                    tab: widget.tab,
                    session: session,
                    enabled: ready,
                    canEdit: canEdit,
                  ),
                  const ReadOnlyLockButton(),
                ],
              ),
            ),
            if (isTable && _showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                child: TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: l10n.csvFilterRowsHint,
                    prefixIcon: const Icon(Icons.filter_list),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _search.clear();
                        session.setFilterQuery('');
                        setState(() => _showSearch = false);
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: session.setFilterQuery,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _jumpToRow(
    BuildContext context,
    CsvDocumentSession session,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final row = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.csvJumpToRow),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.csvRowNumberLabel(session.table.rowCount),
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) =>
              Navigator.of(context).pop(int.tryParse(v.trim())),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text.trim())),
            child: Text(l10n.actionGo),
          ),
        ],
      ),
    );
    if (row != null && row >= 1 && row <= session.table.rowCount) {
      session.requestJumpToRow(row - 1);
    }
  }
}

enum _MenuAction { saveAs, replace, info, dedup, split, merge, share, shareZip, print, export }

class _OverflowMenu extends ConsumerWidget {
  final DocumentTab tab;
  final CsvDocumentSession session;
  final bool enabled;
  final bool canEdit;

  const _OverflowMenu({
    required this.tab,
    required this.session,
    required this.enabled,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final raw = session.mode == CsvViewMode.raw;
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_MenuAction>(
      key: const Key('csv-overflow-menu'),
      enabled: enabled,
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.saveAs,
          child: ListTile(
            leading: const Icon(Icons.save_as_outlined),
            title: Text(l10n.actionSaveAs),
          ),
        ),
        if (canEdit && raw)
          PopupMenuItem(
            value: _MenuAction.replace,
            child: ListTile(
              leading: const Icon(Icons.find_replace),
              title: Text(l10n.actionFindReplace),
            ),
          ),
        PopupMenuItem(
          value: _MenuAction.info,
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.actionFileInfo),
          ),
        ),
        if (canEdit)
          PopupMenuItem(
            value: _MenuAction.dedup,
            child: ListTile(
              leading: const Icon(Icons.filter_alt_off_outlined),
              title: Text(l10n.csvRemoveDuplicates),
            ),
          ),
        PopupMenuItem(
          value: _MenuAction.split,
          child: ListTile(
            leading: const Icon(Icons.call_split),
            title: Text(l10n.csvSplitByRows),
          ),
        ),
        if (canEdit)
          PopupMenuItem(
            value: _MenuAction.merge,
            child: ListTile(
              leading: const Icon(Icons.merge_type),
              title: Text(l10n.csvAppendFile),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.share,
          child: ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.actionShare),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.shareZip,
          child: ListTile(
            leading: const Icon(Icons.folder_zip_outlined),
            title: Text(l10n.actionShareZip),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.print,
          child: ListTile(
            leading: const Icon(Icons.print_outlined),
            title: Text(l10n.actionPrint),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.export,
          child: ListTile(
            leading: const Icon(Icons.ios_share_outlined),
            title: Text(l10n.actionExport),
          ),
        ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.saveAs:
        await showCsvSaveOptionsSheet(context, session);
        break;
      case _MenuAction.replace:
        session.find?.replaceMode();
        break;
      case _MenuAction.info:
        await showCsvInfoSheet(context, session);
        break;
      case _MenuAction.dedup:
        await _dedup(context);
        break;
      case _MenuAction.split:
        await _actions(ref).split(context, session);
        break;
      case _MenuAction.merge:
        await _actions(ref).mergeAppend(context, session);
        break;
      case _MenuAction.share:
        await _output(ref).shareFile(context, session);
        break;
      case _MenuAction.shareZip:
        await _output(ref).shareAsZip(context, session);
        break;
      case _MenuAction.print:
        await _output(ref).printDoc(context, session);
        break;
      case _MenuAction.export:
        await showCsvExportSheet(
          context,
          session,
          _output(ref),
          ref.read(exportServiceProvider),
        );
        break;
    }
  }

  Future<void> _dedup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // Pick the match key: whole row or one column.
    final keyColumn = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(l10n.csvMatchDuplicatesBy,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.table_rows_outlined),
              title: Text(l10n.csvWholeRow),
              onTap: () => Navigator.pop(context, -1),
            ),
            for (var c = 0; c < session.table.columnCount; c++)
              ListTile(
                leading: const Icon(Icons.view_column_outlined),
                title: Text(session.table.header[c].isEmpty
                    ? l10n.csvColumnN(c + 1)
                    : session.table.header[c]),
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (keyColumn == null || !context.mounted) return;

    final key = keyColumn < 0 ? null : keyColumn;
    final count = session.duplicateCount(keyColumn: key);
    if (count == 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.csvNoDuplicates)),
      );
      return;
    }
    session.removeDuplicateRows(keyColumn: key);
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.csvRemovedDuplicates(count))),
    );
  }

  CsvSplitMergeActions _actions(WidgetRef ref) => CsvSplitMergeActions(
        saf: ref.read(safServiceProvider),
        codec: ref.read(textCodecServiceProvider),
      );

  CsvOutputActions _output(WidgetRef ref) => CsvOutputActions(
        share: ref.read(shareServiceProvider),
        zip: ref.read(zipServiceProvider),
        print: ref.read(printServiceProvider),
        export: ref.read(exportServiceProvider),
        saf: ref.read(safServiceProvider),
        codec: ref.read(textCodecServiceProvider),
      );
}
