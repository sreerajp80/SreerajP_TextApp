import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'txt_document_session.dart';
import 'txt_link_warning_dialog.dart';

/// A bottom sheet listing every link found in the document (task 4.1).
///
/// `re_editor` paints its own text, so links cannot be tapped inline; this sheet
/// collects them so the user can still open one — always through the safety
/// warning dialog ([showLinkWarningDialog]) that offers Open in browser / Copy
/// link / Cancel.
Future<void> showLinksSheet(BuildContext context, TxtDocumentSession session) {
  final links = TxtLinkDetector.findLinks(session.code?.text ?? '');
  final unique = <String>{};
  final ordered = <String>[];
  for (final link in links) {
    if (unique.add(link.url)) ordered.add(link.url);
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                ordered.isEmpty ? l10n.txtNoLinksFound : l10n.txtLinksTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (ordered.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(l10n.txtNoLinksBody),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final url in ordered)
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis),
                      onTap: () => showLinkWarningDialog(context, url),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
