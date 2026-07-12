import 'package:flutter/material.dart';

import '../../core/editor/encoding.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import 'csv_document_session.dart';
import 'csv_parse.dart';
import 'csv_split_merge.dart';

/// UI actions for splitting a CSV by row count and appending another CSV
/// (task 7.6). The heavy lifting is the pure [CsvSplitMerge]; these helpers
/// gather input and move bytes through SAF. The header is repeated on each split
/// part; merge appends rows from a file with the same columns.
class CsvSplitMergeActions {
  final SafService saf;
  final TextCodecService codec;

  const CsvSplitMergeActions({
    required this.saf,
    this.codec = const TextCodecService(),
  });

  /// Asks for a rows-per-part count, splits, and saves each part through the
  /// create-document picker (one prompt per part). The original is never
  /// modified; the header row is repeated on every part.
  Future<void> split(BuildContext context, CsvDocumentSession session) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final rowsPerPart = await _askRowsPerPart(context, session.table.rowCount);
    if (rowsPerPart == null || !context.mounted) return;

    final parts = CsvSplitMerge.splitByRows(session.table, rowsPerPart);
    if (parts.length < 2) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.csvSplitOnePart),
      ));
      return;
    }

    final baseName = _stripExtension(session.tab.displayName);
    for (var i = 0; i < parts.length; i++) {
      final text = parts[i].toCsv(session.dialect);
      final bytes = codec.encode(text, session.encoding, session.lineEnding);
      try {
        await saf.createDocument(
          suggestedName: '$baseName.part${i + 1}.csv',
          bytes: bytes,
          mimeType: 'text/csv',
        );
      } on SafCancelled {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.csvSplitStopped(i, parts.length)),
        ));
        return;
      } on SafException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.csvSplitSaved(parts.length))),
    );
  }

  /// Picks another CSV file and appends its data rows to this table (columns are
  /// aligned by the table model). The merge is applied in memory so it can be
  /// reviewed and saved.
  Future<void> mergeAppend(
    BuildContext context,
    CsvDocumentSession session,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    SafFile file;
    try {
      file = await saf.pickFile(mimeTypes: const ['text/*']);
    } on SafCancelled {
      return;
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    try {
      final bytes = await saf.readBytes(file.uri);
      final decoded = codec.detectAndDecode(bytes);
      final other = CsvParse.parse(decoded.text, session.dialect);
      final merged = CsvSplitMerge.merge([session.table, other]);
      session.replaceTable(merged);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.csvMerged(file.displayName))),
      );
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<int?> _askRowsPerPart(BuildContext context, int totalRows) {
    final controller = TextEditingController(
      text: totalRows > 0 ? '${(totalRows / 2).ceil()}' : '100',
    );
    return showDialog<int>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.csvSplitByRows),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.csvRowsPerPart,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () {
                final n = int.tryParse(controller.text.trim());
                Navigator.of(context).pop(n != null && n > 0 ? n : null);
              },
              child: Text(l10n.csvSplitAction),
            ),
          ],
        );
      },
    );
  }

  String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }
}
