import 'csv_dialect.dart';
import 'csv_table.dart';

/// Splits and merges CSV tables at the file level (task 7.6). Pure Dart,
/// host-tested; `merge(splitByRows(t, n)) == t` for any table.
class CsvSplitMerge {
  const CsvSplitMerge._();

  /// Splits [table] into parts of at most [rowsPerPart] data rows each. The
  /// header row is repeated on every part so each part is a valid CSV.
  static List<CsvTable> splitByRows(CsvTable table, int rowsPerPart) {
    if (rowsPerPart < 1) rowsPerPart = 1;
    if (table.rows.isEmpty) return [table.clone()];
    final parts = <CsvTable>[];
    for (var start = 0; start < table.rows.length; start += rowsPerPart) {
      final end = (start + rowsPerPart).clamp(0, table.rows.length);
      parts.add(CsvTable(
        header: List<String>.from(table.header),
        rows: table.rows
            .sublist(start, end)
            .map((r) => List<String>.from(r))
            .toList(),
        hasHeader: table.hasHeader,
      ));
    }
    return parts;
  }

  /// Splits [table] so each part's serialized text stays under [maxBytes]
  /// (UTF-8), the header repeated on each part. A single over-large row still
  /// forms its own part rather than being dropped.
  static List<CsvTable> splitBySize(
    CsvTable table,
    int maxBytes,
    CsvDialect dialect,
  ) {
    if (table.rows.isEmpty) return [table.clone()];
    final parts = <CsvTable>[];
    var current = <List<String>>[];

    CsvTable partOf(List<List<String>> rows) => CsvTable(
          header: List<String>.from(table.header),
          rows: rows.map((r) => List<String>.from(r)).toList(),
          hasHeader: table.hasHeader,
        );

    for (final row in table.rows) {
      final trial = partOf([...current, row]);
      final size = trial.toCsv(dialect).length;
      if (current.isNotEmpty && size > maxBytes) {
        parts.add(partOf(current));
        current = [row];
      } else {
        current.add(row);
      }
    }
    if (current.isNotEmpty) parts.add(partOf(current));
    return parts;
  }

  /// Concatenates [parts] that share the same columns into one table. The header
  /// and header flag come from the first part; each part's data rows are kept in
  /// order. Parts with a different column count are still appended (padded by the
  /// table model) rather than rejected.
  static CsvTable merge(List<CsvTable> parts) {
    if (parts.isEmpty) return CsvTable.empty();
    final first = parts.first;
    final rows = <List<String>>[];
    for (final part in parts) {
      for (final r in part.rows) {
        rows.add(List<String>.from(r));
      }
    }
    return CsvTable(
      header: List<String>.from(first.header),
      rows: rows,
      hasHeader: first.hasHeader,
    );
  }
}
