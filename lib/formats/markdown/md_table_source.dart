/// How a Markdown table column is lined up (roadmap §4.4.2).
enum MdColumnAlign { none, left, center, right }

extension MdColumnAlignInfo on MdColumnAlign {
  /// The separator-row cell that carries this alignment: `---`, `:---`,
  /// `:---:`, `---:`.
  String separator(int width) {
    final dashes = '-' * (width < 3 ? 3 : width);
    switch (this) {
      case MdColumnAlign.none:
        return dashes;
      case MdColumnAlign.left:
        return ':${dashes.substring(1)}';
      case MdColumnAlign.center:
        return ':${dashes.substring(2)}:';
      case MdColumnAlign.right:
        return '${dashes.substring(1)}:';
    }
  }
}

/// The span of a table inside a Markdown document: `[start, end)` offsets.
class MdTableSpan {
  final int start;
  final int end;

  const MdTableSpan(this.start, this.end);
}

/// A GFM pipe table, held as a grid so it can be edited in a form rather than
/// by lining up `|` characters by hand (roadmap §4.4.2).
///
/// Pure Dart with no Flutter import, so parsing and rendering are host-tested.
class MdTableData {
  /// The header cells.
  final List<String> header;

  /// The body rows. Each is padded to [columnCount].
  final List<List<String>> rows;

  /// One alignment per column.
  final List<MdColumnAlign> alignments;

  MdTableData({
    required this.header,
    required this.rows,
    required this.alignments,
  });

  /// A blank table to start from: [columns] columns and [rows] body rows.
  factory MdTableData.blank({int columns = 3, int rows = 2}) => MdTableData(
        header: [for (var c = 0; c < columns; c++) 'Column ${c + 1}'],
        rows: [
          for (var r = 0; r < rows; r++) [for (var c = 0; c < columns; c++) ''],
        ],
        alignments: List.filled(columns, MdColumnAlign.none),
      );

  int get columnCount => header.length;
  int get rowCount => rows.length;

  String cell(int row, int col) {
    if (row < 0 || row >= rows.length) return '';
    if (col < 0 || col >= rows[row].length) return '';
    return rows[row][col];
  }

  MdTableData copy() => MdTableData(
        header: List<String>.from(header),
        rows: rows.map((r) => List<String>.from(r)).toList(),
        alignments: List<MdColumnAlign>.from(alignments),
      );

  // --- edits (each changes this instance; the dialog owns a working copy) ---

  void setHeader(int col, String value) {
    if (col < 0 || col >= header.length) return;
    header[col] = value;
  }

  void setCell(int row, int col, String value) {
    if (row < 0 || row >= rows.length) return;
    if (col < 0 || col >= rows[row].length) return;
    rows[row][col] = value;
  }

  void setAlignment(int col, MdColumnAlign align) {
    if (col < 0 || col >= alignments.length) return;
    alignments[col] = align;
  }

  void addColumn() {
    header.add('Column ${columnCount + 1}');
    alignments.add(MdColumnAlign.none);
    for (final row in rows) {
      row.add('');
    }
  }

  void removeColumn(int col) {
    // A table needs at least one column to still be a table.
    if (columnCount <= 1 || col < 0 || col >= columnCount) return;
    header.removeAt(col);
    alignments.removeAt(col);
    for (final row in rows) {
      if (col < row.length) row.removeAt(col);
    }
  }

  void addRow() => rows.add(List.filled(columnCount, ''));

  void removeRow(int row) {
    if (row < 0 || row >= rows.length) return;
    rows.removeAt(row);
  }

  // --- rendering -----------------------------------------------------------

  /// The table as GFM Markdown, with every column padded to the same width so
  /// the source stays readable — the point of the builder is that the user never
  /// has to do this alignment themselves.
  ///
  /// A `|` inside a cell is escaped, and a newline becomes a `<br>`, so a value
  /// can never break the table it sits in.
  String toMarkdown() {
    if (columnCount == 0) return '';
    final headerCells = [for (final h in header) _escape(h)];
    final bodyCells = [
      for (final row in rows)
        [
          for (var c = 0; c < columnCount; c++)
            _escape(c < row.length ? row[c] : ''),
        ],
    ];

    // The width of each column: the widest of its header and body cells, and
    // never less than 3 so the separator row is still valid.
    final widths = <int>[];
    for (var c = 0; c < columnCount; c++) {
      var width = headerCells[c].length;
      for (final row in bodyCells) {
        if (row[c].length > width) width = row[c].length;
      }
      widths.add(width < 3 ? 3 : width);
    }

    final buffer = StringBuffer();
    buffer.writeln(_line([
      for (var c = 0; c < columnCount; c++) headerCells[c].padRight(widths[c]),
    ]));
    buffer.writeln(_line([
      for (var c = 0; c < columnCount; c++) alignments[c].separator(widths[c]),
    ]));
    for (final row in bodyCells) {
      buffer.writeln(_line([
        for (var c = 0; c < columnCount; c++) row[c].padRight(widths[c]),
      ]));
    }
    return buffer.toString().trimRight();
  }

