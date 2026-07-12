import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tabs_controller.dart';

/// A lock toggle for the active document (task 3.8).
///
/// When a tab is locked it shows a filled lock icon and the editor rejects
/// edits; tapping unlocks it. When unlocked it shows an open lock. The label is
/// there for screen readers (architecture.md §6). Nothing shows when no tab is
/// open.
class ReadOnlyLockButton extends ConsumerWidget {
  const ReadOnlyLockButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tabsControllerProvider);
    final tab = state.activeTab;
    if (tab == null) return const SizedBox.shrink();

    final locked = tab.isReadOnly;
    return IconButton(
      key: const Key('read-only-lock-button'),
      tooltip: locked ? 'Unlock editing' : 'Lock (read-only)',
      isSelected: locked,
      icon: const Icon(Icons.lock_open_outlined),
      selectedIcon: const Icon(Icons.lock_outline),
      onPressed: () =>
          ref.read(tabsControllerProvider.notifier).toggleReadOnly(tab.id),
    );
  }
}

/// A small inline banner shown at the top of a locked document so the "locked"
/// state is obvious, not just an icon (architecture.md §6).
class ReadOnlyBanner extends StatelessWidget {
  const ReadOnlyBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const Key('read-only-banner'),
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline,
              size: 16, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Text(
            'Read-only — editing is locked',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSecondaryContainer),
          ),
        ],
      ),
    );
  }
}
