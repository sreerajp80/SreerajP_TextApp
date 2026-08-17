import 'package:flutter/material.dart';

import 'package:sreerajp_textapp/l10n/app_localizations.dart';
import 'package:sreerajp_textapp/formats/csv/csv_document_session.dart';
import 'package:sreerajp_textapp/formats/csv/csv_formula.dart';

/// A sheet to set, change or clear the formula on a calculated column
/// (roadmap §4.2.2).
///
/// The formula is checked as it is typed and the first rows are previewed, so a
/// mistake is visible before it is applied to the whole column.
Future<void> showCsvFormulaSheet(
  BuildContext context,
  CsvDocumentSession session,
  int column,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _FormulaBody(session: session, column: column),
    ),
  );
}

class _FormulaBody extends StatefulWidget {
  final CsvDocumentSession session;
  final int column;

  const _FormulaBody({required this.session, required this.column});

  @override
  State<_FormulaBody> createState() => _FormulaBodyState();
}

class _FormulaBodyState extends State<_FormulaBody> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.session.columnFormula(widget.column) ?? '',
  );

  /// A problem the user should fix before applying, or null when it looks fine.
  String? _problem;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    final text = _controller.text.trim();
    setState(() {
      _problem = text.isEmpty
          ? null
          : CsvFormula.validate(
              widget.session.table,
              text,
              selfColumn: widget.column,
            );
    });
  }

  void _apply() {
    final text = _controller.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (text.isEmpty) {
      widget.session.clearColumnFormula(widget.column);
      navigator.pop();
      return;
    }
    final problem = widget.session.setColumnFormula(widget.column, text);
    if (problem != null) {
      setState(() => _problem = problem);
      return;
    }
    messenger.hideCurrentSnackBar();
    navigator.pop();
  }

  void _clear() {
    widget.session.clearColumnFormula(widget.column);
    Navigator.of(context).pop();
  }

  /// The computed value for the first few rows, so the user can see the formula
  /// working before it is applied.
  List<String> get _preview {
    final text = _controller.text.trim();
    if (text.isEmpty || _problem != null) return const [];
    final table = widget.session.table;
    final rows = table.rowCount < 3 ? table.rowCount : 3;
    return [
      for (var r = 0; r < rows; r++)
        CsvFormula.evaluate(table, text, r, selfColumn: widget.column).display,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final header = widget.session.table.header;
    final name =
        widget.column < header.length && header[widget.column].isNotEmpty
        ? header[widget.column]
        : l10n.csvColumnN(widget.column + 1);
    final hasFormula = widget.session.columnFormula(widget.column) != null;
    final preview = _preview;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.csvFormulaTitle(name),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.csvFormulaHelp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('csv-formula-field'),
              controller: _controller,
              autofocus: true,
              onChanged: (_) => _check(),
              onSubmitted: (_) => _apply(),
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: InputDecoration(
                labelText: l10n.csvFormulaLabel,
                hintText: '=A*B',
                errorText: _problem,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.csvFormulaColumnLetters,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (var c = 0; c < widget.session.table.columnCount; c++)
                  if (c != widget.column)
                    ActionChip(
                      label: Text(
                        '${CsvFormula.columnLetters(c)} · '
                        '${c < header.length && header[c].isNotEmpty ? header[c] : l10n.csvColumnN(c + 1)}',
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        final insert = CsvFormula.columnLetters(c);
                        final text = _controller.text;
                        _controller.text = text.isEmpty
                            ? '=$insert'
                            : '$text$insert';
                        _controller.selection = TextSelection.collapsed(
                          offset: _controller.text.length,
                        );
                        _check();
                      },
                    ),
              ],
            ),
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.csvFormulaPreview, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(
                preview.join(' · '),
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                if (hasFormula)
                  TextButton(
                    onPressed: _clear,
                    child: Text(l10n.csvFormulaRemove),
                  ),
                const Spacer(),
                FilledButton(
                  key: const Key('csv-formula-apply'),
                  onPressed: _problem == null ? _apply : null,
                  child: Text(l10n.csvFormulaApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
