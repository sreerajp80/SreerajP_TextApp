import 'package:sreerajp_textapp/core/sql/sql_dataset.dart';

/// An open document that can be loaded as a SQL table (Feature 4).
///
/// The query engine must not know what a CSV or a JSON array is, so each format
/// module supplies one of these instead: a label to show, a table name to
/// suggest, and a [build] that produces the dataset when the user asks for it.
///
/// [build] returns `null` when the document holds nothing tabular (an empty CSV,
/// a JSON file that is not an array of records), so a caller never has to catch
/// a throw to find that out.
class SqlSource {
  /// The tab this source reads, used to keep one tab out of its own extra-table
  /// list.
  final String tabId;

  /// The file name, shown in the picker.
  final String displayName;

  /// The table name offered for it, before duplicates are resolved.
  final String suggestedTableName;

  final Future<SqlDataset?> Function() build;

  const SqlSource({
    required this.tabId,
    required this.displayName,
    required this.suggestedTableName,
    required this.build,
  });
}
