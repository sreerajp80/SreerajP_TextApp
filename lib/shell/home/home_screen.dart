import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../create_document_action.dart';
import '../open_file_action.dart';
import 'file_type_icon.dart';
import 'recents_controller.dart';

/// Home / Recent Files screen (task 2.3).
///
/// Lists recent files with a one-tap re-open, a per-item remove, and a clear-all
/// action. Stale entries (URI no longer reachable) are shown as unavailable with
/// only a remove option. When there are no recents, a friendly empty state
/// invites the user to open a file.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(recentsControllerProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            tooltip: l10n.actionOpenFile,
            icon: const Icon(Icons.folder_open_outlined),
            onPressed: () => OpenFileAction(ref).pickAndOpen(context),
          ),
          recents.maybeWhen(
            data: (entries) => entries.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.homeClearAllTooltip,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: () => _confirmClearAll(context, ref),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateDocumentAction(ref).showFormatPicker(context),
        icon: const Icon(Icons.note_add_outlined),
        label: Text(l10n.actionNewDocument),
      ),
      body: recents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: '$e'),
        data: (entries) => entries.isEmpty
            ? const _EmptyState()
            : _RecentsList(entries: entries),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.homeClearAllTitle),
        content: Text(l10n.homeClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.homeClearConfirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(recentsControllerProvider.notifier).clearAll();
    }
  }
}

class _RecentsList extends ConsumerWidget {
  final List<RecentEntry> entries;

  const _RecentsList({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 0),
      itemBuilder: (context, i) {
        final entry = entries[i];
        final file = entry.file;
        return ListTile(
          leading: Icon(
            fileTypeIcon(
              displayName: file.displayName,
              mimeType: file.mimeType,
            ),
          ),
          title: Text(file.displayName),
          subtitle: Text(
            entry.available
                ? _subtitle(file.uri, file.lastOpenedAt)
                : l10n.homeUnavailable,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: entry.available
                ? null
                : TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          enabled: entry.available,
          onTap: entry.available
              ? () => OpenFileAction(ref).openRecent(context, file)
              : null,
          trailing: IconButton(
            tooltip: l10n.homeRemoveTooltip,
            icon: const Icon(Icons.close),
            onPressed: () => ref
                .read(recentsControllerProvider.notifier)
                .remove(file.fingerprint),
          ),
        );
      },
    );
  }

  String _subtitle(String uri, int lastOpenedAt) {
    final when = DateTime.fromMillisecondsSinceEpoch(lastOpenedAt);
    final date =
        '${when.year}-${_two(when.month)}-${_two(when.day)} ${_two(when.hour)}:${_two(when.minute)}';
    return '$date  ·  $uri';
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 72,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(l10n.homeEmptyTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.homeEmptyBody,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => OpenFileAction(ref).pickAndOpen(context),
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(l10n.actionOpenFile),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.homeLoadError, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
