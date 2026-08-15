/// The storage class a column is loaded into (Feature 4).
///
/// Only three are used. Dates stay [text] on purpose: an ISO date sorts and
/// compares correctly as text, and anything else (`31/01/2026`) has no single
/// right numeric reading.
enum SqlColumnType { text, real, integer }

extension SqlColumnTypeSql on SqlColumnType {
  /// The SQLite type name used in `CREATE TABLE`.
  String get sqlType {
    switch (this) {
      case SqlColumnType.text:
        return 'TEXT';
      case SqlColumnType.real:
        return 'REAL';
      case SqlColumnType.integer:
        return 'INTEGER';
    }
  }
}

/// One column of a [SqlDataset].
class SqlColumn {
  /// The name the user types in a query. Never empty and unique within its
  /// table; it keeps the document's own header wherever that is possible.
  final String name;

  /// The header exactly as the document spells it, kept so the schema panel can
  /// show what was renamed.
  final String sourceName;

  final SqlColumnType type;

  const SqlColumn({
    required this.name,
    required this.sourceName,
    required this.type,
  });

  /// True when [name] had to be invented or changed to be usable.
  bool get wasRenamed => name != sourceName;

  /// The name written into SQL, quoted only when it is not a plain identifier.
  String get quotedName => SqlDataset.quoteIdentifier(name);
}

/// One document loaded as a SQL table (Feature 4).
///
/// This is a **format-neutral** model: a table name, typed columns, and rows of
/// plain strings. The CSV and JSON adapters in `lib/formats/` build it, so this
/// file — and the query engine above it — never import a format module.
///
/// Pure Dart with no Flutter or sqflite import, so it is host-tested.
class SqlDataset {
  /// How many source rows are copied into SQLite at most. A phone has to hold
  /// this copy **and** the document's own buffer, so the cap is deliberate; the
  /// UI says when it bites rather than silently querying part of a file.
  static const int maxRows = 200000;

  /// The name the user writes in `FROM`. Always a plain identifier.
  final String tableName;

  /// What to call this table on screen — usually the file name.
  final String sourceLabel;

  final List<SqlColumn> columns;

  /// Row values as they read in the document. Conversion to numbers happens at
  /// insert time, so the dataset stays a faithful copy of the text.
  final List<List<String>> rows;

  /// How many rows the document had before [maxRows] was applied.
  final int sourceRowCount;

  const SqlDataset({
    required this.tableName,
    required this.sourceLabel,
    required this.columns,
    required this.rows,
    required this.sourceRowCount,
  });

  int get rowCount => rows.length;
  int get columnCount => columns.length;

  /// True when rows were left behind because of [maxRows].
  bool get truncated => sourceRowCount > rows.length;

  /// Builds a dataset from raw header names and string rows, inferring each
  /// column's type from its own values.
  ///
  /// [tableName] is sanitised to a plain identifier. Blank or repeated column
  /// names are repaired (`column_1`, `total_2`) so every column is reachable
  /// from a query.
  factory SqlDataset.fromRows({
    required String tableName,
    required String sourceLabel,
    required List<String> columnNames,
    required List<List<String>> rows,
    int maxRows = SqlDataset.maxRows,
  }) {
    final safeName = sanitizeTableName(tableName);
    final names = _uniqueColumnNames(columnNames);

    final kept = rows.length > maxRows ? rows.sublist(0, maxRows) : rows;
    final columns = <SqlColumn>[];
    for (var c = 0; c < names.length; c++) {
      columns.add(
        SqlColumn(
          name: names[c],
          sourceName: c < columnNames.length ? columnNames[c] : '',
          type: inferType([
            for (final row in kept) c < row.length ? row[c] : '',
          ]),
        ),
      );
    }

    // Every row is padded/trimmed to the column count, so a ragged CSV loads
    // instead of failing (CLAUDE.md §3.4).
    final fitted = <List<String>>[
      for (final row in kept) _fit(row, names.length),
    ];

    return SqlDataset(
      tableName: safeName,
      sourceLabel: sourceLabel,
      columns: columns,
      rows: fitted,
      sourceRowCount: rows.length,
    );
  }

