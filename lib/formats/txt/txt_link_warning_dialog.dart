import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';

/// A single detected link in some text: the `http`/`https` URL and the character
/// range `[start, end)` it occupies.
class DetectedLink {
  final String url;
  final int start;
  final int end;

  const DetectedLink(this.url, this.start, this.end);
}

/// Finds `http` / `https` URLs in plain text so the viewer can make them tappable
/// (task 4.1). Deliberately conservative: it matches well-formed absolute web
/// links only, so ordinary prose is not littered with false links.
class TxtLinkDetector {
  const TxtLinkDetector._();

  static final RegExp _pattern = RegExp(
    r'https?://[^\s<>"' r"'" r']+',
    caseSensitive: false,
  );

  /// Returns every detected link in [text], in order.
  static List<DetectedLink> findLinks(String text) {
    final links = <DetectedLink>[];
    for (final m in _pattern.allMatches(text)) {
      var url = m.group(0)!;
      var end = m.end;
      // Trailing punctuation is almost always sentence punctuation, not part of
      // the URL — trim a few common ones.
      while (url.isNotEmpty && _trailingTrim.contains(url[url.length - 1])) {
        url = url.substring(0, url.length - 1);
        end--;
      }
      if (url.isNotEmpty) links.add(DetectedLink(url, m.start, end));
    }
    return links;
  }

  static const String _trailingTrim = '.,;:!?)]}\'"';
}

/// Opens a URL after the user explicitly agrees. Injectable so tests can verify
/// the flow without the real platform plugin.
typedef UrlOpener = Future<bool> Function(Uri url);

/// The default opener: launch the URL in the device's default browser (a new
/// external app, never inside our app).
Future<bool> launchInBrowser(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Shows the link-safety warning before ever leaving the app (task 4.1,
/// CLAUDE.md offline-first + untrusted-file-content).
///
/// A link inside an opened file could point anywhere, so tapping it never opens
/// the browser straight away. This dialog shows the full URL and offers:
/// **Open in browser** (launches only here, on explicit accept), **Copy link**
/// (always safe), and **Cancel** (the default, launches nothing).
///
/// [open] defaults to [launchInBrowser]; tests pass a fake. A failed launch
/// shows a short, non-blocking notice and never crashes.
Future<void> showLinkWarningDialog(
  BuildContext context,
  String url, {
  UrlOpener open = launchInBrowser,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final outerL10n = AppLocalizations.of(context);
  final action = await showDialog<_LinkAction>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context);
      return AlertDialog(
        key: const Key('link-warning-dialog'),
        icon: const Icon(Icons.open_in_new),
        title: Text(l10n.txtLinkWarningTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.txtLinkWarningBody),
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
            child: Text(l10n.txtCancel),
          ),
          TextButton(
            key: const Key('link-warning-copy'),
            onPressed: () => Navigator.of(context).pop(_LinkAction.copy),
            child: Text(l10n.txtCopyLink),
          ),
          FilledButton(
            key: const Key('link-warning-open'),
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
