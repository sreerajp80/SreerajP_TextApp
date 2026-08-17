import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/editor/column_selection_sheet.dart';
import 'package:sreerajp_textapp/core/editor/editor_providers.dart';
import 'package:sreerajp_textapp/core/privacy/ui/privacy_shield_sheet.dart';
import 'package:sreerajp_textapp/sync/diff/diff_dialog_helper.dart';
import 'package:sreerajp_textapp/airqr/ui/airqr_send_action.dart';
import 'package:sreerajp_textapp/core/output/output_providers.dart';
import 'package:sreerajp_textapp/core/sql/sql_query_screen.dart';
import 'package:sreerajp_textapp/core/sql/sql_source.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_controller.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/read_only_lock_button.dart';
import 'package:sreerajp_textapp/formats/format_dispatch.dart';
import 'package:sreerajp_textapp/formats/json/json_document_session.dart';
import 'package:sreerajp_textapp/formats/json/json_export_sheet.dart';
import 'package:sreerajp_textapp/formats/json/json_info_sheet.dart';
import 'package:sreerajp_textapp/formats/json/json_output_actions.dart';
import 'package:sreerajp_textapp/formats/json/json_parser.dart';
import 'package:sreerajp_textapp/formats/json/json_query_builder_sheet.dart';
import 'package:sreerajp_textapp/formats/json/json_read_aloud_button.dart';
import 'package:sreerajp_textapp/formats/json/json_save_options_sheet.dart';
import 'package:sreerajp_textapp/formats/json/json_session_manager.dart';
import 'package:sreerajp_textapp/formats/json/json_split_merge_actions.dart';
import 'package:sreerajp_textapp/formats/json/json_sql_source.dart';
import 'package:sreerajp_textapp/formats/sql_sources.dart';
import 'package:sreerajp_textapp/formats/json/json_tools_sheets.dart';

/// The action bar for an open JSON document (tasks 8.1–8.6): the
/// pretty/tree/raw/minified/edit view controls, undo/redo, find, format/minify,
/// validate, tree expand/collapse, save, read-aloud, and an overflow menu with
/// JSONPath, insights, diff, split/merge, copy, and the output services.
class JsonToolbar extends ConsumerWidget {
  final DocumentTab tab;

  const JsonToolbar({super.key, required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(jsonSessionManagerProvider).sessionFor(tab);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final ready = session.status == JsonLoadStatus.ready;
        final canEdit = ready && !tab.isReadOnly;
        final editing = session.mode == JsonViewMode.edit && !tab.isReadOnly;
        final showingSource =
            session.mode == JsonViewMode.raw ||
            session.mode == JsonViewMode.edit;
        final inTree = session.mode == JsonViewMode.tree;
        final hasTree = ready && session.root != null;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ready) ...[
                _ViewButton(
                  session: session,
                  mode: JsonViewMode.pretty,
                  icon: Icons.data_object,
                  tooltip: l10n.xmlViewPretty,
                ),
                _ViewButton(
                  session: session,
                  mode: JsonViewMode.tree,
                  icon: Icons.account_tree_outlined,
                  tooltip: l10n.xmlViewTree,
                ),
                _ViewButton(
                  session: session,
                  mode: JsonViewMode.raw,
                  icon: Icons.notes,
                  tooltip: l10n.xmlViewRaw,
                ),
                _ViewButton(
                  session: session,
                  mode: JsonViewMode.minified,
                  icon: Icons.compress,
                  tooltip: l10n.jsonViewMinified,
                ),
                // Roadmap §4.3.1 — greyed out when there is no array to show.
                _ViewButton(
                  key: const Key('json-table-view-button'),
                  session: session,
                  mode: JsonViewMode.table,
                  icon: Icons.table_chart_outlined,
                  tooltip: l10n.jsonViewAsTable,
                  enabled: session.hasTabularArray,
                ),
              ],
              if (canEdit)
                IconButton(
                  key: const Key('json-edit-toggle'),
                  tooltip: editing
                      ? l10n.editorExitEditMode
                      : l10n.xmlEditSource,
                  isSelected: editing,
                  icon: const Icon(Icons.edit_outlined),
                  // A filled pencil still reads as "edit"; this is the exit.
                  selectedIcon: const Icon(Icons.edit_off_outlined),
                  onPressed: () => session.setMode(
                    editing ? JsonViewMode.pretty : JsonViewMode.edit,
                  ),
                ),
              if (editing) ...[
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
              if (inTree) ...[
                IconButton(
                  tooltip: l10n.xmlExpandAll,
                  icon: const Icon(Icons.unfold_more),
                  onPressed: hasTree ? session.expandAll : null,
                ),
                IconButton(
                  tooltip: l10n.xmlCollapseAll,
                  icon: const Icon(Icons.unfold_less),
                  onPressed: hasTree ? session.collapseAll : null,
                ),
              ],
              IconButton(
                tooltip: l10n.actionFind,
                icon: const Icon(Icons.search),
                onPressed: showingSource ? session.openFind : null,
              ),
              IconButton(
                key: const Key('json-format-button'),
                tooltip: l10n.xmlFormat,
                icon: const Icon(Icons.format_align_left),
                onPressed: hasTree ? session.formatDocument : null,
              ),
              IconButton(
                tooltip: l10n.xmlMinify,
                icon: const Icon(Icons.horizontal_rule),
                onPressed: hasTree ? session.minifyDocument : null,
              ),
              IconButton(
                tooltip: l10n.xmlValidate,
                icon: Icon(
                  session.isWellFormed
                      ? Icons.check_circle_outline
                      : Icons.error_outline,
                ),
                onPressed: ready
                    ? () => showJsonValidateSheet(
                        context,
                        session,
                        ref.read(safServiceProvider),
                        ref.read(textCodecServiceProvider),
                      )
                    : null,
              ),
              IconButton(
                key: const Key('json-save-button'),
                tooltip: l10n.actionSave,
                icon: const Icon(Icons.save_outlined),
                onPressed: ready
                    ? () async => exitEditModeAfterSave(
                        ref,
                        tab,
                        saved: await saveJsonDirect(context, session),
                      )
                    : null,
              ),
              if (ready) JsonReadAloudButton(session: session),
              _OverflowMenu(tab: tab, session: session, enabled: ready),
              const ReadOnlyLockButton(),
            ],
          ),
        );
      },
    );
  }
}

