import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/core/backup/backup_models.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Simple dialog asking for the password to decrypt an imported `.txdata` archive.
class BackupPasswordPromptDialog extends StatefulWidget {
  const BackupPasswordPromptDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BackupPasswordPromptDialog(),
    );
  }

  @override
  State<BackupPasswordPromptDialog> createState() =>
      _BackupPasswordPromptDialogState();
}

class _BackupPasswordPromptDialogState
    extends State<BackupPasswordPromptDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_open, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.backupEnterPasswordTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.backupEnterPasswordPrompt),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.backupPasswordLabel,
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            onSubmitted: (_) {
              if (_controller.text.isNotEmpty) {
                Navigator.of(context).pop(_controller.text);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop(_controller.text);
            }
          },
          child: Text(l10n.backupUnlockAction),
        ),
      ],
    );
  }
}

/// Dialog presenting a decrypted backup preview and allowing selection of
/// components to restore.
class BackupRestoreDialog extends StatefulWidget {
  final BackupPreview preview;

  const BackupRestoreDialog({super.key, required this.preview});

  static Future<BackupRestoreOptions?> show(
    BuildContext context, {
    required BackupPreview preview,
  }) {
    return showDialog<BackupRestoreOptions>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackupRestoreDialog(preview: preview),
    );
  }

  @override
  State<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<BackupRestoreDialog> {
  late bool _restoreRecents;
  late bool _restoreFavorites;
  late bool _restoreBookmarks;
  late bool _restoreSettings;
  late bool _restoreFiles;
  bool _mergeMode = true;

  @override
  void initState() {
    super.initState();
    _restoreRecents = widget.preview.recents.isNotEmpty;
    _restoreFavorites = widget.preview.favorites.isNotEmpty;
    _restoreBookmarks = widget.preview.bookmarks.isNotEmpty;
    _restoreSettings = widget.preview.settings.isNotEmpty;
    _restoreFiles = widget.preview.files.isNotEmpty;
  }

  void _submit() {
    final options = BackupRestoreOptions(
      restoreRecents: _restoreRecents,
      restoreFavorites: _restoreFavorites,
      restoreBookmarks: _restoreBookmarks,
      restoreSettings: _restoreSettings,
      restoreFiles: _restoreFiles,
      mergeMode: _mergeMode,
    );
    Navigator.of(context).pop(options);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final manifest = widget.preview.manifest;

    final createdDate = DateTime.fromMillisecondsSinceEpoch(manifest.createdAt);
    final dateStr =
        '${createdDate.year}-${_two(createdDate.month)}-${_two(createdDate.day)} '
        '${_two(createdDate.hour)}:${_two(createdDate.minute)}';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.restore, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.backupRestoreTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupCreatedOn(dateStr),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.backupSelectRestoreItems,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            if (widget.preview.recents.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  l10n.backupRecentsCount(widget.preview.recents.length),
                ),
                value: _restoreRecents,
                onChanged: (v) => setState(() => _restoreRecents = v ?? true),
              ),
            if (widget.preview.favorites.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  l10n.backupFavoritesCount(widget.preview.favorites.length),
                ),
                value: _restoreFavorites,
                onChanged: (v) => setState(() => _restoreFavorites = v ?? true),
              ),
            if (widget.preview.bookmarks.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  l10n.backupBookmarksCount(widget.preview.bookmarks.length),
                ),
                value: _restoreBookmarks,
                onChanged: (v) => setState(() => _restoreBookmarks = v ?? true),
              ),
            if (widget.preview.settings.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  l10n.backupSettingsCount(widget.preview.settings.length),
                ),
                value: _restoreSettings,
                onChanged: (v) => setState(() => _restoreSettings = v ?? true),
              ),
            if (widget.preview.files.isNotEmpty)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.backupFilesCount(widget.preview.files.length)),
                value: _restoreFiles,
                onChanged: (v) => setState(() => _restoreFiles = v ?? true),
              ),
            const Divider(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(l10n.backupMergeModeTitle),
              subtitle: Text(
                _mergeMode
                    ? l10n.backupMergeModeSubtitle
                    : l10n.backupReplaceModeSubtitle,
              ),
              value: _mergeMode,
              onChanged: (v) => setState(() => _mergeMode = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.download_done),
          label: Text(l10n.backupRestoreAction),
        ),
      ],
    );
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
