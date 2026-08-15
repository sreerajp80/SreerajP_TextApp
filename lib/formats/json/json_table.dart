import 'package:text_data/formats/json/json_node.dart';

/// Which way a [JsonTable] column is sorted.
enum JsonSortDirection { none, ascending, descending }

/// A JSON array shown as a table (roadmap §4.3.1).
///
/// An array of objects becomes one row per element and one column per key —
/// the union of every element's keys, in the order they first appear, so a
/// record that is missing a field leaves a blank cell rather than shifting the
/// row. An array of plain values becomes a single "value" column.
///
/// Values are rendered to short display text: a nested object or array shows
/// its size (`{ 3 }`, `[ 2 ]`) rather than being flattened, because this is a
/// read-only overview, not an editor.
///
/// Pure Dart with no Flutter import, so it is host-tested.
class JsonTable {
  /// Column names, left to right.
  final List<String> columns;

  /// Rows of display text, each the same length as [columns].
  final List<List<String>> rows;

  /// True when the source array held plain values rather than objects, so the
  /// single column is synthetic.
  final bool isValueList;

  const JsonTable({
    required this.columns,
    required this.rows,
    this.isValueList = false,
  });

  static const JsonTable empty = JsonTable(
    columns: [],
    rows: [],
    isValueList: false,
  );

  int get columnCount => columns.length;
  int get rowCount => rows.length;
  bool get isEmpty => rows.isEmpty || columns.isEmpty;

  String cell(int row, int col) {
    if (row < 0 || row >= rows.length) return '';
    if (col < 0 || col >= rows[row].length) return '';
    return rows[row][col];
  }

  /// The name used for the single column of a value list.
  static const String valueColumnName = 'value';

  /// True when [node] is an array this view can show as a table: it has at
  /// least one element, and its elements are either all containers-free values
  /// or objects.
  static bool isTabular(JsonNode? node) {
    if (node == null || node.kind != JsonKind.array) return false;
    if (node.children.isEmpty) return false;
    final objects = node.children
        .where((c) => c.kind == JsonKind.object)
        .length;
    // Either mostly objects (a record list) or no objects at all (a value list).
    return objects == node.children.length || objects == 0;
  }

  /// Builds the table for [node]. A node that is not a usable array gives
  /// [empty] rather than an error, so the caller never has to guard a throw.
  factory JsonTable.fromNode(JsonNode? node) {
    if (!isTabular(node)) return empty;
    final children = node!.children;

    final allObjects = children.every((c) => c.kind == JsonKind.object);
    if (!allObjects) {
      return JsonTable(
        columns: const [valueColumnName],
        rows: [
          for (final child in children) [_display(child)],
        ],
        isValueList: true,
      );
    }

    // The column union, in the order the keys first appear.
    final columns = <String>[];
    final seen = <String>{};
    for (final child in children) {
      for (final member in child.children) {
        final key = member.key ?? '';
        if (seen.add(key)) columns.add(key);
      }
    }
    if (columns.isEmpty) return empty;

    final rows = <List<String>>[];
    for (final child in children) {
      final byKey = <String, JsonNode>{};
      for (final member in child.children) {
        byKey[member.key ?? ''] = member;
      }
      rows.add([
        for (final column in columns)
          byKey.containsKey(column) ? _display(byKey[column]!) : '',
      ]);
    }
    return JsonTable(columns: columns, rows: rows);
  }

  /// Row indices sorted by [column]. A column whose cells all read as numbers
  /// sorts numerically; anything else sorts as case-insensitive text. The sort
  /// is stable, and blank cells sort last so a gap never leads the list.
  List<int> sortedRowIndices(int column, JsonSortDirection direction) {
    final indices = [for (var i = 0; i < rows.length; i++) i];
    if (direction == JsonSortDirection.none) return indices;
    if (column < 0 || column >= columnCount) return indices;

    final values = [for (var r = 0; r < rows.length; r++) cell(r, column)];
    final numeric = values
        .where((v) => v.trim().isNotEmpty)
        .every((v) => num.tryParse(v.trim()) != null);
    final hasAnyValue = values.any((v) => v.trim().isNotEmpty);

    int compare(int a, int b) {
      final va = values[a].trim();
      final vb = values[b].trim();
      if (va.isEmpty && vb.isEmpty) return 0;
      if (va.isEmpty) return 1;
      if (vb.isEmpty) return -1;
      if (numeric && hasAnyValue) {
        final na = num.tryParse(va);
        final nb = num.tryParse(vb);
        if (na != null && nb != null) return na.compareTo(nb);
      }
      return va.toLowerCase().compareTo(vb.toLowerCase());
    }

    indices.sort((a, b) {
      final result = compare(a, b);
      if (result != 0) {
        return direction == JsonSortDirection.descending ? -result : result;
      }
      return a.compareTo(b);
    });
    return indices;
  }

  /// The table as CSV text, so a JSON array can be exported or shared as a
  /// table. Fields containing a comma, quote or newline are quoted.
  String toCsv() {
    final buffer = StringBuffer();
    buffer.writeln(columns.map(_csvField).join(','));
    for (final row in rows) {
      buffer.writeln(row.map(_csvField).join(','));
    }
    return buffer.toString().trimRight();
  }

  static String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Short display text for one value.
  static String _display(JsonNode node) {
    switch (node.kind) {
      case JsonKind.string:
        return node.stringValue ?? '';
      case JsonKind.number:
      case JsonKind.boolean:
      case JsonKind.nullValue:
        return node.rawText;
      case JsonKind.object:
        return '{ ${node.childCount} }';
      case JsonKind.array:
        return '[ ${node.childCount} ]';
    }
  }
}
