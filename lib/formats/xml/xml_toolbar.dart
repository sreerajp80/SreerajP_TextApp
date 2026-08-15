import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/editor/column_selection_sheet.dart';
import 'package:text_data/core/editor/editor_providers.dart';
import 'package:text_data/core/privacy/ui/privacy_shield_sheet.dart';
import 'package:text_data/sync/diff/diff_dialog_helper.dart';
import 'package:text_data/airqr/ui/airqr_send_action.dart';
import 'package:text_data/core/output/output_providers.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/core/ephemeral/ephemeral_controller.dart';
import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/read_only_lock_button.dart';
import 'package:text_data/formats/xml/xml_document_session.dart';
import 'package:text_data/formats/xml/xml_export_sheet.dart';
import 'package:text_data/formats/xml/xml_info_sheet.dart';
import 'package:text_data/formats/xml/xml_output_actions.dart';
import 'package:text_data/formats/xml/xml_query_builder_sheet.dart';
import 'package:text_data/formats/xml/xml_read_aloud_button.dart';
import 'package:text_data/formats/xml/xml_save_options_sheet.dart';
import 'package:text_data/formats/xml/xml_session_manager.dart';
import 'package:text_data/formats/xml/xml_split_merge_actions.dart';
import 'package:text_data/formats/xml/xml_tools_sheets.dart';

/// The action bar for an open XML document (tasks 9.1–9.6): the
/// pretty/tree/raw/edit view controls, undo/redo, find, format/minify, validate,
/// tree expand/collapse, save, read-aloud, and an overflow menu with XPath,
/// insights, split/merge, copy, and the output services.
class XmlToolbar extends ConsumerWidget {
  final DocumentTab tab;

  const XmlToolbar({super.key, required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(xmlSessionManagerProvider).sessionFor(tab);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final ready = session.status == XmlLoadStatus.ready;
        final canEdit = ready && !tab.isReadOnly;
        final editing = session.mode == XmlViewMode.edit && !tab.isReadOnly;
        final showingSource =
            session.mode == XmlViewMode.raw || session.mode == XmlViewMode.edit;
        final inTree = session.mode == XmlViewMode.tree;
        final hasTree = ready && session.document != null;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ready) ...[
                _ViewButton(
                  session: session,
                  mode: XmlViewMode.pretty,
                  icon: Icons.code,
                  tooltip: l10n.xmlViewPretty,
                ),
                _ViewButton(
                  session: session,
                  mode: XmlViewMode.tree,
                  icon: Icons.account_tree_outlined,
                  tooltip: l10n.xmlViewTree,
                ),
                _ViewButton(
                  session: session,
                  mode: XmlViewMode.raw,
                  icon: Icons.notes,
                  tooltip: l10n.xmlViewRaw,
                ),
              ],
              if (canEdit)
                IconButton(
                  key: const Key('xml-edit-toggle'),
                  tooltip: editing ? l10n.xmlStopEditing : l10n.xmlEditSource,
                  isSelected: editing,
                  icon: const Icon(Icons.edit_outlined),
                  selectedIcon: const Icon(Icons.edit),
                  onPressed: () => session.setMode(
                    editing ? XmlViewMode.pretty : XmlViewMode.edit,
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
                key: const Key('xml-format-button'),
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
                    ? () => showXmlValidateSheet(context, session)
                    : null,
              ),
              IconButton(
                key: const Key('xml-save-button'),
                tooltip: l10n.actionSave,
                icon: const Icon(Icons.save_outlined),
                onPressed: ready ? () => saveXmlDirect(context, session) : null,
              ),
              if (ready) XmlReadAloudButton(session: session),
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
  final XmlDocumentSession session;
  final XmlViewMode mode;
  final IconData icon;
  final String tooltip;

  const _ViewButton({
    required this.session,
    required this.mode,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final selected = session.mode == mode;
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      icon: Icon(icon),
      onPressed: () => session.setMode(mode),
    );
  }
}

enum _MenuAction {
  saveAs,
  replace,
  columnEdit,
  xpath,
  queryBuilder,
  info,
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
  final XmlDocumentSession session;
  final bool enabled;

  const _OverflowMenu({
    required this.tab,
    required this.session,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = session.mode == XmlViewMode.edit && !tab.isReadOnly;
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_MenuAction>(
      key: const Key('xml-overflow-menu'),
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
          value: _MenuAction.xpath,
          child: ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(l10n.xmlXPathQuery),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.queryBuilder,
          child: ListTile(
            leading: const Icon(Icons.account_tree_outlined),
            title: Text(l10n.xmlQueryBuilderTitle),
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
          value: _MenuAction.split,
          child: ListTile(
            leading: const Icon(Icons.call_split),
            title: Text(l10n.xmlSplitByElement),
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
        const PopupMenuItem(
          value: _MenuAction.liveDiff,
          child: ListTile(
            leading: Icon(Icons.difference_outlined),
            title: Text('Live P2P Diff & Sync'),
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
        await showXmlSaveOptionsSheet(context, session);
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
      case _MenuAction.xpath:
        await showXmlPathSheet(context, session);
        break;
      case _MenuAction.queryBuilder:
        final query = await showXmlQueryBuilderSheet(context, session);
        if (query == null || !context.mounted) break;
        // The builder only writes the query; running it stays the XPath
        // sheet's job, so there is one place that shows matches.
        await showXmlPathSheet(context, session, initialQuery: query);
        break;
      case _MenuAction.info:
        await showXmlInfoSheet(context, session);
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
        final doc = session.document;
        if (doc != null) {
          await Clipboard.setData(ClipboardData(text: doc.toXmlString()));
        }
        break;
      case _MenuAction.share:
        await _output(ref).shareFile(context, session);
        break;
      case _MenuAction.privacyShield:
        final editing = session.mode == XmlViewMode.edit && !tab.isReadOnly;
        await PrivacyShieldSheet.show(
          context,
          text: session.textContent.text,
          documentTitle: session.tab.displayName,
          mimeType: session.tab.mimeType ?? 'application/xml',
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
        final editing = session.mode == XmlViewMode.edit && !tab.isReadOnly;
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
          mimeType: session.tab.mimeType ?? 'application/xml',
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
        await showXmlExportSheet(
          context,
          session,
          _output(ref),
          ref.read(exportServiceProvider),
        );
        break;
    }
  }

  XmlSplitMergeActions _actions(WidgetRef ref) => XmlSplitMergeActions(
    saf: ref.read(safServiceProvider),
    codec: ref.read(textCodecServiceProvider),
  );

  XmlOutputActions _output(WidgetRef ref) => XmlOutputActions(
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
