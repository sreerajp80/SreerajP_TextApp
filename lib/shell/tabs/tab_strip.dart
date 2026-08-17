import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/ephemeral/ephemeral_badge.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_controller.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_sheet.dart';
import 'package:sreerajp_textapp/core/ephemeral/ephemeral_settings.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';

/// The horizontal strip of open-document tabs (architecture.md §5).
///
/// Tap a tab to switch; the close (×) button closes it. A long-press / menu
/// offers "Close others" and "Close all". An unsaved tab shows a dot and, on
/// close, asks the caller to confirm via [onRequestClose] so edits are never
/// lost silently (CLAUDE.md §3.6).
class TabStrip extends ConsumerWidget {
  /// Called when a tab that may need a prompt is asked to close. Returns true if
  /// it should actually close. For a clean tab this is not called.
  final Future<bool> Function(DocumentTab tab) onRequestClose;

  const TabStrip({super.key, required this.onRequestClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tabsControllerProvider);
    final controller = ref.read(tabsControllerProvider.notifier);
    final ephemeral = ref.watch(ephemeralControllerProvider);
    final theme = Theme.of(context);

    if (state.tabs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.tabs.length,
        itemBuilder: (context, i) {
          final tab = state.tabs[i];
          final selected = tab.id == state.activeId;
          return _TabChip(
            tab: tab,
            selected: selected,
            isEphemeral: ephemeral.marks.containsKey(tab.id),
            onTap: () => controller.setActive(tab.id),
            onClose: () async {
              if (tab.isDirty) {
                final ok = await onRequestClose(tab);
                if (ok) controller.closeTab(tab.id, force: true);
              } else {
                controller.closeTab(tab.id);
              }
            },
            onMenu: (action) => _handleMenu(context, ref, tab, action),
          );
        },
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    DocumentTab tab,
    _TabMenuAction action,
  ) async {
    final controller = ref.read(tabsControllerProvider.notifier);
    final ephemeral = ref.read(ephemeralControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    switch (action) {
      case _TabMenuAction.closeOthers:
        final blocked = controller.closeOthers(tab.id);
        _notifyBlocked(messenger, blocked.length);
        break;
      case _TabMenuAction.closeAll:
        final blocked = controller.closeAll();
        _notifyBlocked(messenger, blocked.length);
        break;
      case _TabMenuAction.ephemeral:
        final option = await showEphemeralSheet(
          context,
          fileName: tab.displayName,
          // Seed the sheet with the tab's own settings when it is already
          // ephemeral, so "change" starts from what is in force.
          initial: ref.read(ephemeralSettingsProvider),
        );
        if (option == null) return;
        ephemeral.mark(tab, option);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.ephemeralMarked(tab.displayName))),
        );
        break;
      case _TabMenuAction.keepTab:
        ephemeral.cancel(tab.id);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.ephemeralCancelled(tab.displayName))),
        );
        break;
      case _TabMenuAction.burnNow:
        final confirmed = await _confirmBurn(context, tab.displayName);
        if (!confirmed) return;
        final failures = await ephemeral.burn(tab.id);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              failures.isEmpty
                  ? l10n.ephemeralBurned(tab.displayName)
                  : l10n.ephemeralBurnedPartly(tab.displayName),
            ),
          ),
        );
        break;
    }
  }

  /// Confirms a manual burn. Destroying a document on one menu tap, with unsaved
  /// edits going with it, is worth one question.
  Future<bool> _confirmBurn(BuildContext context, String fileName) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ephemeralBurnNowTitle),
        content: Text(l10n.ephemeralBurnNowBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionBurn),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _notifyBlocked(ScaffoldMessengerState messenger, int count) {
    if (count == 0) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '$count tab${count == 1 ? '' : 's'} with unsaved edits '
          'left open.',
        ),
      ),
    );
  }
}

enum _TabMenuAction {
  closeOthers,
  closeAll,

  /// Open the self-destruct sheet (Feature 9) — for a normal tab, or to change
  /// the settings of one that is already ephemeral.
  ephemeral,

  /// Drop the ephemeral mark and keep the tab as a normal one.
  keepTab,

  /// Burn the tab right now.
  burnNow,
}

class _TabChip extends StatelessWidget {
  final DocumentTab tab;
  final bool selected;

  /// Whether this tab is marked to self-destruct (Feature 9). Drives which
  /// items the long-press menu offers.
  final bool isEphemeral;

  final VoidCallback onTap;
  final VoidCallback onClose;
  final void Function(_TabMenuAction action) onMenu;

  const _TabChip({
    required this.tab,
    required this.selected,
    required this.isEphemeral,
    required this.onTap,
    required this.onClose,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: GestureDetector(
        onLongPress: () => _showMenu(context),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 200),
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (tab.isDirty)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(Icons.circle, size: 8, color: color),
                ),
              // Draws nothing unless the tab is ephemeral (Feature 9).
              EphemeralBadge(tabId: tab.id),
              Flexible(
                child: Text(
                  tab.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.tabClose,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;
    final l10n = AppLocalizations.of(context);
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final action = await showMenu<_TabMenuAction>(
      context: context,
      position: position,
      items: [
        PopupMenuItem(
          value: _TabMenuAction.closeOthers,
          child: Text(l10n.tabCloseOthers),
        ),
        PopupMenuItem(
          value: _TabMenuAction.closeAll,
          child: Text(l10n.tabCloseAll),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _TabMenuAction.ephemeral,
          child: Text(
            isEphemeral ? l10n.tabChangeEphemeral : l10n.tabMakeEphemeral,
          ),
        ),
        if (isEphemeral) ...[
          PopupMenuItem(
            value: _TabMenuAction.keepTab,
            child: Text(l10n.tabCancelEphemeral),
          ),
          PopupMenuItem(
            value: _TabMenuAction.burnNow,
            child: Text(l10n.tabBurnNow),
          ),
        ],
      ],
    );
    if (action != null) onMenu(action);
  }
}