class _ViewButton extends StatelessWidget {
  final JsonDocumentSession session;
  final JsonViewMode mode;
  final IconData icon;
  final String tooltip;

  /// False greys the button out — used by the table view, which needs an array
  /// to show.
  final bool enabled;

  const _ViewButton({
    super.key,
    required this.session,
    required this.mode,
    required this.icon,
    required this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selected = session.mode == mode;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      icon: Icon(icon),
      onPressed: enabled ? () => session.setMode(mode) : null,
    );
  }
}

enum _MenuAction {
  saveAs,
  replace,
  columnEdit,
  jsonPath,
  queryBuilder,
  sqlQuery,
  info,
  diff,
  split,
  merge,
  copyFull,
  copyMinified,
  share,
  privacyShield,
  liveDiff,
  sendByQr,
  shareZip,
  print,
  export,
}

class _OverflowMenu extends ConsumerWidget {
  final DocumentTab tab;
  final JsonDocumentSession session;
  final bool enabled;

  const _OverflowMenu({
    required this.tab,
    required this.session,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = session.mode == JsonViewMode.edit && !tab.isReadOnly;
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_MenuAction>(
      key: const Key('json-overflow-menu'),
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
        if (editing) ...[
          PopupMenuItem(
            value: _MenuAction.replace,
            child: ListTile(
              leading: const Icon(Icons.find_replace),
              title: Text(l10n.actionFindReplace),
            ),
          ),
          PopupMenuItem(
            value: _MenuAction.columnEdit,
            child: ListTile(
              leading: const Icon(Icons.view_column_rounded),
              title: Text(l10n.columnSelectionTitle),
            ),
          ),
        ],
        PopupMenuItem(
          value: _MenuAction.jsonPath,
          child: ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(l10n.jsonPathQuery),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.queryBuilder,
          child: ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: Text(l10n.jsonQueryBuilderTitle),
          ),
        ),
        // Needs an array of records to load as a table, so it is greyed out on a
        // document that has none (Feature 4).
        PopupMenuItem(
          value: _MenuAction.sqlQuery,
          enabled: session.hasTabularArray,
          child: ListTile(
            enabled: session.hasTabularArray,
            leading: const Icon(Icons.terminal),
            title: Text(l10n.sqlMenuAction),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.info,
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.xmlInsightsInfo),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.diff,
          child: ListTile(
            leading: const Icon(Icons.difference_outlined),
            title: Text(l10n.jsonCompareFile),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.split,
          child: ListTile(
            leading: const Icon(Icons.call_split),
            title: Text(l10n.jsonSplitArray),
          ),
        ),
        if (editing)
          PopupMenuItem(
            value: _MenuAction.merge,
            child: ListTile(
              leading: const Icon(Icons.merge_type),
              title: Text(l10n.xmlMergeFile),
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _MenuAction.copyFull,
          child: ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: Text(l10n.xmlCopyAll),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.copyMinified,
          child: ListTile(
            leading: const Icon(Icons.content_copy_outlined),
            title: Text(l10n.xmlCopyMinified),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.share,
          child: ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(l10n.actionShare),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.privacyShield,
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyShieldAction),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.liveDiff,
          child: ListTile(
            leading: const Icon(Icons.difference_outlined),
            title: Text(l10n.liveDiffAction),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.sendByQr,
          child: ListTile(
            leading: const Icon(Icons.qr_code_2),
            title: Text(l10n.airqrSendByQr),
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
        await showJsonSaveOptionsSheet(context, session);
        break;
      case _MenuAction.replace:
        session.openReplace();
        break;
      case _MenuAction.columnEdit:
        final code = session.code;
        if (code != null) {
          await ColumnSelectionSheet.show(context: context, controller: code);
        }
        break;
      case _MenuAction.jsonPath:
        await showJsonPathSheet(context, session);
        break;
      case _MenuAction.queryBuilder:
        final query = await showJsonQueryBuilderSheet(context, session);
        if (query == null || !context.mounted) break;
        // The builder only writes the query; running it stays the JSONPath
        // sheet's job, so there is one place that shows matches.
        await showJsonPathSheet(context, session, initialQuery: query);
        break;
      case _MenuAction.sqlQuery:
        // The array the table view is pointed at is what gets queried, so
        // drilling into a nested array first also narrows the SQL table.
        await SqlQueryScreen.open(
          context,
          primary: SqlSource(
            tabId: tab.id,
            displayName: tab.displayName,
            suggestedTableName: 'data',
            build: () async => jsonSqlDataset(
              session.jsonTable,
              tableName: 'data',
              sourceLabel: tab.displayName,
            ),
          ),
          otherSources: () => sqlSourcesForOpenTabs(ref, excludeTabId: tab.id),
        );
        break;
      case _MenuAction.info:
        await showJsonInfoSheet(context, session);
        break;
      case _MenuAction.diff:
        await showJsonDiffSheet(
          context,
          session,
          ref.read(safServiceProvider),
          ref.read(textCodecServiceProvider),
        );
        break;
      case _MenuAction.split:
        await _actions(ref).split(context, session);
        break;
      case _MenuAction.merge:
        await _actions(ref).mergeAppend(context, session);
        break;
      case _MenuAction.copyFull:
        await Clipboard.setData(ClipboardData(text: session.textContent.text));
        break;
      case _MenuAction.copyMinified:
        final root = session.root;
        if (root != null) {
          await Clipboard.setData(ClipboardData(text: minifyJson(root)));
        }
        break;
      case _MenuAction.share:
        await _output(ref).shareFile(context, session);
        break;
      case _MenuAction.privacyShield:
        final editing = session.mode == JsonViewMode.edit && !tab.isReadOnly;
        await PrivacyShieldSheet.show(
          context,
          text: session.textContent.text,
          documentTitle: session.tab.displayName,
          mimeType: session.tab.mimeType ?? 'application/json',
          onApplyToEditor: editing
              ? (newText) {
                  final code = session.code;
                  if (code != null) {
                    code.text = newText;
                  }
                }
              : null,
          shareService: ref.read(shareServiceProvider),
          safService: ref.read(safServiceProvider),
        );
        break;
      case _MenuAction.liveDiff:
        final editing = session.mode == JsonViewMode.edit && !tab.isReadOnly;
        await LiveDiffLauncher.showDiffOptions(
          context: context,
          ref: ref,
          tab: session.tab,
          content: session.textContent.text,
          onApplyToEditor: editing
              ? (newText) {
                  final code = session.code;
                  if (code != null) {
                    code.text = newText;
                  }
                }
              : null,
        );
        break;
      case _MenuAction.sendByQr:
        await AirqrSendAction.sendDocument(
          context: context,
          name: session.tab.displayName,
          mimeType: session.tab.mimeType ?? 'application/json',
          content: session.textContent.text,
        );
        break;
      case _MenuAction.shareZip:
        await _output(ref).shareAsZip(context, session);
        break;
      case _MenuAction.print:
        await _output(ref).printDoc(context, session);
        break;
      case _MenuAction.export:
        await showJsonExportSheet(
          context,
          session,
          _output(ref),
          ref.read(exportServiceProvider),
        );
        break;
    }
  }

  JsonSplitMergeActions _actions(WidgetRef ref) => JsonSplitMergeActions(
    saf: ref.read(safServiceProvider),
    codec: ref.read(textCodecServiceProvider),
  );

  JsonOutputActions _output(WidgetRef ref) => JsonOutputActions(
    share: ref.read(shareServiceProvider),
    zip: ref.read(zipServiceProvider),
    print: ref.read(printServiceProvider),
    export: ref.read(exportServiceProvider),
    saf: ref.read(safServiceProvider),
    codec: ref.read(textCodecServiceProvider),
    // Burns this tab when it was marked "burn after export" (Feature 9).
    onOutputCompleted: () => unawaited(
      ref
          .read(ephemeralControllerProvider.notifier)
          .notifyOutputCompleted(tab.id),
    ),
  );
}
