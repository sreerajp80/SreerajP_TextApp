import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'md_document_session.dart';

/// A bottom sheet listing the document's headings (task 6.3). Tapping an entry
/// scrolls the rendered preview to that heading.
Future<void> showMdTocSheet(
  BuildContext context,
  MdDocumentSession session,
) async {
  final headings = session.toc.headings;
  if (headings.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).mdNoHeadings)),
    );
    return;
  }
  // The TOC scrolls the rendered preview, so make sure we are showing it.
  if (session.mode == MdMode.raw) session.setMode(MdMode.rendered);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(AppLocalizations.of(context).mdContents,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final heading in headings)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.only(
                          left: 16.0 + (heading.level - 1) * 16,
                          right: 16,
                        ),
                        title: Text(
                          heading.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: heading.level <= 2
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          session.jumpToAnchor(heading.anchor);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
