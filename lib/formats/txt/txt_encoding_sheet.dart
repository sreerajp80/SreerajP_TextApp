import 'package:flutter/material.dart';

import '../../core/editor/encoding.dart';
import '../../l10n/app_localizations.dart';
import 'txt_document_session.dart';
import 'txt_encoding_labels.dart';

/// A bottom sheet to view and switch the file's text encoding (task 4.4).
///
/// Picking a different encoding re-decodes the **original bytes** so the user
/// can recover text that was detected wrongly. It changes only how the file is
/// read; the bytes on disk are untouched until the user saves.
Future<void> showEncodingSheet(
  BuildContext context,
  TxtDocumentSession session,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(AppLocalizations.of(context).txtEncodingSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            RadioGroup<TextEncodingType>(
              groupValue: session.encoding,
              onChanged: (value) {
                if (value != null) session.changeEncoding(value);
                Navigator.of(context).pop();
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final encoding in TextEncodingType.values)
                    RadioListTile<TextEncodingType>(
                      value: encoding,
                      title: Text(encoding.label),
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
