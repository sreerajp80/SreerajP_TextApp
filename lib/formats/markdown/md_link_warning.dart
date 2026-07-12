import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// Opens a URL after the user explicitly agrees. Injectable so tests can verify
/// the flow without the real platform plugin.
typedef UrlOpener = Future<bool> Function(Uri url);

/// The default opener: launch the URL in the device's default browser (a new
/// external app, never inside our app).
Future<bool> launchMarkdownLinkInBrowser(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Shows the link-safety warning before leaving the app from a rendered Markdown
/// link (task 6.1/6.4, CLAUDE.md offline-first + untrusted-file-content).
///
/// A link inside an opened file could point anywhere, so tapping it never opens
/// the browser straight away. This dialog shows the full URL and offers **Open
/// in browser** (only on explicit accept), **Copy link**, and **Cancel**.
///
/// Kept local to the Markdown module (a small copy of the TXT warning) so the
/// format modules stay decoupled.
Future<void> showMarkdownLinkWarning(
  BuildContext context,
  String url, {
  UrlOpener open = launchMarkdownLinkInBrowser,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final outerL10n = AppLocalizations.of(context);
  final action = await showDialog<_LinkAction>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const Key('md-link-warning-dialog'),
        icon: const Icon(Icons.open_in_new),
        title: Text(l10n.txtLinkWarningTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.mdLinkWarningBody),
            const SizedBox(height: 12),
            SelectableText(
              url,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LinkAction.cancel),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_LinkAction.copy),
            child: Text(l10n.txtCopyLink),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_LinkAction.open),
            child: Text(l10n.txtOpenInBrowser),
          ),
        ],
      );
    },
  );

  switch (action) {
    case null:
    case _LinkAction.cancel:
      return;
    case _LinkAction.copy:
      await Clipboard.setData(ClipboardData(text: url));
      messenger.showSnackBar(
        SnackBar(content: Text(outerL10n.txtLinkCopied)),
      );
      return;
    case _LinkAction.open:
      final uri = Uri.tryParse(url);
      var ok = false;
      if (uri != null) {
        try {
          ok = await open(uri);
        } catch (_) {
          ok = false;
        }
      }
      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(outerL10n.linkCouldNotOpen)),
        );
      }
      return;
  }
}

enum _LinkAction { cancel, copy, open }
