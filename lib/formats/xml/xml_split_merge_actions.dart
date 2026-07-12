import 'package:flutter/material.dart';

import '../../core/editor/encoding.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import 'xml_convert.dart';
import 'xml_document_session.dart';
import 'xml_split_merge.dart';

/// UI actions for splitting an XML document by a repeated child element and
/// merging other XML files under a new wrapper root (task 9.6). The heavy lifting
/// is the pure [XmlSplitMerge]; these helpers gather input and move bytes through
/// SAF.
class XmlSplitMergeActions {
  final SafService saf;
  final TextCodecService codec;
  final XmlSplitMerge splitMerge;

  const XmlSplitMergeActions({
    required this.saf,
    this.codec = const TextCodecService(),
    this.splitMerge = const XmlSplitMerge(),
  });

  /// Asks which repeated child element to split on and how many go in each part,
  /// splits, and saves each part through the create-document picker. The
  /// original file is never modified.
  Future<void> split(BuildContext context, XmlDocumentSession session) async {
    final code = session.code;
    final document = session.document;
    if (code == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    if (document == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.xmlFixErrorsBeforeSplit)),
      );
      return;
    }

    final tag = await _askTag(context, bestRepeatedTag(document));
    if (tag == null || tag.trim().isEmpty || !context.mounted) return;
    final perPart = await _askPerPart(context);
    if (perPart == null) return;

    final List<String> parts;
    try {
      parts = splitMerge.splitByElement(code.text, tag.trim(), perPart);
    } on XmlSplitMergeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (parts.length < 2) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.xmlNothingToSplit)),
      );
      return;
    }

    final baseName = _stripExtension(session.tab.displayName);
    for (var i = 0; i < parts.length; i++) {
      final bytes =
          codec.encode(parts[i], session.encoding, session.lineEnding);
      try {
        await saf.createDocument(
          suggestedName: '$baseName.part${i + 1}.xml',
          bytes: bytes,
          mimeType: 'application/xml',
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

  /// Picks another XML file and merges this document's and its root children
  /// under a new wrapper root, switching to edit mode so the merge can be
  /// reviewed and saved.
  Future<void> mergeAppend(
    BuildContext context,
    XmlDocumentSession session,
  ) async {
    final code = session.code;
    if (code == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);

    final wrapper = await _askWrapper(context);
    if (wrapper == null || wrapper.trim().isEmpty || !context.mounted) return;

    SafFile file;
    try {
      file = await saf.pickFile(
          mimeTypes: const ['application/xml', 'text/xml', 'text/*']);
    } on SafCancelled {
      return;
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    try {
      final bytes = await saf.readBytes(file.uri);
      final decoded = codec.detectAndDecode(bytes);
      final merged = splitMerge
          .mergeUnderWrapper([code.text, decoded.text], wrapper.trim());
      code.text = merged;
      session.setMode(XmlViewMode.edit);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.mergedReview(file.displayName))),
      );
    } on XmlSplitMergeException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on SafException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<String?> _askTag(BuildContext context, String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.xmlSplitByElement),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.xmlRepeatedChildElement,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n.actionNext),
            ),
          ],
        );
      },
    );
  }

  Future<int?> _askPerPart(BuildContext context) {
    final controller = TextEditingController(text: '10');
    return showDialog<int>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.xmlElementsPerPart),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.xmlElementsPerPart,
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

  Future<String?> _askWrapper(BuildContext context) {
    final controller = TextEditingController(text: 'root');
    return showDialog<String>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.xmlMergeFile),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.xmlNewWrapperName,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n.xmlPickFile),
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
