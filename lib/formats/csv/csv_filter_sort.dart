import 'csv_table.dart';
import 'csv_types.dart';

/// The sort direction applied to a column header.
enum SortDirection { none, ascending, descending }

/// One level of a multi-column sort (roadmap §4.2.1), e.g. "Department
/// ascending". Several of these in order make a sort hierarchy: the first level
/// decides, and later levels only break its ties.
class CsvSortSpec {
  final int column;
  final SortDirection direction;

  const CsvSortSpec(this.column, this.direction);

  /// The stored form `column:directionIndex`, used to remember the hierarchy
  /// per file.
  String encode() => '$column:${direction.index}';

  /// Reads back [encode]'s form. Returns null when the text is not a valid
  /// spec, so a corrupt stored value is ignored rather than crashing.
  static CsvSortSpec? decode(String text) {
    final parts = text.split(':');
    if (parts.length != 2) return null;
    final column = int.tryParse(parts[0]);
    final dirIndex = int.tryParse(parts[1]);
    if (column == null || column < 0) return null;
    if (dirIndex == null || dirIndex < 0 || dirIndex >= SortDirection.values.length) {
      return null;
    }
    return CsvSortSpec(column, SortDirection.values[dirIndex]);
  }

  @override
  bool operator ==(Object other) =>
      other is CsvSortSpec &&
      other.column == column &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(column, direction);

  @override
  String toString() => 'CsvSortSpec($column, ${direction.name})';
}

/// Pure helpers for table navigation (task 7.2): filtering/searching rows and
/// sorting by a column. They return **row indices into the original table** so
/// the grid can show a filtered/sorted order without mutating the underlying
/// [CsvTable] (edits still address original rows). Host-tested.
class CsvFilterSort {
  const CsvFilterSort._();

  /// Row indices whose any cell contains [query] (case-insensitive). An empty
  /// query returns every row in natural order.
  static List<int> filter(CsvTable table, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return [for (var i = 0; i < table.rowCount; i++) i];
    }
    final out = <int>[];
    for (var i = 0; i < table.rowCount; i++) {
      final row = table.rows[i];
      if (row.any((c) => c.toLowerCase().contains(q))) out.add(i);
    }
    return out;
  }

  /// Sorts [indices] by column [col]. Numeric/currency columns sort numerically;
  /// others sort as case-insensitive text. Returns a new list; [indices] is not
  /// mutated. [direction] of [SortDirection.none] returns [indices] unchanged.
  ///
  /// A one-level shortcut for [sortMulti].
  static List<int> sort(
    CsvTable table,
    List<int> indices,
    int col,
    SortDirection direction,
  ) {
    return sortMulti(table, indices, [CsvSortSpec(col, direction)]);
  }

  /// Sorts [indices] by a hierarchy of columns (roadmap §4.2.1). The first spec
  /// decides the order; each later spec only breaks the ties the ones before it
  /// left, so "Department ascending, then Salary descending" works as expected.
  ///
  /// Levels that name a column outside the table, or whose direction is
  /// [SortDirection.none], are skipped. The sort is **stable**: rows that every
  /// level ties on keep their incoming order. Returns a new list; [indices] is
  /// not mutated.
  static List<int> sortMulti(
    CsvTable table,
    List<int> indices,
    List<CsvSortSpec> specs,
  ) {
    final active = [
      for (final spec in specs)
        if (spec.direction != SortDirection.none &&
            spec.column >= 0 &&
            spec.column < table.columnCount)
          spec,
    ];
    final sorted = List<int>.from(indices);
    if (active.isEmpty) return sorted;

    // Work out once per level whether the column compares as numbers; inferring
    // it per comparison would re-scan the whole column on every step.
    final numeric = [
      for (final spec in active)
        () {
          final type = inferColumnType(table.column(spec.column));
          return type == ColumnType.number || type == ColumnType.currency;
        }(),
    ];

    // Remember where each row started so ties can fall back to that order —
    // this is what makes the sort stable.
    final position = <int, int>{};
    for (var i = 0; i < sorted.length; i++) {
      position.putIfAbsent(sorted[i], () => i);
    }

    int cmp(int a, int b) {
      for (var level = 0; level < active.length; level++) {
        final spec = active[level];
        final result = _compareCell(table, a, b, spec.column, numeric[level]);
        if (result != 0) {
          return spec.direction == SortDirection.descending ? -result : result;
        }
      }
      return (position[a] ?? 0).compareTo(position[b] ?? 0);
    }

    sorted.sort(cmp);
    return sorted;
  }

  /// Compares one column of two rows. In a numeric column a cell that does not
  /// read as a number (including an empty one) sorts after every real number.
  static int _compareCell(
    CsvTable table,
    int a,
    int b,
    int col,
    bool numeric,
  ) {
    final va = table.cell(a, col);
    final vb = table.cell(b, col);
    if (numeric) {
      final na = parseNumber(va) ?? parseCurrency(va);
      final nb = parseNumber(vb) ?? parseCurrency(vb);
      if (na != null && nb != null) return na.compareTo(nb);
      if (na != null) return -1;
      if (nb != null) return 1;
    }
    return va.toLowerCase().compareTo(vb.toLowerCase());
  }
}
