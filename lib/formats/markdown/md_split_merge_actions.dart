import 'package:flutter/material.dart';

import '../../core/editor/encoding.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import 'md_document_session.dart';
import 'md_split_merge.dart';

/// UI actions for splitting a Markdown file by top-level heading and appending
/// another Markdown file into this one (task 6.5). The heavy lifting is the pure
/// [MdSplitMerge]; these helpers gather input and move bytes through SAF.
class MdSplitMergeActions {
  final SafService saf;
  final TextCodecService codec;
  final MdSplitMerge splitMerge;

  const MdSplitMergeActions({
    required this.saf,
    this.codec = const TextCodecService(),
    this.splitMerge = const MdSplitMerge(),
  });

  /// Splits the document at each top-level `#` heading and saves each part
  /// through the create-document picker (one prompt per part). The original file
  /// is never modified.
  Future<void> split(BuildContext context, MdDocumentSession session) async {
    final code = session.code;
    if (code == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final parts = splitMerge.splitByTopHeading(code.text);
    if (parts.length < 2) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.mdNoTopHeadings),
      ));
      return;
    }

    final baseName = _stripExtension(session.tab.displayName);
    for (var i = 0; i < parts.length; i++) {
      final bytes =
          codec.encode(parts[i], session.encoding, session.lineEnding);
      try {
        await saf.createDocument(
          suggestedName: '$baseName.part${i + 1}.md',
          bytes: bytes,
          mimeType: 'text/markdown',
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

  /// Picks another Markdown file and appends its content to the end of this one,
  /// switching to edit mode so the merge can be reviewed and saved.
  Future<void> mergeAppend(
    BuildContext context,
    MdDocumentSession session,
  ) async {
    final code = session.code;
    if (code == null) return;
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
      final merged = splitMerge.merge([code.text, decoded.text]);
      code.text = merged;
      session.setMode(MdMode.edit);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.mergedReview(file.displayName))),
      );
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  String _stripExtension(String name) {
    final dot = name.lastIndexOf('.');
    return dot <= 0 ? name : name.substring(0, dot);
  }
}
