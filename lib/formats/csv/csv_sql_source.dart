import 'package:text_data/core/sql/sql_dataset.dart';
import 'package:text_data/formats/csv/csv_table.dart';

/// Turns an open CSV into a SQL table (Feature 4).
///
/// The whole table is loaded, not the filtered view: the filter is a convenience
/// on the grid, while SQL is the real way to narrow the data, and a query that
/// silently saw only part of the file would be misleading.
///
/// Pure Dart with no Flutter import, so it is host-tested.
SqlDataset csvSqlDataset(
  CsvTable table, {
  required String tableName,
  required String sourceLabel,
  int maxRows = SqlDataset.maxRows,
}) {
  return SqlDataset.fromRows(
    tableName: tableName,
    sourceLabel: sourceLabel,
    columnNames: table.header,
    rows: table.rows,
    maxRows: maxRows,
  );
}
