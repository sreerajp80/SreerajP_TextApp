import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/editor_providers.dart';
import '../../core/output/output_providers.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import '../../shell/tabs/read_only_lock_button.dart';
import 'txt_document_session.dart';
import 'txt_encoding_sheet.dart';
import 'txt_export_sheet.dart';
import 'txt_info_sheet.dart';
import 'txt_links_sheet.dart';
import 'txt_output_actions.dart';
import 'txt_read_aloud_button.dart';
import 'txt_save_options_sheet.dart';
import 'txt_session_manager.dart';
import 'txt_split_merge_actions.dart';

/// The action bar for an open TXT document (tasks 4.1–4.5): view/edit toggle,
/// undo/redo, find, word-wrap, save, and an overflow menu with jump-to-line,
/// links, encoding, file info, and split/merge.
class TxtToolbar extends ConsumerWidget {
  final DocumentTab tab;

  const TxtToolbar({super.key, required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(txtSessionManagerProvider).sessionFor(tab);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final ready = session.status == TxtLoadStatus.ready;
        final editing =
            session.viewMode == TabViewMode.edit && !tab.isReadOnly;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (ready && !tab.isReadOnly)
                IconButton(
                  key: const Key('txt-view-edit-toggle'),
                  tooltip: editing ? l10n.txtViewMode : l10n.txtEditMode,
                  isSelected: editing,
                  icon: const Icon(Icons.edit_outlined),
                  selectedIcon: const Icon(Icons.visibility_outlined),
                  onPressed: () => session.setViewMode(
                    editing ? TabViewMode.view : TabViewMode.edit,
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
              IconButton(
                tooltip: l10n.actionFind,
                icon: const Icon(Icons.search),
                onPressed: ready ? session.openFind : null,
              ),
              IconButton(
                tooltip:
                    session.wordWrap ? l10n.txtWordWrapOn : l10n.txtWordWrapOff,
                isSelected: session.wordWrap,
                icon: const Icon(Icons.wrap_text),
                onPressed: ready ? session.toggleWordWrap : null,
              ),
              IconButton(
                key: const Key('txt-save-button'),
                tooltip: l10n.actionSave,
                icon: const Icon(Icons.save_outlined),
                onPressed:
                    ready ? () => saveTxtDirect(context, session) : null,
              ),
              if (ready) TxtReadAloudButton(session: session),
              _OverflowMenu(tab: tab, session: session, enabled: ready),
              const ReadOnlyLockButton(),
            ],
          ),
        );
      },
    );
  }
}

enum _MenuAction {
  jumpToLine,
  saveAs,
  links,
  encoding,
  info,
  replace,
  split,
  merge,
  share,
  shareZip,
  print,
  export,
}

class _OverflowMenu extends ConsumerWidget {
  final DocumentTab tab;
  final TxtDocumentSession session;
  final bool enabled;

  const _OverflowMenu({
    required this.tab,
    required this.session,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = session.viewMode == TabViewMode.edit && !tab.isReadOnly;
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_MenuAction>(
      key: const Key('txt-overflow-menu'),
      enabled: enabled,
      onSelected: (action) => _handle(context, ref, action),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _MenuAction.jumpToLine,
          child: ListTile(
            leading: const Icon(Icons.my_location),
            title: Text(l10n.txtJumpToLine),
          ),
        ),
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
          value: _MenuAction.links,
          child: ListTile(
              leading: const Icon(Icons.link), title: Text(l10n.txtLinksTitle)),
        ),
        PopupMenuItem(
          value: _MenuAction.encoding,
          child: ListTile(
            leading: const Icon(Icons.translate),
            title: Text(l10n.txtEncoding),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.info,
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.actionFileInfo),
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.split,
          child: ListTile(
            leading: const Icon(Icons.call_split),
            title: Text(l10n.txtSplitFile),
          ),
        ),
        if (editing)
          PopupMenuItem(
            value: _MenuAction.merge,
            child: ListTile(
              leading: const Icon(Icons.merge_type),
              title: Text(l10n.txtAppendFile),
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
      case _MenuAction.jumpToLine:
        await _jumpToLine(context);
        break;
      case _MenuAction.saveAs:
        await showSaveOptionsSheet(context, session);
        break;
      case _MenuAction.replace:
        session.openReplace();
        break;
      case _MenuAction.links:
        await showLinksSheet(context, session);
        break;
      case _MenuAction.encoding:
        await showEncodingSheet(context, session);
        break;
      case _MenuAction.info:
        await showInfoSheet(context, session);
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
        await showExportSheet(
          context,
          session,
          _output(ref),
          ref.read(exportServiceProvider),
        );
        break;
    }
  }

  TxtSplitMergeActions _actions(WidgetRef ref) => TxtSplitMergeActions(
        saf: ref.read(safServiceProvider),
        codec: ref.read(textCodecServiceProvider),
      );

  TxtOutputActions _output(WidgetRef ref) => TxtOutputActions(
        share: ref.read(shareServiceProvider),
        zip: ref.read(zipServiceProvider),
        print: ref.read(printServiceProvider),
        export: ref.read(exportServiceProvider),
        saf: ref.read(safServiceProvider),
        codec: ref.read(textCodecServiceProvider),
      );

  Future<void> _jumpToLine(BuildContext context) async {
    final controller = TextEditingController();
    final line = await showDialog<int>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.txtJumpToLine),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.txtLineNumber,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) =>
                Navigator.of(context).pop(int.tryParse(value.trim())),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .pop(int.tryParse(controller.text.trim())),
              child: Text(l10n.actionGo),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (line != null && line > 0) {
      session.jumpToLine(line - 1); // UI is 1-based, editor is 0-based
    }
  }
}
