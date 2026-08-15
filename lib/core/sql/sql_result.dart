/// One query's result, already turned into display text (Feature 4).
///
/// Values arrive from SQLite as `int`, `double`, `String`, `null` or bytes. They
/// are rendered once, here, so the grid, the clipboard copy and the CSV export
/// all show exactly the same thing.
///
/// Pure Dart, host-tested.
class SqlQueryResult {
  final List<String> columns;
  final List<List<String>> rows;

  /// True when the engine stopped short of the full result set.
  final bool truncated;

  /// How long the query took, in milliseconds.
  final int elapsedMs;

  const SqlQueryResult({
    required this.columns,
    required this.rows,
    this.truncated = false,
    this.elapsedMs = 0,
  });

  static const SqlQueryResult empty = SqlQueryResult(columns: [], rows: []);

  int get rowCount => rows.length;
  int get columnCount => columns.length;
  bool get isEmpty => rows.isEmpty;

  String cell(int row, int col) {
    if (row < 0 || row >= rows.length) return '';
    if (col < 0 || col >= rows[row].length) return '';
    return rows[row][col];
  }

  /// The result as CSV text, for the clipboard and for "save as CSV".
  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln(columns.map(csvField).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(csvField).join(','));
    }
    return buffer.toString().trimRight();
  }

  static String csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Display text for one SQLite value. `NULL` shows as an empty cell; bytes are
  /// summarised rather than dumped, because a blob is not readable text.
  static String display(Object? value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is double) {
      // 12.0 reads better as 12 — SQLite gives REAL back for whole numbers too.
      if (value == value.roundToDouble() && value.abs() < 1e15) {
        return value.toInt().toString();
      }
      return value.toString();
    }
    if (value is List<int>) return '<${value.length} bytes>';
    return value.toString();
  }
}

/// A query that could not run. [message] is safe to show; it never contains the
/// document's data, only SQLite's own complaint about the statement.
class SqlQueryException implements Exception {
  final String message;

  const SqlQueryException(this.message);

  @override
  String toString() => 'SqlQueryException: $message';
}
