import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/editor/atomic_saver.dart';
import 'package:sreerajp_textapp/core/editor/pinch_to_zoom_area.dart';
import 'package:sreerajp_textapp/core/editor/unsaved_changes.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_controller.dart';
import 'package:sreerajp_textapp/core/large_file/large_file_policy.dart';
import 'package:sreerajp_textapp/core/vault/ui/vault_unlock_view.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/formats/csv/csv_document_view.dart';
import 'package:sreerajp_textapp/formats/csv/csv_session_manager.dart';
import 'package:sreerajp_textapp/formats/csv/csv_toolbar.dart';
import 'package:sreerajp_textapp/formats/format_dispatch.dart';
import 'package:sreerajp_textapp/formats/json/json_document_view.dart';
import 'package:sreerajp_textapp/formats/json/json_session_manager.dart';
import 'package:sreerajp_textapp/formats/json/json_toolbar.dart';
import 'package:sreerajp_textapp/formats/markdown/md_document_view.dart';
import 'package:sreerajp_textapp/formats/markdown/md_session_manager.dart';
import 'package:sreerajp_textapp/formats/markdown/md_toolbar.dart';
import 'package:sreerajp_textapp/formats/txt/txt_document_view.dart';
import 'package:sreerajp_textapp/formats/txt/txt_session_manager.dart';
import 'package:sreerajp_textapp/formats/txt/txt_toolbar.dart';
import 'package:sreerajp_textapp/formats/xml/xml_document_view.dart';
import 'package:sreerajp_textapp/formats/xml/xml_session_manager.dart';
import 'package:sreerajp_textapp/formats/xml/xml_toolbar.dart';
import 'package:sreerajp_textapp/shell/shell_providers.dart';
import 'package:sreerajp_textapp/shell/tabs/degraded_document_view.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/file_changed_banner.dart';
import 'package:sreerajp_textapp/shell/tabs/placeholder_document_view.dart';
import 'package:sreerajp_textapp/shell/tabs/read_only_lock_button.dart';
import 'package:sreerajp_textapp/shell/tabs/session_retention.dart';
import 'package:sreerajp_textapp/shell/tabs/tab_strip.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/shell/tabs/unsaved_changes_dialog.dart';

/// The open-documents workspace: the tab strip plus the active document body,
/// with edge-bound left/right swipe to move between tabs (tasks 2.5, 2.7).
///
/// The swipe is bound to thin **edge zones**, not the whole body, so on a
/// format that scrolls horizontally (a wide CSV grid, later) the tab-switch
/// gesture does not fight content scrolling (architecture.md §5).
class TabsWorkspace extends ConsumerStatefulWidget {
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
  ConsumerState<TabsWorkspace> createState() => _TabsWorkspaceState();
}

class _TabsWorkspaceState extends ConsumerState<TabsWorkspace> {
  /// Set when the workspace has just become empty, so the shell can leave the
  /// Editor once the frame is done.
  bool _leaveEditorWhenIdle = false;

  bool _cleanUpScheduled = false;

  @override
  void initState() {
    super.initState();
    // Sessions can outlive a rebuild of this screen (they live in the managers),
    // so tidy up once on the way in too.
    _scheduleCleanUp();
  }

