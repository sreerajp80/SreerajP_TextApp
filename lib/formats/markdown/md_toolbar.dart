import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/editor_providers.dart';
import '../../core/output/output_providers.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import '../../shell/tabs/read_only_lock_button.dart';
import 'md_document_session.dart';
import 'md_export_sheet.dart';
import 'md_format_toolbar.dart';
import 'md_info_sheet.dart';
import 'md_output_actions.dart';
import 'md_read_aloud_button.dart';
import 'md_save_options_sheet.dart';
import 'md_session_manager.dart';
import 'md_split_merge_actions.dart';
import 'md_toc_sheet.dart';

/// The action bar for an open Markdown document (tasks 6.1–6.5): the
/// rendered/raw/edit mode controls, the formatting toolbar (edit mode), find,
/// save, TOC, read-aloud, and an overflow menu with file info, split/merge, and
/// the output services.
class MdToolbar extends ConsumerWidget {
  final DocumentTab tab;

  const MdToolbar({super.key, required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(mdSessionManagerProvider).sessionFor(tab);
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final ready = session.status == MdLoadStatus.ready;
        final canEdit = ready && !tab.isReadOnly;
        final editing = session.mode == MdMode.edit && !tab.isReadOnly;
        final showingSource =
            session.mode == MdMode.raw || session.mode == MdMode.edit;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (canEdit)
                    IconButton(
                      key: const Key('md-edit-toggle'),
                      tooltip: editing ? l10n.mdPreview : l10n.mdEdit,
                      isSelected: editing,
                      icon: const Icon(Icons.edit_outlined),
                      selectedIcon: const Icon(Icons.visibility_outlined),
                      onPressed: () => session.setMode(
                        editing ? MdMode.rendered : MdMode.edit,
                      ),
                    ),
                  if (ready && !editing)
                    IconButton(
                      key: const Key('md-rendered-raw-toggle'),
                      tooltip: session.mode == MdMode.rendered
                          ? l10n.mdShowSource
                          : l10n.mdShowRendered,
                      isSelected: session.mode == MdMode.raw,
                      icon: const Icon(Icons.article_outlined),
                      selectedIcon: const Icon(Icons.code),
                      onPressed: () => session.setMode(
                        session.mode == MdMode.rendered
                            ? MdMode.raw
                            : MdMode.rendered,
                      ),
                    ),
                  if (editing) ...[
                    IconButton(
                      tooltip: l10n.mdUndo,
                      icon: const Icon(Icons.undo),
                      onPressed: session.canUndo ? session.undo : null,
                    ),
                    IconButton(
                      tooltip: l10n.mdRedo,
                      icon: const Icon(Icons.redo),
                      onPressed: session.canRedo ? session.redo : null,
                    ),
                    IconButton(
                      tooltip: session.livePreview
                          ? l10n.mdLivePreviewOn
                          : l10n.mdLivePreviewOff,
                      isSelected: session.livePreview,
                      icon: const Icon(Icons.vertical_split_outlined),
                      onPressed: session.toggleLivePreview,
                    ),
                  ],
                  IconButton(
                    tooltip: l10n.mdFind,
                    icon: const Icon(Icons.search),
                    onPressed: showingSource ? session.openFind : null,
                  ),
                  IconButton(
                    tooltip: l10n.mdContents,
                    icon: const Icon(Icons.toc),
                    onPressed:
                        ready ? () => showMdTocSheet(context, session) : null,
                  ),
                  IconButton(
                    key: const Key('md-save-button'),
                    tooltip: l10n.mdSave,
                    icon: const Icon(Icons.save_outlined),
                    onPressed:
                        ready ? () => saveMdDirect(context, session) : null,
                  ),
                  if (ready) MdReadAloudButton(session: session),
                  _OverflowMenu(tab: tab, session: session, enabled: ready),
                  const ReadOnlyLockButton(),
                ],
              ),
            ),
            if (editing) MdFormatToolbar(session: session),
          ],
        );
      },
    );
  }
}

enum _MenuAction {
  saveAs,
  replace,
  info,
  split,
  merge,
  share,
  shareZip,
  print,
  export,
}

class _OverflowMenu extends ConsumerWidget {
  final DocumentTab tab;
  final MdDocumentSession session;
  final bool enabled;

  const _OverflowMenu({
    required this.tab,
    required this.session,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editing = session.mode == MdMode.edit && !tab.isReadOnly;
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<_MenuAction>(
      key: const Key('md-overflow-menu'),
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
            title: Text(l10n.mdSplitByHeading),
          ),
        ),
        if (editing)
          PopupMenuItem(
            value: _MenuAction.merge,
            child: ListTile(
              leading: const Icon(Icons.merge_type),
              title: Text(l10n.mdAppendFile),
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
        await showMdSaveOptionsSheet(context, session);
        break;
      case _MenuAction.replace:
        session.openReplace();
        break;
      case _MenuAction.info:
        await showMdInfoSheet(context, session);
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
        await showMdExportSheet(
          context,
          session,
          _output(ref),
          ref.read(exportServiceProvider),
        );
        break;
    }
  }

  MdSplitMergeActions _actions(WidgetRef ref) => MdSplitMergeActions(
        saf: ref.read(safServiceProvider),
        codec: ref.read(textCodecServiceProvider),
      );

  MdOutputActions _output(WidgetRef ref) => MdOutputActions(
        share: ref.read(shareServiceProvider),
        zip: ref.read(zipServiceProvider),
        print: ref.read(printServiceProvider),
        export: ref.read(exportServiceProvider),
        saf: ref.read(safServiceProvider),
        codec: ref.read(textCodecServiceProvider),
      );
}
