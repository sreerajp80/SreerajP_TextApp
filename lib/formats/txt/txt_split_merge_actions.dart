import 'package:flutter/material.dart';

import '../../core/editor/encoding.dart';
import '../../core/storage/saf_exceptions.dart';
import '../../core/storage/saf_service.dart';
import '../../l10n/app_localizations.dart';
import '../../shell/tabs/document_tab.dart';
import 'txt_document_session.dart';
import 'txt_split_merge.dart';

/// UI actions for splitting one TXT file into parts and merging another file's
/// text into this one (task 4.5). The heavy lifting is the pure [TxtSplitMerge];
/// these helpers just gather the user's choice and move bytes through SAF.
class TxtSplitMergeActions {
  final SafService saf;
  final TextCodecService codec;
  final TxtSplitMerge splitMerge;

  const TxtSplitMergeActions({
    required this.saf,
    this.codec = const TextCodecService(),
    this.splitMerge = const TxtSplitMerge(),
  });

  /// Asks how to split, computes the parts, then saves each one through the
  /// system create-document picker (one prompt per part). Cancelling a prompt
  /// stops cleanly with a notice. The original file is never modified.
  Future<void> split(BuildContext context, TxtDocumentSession session) async {
    final code = session.code;
    if (code == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final choice = await showDialog<_SplitChoice>(
      context: context,
      builder: (context) => const _SplitDialog(),
    );
    if (choice == null) return;

    final parts = choice.byLines
        ? splitMerge.splitByLines(code.text, choice.amount)
        : splitMerge.splitBySize(code.text, choice.amount * 1024,
            encoding: session.encoding);

    if (parts.length < 2) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.txtSplitOnePart),
      ));
      return;
    }

    final baseName = _stripExtension(session.tab.displayName);
    for (var i = 0; i < parts.length; i++) {
      final bytes =
          codec.encode(parts[i], session.encoding, session.lineEnding);
      try {
        await saf.createDocument(
          suggestedName: '$baseName.part${i + 1}.txt',
          bytes: bytes,
          mimeType: 'text/plain',
        );
      } on SafCancelled {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.splitStopped(i, parts.length))),
        );
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

  /// Picks another text file and appends its content to the end of this one,
  /// switching to edit mode so the merge can be reviewed and saved.
  Future<void> mergeAppend(
    BuildContext context,
    TxtDocumentSession session,
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
      session.setViewMode(TabViewMode.edit);
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

/// The user's split choice: [byLines] picks lines-per-part, otherwise
/// kilobytes-per-part; [amount] is the number.
class _SplitChoice {
  final bool byLines;
  final int amount;
  const _SplitChoice({required this.byLines, required this.amount});
}

class _SplitDialog extends StatefulWidget {
  const _SplitDialog();

  @override
  State<_SplitDialog> createState() => _SplitDialogState();
}

class _SplitDialogState extends State<_SplitDialog> {
  bool _byLines = true;
  final _controller = TextEditingController(text: '100');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.txtSplitFile),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RadioGroup<bool>(
            groupValue: _byLines,
            onChanged: (value) => setState(() => _byLines = value ?? true),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<bool>(
                    value: true, title: Text(l10n.txtSplitByLines)),
                RadioListTile<bool>(
                    value: false, title: Text(l10n.txtSplitBySize)),
              ],
            ),
          ),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _byLines ? l10n.txtLinesPerPart : l10n.txtKbPerPart,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            final amount = int.tryParse(_controller.text.trim()) ?? 0;
            if (amount < 1) return;
            Navigator.of(context).pop(
              _SplitChoice(byLines: _byLines, amount: amount),
            );
          },
          child: Text(l10n.actionSplit),
        ),
      ],
    );
  }
}
