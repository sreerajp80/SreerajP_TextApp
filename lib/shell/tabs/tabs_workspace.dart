import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/editor/atomic_saver.dart';
import '../../core/editor/unsaved_changes.dart';
import '../../core/large_file/large_file_policy.dart';
import '../../l10n/app_localizations.dart';
import '../../formats/csv/csv_document_view.dart';
import '../../formats/csv/csv_session_manager.dart';
import '../../formats/csv/csv_toolbar.dart';
import '../../formats/format_dispatch.dart';
import '../../formats/json/json_document_view.dart';
import '../../formats/json/json_session_manager.dart';
import '../../formats/json/json_toolbar.dart';
import '../../formats/markdown/md_document_view.dart';
import '../../formats/markdown/md_session_manager.dart';
import '../../formats/markdown/md_toolbar.dart';
import '../../formats/txt/txt_document_view.dart';
import '../../formats/txt/txt_session_manager.dart';
import '../../formats/txt/txt_toolbar.dart';
import '../../formats/xml/xml_document_view.dart';
import '../../formats/xml/xml_session_manager.dart';
import '../../formats/xml/xml_toolbar.dart';
import 'degraded_document_view.dart';
import 'document_tab.dart';
import 'placeholder_document_view.dart';
import 'read_only_lock_button.dart';
import 'session_retention.dart';
import 'tab_strip.dart';
import 'tabs_controller.dart';
import 'unsaved_changes_dialog.dart';

/// The open-documents workspace: the tab strip plus the active document body,
/// with edge-bound left/right swipe to move between tabs (tasks 2.5, 2.7).
///
/// The swipe is bound to thin **edge zones**, not the whole body, so on a
/// format that scrolls horizontally (a wide CSV grid, later) the tab-switch
/// gesture does not fight content scrolling (architecture.md §5).
class TabsWorkspace extends ConsumerWidget {
  const TabsWorkspace({super.key});

  /// Width of the left/right edge zones that own the swipe gesture.
  static const double edgeWidth = 28;

  /// Minimum fling speed (px/s) that counts as a tab switch.
  static const double _flingThreshold = 250;

