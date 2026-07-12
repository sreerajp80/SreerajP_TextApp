import 'package:csv/csv.dart';

import 'csv_dialect.dart';
import 'csv_table.dart';

/// Parses CSV text into a [CsvTable] using a chosen [CsvDialect] (task 7.1).
///
/// Reading is tolerant and never throws (CLAUDE.md §3.4): ragged rows are padded
/// to the widest row so the grid is always rectangular, and any decode failure
/// falls back to a best-effort single-column table rather than crashing.
class CsvParse {
  const CsvParse._();

  /// Parses [text] (newlines already normalized to `\n`) with [dialect].
  static CsvTable parse(String text, CsvDialect dialect) {
    if (text.isEmpty) {
      return CsvTable(
        header: dialect.hasHeader ? ['Column 1'] : ['Column 1'],
        rows: const [],
        hasHeader: false,
      );
    }

    List<List<String>> matrix;
    try {
      final codec = Csv(
        fieldDelimiter: dialect.delimiter.char,
        quoteCharacter: dialect.quote,
        autoDetect: false,
        skipEmptyLines: false,
        dynamicTyping: false,
      );
      matrix = codec
          .decode(text)
          .map((row) => row.map((cell) => cell?.toString() ?? '').toList())
          .toList();
    } catch (_) {
      // Best-effort fallback: one column, one row per physical line.
      matrix = text.split('\n').map((line) => [line]).toList();
    }

    // Drop a trailing empty row that a final newline can produce.
    if (matrix.isNotEmpty &&
        matrix.last.length == 1 &&
        matrix.last.first.isEmpty) {
      matrix.removeLast();
    }
    if (matrix.isEmpty) {
      return CsvTable(header: ['Column 1'], rows: const [], hasHeader: false);
    }

    // Rectangularize to the widest row.
    final width =
        matrix.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    for (final row in matrix) {
      if (row.length < width) {
        row.addAll(List.filled(width - row.length, ''));
      }
    }

    if (dialect.hasHeader) {
      final header = matrix.first;
      final rows = matrix.skip(1).toList();
      return CsvTable(header: header, rows: rows, hasHeader: true);
    }
    final header = [for (var i = 0; i < width; i++) 'Column ${i + 1}'];
    return CsvTable(header: header, rows: matrix, hasHeader: false);
  }
}
