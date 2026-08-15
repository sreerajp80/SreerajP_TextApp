import 'package:text_data/core/sql/sql_dataset.dart';
import 'package:text_data/formats/json/json_table.dart';

/// Turns a JSON array into a SQL table (Feature 4).
///
/// The array is flattened by the existing [JsonTable] — one row per element, one
/// column per key. A nested object or array keeps the same short display text
/// the table view shows (`{ 3 }`, `[ 2 ]`), so a query can select it but cannot
/// look inside it. Flattening nested JSON is a separate job.
///
/// Returns `null` when the document holds nothing tabular, so the caller does
/// not have to inspect the table itself.
///
/// Pure Dart with no Flutter import, so it is host-tested.
SqlDataset? jsonSqlDataset(
  JsonTable table, {
  required String tableName,
  required String sourceLabel,
  int maxRows = SqlDataset.maxRows,
}) {
  if (table.isEmpty) return null;
  return SqlDataset.fromRows(
    tableName: tableName,
    sourceLabel: sourceLabel,
    columnNames: table.columns,
    rows: table.rows,
    maxRows: maxRows,
  );
}