  /// How many heavy document sessions to keep loaded at once. Background tabs
  /// beyond this budget release their state and rebuild from the file when the
  /// user returns (Phase 10.3). The active and any unsaved (dirty) tab are
  /// always kept.
  static const int _maxLoadedSessions = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tabsControllerProvider);
    final controller = ref.read(tabsControllerProvider.notifier);

    // Free the editor state (and auto-save timers) of any tab that has closed.
    final openIds = state.tabs.map((t) => t.id).toSet();
    ref.read(txtSessionManagerProvider).retainOnly(openIds);
    ref.read(mdSessionManagerProvider).retainOnly(openIds);
    ref.read(jsonSessionManagerProvider).retainOnly(openIds);
    ref.read(csvSessionManagerProvider).retainOnly(openIds);
    ref.read(xmlSessionManagerProvider).retainOnly(openIds);

    // Release heavy state for clean background tabs beyond the loaded budget,
    // so several large files stay in check (Phase 10.3). They rebuild from the
    // file when shown again.
    _releaseBackgroundSessions(ref, state);

    if (state.isEmpty) {
      return const SafeArea(child: _NoOpenTabs());
    }

    final active = state.activeTab;
    return SafeArea(
      child: Column(
        children: [
          TabStrip(onRequestClose: (tab) => _confirmClose(context, ref, tab)),
          if (active != null) _DocumentToolbar(tab: active),
          if (active != null && active.isReadOnly) const ReadOnlyBanner(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: active == null
                      ? const SizedBox.shrink()
                      : _DocumentBody(tab: active),
                ),
                Positioned(
                  key: const Key('tab-swipe-left-edge'),
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: edgeWidth,
                  child: _EdgeSwipeZone(
                    onFling: (v) => _onFling(controller, v),
                  ),
                ),
                Positioned(
                  key: const Key('tab-swipe-right-edge'),
                  top: 0,
                  bottom: 0,
                  right: 0,
                  width: edgeWidth,
                  child: _EdgeSwipeZone(
                    onFling: (v) => _onFling(controller, v),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Applies the retention policy: drops heavy state for clean, non-active,
  /// least-recently-used sessions beyond [_maxLoadedSessions]. Dirty tabs and
  /// the active tab are never released (edits are never lost — CLAUDE.md §3.6).
  void _releaseBackgroundSessions(WidgetRef ref, TabsState state) {
    final txt = ref.read(txtSessionManagerProvider);
    final md = ref.read(mdSessionManagerProvider);
    final json = ref.read(jsonSessionManagerProvider);
    final csv = ref.read(csvSessionManagerProvider);
    final xml = ref.read(xmlSessionManagerProvider);

    final live = <String>{
      ...txt.liveIds,
      ...md.liveIds,
      ...json.liveIds,
      ...csv.liveIds,
      ...xml.liveIds,
    };
    if (live.length <= _maxLoadedSessions) return;

    final recency = [...state.tabs]
      ..sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
    final releasable = pickReleasableSessions(
      liveSessionIds: live,
      recencyOrder: recency.map((t) => t.id).toList(growable: false),
      activeId: state.activeTab?.id,
      dirtyIds: state.tabs.where((t) => t.isDirty).map((t) => t.id).toSet(),
      keepAlive: _maxLoadedSessions,
    );

    // A tab belongs to exactly one format, so releasing on every manager is
    // safe — only the owning manager holds the id.
    for (final id in releasable) {
      txt.release(id);
      md.release(id);
      json.release(id);
      csv.release(id);
      xml.release(id);
    }
  }

  void _onFling(TabsController controller, double velocity) {
    if (velocity <= -_flingThreshold) {
      controller.next();
    } else if (velocity >= _flingThreshold) {
      controller.prev();
    }
  }

  /// Prompt shown before closing a tab with unsaved edits (task 3.7). Offers
  /// Save / Save as a copy / Discard and returns true only when the tab should
  /// close now.
  ///
  /// Discard closes immediately. Save / Save as a copy run through the TXT
  /// document session's atomic saver; a failed save keeps the tab open with a
  /// notice so edits are never lost silently (CLAUDE.md §3.6). A read-only tab is
  /// offered a copy only.
  Future<bool> _confirmClose(
    BuildContext context,
    WidgetRef ref,
    DocumentTab tab,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final action = await showUnsavedChangesDialog(
      context,
      fileName: tab.displayName,
      canOverwrite: !tab.isReadOnly,
    );
    switch (action) {
      case UnsavedChangesAction.discard:
        return true;
      case UnsavedChangesAction.cancel:
        return false;
      case UnsavedChangesAction.save:
      case UnsavedChangesAction.saveAsCopy:
        final saver = _saverFor(ref, tab);
        if (saver == null) return false; // nothing to save (shouldn't happen)
        final result = action == UnsavedChangesAction.save
            ? await _saveOnClose(saver)
            : await saver.saveAsCopy();
        if (result.succeeded) return true;
        if (result.outcome != SaveOutcome.cancelled) {
          messenger.showSnackBar(
            SnackBar(content: Text(result.message ?? l10n.tabCouldNotSave)),
          );
        }
        return false;
    }
  }

  /// Resolves the format-specific document session for [tab] as a small
  /// save-capable interface, so the close guard works for any editable format.
  _CloseSaver? _saverFor(WidgetRef ref, DocumentTab tab) {
    switch (detectFormat(tab)) {
      case DocumentFormat.txt:
        final s = ref.read(txtSessionManagerProvider).peek(tab.id);
        return s == null ? null : _CloseSaver(s.save, s.saveAsCopy);
      case DocumentFormat.markdown:
        final s = ref.read(mdSessionManagerProvider).peek(tab.id);
        return s == null ? null : _CloseSaver(s.save, s.saveAsCopy);
      case DocumentFormat.json:
        final s = ref.read(jsonSessionManagerProvider).peek(tab.id);
        return s == null ? null : _CloseSaver(s.save, s.saveAsCopy);
      case DocumentFormat.csv:
        final s = ref.read(csvSessionManagerProvider).peek(tab.id);
        return s == null ? null : _CloseSaver(s.save, s.saveAsCopy);
      case DocumentFormat.xml:
        final s = ref.read(xmlSessionManagerProvider).peek(tab.id);
        return s == null ? null : _CloseSaver(s.save, s.saveAsCopy);
      default:
        return null;
    }
  }

  Future<SaveResult> _saveOnClose(_CloseSaver saver) async {
    final result = await saver.save();
    // A read-only overwrite falls back to a copy so the edits still land.
    if (result.outcome == SaveOutcome.readOnlyNeedsCopy) {
      return saver.saveAsCopy();
    }
    return result;
  }
}

/// A minimal save interface shared by the format sessions, used by the tab-close
/// guard so it does not need to know which format a tab holds.
class _CloseSaver {
  final Future<SaveResult> Function() save;
  final Future<SaveResult> Function() saveAsCopy;
  const _CloseSaver(this.save, this.saveAsCopy);
}

/// The body for the active tab: the TXT viewer/editor for text files, the
/// placeholder for formats whose module has not landed yet (Phases 6–9).
class _DocumentBody extends StatelessWidget {
  final DocumentTab tab;

  const _DocumentBody({required this.tab});

  @override
  Widget build(BuildContext context) {
    // A file above the comfortable size limit opens in the degraded, paged,
    // read-only view instead of building a heavy format session (Phase 10.2).
    if (LargeFilePolicy.isOversized(tab.size)) {
      return DegradedDocumentView(tab: tab);
    }
    switch (detectFormat(tab)) {
      case DocumentFormat.txt:
        return TxtDocumentView(tab: tab);
      case DocumentFormat.markdown:
        return MdDocumentView(tab: tab);
      case DocumentFormat.json:
        return JsonDocumentView(tab: tab);
      case DocumentFormat.csv:
        return CsvDocumentView(tab: tab);
      case DocumentFormat.xml:
        return XmlDocumentView(tab: tab);
      default:
        return PlaceholderDocumentView(tab: tab);
    }
  }
}

/// A thin action bar above the active document. For a TXT file it shows the full
/// editor toolbar (tasks 4.1–4.5); for other formats it shows just the read-only
/// lock until that format's module lands.
class _DocumentToolbar extends StatelessWidget {
  final DocumentTab tab;

  const _DocumentToolbar({required this.tab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // An oversized file has no editor toolbar — it is read-only (Phase 10.2).
    final format = LargeFilePolicy.isOversized(tab.size)
        ? DocumentFormat.other
        : detectFormat(tab);
    final Widget content = switch (format) {
      DocumentFormat.txt => Align(
        alignment: Alignment.centerRight,
        child: TxtToolbar(tab: tab),
      ),
      DocumentFormat.markdown => Align(
        alignment: Alignment.centerRight,
        child: MdToolbar(tab: tab),
      ),
      DocumentFormat.json => Align(
        alignment: Alignment.centerRight,
        child: JsonToolbar(tab: tab),
      ),
      DocumentFormat.csv => Align(
        alignment: Alignment.centerRight,
        child: CsvToolbar(tab: tab),
      ),
      DocumentFormat.xml => Align(
        alignment: Alignment.centerRight,
        child: XmlToolbar(tab: tab),
      ),
      _ => const Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [ReadOnlyLockButton()],
      ),
    };
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: content,
    );
  }
}

class _EdgeSwipeZone extends StatelessWidget {
  final void Function(double velocity) onFling;

  const _EdgeSwipeZone({required this.onFling});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) => onFling(details.primaryVelocity ?? 0),
      child: const SizedBox.expand(),
    );
  }
}

class _NoOpenTabs extends StatelessWidget {
  const _NoOpenTabs();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tab_unselected,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(l10n.tabNoDocuments, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.tabOpenFromHome,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
