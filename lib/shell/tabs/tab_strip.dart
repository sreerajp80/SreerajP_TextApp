import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'document_tab.dart';
import 'tabs_controller.dart';

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
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case _TabMenuAction.closeOthers:
        final blocked = controller.closeOthers(tab.id);
        _notifyBlocked(messenger, blocked.length);
        break;
      case _TabMenuAction.closeAll:
        final blocked = controller.closeAll();
        _notifyBlocked(messenger, blocked.length);
        break;
    }
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

enum _TabMenuAction { closeOthers, closeAll }

class _TabChip extends StatelessWidget {
  final DocumentTab tab;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClose;
  final void Function(_TabMenuAction action) onMenu;

  const _TabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
    required this.onClose,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final color =
        selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
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
                color: selected ? theme.colorScheme.primary : Colors.transparent,
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
              Flexible(
                child: Text(
                  tab.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
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
      ],
    );
    if (action != null) onMenu(action);
  }
}