  /// The value handed to SQLite for [raw] in a column of [type].
  ///
  /// A blank cell becomes `NULL`, never `0` or `''` — otherwise `AVG` and
  /// `COUNT` would quietly count cells that hold nothing.
  static Object? sqlValue(String raw, SqlColumnType type) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    switch (type) {
      case SqlColumnType.text:
        return raw;
      case SqlColumnType.real:
        return (parseNumeric(trimmed) ?? 0).toDouble();
      case SqlColumnType.integer:
        return _boolValue(trimmed);
    }
  }

  /// `CREATE TABLE` for this dataset.
  String createTableSql() {
    final defs = columns
        .map((c) => '${c.quotedName} ${c.type.sqlType}')
        .join(', ');
    return 'CREATE TABLE ${quoteIdentifier(tableName)} ($defs)';
  }

  /// `INSERT` with one placeholder per column, used with a prepared batch.
  String insertSql() {
    final names = columns.map((c) => c.quotedName).join(', ');
    final marks = List.filled(columns.length, '?').join(', ');
    return 'INSERT INTO ${quoteIdentifier(tableName)} ($names) VALUES ($marks)';
  }

  /// The values of one row, in column order and already converted.
  List<Object?> valuesOf(int row) => [
    for (var c = 0; c < columns.length; c++)
      sqlValue(rows[row][c], columns[c].type),
  ];

  // --- naming ---------------------------------------------------------------

  /// A plain lowercase identifier built from [name]: anything that is not a
  /// letter, digit or underscore becomes `_`, and a name that would start with a
  /// digit is prefixed. An unusable name falls back to `data`.
  static String sanitizeTableName(String name) {
    var out = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    out = out.replaceAll(RegExp('_+'), '_');
    out = out.replaceAll(RegExp(r'^_+|_+$'), '');
    if (out.isEmpty) return 'data';
    if (RegExp(r'^[0-9]').hasMatch(out)) out = 't_$out';
    return out;
  }

  /// Quotes [name] for SQL. A plain identifier is returned untouched so the
  /// generated SQL stays readable; anything else is double-quoted with embedded
  /// quotes doubled, which is what keeps a header like `He said "hi"` from
  /// breaking the schema.
  static String quoteIdentifier(String name) {
    if (isPlainIdentifier(name)) return name;
    return '"${name.replaceAll('"', '""')}"';
  }

  /// True when [name] can be written in SQL without quotes.
  static bool isPlainIdentifier(String name) =>
      RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name) &&
      !_reservedWords.contains(name.toLowerCase());

  static List<String> _uniqueColumnNames(List<String> raw) {
    final used = <String>{};
    final out = <String>[];
    for (var i = 0; i < raw.length; i++) {
      var name = raw[i].trim();
      if (name.isEmpty) name = 'column_${i + 1}';
      var candidate = name;
      var suffix = 2;
      while (!used.add(candidate.toLowerCase())) {
        candidate = '${name}_$suffix';
        suffix++;
      }
      out.add(candidate);
    }
    return out;
  }

  static List<String> _fit(List<String> row, int width) {
    if (row.length == width) return List<String>.from(row);
    final out = List<String>.from(row);
    if (out.length < width) {
      out.addAll(List.filled(width - out.length, ''));
    } else {
      out.removeRange(width, out.length);
    }
    return out;
  }

  // --- type inference -------------------------------------------------------

  /// The column type for a set of values. Blanks are ignored, and a column is
  /// numeric or boolean only when **every** non-blank value fits — one stray
  /// word keeps the whole column as text rather than losing that value.
  ///
  /// The number and currency readings are kept here, rather than reused from
  /// `formats/csv`, so this core module does not depend on a format module
  /// (CLAUDE.md §4, dependency direction).
  static SqlColumnType inferType(Iterable<String> values) {
    final nonEmpty = values
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
    if (nonEmpty.isEmpty) return SqlColumnType.text;
    if (nonEmpty.every((v) => _boolWords.contains(v.toLowerCase()))) {
      return SqlColumnType.integer;
    }
    if (nonEmpty.every((v) => parseNumeric(v) != null)) {
      return SqlColumnType.real;
    }
    return SqlColumnType.text;
  }

  /// Reads `1234`, `1,234.5` and `$1,299.00` / `₹500` as a number, or null.
  static num? parseNumeric(String value) {
    var s = value.trim();
    if (s.isEmpty) return null;
    if (s.isNotEmpty &&
        (_currencySymbols.contains(s[0]) ||
            _currencySymbols.contains(s[s.length - 1]))) {
      s = s.replaceAll(RegExp('[$_currencySymbols]'), '').trim();
    }
    s = s.replaceAll(',', '');
    if (s.isEmpty) return null;
    return num.tryParse(s);
  }

  static int _boolValue(String value) =>
      (value.toLowerCase() == 'true' || value.toLowerCase() == 'yes') ? 1 : 0;

  static const _boolWords = {'true', 'false', 'yes', 'no'};
  static const _currencySymbols = r'$€£¥₹';

  /// SQL words that must not be used bare as an identifier.
  static const _reservedWords = {
    'select',
    'from',
    'where',
    'group',
    'order',
    'by',
    'join',
    'on',
    'as',
    'and',
    'or',
    'not',
    'null',
    'in',
    'is',
    'like',
    'limit',
    'offset',
    'union',
    'having',
    'case',
    'when',
    'then',
    'else',
    'end',
    'table',
    'index',
    'values',
    'default',
    'primary',
    'key',
    'unique',
    'check',
    'references',
    'using',
    'natural',
    'left',
    'right',
    'inner',
    'outer',
    'cross',
    'distinct',
    'all',
    'exists',
    'between',
    'collate',
    'asc',
    'desc',
    'with',
  };
}
