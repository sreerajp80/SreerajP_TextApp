import 'csv_table.dart';
import 'csv_types.dart';

/// The sort direction applied to a column header.
enum SortDirection { none, ascending, descending }

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
  static List<int> sort(
    CsvTable table,
    List<int> indices,
    int col,
    SortDirection direction,
  ) {
    if (direction == SortDirection.none) return List<int>.from(indices);
    if (col < 0 || col >= table.columnCount) return List<int>.from(indices);

    final type = inferColumnType(table.column(col));
    final numeric = type == ColumnType.number || type == ColumnType.currency;
    final sorted = List<int>.from(indices);

    int cmp(int a, int b) {
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

    sorted.sort(cmp);
    if (direction == SortDirection.descending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }
}
