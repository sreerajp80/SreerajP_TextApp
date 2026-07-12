import 'package:flutter/material.dart';

import '../../core/editor/atomic_saver.dart';
import '../../core/editor/confirm_overwrite.dart';
import '../../core/editor/encoding.dart';
import '../../l10n/app_localizations.dart';
import '../txt/txt_encoding_labels.dart';
import 'xml_document_session.dart';

/// Runs Save or Save-as-a-copy with a chance to pick the indentation, output
/// encoding, and line ending first (task 9.5). Defaults preserve what the file
/// was opened as. The pre-save gate blocks a broken overwrite; a read-only file
/// is offered "Save as a copy".
Future<void> showXmlSaveOptionsSheet(
  BuildContext context,
  XmlDocumentSession session,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final outcome = await showModalBottomSheet<_SaveChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _SaveOptionsBody(session: session),
  );
  if (outcome == null) return;

  if (outcome.reformat) session.formatDocument();

  SaveResult result;
  switch (outcome.action) {
    case _SaveAction.overwrite:
      if (!context.mounted) return;
      if (!await confirmOverwriteIfNeeded(context)) return;
      result = await session.save();
      if (result.outcome == SaveOutcome.readOnlyNeedsCopy) {
        result = await session.saveAsCopy();
      }
      break;
    case _SaveAction.copy:
      result = await session.saveAsCopy();
      break;
  }

  final message = switch (result.outcome) {
    SaveOutcome.saved => l10n.saveDone,
    SaveOutcome.savedAsCopy =>
      l10n.saveCopyDone(result.destination?.displayName ?? l10n.saveNewFile),
    SaveOutcome.cancelled => null,
    SaveOutcome.blockedByGate => result.message ?? l10n.saveCouldNot,
    SaveOutcome.readOnlyNeedsCopy => l10n.saveReadOnly,
    SaveOutcome.failed => result.message ?? l10n.saveFailed,
  };
  if (message != null) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _SaveAction { overwrite, copy }

class _SaveChoice {
  final _SaveAction action;
  final bool reformat;
  const _SaveChoice(this.action, {this.reformat = false});
}

class _SaveOptionsBody extends StatefulWidget {
  final XmlDocumentSession session;
  const _SaveOptionsBody({required this.session});

  @override
  State<_SaveOptionsBody> createState() => _SaveOptionsBodyState();
}

class _SaveOptionsBodyState extends State<_SaveOptionsBody> {
  late TextEncodingType _encoding = widget.session.encoding;
  late LineEndingStyle _lineEnding = widget.session.lineEnding;
  late XmlIndent _indent = widget.session.indent;
  bool _reformat = false;

  void _apply() {
    widget.session.setSaveEncoding(_encoding);
    widget.session.setLineEnding(_lineEnding);
    widget.session.setIndent(_indent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canOverwrite = widget.session.isWritable;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.saveOptionsTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<XmlIndent>(
              initialValue: _indent,
              decoration: InputDecoration(
                labelText: l10n.xmlIndentation,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final i in XmlIndent.values)
                  DropdownMenuItem(value: i, child: Text(i.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _indent = value);
              },
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _reformat,
              onChanged: (v) => setState(() => _reformat = v ?? false),
              title: Text(l10n.xmlReformat),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<TextEncodingType>(
              initialValue: _encoding,
              decoration: InputDecoration(
                labelText: l10n.labelEncoding,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final e in TextEncodingType.values)
                  DropdownMenuItem(value: e, child: Text(e.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _encoding = value);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LineEndingStyle>(
              initialValue: _lineEnding,
              decoration: InputDecoration(
                labelText: l10n.labelLineEnding,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final l in LineEndingStyle.values)
                  DropdownMenuItem(value: l, child: Text(l.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _lineEnding = value);
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    _apply();
                    Navigator.of(context).pop(
                      _SaveChoice(_SaveAction.copy, reformat: _reformat),
                    );
                  },
                  child: Text(l10n.actionSaveAsCopy),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    _apply();
                    Navigator.of(context).pop(
                      _SaveChoice(
                        canOverwrite ? _SaveAction.overwrite : _SaveAction.copy,
                        reformat: _reformat,
                      ),
                    );
                  },
                  child: Text(
                      canOverwrite ? l10n.actionSave : l10n.actionSaveAsCopy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
