import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:text_data/core/backup/backup_crypto.dart';
import 'package:text_data/core/backup/backup_models.dart';
import 'package:text_data/core/backup/backup_providers.dart';
import 'package:text_data/core/backup/ui/backup_export_dialog.dart';
import 'package:text_data/core/backup/ui/backup_restore_dialog.dart';
import 'package:text_data/core/output/output_providers.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/core/storage/storage_providers.dart';
import 'package:text_data/core/theme/theme_controller.dart';
import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/shell/home/recents_controller.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';

/// Full screen for creating and restoring zero-knowledge encrypted backup archives (.txdata).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isProcessing = false;

  Future<void> _exportBackup() async {
    final tabsState = ref.read(tabsControllerProvider);
    final saf = ref.read(safServiceProvider);
    final attachedFiles = <BackupFileEntry>[];

    // Collect open tabs as attached files
    for (final tab in tabsState.tabs) {
      if (tab.displayName.isNotEmpty) {
        try {
          final bytes = await saf.readBytes(tab.uri);
          attachedFiles.add(
            BackupFileEntry(
              displayName: tab.displayName,
              relativePath: 'files/${tab.displayName}',
              size: bytes.length,
              sha256: '',
              mimeType: tab.mimeType,
              bytes: bytes,
            ),
          );
        } catch (_) {
          // Stale / unreadable tab skipped
        }
      }
    }

    if (!mounted) return;

    final exportChoice = await BackupExportDialog.show(
      context,
      attachedFiles: attachedFiles,
    );
    if (exportChoice == null || !mounted) return;

    setState(() => _isProcessing = true);
    final l10n = AppLocalizations.of(context);

    try {
      final backupService = await ref.read(backupServiceProvider.future);
      final archiveBytes = await backupService.createBackup(
        password: exportChoice.password,
        options: exportChoice.options,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('-', '')
          .split('.')
          .first;
      final suggestedName = 'textdata_backup_$timestamp.txdata';

      // Ask user whether to save to disk or share
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save_alt),
                title: Text(l10n.backupSaveToDevice),
                onTap: () => Navigator.of(ctx).pop('save'),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: Text(l10n.backupShareArchive),
                onTap: () => Navigator.of(ctx).pop('share'),
              ),
            ],
          ),
        ),
      );

      if (!mounted || action == null) return;

      if (action == 'save') {
        final saf = ref.read(safServiceProvider);
        final file = await saf.createDocument(
          suggestedName: suggestedName,
          bytes: archiveBytes,
          mimeType: 'application/octet-stream',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupExportSaved(file.displayName))),
          );
        }
      } else if (action == 'share') {
        final share = ref.read(shareServiceProvider);
        await share.shareFileBytes(
          name: suggestedName,
          mimeType: 'application/octet-stream',
          bytes: archiveBytes,
          subject: 'TextData Encrypted Backup (.txdata)',
        );
      }
    } on SafCancelled {
      // User cancelled picker
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.backupExportError}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _restoreBackup() async {
    final l10n = AppLocalizations.of(context);
    final saf = ref.read(safServiceProvider);

    try {
      final file = await saf.pickFile(mimeTypes: const ['*/*']);
      setState(() => _isProcessing = true);
      final archiveBytes = await saf.readBytes(file.uri);
      setState(() => _isProcessing = false);

      if (!mounted) return;

      final password = await BackupPasswordPromptDialog.show(context);
      if (password == null || !mounted) return;

      setState(() => _isProcessing = true);
      final backupService = await ref.read(backupServiceProvider.future);

      late final BackupPreview preview;
      try {
        preview = backupService.inspectBackup(
          archiveBytes: archiveBytes,
          password: password,
        );
      } on BackupCryptoException catch (e) {
        setState(() => _isProcessing = false);
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(l10n.backupUnlockFailedTitle),
              content: Text(e.message),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(l10n.actionOk),
                ),
              ],
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      setState(() => _isProcessing = false);

      final restoreOptions = await BackupRestoreDialog.show(
        context,
        preview: preview,
      );
      if (restoreOptions == null || !mounted) return;

      setState(() => _isProcessing = true);
      final result = await backupService.restoreBackup(
        preview: preview,
        options: restoreOptions,
      );

      // Invalidate relevant providers to refresh UI state immediately
      ref.invalidate(recentsControllerProvider);
      ref.invalidate(favoritesRepositoryProvider);
      ref.invalidate(bookmarksRepositoryProvider);
      ref.invalidate(themeControllerProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.backupRestoreSuccessSummary(
                result.restoredRecents,
                result.restoredFavorites,
                result.restoredBookmarks,
                result.restoredSettings,
              ),
            ),
          ),
        );
      }
    } on SafCancelled {
      // User cancelled picker
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.backupRestoreError}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupScreenTitle)),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overview card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.security,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.backupHeroTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.backupHeroBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Export Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.archive_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.backupExportCardTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.backupExportCardBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _exportBackup,
                          icon: const Icon(Icons.file_upload_outlined),
                          label: Text(l10n.backupExportButton),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Restore Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.unarchive_outlined,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.backupRestoreCardTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.backupRestoreCardBody,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _restoreBackup,
                          icon: const Icon(Icons.file_download_outlined),
                          label: Text(l10n.backupRestoreButton),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Security Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.backupZeroKnowledgeNote,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
