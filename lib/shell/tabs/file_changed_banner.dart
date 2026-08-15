import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/editor/external_change.dart';
import 'package:text_data/formats/csv/csv_session_manager.dart';
import 'package:text_data/formats/format_dispatch.dart';
import 'package:text_data/formats/json/json_session_manager.dart';
import 'package:text_data/formats/markdown/md_session_manager.dart';
import 'package:text_data/formats/txt/txt_session_manager.dart';
import 'package:text_data/formats/xml/xml_session_manager.dart';
import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/shell/tabs/document_tab.dart';

/// Warns that the file behind the active tab changed on disk, and offers to load
/// the fresh content.
///
/// The tab keeps the content it loaded, so without this the user would silently
/// look at a stale document. Nothing shows until a change is actually spotted.
///
/// When the check runs:
///
/// * when the app comes back to the **foreground** — the common case, where the
///   user edited the file in another app and came back;
/// * when this tab is **focused** — switched to, or re-opened from Home.
///
/// Only the active tab is checked, so a workspace full of tabs does not fire a
/// burst of platform calls.
class FileChangedBanner extends ConsumerStatefulWidget {
  /// The active tab. A change of [DocumentTab.id] or [DocumentTab.lastActiveAt]
  /// counts as a focus event and triggers a fresh check.
  final DocumentTab tab;

  /// Test seam: how to find the document for [tab]. The app leaves this null and
  /// the banner asks the format session managers.
  final ReloadableDocument? Function(WidgetRef ref, DocumentTab tab)?
  resolveDocument;

  const FileChangedBanner({super.key, required this.tab, this.resolveDocument});

  @override
  ConsumerState<FileChangedBanner> createState() => _FileChangedBannerState();
}

class _FileChangedBannerState extends ConsumerState<FileChangedBanner>
    with WidgetsBindingObserver {
  ReloadableDocument? _doc;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleSync();
  }

  @override
  void didUpdateWidget(FileChangedBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focused =
        oldWidget.tab.id != widget.tab.id ||
        oldWidget.tab.lastActiveAt != widget.tab.lastActiveAt;
    if (focused) _scheduleSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _scheduleSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Resolves the session and runs the check after the current frame: the
  /// document body creates its session while building, so it may not exist yet
  /// while this banner builds.
  void _scheduleSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final doc = _resolve();
      if (doc != _doc) setState(() => _doc = doc);
      doc?.checkForExternalChange();
    });
  }

  /// The active tab's session as a format-agnostic [ReloadableDocument], or null
  /// when the format has no session (placeholder or oversized file).
  ReloadableDocument? _resolve() {
    final override = widget.resolveDocument;
    if (override != null) return override(ref, widget.tab);
    final id = widget.tab.id;
    return switch (detectFormat(widget.tab)) {
      DocumentFormat.txt => ref.read(txtSessionManagerProvider).peek(id),
      DocumentFormat.markdown => ref.read(mdSessionManagerProvider).peek(id),
      DocumentFormat.json => ref.read(jsonSessionManagerProvider).peek(id),
      DocumentFormat.csv => ref.read(csvSessionManagerProvider).peek(id),
      DocumentFormat.xml => ref.read(xmlSessionManagerProvider).peek(id),
      _ => null,
    };
  }

  Future<void> _reload(ReloadableDocument doc) async {
    if (_reloading) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    // Reloading throws unsaved edits away, so it must be confirmed first
    // (CLAUDE.md §3.6 — never lose edits silently).
    if (doc.isDirty) {
      final confirmed = await _confirmDiscard();
      if (!confirmed) return;
    }

    setState(() => _reloading = true);
    final ok = await doc.reloadFromDisk();
    if (!mounted) return;
    setState(() => _reloading = false);
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.fileChangedReloadFailed)),
      );
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final answer = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('file-changed-confirm-dialog'),
        title: Text(l10n.fileChangedConfirmTitle),
        content: Text(l10n.fileChangedConfirmBody(widget.tab.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.fileChangedConfirmCancel),
          ),
          TextButton(
            key: const Key('file-changed-confirm-reload'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.fileChangedConfirmReload),
          ),
        ],
      ),
    );
    return answer ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    if (doc == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: doc,
      builder: (context, _) {
        if (!doc.externalChangeDetected) return const SizedBox.shrink();
        return _Banner(
          busy: _reloading,
          onReload: () => _reload(doc),
          onDismiss: doc.dismissExternalChange,
        );
      },
    );
  }
}

/// The visible strip: a short warning plus Reload and Dismiss. Styled like the
/// read-only banner so the two read as one family.
class _Banner extends StatelessWidget {
  final bool busy;
  final VoidCallback onReload;
  final VoidCallback onDismiss;

  const _Banner({
    required this.busy,
    required this.onReload,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final onColor = theme.colorScheme.onTertiaryContainer;
    return Container(
      key: const Key('file-changed-banner'),
      width: double.infinity,
      color: theme.colorScheme.tertiaryContainer,
      padding: const EdgeInsets.only(left: 12, right: 4),
      child: Row(
        children: [
          Icon(Icons.sync_problem_outlined, size: 16, color: onColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.fileChangedBanner,
              style: theme.textTheme.bodySmall?.copyWith(color: onColor),
            ),
          ),
          TextButton(
            key: const Key('file-changed-reload-button'),
            onPressed: busy ? null : onReload,
            child: Text(l10n.fileChangedReload),
          ),
          IconButton(
            key: const Key('file-changed-dismiss-button'),
            tooltip: l10n.fileChangedDismiss,
            iconSize: 18,
            color: onColor,
            onPressed: busy ? null : onDismiss,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
