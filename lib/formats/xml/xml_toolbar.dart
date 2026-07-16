import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/editor_providers.dart';
import '../../core/output/output_providers.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import '../../shell/tabs/read_only_lock_button.dart';
import 'xml_document_session.dart';
import 'xml_export_sheet.dart';
import 'xml_info_sheet.dart';
import 'xml_output_actions.dart';
import 'xml_read_aloud_button.dart';
import 'xml_save_options_sheet.dart';
import 'xml_session_manager.dart';
import 'xml_split_merge_actions.dart';
import 'xml_tools_sheets.dart';

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
        final showingSource = session.mode == XmlViewMode.raw ||
            session.mode == XmlViewMode.edit;
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
                onPressed:
                    ready ? () => showXmlValidateSheet(context, session) : null,
              ),
              IconButton(
                key: const Key('xml-save-button'),
                tooltip: l10n.actionSave,
                icon: const Icon(Icons.save_outlined),
                onPressed:
                    ready ? () => saveXmlDirect(context, session) : null,
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
  xpath,
  info,
  split,
  merge,
  copyFull,
  copyMinified,
  share,
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
        if (editing)
          PopupMenuItem(
            value: _MenuAction.replace,
            child: ListTile(
              leading: const Icon(Icons.find_replace),
              title: Text(l10n.actionFindReplace),
            ),
          ),
        PopupMenuItem(
          value: _MenuAction.xpath,
          child: ListTile(
            leading: const Icon(Icons.alternate_email),
            title: Text(l10n.xmlXPathQuery),
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
      case _MenuAction.xpath:
        await showXmlPathSheet(context, session);
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
      );
}
