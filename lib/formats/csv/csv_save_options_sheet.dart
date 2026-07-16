import 'package:flutter/material.dart';

import '../../core/editor/atomic_saver.dart';
import '../../core/editor/confirm_overwrite.dart';
import '../../core/editor/encoding.dart';
import '../../l10n/app_localizations.dart';
import '../txt/txt_encoding_labels.dart';
import 'csv_dialect.dart';
import 'csv_document_session.dart';

/// Runs a plain Save: overwrite the file, preserving its delimiter, encoding +
/// line ending, and report the outcome with a snackbar. A read-only file falls
/// back to "Save as a copy". This is what the toolbar Save button uses, so an
/// ordinary save does not ask any questions; the delimiter/encoding/line-ending
/// options live under the "Save as…" menu.
Future<void> saveCsvDirect(
  BuildContext context,
  CsvDocumentSession session,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  if (!await confirmOverwriteIfNeeded(context)) return;
  var result = await session.save();
  if (result.outcome == SaveOutcome.readOnlyNeedsCopy) {
    result = await session.saveAsCopy();
  }
  _reportSaveResult(messenger, l10n, result);
}

/// Runs Save or Save-as-a-copy with a chance to pick the delimiter, encoding,
/// and line ending first (task 7.5). Reached from the "Save as…" menu. Defaults
/// preserve what the file was opened as. A read-only file that cannot be
/// overwritten is offered "Save as a copy".
Future<void> showCsvSaveOptionsSheet(
  BuildContext context,
  CsvDocumentSession session,
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

  _reportSaveResult(messenger, l10n, result);
}

/// Shows the right snackbar for a [SaveResult] (shared by the direct save and
/// the options sheet so the messages stay identical).
void _reportSaveResult(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  SaveResult result,
) {
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
  const _SaveChoice(this.action);
}

class _SaveOptionsBody extends StatefulWidget {
  final CsvDocumentSession session;
  const _SaveOptionsBody({required this.session});

  @override
  State<_SaveOptionsBody> createState() => _SaveOptionsBodyState();
}

class _SaveOptionsBodyState extends State<_SaveOptionsBody> {
  late CsvDelimiter _delimiter = widget.session.dialect.delimiter;
  late TextEncodingType _encoding = widget.session.encoding;
  late LineEndingStyle _lineEnding = widget.session.lineEnding;

  void _apply() {
    widget.session.setDelimiter(_delimiter);
    widget.session.setSaveEncoding(_encoding);
    widget.session.setLineEnding(_lineEnding);
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
            DropdownButtonFormField<CsvDelimiter>(
              initialValue: _delimiter,
              decoration: InputDecoration(
                labelText: l10n.labelDelimiter,
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final d in CsvDelimiter.values)
                  DropdownMenuItem(value: d, child: Text(d.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _delimiter = value);
              },
            ),
            const SizedBox(height: 12),
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
                    Navigator.of(context)
                        .pop(const _SaveChoice(_SaveAction.copy));
                  },
                  child: Text(l10n.actionSaveAsCopy),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () {
                    _apply();
                    Navigator.of(context).pop(
                      _SaveChoice(canOverwrite
                          ? _SaveAction.overwrite
                          : _SaveAction.copy),
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
