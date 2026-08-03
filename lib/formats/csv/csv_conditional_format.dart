import 'csv_table.dart';
import 'csv_types.dart';

/// The test a conditional-formatting rule applies to a cell (roadmap §4.2.3).
enum CsvCondition {
  lessThan,
  greaterThan,
  equalTo,
  notEqualTo,
  contains,
  isEmpty,
  isDuplicate,
}

extension CsvConditionInfo on CsvCondition {
  /// True when the rule needs a comparison value typed by the user.
  bool get needsValue =>
      this != CsvCondition.isEmpty && this != CsvCondition.isDuplicate;

  /// The stored form, used to remember rules per file.
  String get code => name;

  static CsvCondition? fromCode(String code) {
    for (final c in CsvCondition.values) {
      if (c.name == code) return c;
    }
    return null;
  }
}

/// The highlight a matching cell gets. Kept as a plain choice rather than a
/// colour so the widget layer can map it onto the current Material theme (and
/// stay readable in dark mode).
enum CsvHighlight { red, yellow, green, blue }

extension CsvHighlightInfo on CsvHighlight {
  String get code => name;

  static CsvHighlight? fromCode(String code) {
    for (final h in CsvHighlight.values) {
      if (h.name == code) return h;
    }
    return null;
  }
}

/// One conditional-formatting rule: "highlight cells in this column in red when
/// the value is less than 0" (roadmap §4.2.3).
class CsvFormatRule {
  /// The column the rule watches, or null for every column.
  final int? column;

  final CsvCondition condition;

  /// The comparison value. Ignored for conditions where
  /// [CsvConditionInfo.needsValue] is false.
  final String value;

  final CsvHighlight highlight;

  const CsvFormatRule({
    required this.column,
    required this.condition,
    required this.highlight,
    this.value = '',
  });

  /// The stored form `column|condition|highlight|value`. The value comes last
  /// so a `|` inside it cannot break the split.
  String encode() =>
      '${column ?? -1}|${condition.code}|${highlight.code}|$value';

  /// Reads back [encode]'s form, or null when the text is not a valid rule.
  static CsvFormatRule? decode(String text) {
    final parts = text.split('|');
    if (parts.length < 4) return null;
    final columnValue = int.tryParse(parts[0]);
    if (columnValue == null) return null;
    final condition = CsvConditionInfo.fromCode(parts[1]);
    final highlight = CsvHighlightInfo.fromCode(parts[2]);
    if (condition == null || highlight == null) return null;
    return CsvFormatRule(
      column: columnValue < 0 ? null : columnValue,
      condition: condition,
      highlight: highlight,
      value: parts.sublist(3).join('|'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CsvFormatRule &&
      other.column == column &&
      other.condition == condition &&
      other.value == value &&
      other.highlight == highlight;

  @override
  int get hashCode => Object.hash(column, condition, value, highlight);
}

/// Applies a set of [CsvFormatRule]s to a table (roadmap §4.2.3).
///
/// Built once per rule set, not per cell: the "is duplicate" test needs to know
/// which values repeat in a column, and scanning the column for every cell
/// would make a large grid crawl. Ask [highlightFor] per cell afterwards — it
/// is a map lookup and a few comparisons.
///
/// Pure Dart with no Flutter import, so it is host-tested.
class CsvConditionalFormat {
  final List<CsvFormatRule> rules;

  /// For each column that a duplicate rule watches: the values that appear more
  /// than once in it.
  final Map<int, Set<String>> _duplicates;

  CsvConditionalFormat._(this.rules, this._duplicates);

  /// Prepares [rules] against [table].
  factory CsvConditionalFormat.prepare(CsvTable table, List<CsvFormatRule> rules) {
    final duplicates = <int, Set<String>>{};
    for (final rule in rules) {
      if (rule.condition != CsvCondition.isDuplicate) continue;
      final columns = rule.column != null
          ? [rule.column!]
          : [for (var c = 0; c < table.columnCount; c++) c];
      for (final c in columns) {
        duplicates.putIfAbsent(c, () => _repeatedValues(table, c));
      }
    }
    return CsvConditionalFormat._(List.unmodifiable(rules), duplicates);
  }

  /// True when there is nothing to draw, so the grid can skip the work.
  bool get isEmpty => rules.isEmpty;

  /// The highlight for the cell at [row], [col], or null when no rule matches.
  /// The **first** matching rule wins, so the user's order is their priority.
  CsvHighlight? highlightFor(CsvTable table, int row, int col) {
    if (rules.isEmpty) return null;
    final cell = table.cell(row, col);
    for (final rule in rules) {
      if (rule.column != null && rule.column != col) continue;
      if (_matches(rule, cell, col)) return rule.highlight;
    }
    return null;
  }

  bool _matches(CsvFormatRule rule, String cell, int col) {
    switch (rule.condition) {
      case CsvCondition.isEmpty:
        return cell.trim().isEmpty;
      case CsvCondition.isDuplicate:
        final values = _duplicates[col];
        if (values == null) return false;
        final key = cell.trim();
        // A blank cell is not a meaningful duplicate.
        return key.isNotEmpty && values.contains(key.toLowerCase());
      case CsvCondition.contains:
        if (rule.value.isEmpty) return false;
        return cell.toLowerCase().contains(rule.value.toLowerCase());
      case CsvCondition.equalTo:
        return _compare(cell, rule.value) == 0;
      case CsvCondition.notEqualTo:
        return _compare(cell, rule.value) != 0;
      case CsvCondition.lessThan:
        final result = _compare(cell, rule.value);
        return result != null && result < 0;
      case CsvCondition.greaterThan:
        final result = _compare(cell, rule.value);
        return result != null && result > 0;
    }
  }

  /// Compares a cell with a rule value: as numbers when both read as numbers,
  /// otherwise as case-insensitive text. Returns null when the comparison makes
  /// no sense (an empty cell against a number), so "less than 0" never lights
  /// up every blank cell.
  int? _compare(String cell, String value) {
    final a = parseNumber(cell) ?? parseCurrency(cell);
    final b = parseNumber(value) ?? parseCurrency(value);
    if (a != null && b != null) return a.compareTo(b);
    if (b != null && cell.trim().isEmpty) return null;
    return cell.trim().toLowerCase().compareTo(value.trim().toLowerCase());
  }

  static Set<String> _repeatedValues(CsvTable table, int col) {
    final seen = <String>{};
    final repeated = <String>{};
    for (final raw in table.column(col)) {
      final key = raw.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (!seen.add(key)) repeated.add(key);
    }
    return repeated;
  }
}
