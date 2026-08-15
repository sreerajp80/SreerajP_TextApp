import 'dart:math';

/// Result of a column or multi-line edit operation.
class ColumnEditResult {
  final String text;
  final int startLineIndex;
  final int endLineIndex;
  final int affectedLineCount;
  final String? extractedBlock;

  const ColumnEditResult({
    required this.text,
    required this.startLineIndex,
    required this.endLineIndex,
    required this.affectedLineCount,
    this.extractedBlock,
  });
}

/// Pure-Dart engine for multi-cursor and column block text operations across
/// lines (task 4.1 in architecture & roadmap).
///
/// Has **no Flutter dependencies** and can be tested in isolation.
class ColumnSelectionEngine {
  const ColumnSelectionEngine._();

  /// Splits [text] into lines and detects whether CRLF (`\r\n`) or LF (`\n`) is used.
  static (List<String> lines, String lineEnding) _splitLines(String text) {
    final bool hasCrlf = text.contains('\r\n');
    final String lineEnding = hasCrlf ? '\r\n' : '\n';
    final List<String> lines = text.split(RegExp(r'\r?\n'));
    return (lines, lineEnding);
  }

  /// Clamps [startLineIndex] and [endLineIndex] to valid 0-based line bounds.
  static (int start, int end) _normalizeLineBounds(
    int lineCount,
    int startLineIndex,
    int endLineIndex,
  ) {
    if (lineCount == 0) return (0, 0);
    final int minBound = min(
      startLineIndex,
      endLineIndex,
    ).clamp(0, lineCount - 1);
    final int maxBound = max(
      startLineIndex,
      endLineIndex,
    ).clamp(0, lineCount - 1);
    return (minBound, maxBound);
  }

  /// Inserts [prefix] at the start of each line in `[startLineIndex..endLineIndex]`.
  static ColumnEditResult applyPrefix(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    required String prefix,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );

    for (int i = start; i <= end; i++) {
      lines[i] = '$prefix${lines[i]}';
    }

