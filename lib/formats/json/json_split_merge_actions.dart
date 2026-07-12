import 'package:flutter/material.dart';

import '../../core/editor/encoding.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import 'json_document_session.dart';
import 'json_split_merge.dart';

/// UI actions for splitting a top-level JSON array into parts and merging other
/// JSON arrays into this one (task 8.6). The heavy lifting is the pure
/// [JsonSplitMerge]; these helpers gather input and move bytes through SAF.
class JsonSplitMergeActions {
  final SafService saf;
  final TextCodecService codec;
  final JsonSplitMerge splitMerge;

  const JsonSplitMergeActions({
    required this.saf,
    this.codec = const TextCodecService(),
    this.splitMerge = const JsonSplitMerge(),
  });

  /// Asks how many items go in each part, splits the top-level array, and saves
  /// each part through the create-document picker (one prompt per part). The
  /// original file is never modified.
  Future<void> split(BuildContext context, JsonDocumentSession session) async {
    final code = session.code;
    if (code == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final perPart = await _askPerPart(context);
    if (perPart == null) return;

    final List<String> parts;
    try {
      parts = splitMerge.splitByCount(code.text, perPart);
    } on JsonSplitMergeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (parts.length < 2) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.jsonNothingToSplit)),
      );
      return;
    }

    final baseName = _stripExtension(session.tab.displayName);
    for (var i = 0; i < parts.length; i++) {
      final bytes =
          codec.encode(parts[i], session.encoding, session.lineEnding);
      try {
        await saf.createDocument(
          suggestedName: '$baseName.part${i + 1}.json',
          bytes: bytes,
          mimeType: 'application/json',
        );
      } on SafCancelled {
        messenger.showSnackBar(SnackBar(
          content: Text(l10n.splitStopped(i, parts.length)),
        ));
        return;
      } on SafException catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.splitSaved(parts.length))),
    );
  }

  /// Picks another JSON file (a top-level array) and appends its elements to this
  /// one, switching to edit mode so the merge can be reviewed and saved.
  Future<void> mergeAppend(
    BuildContext context,
    JsonDocumentSession session,
  ) async {
    final code = session.code;
    if (code == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    SafFile file;
    try {
      file = await saf.pickFile(mimeTypes: const ['application/json', 'text/*']);
    } on SafCancelled {
      return;
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    try {
      final bytes = await saf.readBytes(file.uri);
      final decoded = codec.detectAndDecode(bytes);
      final merged = splitMerge.mergeArrays([code.text, decoded.text]);
      code.text = merged;
      session.setMode(JsonViewMode.edit);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.mergedReview(file.displayName))),
      );
    } on JsonSplitMergeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<int?> _askPerPart(BuildContext context) {
    final controller = TextEditingController(text: '10');
    return showDialog<int>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.jsonSplitArray),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.jsonItemsPerPart,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context)
                  .pop(int.tryParse(controller.text.trim())),
              child: Text(l10n.actionSplit),
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