  /// Runs the session clean-up **after** the current frame.
  ///
  /// Closing a tab disposes its document session, and with it the editor
  /// controllers the screen is still holding on to. Doing that inside `build()`
  /// pulls the ground out from under the widget being built — which threw, and a
  /// release build paints a thrown build as a plain grey box. Waiting for the
  /// frame to finish means the closed document is already off the screen.
  void _scheduleCleanUp() {
    if (_cleanUpScheduled) return;
    _cleanUpScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanUpScheduled = false;
      if (!mounted) return;
      _cleanUpAfterFrame();
    });
  }

  void _cleanUpAfterFrame() {
    final state = ref.read(tabsControllerProvider);
    final openIds = state.tabs.map((t) => t.id).toSet();

    // Free the editor state (and auto-save timers) of any tab that has closed.
    ref.read(txtSessionManagerProvider).retainOnly(openIds);
    ref.read(mdSessionManagerProvider).retainOnly(openIds);
    ref.read(jsonSessionManagerProvider).retainOnly(openIds);
    ref.read(csvSessionManagerProvider).retainOnly(openIds);
    ref.read(xmlSessionManagerProvider).retainOnly(openIds);

    // Burn the traces of any ephemeral tab that left the workspace by another
    // route — the × button, "close all", or the tab cap closing the least
    // recently used one (Feature 9). How the tab closed does not change the
    // user's instruction that this document leave nothing behind.
    unawaited(
      ref.read(ephemeralControllerProvider.notifier).syncOpenTabs(openIds),
    );

    // Release heavy state for clean background tabs beyond the loaded budget,
    // so several large files stay in check (Phase 10.3). They rebuild from the
    // file when shown again.
    _releaseBackgroundSessions(ref, state);

    // The last tab just closed: there is nothing to edit, so go back to Home
    // instead of leaving the user on an empty screen.
    if (_leaveEditorWhenIdle) {
      _leaveEditorWhenIdle = false;
      if (state.isEmpty &&
          ref.read(shellDestinationProvider) == ShellDestination.editor) {
        ref
            .read(shellDestinationProvider.notifier)
            .select(ShellDestination.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Every change to the tab set needs a clean-up pass; it runs after the
    // frame, never during it.
    ref.listen(tabsControllerProvider, (previous, next) {
      if (previous != null && previous.tabs.isNotEmpty && next.tabs.isEmpty) {
        _leaveEditorWhenIdle = true;
      }
      _scheduleCleanUp();
    });

    final state = ref.watch(tabsControllerProvider);
    final controller = ref.read(tabsControllerProvider.notifier);

    if (state.isEmpty) {
      return const SafeArea(child: _NoOpenTabs());
    }

    final active = state.activeTab;
    return _EditModeBackGuard(
      tab: active,
      child: SafeArea(
        child: Column(
          children: [
            TabStrip(onRequestClose: (tab) => _confirmClose(context, ref, tab)),
            if (active != null) _DocumentToolbar(tab: active),
            if (active != null && active.isReadOnly) const ReadOnlyBanner(),
            // Warns when another app changed the file behind this tab, and offers
            // to load the fresh content. Shows nothing until that happens.
            if (active != null) FileChangedBanner(tab: active),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: active == null
                        ? const SizedBox.shrink()
                        : PinchToZoomArea(child: _DocumentBody(tab: active)),
                  ),
                  Positioned(
                    key: const Key('tab-swipe-left-edge'),
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: TabsWorkspace.edgeWidth,
                    child: _EdgeSwipeZone(
                      onFling: (v) => _onFling(controller, v),
                    ),
                  ),
                  Positioned(
                    key: const Key('tab-swipe-right-edge'),
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: TabsWorkspace.edgeWidth,
                    child: _EdgeSwipeZone(
                      onFling: (v) => _onFling(controller, v),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Applies the retention policy: drops heavy state for clean, non-active,
  /// least-recently-used sessions beyond [TabsWorkspace._maxLoadedSessions]. Dirty tabs and
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
    if (live.length <= TabsWorkspace._maxLoadedSessions) return;

    final recency = [...state.tabs]
      ..sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
    final releasable = pickReleasableSessions(
      liveSessionIds: live,
      recencyOrder: recency.map((t) => t.id).toList(growable: false),
      activeId: state.activeTab?.id,
      dirtyIds: state.tabs.where((t) => t.isDirty).map((t) => t.id).toSet(),
      keepAlive: TabsWorkspace._maxLoadedSessions,
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
    if (velocity <= -TabsWorkspace._flingThreshold) {
      controller.next();
    } else if (velocity >= TabsWorkspace._flingThreshold) {
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
  static _TabSaver? _saverFor(WidgetRef ref, DocumentTab tab) {
    switch (detectFormat(tab)) {
      case DocumentFormat.txt:
        final s = ref.read(txtSessionManagerProvider).peek(tab.id);
        return s == null
            ? null
            : _TabSaver.of(
                s.save,
                s.saveAsCopy,
                s.reloadFromDisk,
                s.discardDraft,
              );
      case DocumentFormat.markdown:
        final s = ref.read(mdSessionManagerProvider).peek(tab.id);
        return s == null
            ? null
            : _TabSaver.of(
                s.save,
                s.saveAsCopy,
                s.reloadFromDisk,
                s.discardDraft,
              );
      case DocumentFormat.json:
        final s = ref.read(jsonSessionManagerProvider).peek(tab.id);
        return s == null
            ? null
            : _TabSaver.of(
                s.save,
                s.saveAsCopy,
                s.reloadFromDisk,
                s.discardDraft,
              );
      case DocumentFormat.csv:
        final s = ref.read(csvSessionManagerProvider).peek(tab.id);
        return s == null
            ? null
            : _TabSaver.of(
                s.save,
                s.saveAsCopy,
                s.reloadFromDisk,
                s.discardDraft,
              );
      case DocumentFormat.xml:
        final s = ref.read(xmlSessionManagerProvider).peek(tab.id);
        return s == null
            ? null
            : _TabSaver.of(
                s.save,
                s.saveAsCopy,
                s.reloadFromDisk,
                s.discardDraft,
              );
      default:
        return null;
    }
  }

  static Future<SaveResult> _saveOnClose(_TabSaver saver) async {
    final result = await saver.save();
    // A read-only overwrite falls back to a copy so the edits still land.
    if (result.outcome == SaveOutcome.readOnlyNeedsCopy) {
      return saver.saveAsCopy();
    }
    return result;
  }
}

/// Makes the Android back button leave **edit mode** before it leaves the
/// screen.
///
/// Edit mode used to be a one-way door: the only way out was a toolbar toggle
/// that people did not read as an exit. Back is the gesture everyone already
/// reaches for, so it is wired to the same thing here.
///
/// A tab with unsaved edits goes through the very same prompt the tab-close
/// guard uses, so leaving by back and leaving by close behave alike and no work
/// is ever dropped without being asked about (CLAUDE.md §3.6). When the tab is
/// not being edited this widget is transparent — back pops as it always did.
///
/// It listens to the active document's session so `canPop` is recomputed the
/// moment the mode changes; without that the first back press after entering
/// edit mode would still leave the screen.
class _EditModeBackGuard extends ConsumerWidget {
  final DocumentTab? tab;
  final Widget child;

  const _EditModeBackGuard({required this.tab, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = this.tab;
    if (tab == null) return child;
    // An oversized file opens in the degraded, read-only view and never builds
    // a heavy format session (Phase 10.2). It cannot be in edit mode, so do not
    // build one here just to watch it.
    if (LargeFilePolicy.isOversized(tab.size)) return child;
    final listenable = tabSessionListenable(ref, tab);
    if (listenable == null) return child;
    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final editing = isTabEditing(ref, tab);
        return PopScope(
          canPop: !editing,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            unawaited(_leaveEditMode(context, ref, tab));
          },
          child: child,
        );
      },
    );
  }

  /// Leaves edit mode, asking about unsaved edits first.
  ///
  /// Nothing here discards work on its own: "Discard" is an explicit choice, a
  /// failed save keeps the user in edit mode with the reason shown, and Cancel
  /// changes nothing.
  Future<void> _leaveEditMode(
    BuildContext context,
    WidgetRef ref,
    DocumentTab tab,
  ) async {
    if (!tab.isDirty) {
      exitTabEditMode(ref, tab);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final saver = _TabsWorkspaceState._saverFor(ref, tab);
    if (saver == null) {
      // No live session to save from; the text cannot be at risk either.
      exitTabEditMode(ref, tab);
      return;
    }

    final action = await showUnsavedChangesDialog(
      context,
      fileName: tab.displayName,
      canOverwrite: !tab.isReadOnly,
    );
    switch (action) {
      case UnsavedChangesAction.cancel:
        return; // stay in edit mode, nothing changed
      case UnsavedChangesAction.discard:
        // The tab stays open, so "discard" has to actually put the file's own
        // content back — and drop the draft, or the banner would offer the
        // thrown-away text again on the next open.
        await saver.revert();
        await saver.discardDraft();
        exitTabEditMode(ref, tab);
      case UnsavedChangesAction.save:
      case UnsavedChangesAction.saveAsCopy:
        final result = action == UnsavedChangesAction.save
            ? await _TabsWorkspaceState._saveOnClose(saver)
            : await saver.saveAsCopy();
        if (result.succeeded) {
          exitTabEditMode(ref, tab);
          return;
        }
        if (result.outcome != SaveOutcome.cancelled) {
          messenger.showSnackBar(
            SnackBar(content: Text(result.message ?? l10n.tabCouldNotSave)),
          );
        }
      // Anything other than a real save keeps the user in edit mode.
    }
  }
}

/// A minimal interface shared by the format sessions, used by the tab-close
/// guard and the leave-edit-mode guard so neither needs to know which format a
/// tab holds.
///
/// [revert] throws unsaved edits away by reloading the file from disk, and
/// [discardDraft] drops the crash-recovery draft that went with them — together
/// they are what "Discard" means for a tab that stays open.
class _TabSaver {
  final Future<SaveResult> Function() save;
  final Future<SaveResult> Function() saveAsCopy;
  final Future<bool> Function() revert;
  final Future<void> Function() discardDraft;
  const _TabSaver.of(
    this.save,
    this.saveAsCopy,
    this.revert,
    this.discardDraft,
  );
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
      case DocumentFormat.vault:
        return VaultUnlockView(tab: tab);
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
    return DecoratedBox(
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
