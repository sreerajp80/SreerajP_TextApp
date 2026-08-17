import 'package:sreerajp_textapp/core/sql/sql_dataset.dart';

/// The kind of starter query, so the screen can label it in the user's language.
enum SqlPresetKind { selectAll, countRows, groupCount, orderBy, join }

/// A ready-to-run starter query, written against the tables that are actually
/// loaded (Feature 4).
class SqlPreset {
  final SqlPresetKind kind;
  final String sql;

  const SqlPreset(this.kind, this.sql);
}

/// Builds the starter queries for [datasets].
///
/// The point is that the user should never have to guess a table or column name:
/// every preset is written with the real names of the document on screen. A
/// preset that cannot be written (no text column to group by, only one table to
/// join) is simply left out rather than offered broken.
List<SqlPreset> buildSqlPresets(List<SqlDataset> datasets) {
  if (datasets.isEmpty) return const [];
  final main = datasets.first;
  final table = main.tableName;
  final presets = <SqlPreset>[
    SqlPreset(SqlPresetKind.selectAll, 'SELECT * FROM $table LIMIT 100'),
    SqlPreset(SqlPresetKind.countRows, 'SELECT COUNT(*) AS rows FROM $table'),
  ];

  final textColumn = _firstWhere(
    main.columns,
    (c) => c.type == SqlColumnType.text,
  );
  final numberColumn = _firstWhere(
    main.columns,
    (c) => c.type != SqlColumnType.text,
  );

  if (textColumn != null) {
    final group = textColumn.quotedName;
    final measure = numberColumn == null
        ? 'COUNT(*) AS count'
        : 'COUNT(*) AS count, SUM(${numberColumn.quotedName}) AS total';
    presets.add(
      SqlPreset(
        SqlPresetKind.groupCount,
        'SELECT $group, $measure\n'
        'FROM $table\n'
        'GROUP BY $group\n'
        'ORDER BY count DESC',
      ),
    );
  }

  if (numberColumn != null) {
    presets.add(
      SqlPreset(
        SqlPresetKind.orderBy,
        'SELECT * FROM $table\n'
        'WHERE ${numberColumn.quotedName} IS NOT NULL\n'
        'ORDER BY ${numberColumn.quotedName} DESC\n'
        'LIMIT 50',
      ),
    );
  }

  if (datasets.length > 1) {
    final other = datasets[1];
    final shared = _sharedColumn(main, other);
    final left = shared?.$1 ?? main.columns.first;
    final right = shared?.$2 ?? other.columns.first;
    presets.add(
      SqlPreset(
        SqlPresetKind.join,
        'SELECT a.*, b.*\n'
        'FROM $table AS a\n'
        'JOIN ${other.tableName} AS b\n'
        '  ON a.${left.quotedName} = b.${right.quotedName}\n'
        'LIMIT 100',
      ),
    );
  }

  return presets;
}

SqlColumn? _firstWhere(List<SqlColumn> columns, bool Function(SqlColumn) test) {
  for (final column in columns) {
    if (test(column)) return column;
  }
  return null;
}

/// The first pair of columns the two tables share by name (case-insensitive) —
/// the natural join key when there is one.
(SqlColumn, SqlColumn)? _sharedColumn(SqlDataset a, SqlDataset b) {
  for (final left in a.columns) {
    for (final right in b.columns) {
      if (left.name.toLowerCase() == right.name.toLowerCase()) {
        return (left, right);
      }
    }
  }
  return null;
}