  static String _line(List<String> cells) => '| ${cells.join(' | ')} |';

  static String _escape(String value) =>
      value.replaceAll('|', r'\|').replaceAll('\n', '<br>').trim();

  static String _unescape(String value) =>
      value.replaceAll(r'\|', '|').trim();

  // --- parsing -------------------------------------------------------------

  /// Reads a GFM pipe table out of [block], or null when the text is not one.
  ///
  /// A table needs a header line, a separator line of dashes, and any number of
  /// body lines. Ragged rows are padded or trimmed to the header's width rather
  /// than refused, so a hand-written table still opens in the builder.
  static MdTableData? parse(String block) {
    final lines = block
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length < 2) return null;
    if (!_looksLikeRow(lines[0])) return null;
    if (!isSeparatorLine(lines[1])) return null;

    final header = _splitRow(lines[0]);
    final separators = _splitRow(lines[1]);
    if (header.isEmpty) return null;

    final alignments = <MdColumnAlign>[];
    for (var c = 0; c < header.length; c++) {
      alignments.add(
        c < separators.length ? _alignOf(separators[c]) : MdColumnAlign.none,
      );
    }

    final rows = <List<String>>[];
    for (var i = 2; i < lines.length; i++) {
      if (!_looksLikeRow(lines[i])) break;
      final cells = _splitRow(lines[i]);
      rows.add([
        for (var c = 0; c < header.length; c++)
          c < cells.length ? cells[c] : '',
      ]);
    }

    return MdTableData(header: header, rows: rows, alignments: alignments);
  }

  /// True when [line] is a table separator like `|---|:--:|`.
  static bool isSeparatorLine(String line) {
    final trimmed = line.trim();
    if (!trimmed.contains('-')) return false;
    final cells = _splitRow(trimmed);
    if (cells.isEmpty) return false;
    return cells.every((c) => RegExp(r'^:?-{1,}:?$').hasMatch(c.trim()));
  }

  /// The span of the table that contains [offset] in [text], or null when the
  /// cursor is not inside one. Used so the builder opens on the table the user
  /// is standing in rather than always making a new one.
  static MdTableSpan? findTableAt(String text, int offset) {
    if (text.isEmpty) return null;
    final lines = text.split('\n');

    // Line starts, so a span can be turned back into character offsets.
    final starts = <int>[];
    var at = 0;
    for (final line in lines) {
      starts.add(at);
      at += line.length + 1;
    }

    final position = offset.clamp(0, text.length);
    var cursorLine = lines.length - 1;
    for (var i = 0; i < lines.length; i++) {
      final end = starts[i] + lines[i].length;
      if (position <= end) {
        cursorLine = i;
        break;
      }
    }

    // Walk out from the cursor over the run of table-looking lines.
    if (!_looksLikeRow(lines[cursorLine])) return null;
    var first = cursorLine;
    while (first > 0 && _looksLikeRow(lines[first - 1])) {
      first--;
    }
    var last = cursorLine;
    while (last + 1 < lines.length && _looksLikeRow(lines[last + 1])) {
      last++;
    }
    if (last - first < 1) return null;

    // A run only counts as a table when its second line is a separator.
    if (!isSeparatorLine(lines[first + 1])) return null;

    return MdTableSpan(starts[first], starts[last] + lines[last].length);
  }

  static bool _looksLikeRow(String line) {
    final trimmed = line.trim();
    return trimmed.contains('|') && trimmed.isNotEmpty;
  }

  /// Splits a `| a | b |` line into its cells, honouring `\|` escapes and
  /// dropping the empty parts the leading and trailing pipes create.
  static List<String> _splitRow(String line) {
    var trimmed = line.trim();
    if (trimmed.startsWith('|')) trimmed = trimmed.substring(1);
    if (trimmed.endsWith('|') && !trimmed.endsWith(r'\|')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }

    final cells = <String>[];
    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      final c = trimmed[i];
      if (c == r'\' && i + 1 < trimmed.length && trimmed[i + 1] == '|') {
        buffer.write(r'\|');
        i++;
        continue;
      }
      if (c == '|') {
        cells.add(_unescape(buffer.toString()));
        buffer.clear();
        continue;
      }
      buffer.write(c);
    }
    cells.add(_unescape(buffer.toString()));
    return cells;
  }

  static MdColumnAlign _alignOf(String cell) {
    final trimmed = cell.trim();
    final left = trimmed.startsWith(':');
    final right = trimmed.endsWith(':');
    if (left && right) return MdColumnAlign.center;
    if (left) return MdColumnAlign.left;
    if (right) return MdColumnAlign.right;
    return MdColumnAlign.none;
  }
}