    return ColumnEditResult(
      text: lines.join(ending),
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
    );
  }

  /// Appends [suffix] to the end of each line in `[startLineIndex..endLineIndex]`.
  static ColumnEditResult applySuffix(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    required String suffix,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );

    for (int i = start; i <= end; i++) {
      lines[i] = '${lines[i]}$suffix';
    }

    return ColumnEditResult(
      text: lines.join(ending),
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
    );
  }

  /// Wraps each line in `[startLineIndex..endLineIndex]` with [prefix] and [suffix].
  static ColumnEditResult applyWrap(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    required String prefix,
    required String suffix,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );

    for (int i = start; i <= end; i++) {
      lines[i] = '$prefix${lines[i]}$suffix';
    }

    return ColumnEditResult(
      text: lines.join(ending),
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
    );
  }

  /// Inserts [insertText] at [column] across lines `[startLineIndex..endLineIndex]`.
  /// If [padShorterLines] is true and a line has fewer characters than [column],
  /// spaces are padded up to [column].
  static ColumnEditResult applyInsertAtColumn(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    required int column,
    required String insertText,
    bool padShorterLines = true,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );
    final int targetCol = max(0, column);

    for (int i = start; i <= end; i++) {
      final String line = lines[i];
      if (line.length < targetCol) {
        if (padShorterLines) {
          final String padded = line.padRight(targetCol, ' ');
          lines[i] = '$padded$insertText';
        } else {
          // Append to end of shorter line
          lines[i] = '$line$insertText';
        }
      } else {
        final String head = line.substring(0, targetCol);
        final String tail = line.substring(targetCol);
        lines[i] = '$head$insertText$tail';
      }
    }

    return ColumnEditResult(
      text: lines.join(ending),
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
    );
  }

  /// Extracts a rectangular vertical column block of characters `[startCol..endCol]`
  /// across lines `[startLineIndex..endLineIndex]`. Returns the block lines joined with newlines.
  static ColumnEditResult extractColumnBlock(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    required int startCol,
    required int endCol,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );
    final int colMin = max(0, min(startCol, endCol));
    final int colMax = max(0, max(startCol, endCol));

    final List<String> extractedLines = [];
    for (int i = start; i <= end; i++) {
      final String line = lines[i];
      if (line.length <= colMin) {
        extractedLines.add('');
      } else {
        final int lineEnd = min(line.length, colMax);
        extractedLines.add(line.substring(colMin, lineEnd));
      }
    }

    return ColumnEditResult(
      text: text,
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
      extractedBlock: extractedLines.join(ending),
    );
  }

  /// Replaces the rectangular vertical column block `[startCol..endCol]`
  /// across lines `[startLineIndex..endLineIndex]` with [replacement].
  static ColumnEditResult replaceColumnBlock(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    required int startCol,
    required int endCol,
    required String replacement,
    bool padShorterLines = false,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );
    final int colMin = max(0, min(startCol, endCol));
    final int colMax = max(0, max(startCol, endCol));

    for (int i = start; i <= end; i++) {
      final String line = lines[i];
      if (line.length < colMin) {
        if (padShorterLines) {
          final String padded = line.padRight(colMin, ' ');
          lines[i] = '$padded$replacement';
        }
      } else {
        final String head = line.substring(0, colMin);
        final int actualEnd = min(line.length, colMax);
        final String tail = line.substring(actualEnd);
        lines[i] = '$head$replacement$tail';
      }
    }

    return ColumnEditResult(
      text: lines.join(ending),
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
    );
  }

  /// Deletes the vertical column block `[startCol..endCol]` across lines `[startLineIndex..endLineIndex]`.
  static ColumnEditResult deleteColumnBlock(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    required int startCol,
    required int endCol,
  }) {
    return replaceColumnBlock(
      text,
      startLineIndex: startLineIndex,
      endLineIndex: endLineIndex,
      startCol: startCol,
      endCol: endCol,
      replacement: '',
      padShorterLines: false,
    );
  }

  /// Inserts auto-incrementing numbers across lines `[startLineIndex..endLineIndex]`.
  ///
  /// - [startNumber]: Initial sequence number (e.g. 1).
  /// - [step]: Increment amount per line (e.g. 1).
  /// - [format]: Template string containing `%d` (e.g. `%d. `, `[%d]`, `%d: `).
  /// - [padding]: Minimum digits with zero-padding (e.g. `2` -> `01`, `02`).
  /// - [column]: Column index to insert at (defaults to 0 for start of line).
  static ColumnEditResult applyNumbering(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    int startNumber = 1,
    int step = 1,
    String format = '%d. ',
    int padding = 0,
    int column = 0,
    bool padShorterLines = true,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );
    final int targetCol = max(0, column);

    int currentNumber = startNumber;
    for (int i = start; i <= end; i++) {
      final String numStr = padding > 0
          ? currentNumber.toString().padLeft(padding, '0')
          : currentNumber.toString();
      final String token = format.replaceAll('%d', numStr);

      final String line = lines[i];
      if (line.length < targetCol) {
        if (padShorterLines) {
          final String padded = line.padRight(targetCol, ' ');
          lines[i] = '$padded$token';
        } else {
          lines[i] = '$line$token';
        }
      } else {
        final String head = line.substring(0, targetCol);
        final String tail = line.substring(targetCol);
        lines[i] = '$head$token$tail';
      }
      currentNumber += step;
    }

    return ColumnEditResult(
      text: lines.join(ending),
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
    );
  }

  /// Trims whitespace from lines in `[startLineIndex..endLineIndex]`.
  static ColumnEditResult applyTrim(
    String text, {
    required int startLineIndex,
    required int endLineIndex,
    bool trimLeading = true,
    bool trimTrailing = true,
  }) {
    final (lines, ending) = _splitLines(text);
    final (start, end) = _normalizeLineBounds(
      lines.length,
      startLineIndex,
      endLineIndex,
    );

    for (int i = start; i <= end; i++) {
      String line = lines[i];
      if (trimLeading) line = line.replaceFirst(RegExp(r'^\s+'), '');
      if (trimTrailing) line = line.replaceFirst(RegExp(r'\s+$'), '');
      lines[i] = line;
    }

    return ColumnEditResult(
      text: lines.join(ending),
      startLineIndex: start,
      endLineIndex: end,
      affectedLineCount: end - start + 1,
    );
  }
}
