import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:text_data/core/storage/saf_exceptions.dart';
import 'package:text_data/core/storage/saf_service.dart';
import 'package:text_data/shell/tabs/document_tab.dart';
import 'package:text_data/shell/tabs/tabs_controller.dart';
import 'package:text_data/sync/diff/live_diff_controller.dart';
import 'package:text_data/sync/ui/live_diff_screen.dart';
import 'package:text_data/sync/ui/sync_host_screen.dart';

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
                      'Live Document Diff & Delta Sync',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Compare "${tab.displayName}" side-by-side and selectively merge edits.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.wifi_tethering),
                  title: const Text('Start P2P Live Sync with Peer'),
                  subtitle: const Text(
                    'Connect with another device over local Wi-Fi to diff & pair-edit.',
                  ),
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
                  title: const Text('Compare with Local File (SAF)'),
                  subtitle: const Text(
                    'Pick a second document from device storage.',
                  ),
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
                          const SnackBar(
                            content: Text(
                              'Could not read chosen file for diff.',
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                if (otherTabs.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Or Compare with Open Tab:',
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
                                const SnackBar(
                                  content: Text(
                                    'Could not read tab for comparison.',
                                  ),
                                ),
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
