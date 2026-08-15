import 'package:flutter/material.dart';

import 'package:text_data/l10n/app_localizations.dart';
import 'package:text_data/formats/csv/csv_conditional_format.dart';
import 'package:text_data/formats/csv/csv_document_session.dart';

/// The colour a highlight draws with, taken from the current theme so the grid
/// stays readable in light and dark mode.
///
/// Kept here (not in the rule model) so the pure rule logic has no Flutter
/// dependency.
Color csvHighlightColor(BuildContext context, CsvHighlight highlight) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  switch (highlight) {
    case CsvHighlight.red:
      return dark ? const Color(0xFF5C1F1F) : const Color(0xFFFFDAD6);
    case CsvHighlight.yellow:
      return dark ? const Color(0xFF574A16) : const Color(0xFFFFF3C4);
    case CsvHighlight.green:
      return dark ? const Color(0xFF1E4620) : const Color(0xFFD7F5DA);
    case CsvHighlight.blue:
      return dark ? const Color(0xFF1B3A57) : const Color(0xFFD6E8FF);
  }
}

String csvHighlightLabel(AppLocalizations l10n, CsvHighlight highlight) {
  switch (highlight) {
    case CsvHighlight.red:
      return l10n.csvHighlightRed;
    case CsvHighlight.yellow:
      return l10n.csvHighlightYellow;
    case CsvHighlight.green:
      return l10n.csvHighlightGreen;
    case CsvHighlight.blue:
      return l10n.csvHighlightBlue;
  }
}

String csvConditionLabel(AppLocalizations l10n, CsvCondition condition) {
  switch (condition) {
    case CsvCondition.lessThan:
      return l10n.csvConditionLessThan;
    case CsvCondition.greaterThan:
      return l10n.csvConditionGreaterThan;
    case CsvCondition.equalTo:
      return l10n.csvConditionEqualTo;
    case CsvCondition.notEqualTo:
      return l10n.csvConditionNotEqualTo;
    case CsvCondition.contains:
      return l10n.csvConditionContains;
    case CsvCondition.isEmpty:
      return l10n.csvConditionIsEmpty;
    case CsvCondition.isDuplicate:
      return l10n.csvConditionIsDuplicate;
  }
}

/// A sheet to list, add and remove conditional formatting rules
/// (roadmap §4.2.3), e.g. "highlight balance in red when it is below 0".
Future<void> showCsvConditionalFormatSheet(
  BuildContext context,
  CsvDocumentSession session,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, controller) =>
          _RulesBody(session: session, scrollController: controller),
    ),
  );
}

class _RulesBody extends StatefulWidget {
  final CsvDocumentSession session;
  final ScrollController scrollController;

  const _RulesBody({required this.session, required this.scrollController});

  @override
  State<_RulesBody> createState() => _RulesBodyState();
}

class _RulesBodyState extends State<_RulesBody> {
  String _columnName(int? col) {
    final l10n = AppLocalizations.of(context);
    if (col == null) return l10n.csvRuleEveryColumn;
    final header = widget.session.table.header;
    if (col < 0 || col >= header.length) return l10n.csvColumnN(col + 1);
    return header[col].isEmpty ? l10n.csvColumnN(col + 1) : header[col];
  }

  Future<void> _add() async {
    final rule = await showModalBottomSheet<CsvFormatRule>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _NewRuleBody(session: widget.session),
      ),
    );
    if (rule == null) return;
    widget.session.addFormatRule(rule);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final rules = widget.session.formatRules;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.csvHighlightRules,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (rules.isNotEmpty)
                TextButton(
                  onPressed: () {
                    widget.session.clearFormatRules();
                    setState(() {});
                  },
                  child: Text(l10n.actionClearAll),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (rules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    l10n.csvNoHighlightRules,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              for (var i = 0; i < rules.length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: csvHighlightColor(context, rules[i].highlight),
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  title: Text(_columnName(rules[i].column)),
                  subtitle: Text(
                    rules[i].condition.needsValue
                        ? '${csvConditionLabel(l10n, rules[i].condition)} '
                              '${rules[i].value}'
                        : csvConditionLabel(l10n, rules[i].condition),
                  ),
                  trailing: IconButton(
                    tooltip: l10n.actionRemove,
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      widget.session.removeFormatRuleAt(i);
                      setState(() {});
                    },
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('csv-add-highlight-rule'),
                onPressed: _add,
                icon: const Icon(Icons.add),
                label: Text(l10n.csvAddHighlightRule),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The form for one new rule: which column, which test, which colour.
class _NewRuleBody extends StatefulWidget {
  final CsvDocumentSession session;

  const _NewRuleBody({required this.session});

  @override
  State<_NewRuleBody> createState() => _NewRuleBodyState();
}

class _NewRuleBodyState extends State<_NewRuleBody> {
  final TextEditingController _value = TextEditingController();
  int? _column;
  CsvCondition _condition = CsvCondition.lessThan;
  CsvHighlight _highlight = CsvHighlight.red;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  bool get _canSave => !_condition.needsValue || _value.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final header = widget.session.table.header;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.csvAddHighlightRule, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _column ?? -1,
              decoration: InputDecoration(
                labelText: l10n.csvColumnLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                DropdownMenuItem(
                  value: -1,
                  child: Text(l10n.csvRuleEveryColumn),
                ),
                for (var c = 0; c < widget.session.table.columnCount; c++)
                  DropdownMenuItem(
                    value: c,
                    child: Text(
                      c < header.length && header[c].isNotEmpty
                          ? header[c]
                          : l10n.csvColumnN(c + 1),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(
                () => _column = value == null || value < 0 ? null : value,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CsvCondition>(
              initialValue: _condition,
              decoration: InputDecoration(
                labelText: l10n.csvRuleWhen,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final condition in CsvCondition.values)
                  DropdownMenuItem(
                    value: condition,
                    child: Text(csvConditionLabel(l10n, condition)),
                  ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _condition = value);
              },
            ),
            if (_condition.needsValue) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('csv-rule-value'),
                controller: _value,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.csvRuleValue,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.csvRuleHighlight, style: theme.textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final highlight in CsvHighlight.values)
                  ChoiceChip(
                    selected: _highlight == highlight,
                    avatar: Container(
                      decoration: BoxDecoration(
                        color: csvHighlightColor(context, highlight),
                        shape: BoxShape.circle,
                      ),
                    ),
                    label: Text(csvHighlightLabel(l10n, highlight)),
                    onSelected: (_) => setState(() => _highlight = highlight),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('csv-rule-save'),
                onPressed: _canSave
                    ? () => Navigator.of(context).pop(
                        CsvFormatRule(
                          column: _column,
                          condition: _condition,
                          value: _value.text.trim(),
                          highlight: _highlight,
                        ),
                      )
                    : null,
                child: Text(l10n.actionSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
