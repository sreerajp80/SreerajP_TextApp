import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sreerajp_textapp/core/storage/saf_exceptions.dart';
import 'package:sreerajp_textapp/core/storage/saf_service.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';
import 'package:sreerajp_textapp/shell/tabs/tabs_controller.dart';
import 'package:sreerajp_textapp/sync/diff/live_diff_controller.dart';
import 'package:sreerajp_textapp/sync/ui/live_diff_screen.dart';
import 'package:sreerajp_textapp/sync/ui/sync_host_screen.dart';

/// Helper to launch Live Diff & Delta Sync from document toolbars and menus.
class LiveDiffLauncher {
  LiveDiffLauncher._();

  /// Shows dialog allowing user to choose comparison source (local file, open tab, or P2P LAN sync).
  static Future<void> showDiffOptions({
    required BuildContext context,
    required WidgetRef ref,
    required DocumentTab tab,
    required String content,
    void Function(String mergedText)? onApplyToEditor,
  }) async {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tabsState = ref.read(tabsControllerProvider);
    final otherTabs = tabsState.tabs.where((t) => t.id != tab.id).toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.difference_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.diffSheetTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.diffSheetSubtitle(tab.displayName),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.wifi_tethering),
                  title: Text(l10n.diffStartLiveSync),
                  subtitle: Text(l10n.diffStartLiveSyncSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SyncHostScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.folder_open),
                  title: Text(l10n.diffCompareLocalFile),
                  subtitle: Text(l10n.diffCompareLocalFileSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    try {
                      final saf = ref.read(safServiceProvider);
                      final file = await saf.pickFile();
                      final bytes = await saf.readBytes(file.uri);
                      final remoteText = utf8.decode(
                        bytes,
                        allowMalformed: true,
                      );

                      if (context.mounted) {
                        final diffCtrl = LiveDiffController(
                          documentName: tab.displayName,
                          mimeType: tab.mimeType ?? 'text/plain',
                          mode: DiffSessionMode.standalone,
                          initialLocalContent: content,
                          initialRemoteContent: remoteText,
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LiveDiffScreen(
                              controller: diffCtrl,
                              onApplyToEditor: onApplyToEditor,
                            ),
                          ),
                        );
                      }
                    } on SafCancelled {
                      // User cancelled
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.diffReadChosenFileFailed),
                          ),
                        );
                      }
                    }
                  },
                ),
                if (otherTabs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.diffCompareOpenTab,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: otherTabs.map((t) {
                      return ActionChip(
                        avatar: const Icon(Icons.tab, size: 16),
                        label: Text(t.displayName),
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          try {
                            final saf = ref.read(safServiceProvider);
                            final bytes = await saf.readBytes(t.uri);
                            final remoteText = utf8.decode(
                              bytes,
                              allowMalformed: true,
                            );

                            if (context.mounted) {
                              final diffCtrl = LiveDiffController(
                                documentName:
                                    '${tab.displayName} ↔ ${t.displayName}',
                                mimeType: tab.mimeType ?? 'text/plain',
                                mode: DiffSessionMode.standalone,
                                initialLocalContent: content,
                                initialRemoteContent: remoteText,
                              );

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LiveDiffScreen(
                                    controller: diffCtrl,
                                    onApplyToEditor: onApplyToEditor,
                                  ),
                                ),
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.diffReadTabFailed)),
                              );
                            }
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
