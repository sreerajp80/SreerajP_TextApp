import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/core/backup/backup_constants.dart';
import 'package:sreerajp_textapp/core/backup/backup_models.dart';
import 'package:sreerajp_textapp/l10n/app_localizations.dart';

/// Dialog collecting options and password for creating a new `.txdata` backup archive.
class BackupExportDialog extends StatefulWidget {
  final List<BackupFileEntry> attachedFiles;

  const BackupExportDialog({super.key, this.attachedFiles = const []});

  static Future<({String password, BackupExportOptions options})?> show(
    BuildContext context, {
    List<BackupFileEntry> attachedFiles = const [],
  }) {
    return showDialog<({String password, BackupExportOptions options})>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackupExportDialog(attachedFiles: attachedFiles),
    );
  }

  @override
  State<BackupExportDialog> createState() => _BackupExportDialogState();
}

class _BackupExportDialogState extends State<BackupExportDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  bool _includeRecents = true;
  bool _includeFavorites = true;
  bool _includeBookmarks = true;
  bool _includeSettings = true;
  late bool _includeFiles;

  @override
  void initState() {
    super.initState();
    _includeFiles = widget.attachedFiles.isNotEmpty;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final options = BackupExportOptions(
      includeRecents: _includeRecents,
      includeFavorites: _includeFavorites,
      includeBookmarks: _includeBookmarks,
      includeSettings: _includeSettings,
      files: _includeFiles ? widget.attachedFiles : const [],
    );

    Navigator.of(
      context,
    ).pop((password: _passwordController.text, options: options));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.backupExportTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.backupExportSelectItems,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.backupIncludeRecents),
                value: _includeRecents,
                onChanged: (v) => setState(() => _includeRecents = v ?? true),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.backupIncludeFavorites),
                value: _includeFavorites,
                onChanged: (v) => setState(() => _includeFavorites = v ?? true),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.backupIncludeBookmarks),
                value: _includeBookmarks,
                onChanged: (v) => setState(() => _includeBookmarks = v ?? true),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(l10n.backupIncludeSettings),
                value: _includeSettings,
                onChanged: (v) => setState(() => _includeSettings = v ?? true),
              ),
              if (widget.attachedFiles.isNotEmpty)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(
                    l10n.backupIncludeFiles(widget.attachedFiles.length),
                  ),
                  value: _includeFiles,
                  onChanged: (v) => setState(() => _includeFiles = v ?? true),
                ),
              const SizedBox(height: 12),
              Text(
                l10n.backupPasswordHeader,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: l10n.backupPasswordLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (val) {
                  if (val == null ||
                      val.length < BackupConstants.minPasswordLength) {
                    return l10n.backupPasswordTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: l10n.backupConfirmPasswordLabel,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) {
                  if (val != _passwordController.text) {
                    return l10n.backupPasswordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.backupPasswordWarning,
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
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.lock),
          label: Text(l10n.backupCreateAction),
        ),
      ],
    );
  }
}
