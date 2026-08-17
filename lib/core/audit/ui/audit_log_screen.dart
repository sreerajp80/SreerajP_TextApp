/// Full-screen audit log viewer with chain verification banner (Feature 8).
///
/// Shows audit entries in reverse chronological order with a verification
/// status banner at the top. Supports pagination via scroll-to-load-more,
/// one-tap export, and chain re-verification.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:sreerajp_textapp/core/audit/audit_constants.dart';
import 'package:sreerajp_textapp/core/audit/audit_export.dart';
import 'package:sreerajp_textapp/core/audit/audit_models.dart';
import 'package:sreerajp_textapp/core/audit/audit_providers.dart';
import 'package:sreerajp_textapp/core/config/config_service.dart';
import 'package:sreerajp_textapp/core/storage/secure_store.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// The audit log screen, reached from Settings > Audit Log > View Audit Log.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final List<AuditEntry> _entries = [];
  bool _loading = true;
  bool _hasMore = true;
  int _offset = 0;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (!_hasMore) return;
    setState(() => _loading = true);
    try {
      final service = await ref.read(auditServiceProvider.future);
      final batch = await service.getEntries(
        limit: AuditConstants.pageSize,
        offset: _offset,
      );
      setState(() {
        _entries.addAll(batch);
        _offset += batch.length;
        _hasMore = batch.length >= AuditConstants.pageSize;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    _entries.clear();
    _offset = 0;
    _hasMore = true;
    ref.invalidate(auditChainStatusProvider);
    await _loadMore();
  }

  Future<void> _exportCertificate() async {
    final l10n = AppLocalizations.of(context);
    try {
      final service = await ref.read(auditServiceProvider.future);
      final config = ref.read(configServiceProvider);
      final appConfig = await config.loadAndVerify();

      final json = await AuditExport.buildCertificate(
        service: service,
        secureStore: FlutterSecureStore(),
        appName: appConfig.appName,
        appVersion: appConfig.version,
      );

      // Write to a temp file and share via the system share sheet.
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'audit_certificate_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(json, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path, mimeType: 'application/json', name: fileName),
          ],
          subject: l10n.auditExportSubject,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.auditExportFailed)));
      }
    }
  }

  Future<void> _clearLog() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.auditClearTitle),
        content: Text(l10n.auditClearConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.auditClearAction),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final service = await ref.read(auditServiceProvider.future);
      await service.clearLog();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.auditClearSuccess)));
      }
    } catch (_) {
      // Best effort.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auditLogTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined),
            tooltip: l10n.auditVerifyAction,
            onPressed: () => ref.invalidate(auditChainStatusProvider),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: l10n.auditExportAction,
            onPressed: _exportCertificate,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') _clearLog();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(value: 'clear', child: Text(l10n.auditClearAction)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Verification banner.
          const _VerificationBanner(),
          const Divider(height: 1),
          // Entry list.
          Expanded(
            child: _entries.isEmpty && !_loading
                ? Center(
                    child: Text(
                      l10n.auditEmptyState,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200 &&
                          !_loading &&
                          _hasMore) {
                        _loadMore();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: _entries.length + (_loading ? 1 : 0),
                        itemBuilder: (ctx, index) {
                          if (index >= _entries.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _AuditEntryTile(entry: _entries[index]);
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// The chain-verification banner at the top of the audit log screen.
class _VerificationBanner extends ConsumerWidget {
  const _VerificationBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStatus = ref.watch(auditChainStatusProvider);
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return asyncStatus.when(
      data: (result) {
        final Color bgColor;
        final Color fgColor;
        final IconData icon;
        final String text;

        switch (result.status) {
          case AuditChainStatus.verified:
            bgColor = Colors.green.withAlpha(30);
            fgColor = Colors.green;
            icon = Icons.verified;
            text = l10n.auditChainVerifiedBanner(result.totalEntries);
          case AuditChainStatus.corrupted:
            bgColor = theme.colorScheme.errorContainer;
            fgColor = theme.colorScheme.error;
            icon = Icons.warning_amber_rounded;
            text = l10n.auditChainCorruptedBanner(
              result.corruptedEntryIndex ?? 0,
            );
          case AuditChainStatus.empty:
            bgColor = theme.colorScheme.surfaceContainerHighest;
            fgColor = theme.colorScheme.outline;
            icon = Icons.remove_circle_outline;
            text = l10n.auditChainEmptyBanner;
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: bgColor,
          child: Row(
            children: [
              Icon(icon, color: fgColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium?.copyWith(color: fgColor),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// A single audit entry rendered as a [ListTile].
class _AuditEntryTile extends StatelessWidget {
  final AuditEntry entry;

  const _AuditEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(entry.timestamp);
    final timeString =
        '${dateTime.year}-${_pad(dateTime.month)}-${_pad(dateTime.day)} '
        '${_pad(dateTime.hour)}:${_pad(dateTime.minute)}:${_pad(dateTime.second)}';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _eventColor(entry.eventType).withAlpha(30),
        child: Icon(
          _eventIcon(entry.eventType),
          color: _eventColor(entry.eventType),
          size: 20,
        ),
      ),
      title: Text(
        _eventLabel(entry.eventType),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entry.fileName != null)
            Text(
              entry.fileName!,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (entry.detail != null)
            Text(
              entry.detail!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          Text(
            timeString,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
      trailing: Tooltip(
        message: entry.entryHash,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: theme.colorScheme.surfaceContainerHighest,
          ),
          child: Text(
            '#${entry.entryHash.substring(0, 8)}',
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: 'JetBrains Mono',
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      ),
      isThreeLine: true,
    );
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  static IconData _eventIcon(String type) {
    return switch (type) {
      AuditEventType.fileOpen => Icons.folder_open,
      AuditEventType.fileSave => Icons.save,
      AuditEventType.fileExport => Icons.file_download,
      AuditEventType.filePrint => Icons.print,
      AuditEventType.fileShare => Icons.share,
      AuditEventType.p2pSyncSend => Icons.upload,
      AuditEventType.p2pSyncReceive => Icons.download,
      AuditEventType.airqrSend => Icons.qr_code,
      AuditEventType.airqrReceive => Icons.qr_code_scanner,
      AuditEventType.securityPinChange => Icons.password,
      AuditEventType.securityLockToggle => Icons.lock,
      AuditEventType.fileBurn => Icons.local_fire_department,
      AuditEventType.auditCleared => Icons.delete_sweep,
      _ => Icons.event_note,
    };
  }

  static Color _eventColor(String type) {
    return switch (type) {
      AuditEventType.fileOpen => Colors.blue,
      AuditEventType.fileSave => Colors.green,
      AuditEventType.fileExport => Colors.teal,
      AuditEventType.filePrint => Colors.indigo,
      AuditEventType.fileShare => Colors.purple,
      AuditEventType.p2pSyncSend => Colors.orange,
      AuditEventType.p2pSyncReceive => Colors.orange,
      AuditEventType.airqrSend => Colors.cyan,
      AuditEventType.airqrReceive => Colors.cyan,
      AuditEventType.securityPinChange => Colors.red,
      AuditEventType.securityLockToggle => Colors.red,
      AuditEventType.fileBurn => Colors.deepOrange,
      AuditEventType.auditCleared => Colors.grey,
      _ => Colors.grey,
    };
  }

  static String _eventLabel(String type) {
    return switch (type) {
      AuditEventType.fileOpen => 'File Opened',
      AuditEventType.fileSave => 'File Saved',
      AuditEventType.fileExport => 'File Exported',
      AuditEventType.filePrint => 'File Printed',
      AuditEventType.fileShare => 'File Shared',
      AuditEventType.p2pSyncSend => 'Sync Sent',
      AuditEventType.p2pSyncReceive => 'Sync Received',
      AuditEventType.airqrSend => 'AirQR Sent',
      AuditEventType.airqrReceive => 'AirQR Received',
      AuditEventType.securityPinChange => 'PIN Changed',
      AuditEventType.securityLockToggle => 'Lock Toggled',
      AuditEventType.fileBurn => 'Document Burned',
      AuditEventType.auditCleared => 'Log Cleared',
      _ => type,
    };
  }
}
