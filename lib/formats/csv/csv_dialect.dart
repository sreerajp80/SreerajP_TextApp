import '../../core/editor/encoding.dart';

/// The field separators a CSV file can use (task 7.1). Comma is the common case;
/// semicolon is frequent in locales that use the comma as a decimal mark; tab
/// and pipe show up in exported data files.
enum CsvDelimiter { comma, semicolon, tab, pipe }

extension CsvDelimiterInfo on CsvDelimiter {
  /// The literal character this delimiter writes between fields.
  String get char {
    switch (this) {
      case CsvDelimiter.comma:
        return ',';
      case CsvDelimiter.semicolon:
        return ';';
      case CsvDelimiter.tab:
        return '\t';
      case CsvDelimiter.pipe:
        return '|';
    }
  }

  /// Short human label for the save/metadata UI.
  String get label {
    switch (this) {
      case CsvDelimiter.comma:
        return 'Comma ( , )';
      case CsvDelimiter.semicolon:
        return 'Semicolon ( ; )';
      case CsvDelimiter.tab:
        return 'Tab';
      case CsvDelimiter.pipe:
        return 'Pipe ( | )';
    }
  }
}

/// How one CSV file is shaped: which delimiter and quote it uses, its line
/// ending, and whether the first row is a header (task 7.1).
///
/// Detection is our own (the `csv` package parses, but does not guess the
/// delimiter). It is pure Dart with no Flutter dependency so it is host-tested.
class CsvDialect {
  final CsvDelimiter delimiter;

  /// The quote character used around fields that contain a delimiter, a quote,
  /// or a line break. Standard CSV uses the double quote.
  final String quote;

  final LineEndingStyle lineEnding;

  /// Whether the first row names the columns.
  final bool hasHeader;

  const CsvDialect({
    this.delimiter = CsvDelimiter.comma,
    this.quote = '"',
    this.lineEnding = LineEndingStyle.lf,
    this.hasHeader = true,
  });

  CsvDialect copyWith({
    CsvDelimiter? delimiter,
    String? quote,
    LineEndingStyle? lineEnding,
    bool? hasHeader,
  }) {
    return CsvDialect(
      delimiter: delimiter ?? this.delimiter,
      quote: quote ?? this.quote,
      lineEnding: lineEnding ?? this.lineEnding,
      hasHeader: hasHeader ?? this.hasHeader,
    );
  }

  /// Guesses the delimiter of [sample] by scoring how consistently each
  /// candidate splits the sample's lines into the same number of fields.
  ///
  /// A good delimiter appears the same number of times on most lines (a table
  /// has a fixed column count). We count each candidate **outside quotes** on
  /// the first several non-empty lines, then prefer the candidate whose
  /// per-line count is both high and consistent. Ties fall back to comma.
  static CsvDelimiter detectDelimiter(String sample) {
    final lines = sample
        .split('\n')
        .map((l) => l.trimRight())
        .where((l) => l.isNotEmpty)
        .take(20)
        .toList();
    if (lines.isEmpty) return CsvDelimiter.comma;

    CsvDelimiter best = CsvDelimiter.comma;
    var bestScore = -1.0;
    for (final candidate in CsvDelimiter.values) {
      final counts =
          lines.map((l) => _countOutsideQuotes(l, candidate.char)).toList();
      final maxCount = counts.reduce((a, b) => a > b ? a : b);
      if (maxCount == 0) continue;
      // Most common non-zero count and how many lines agree with it.
      final mode = _modeOf(counts.where((c) => c > 0));
      final agree = counts.where((c) => c == mode).length;
      // Reward agreement across lines, then the field count itself.
      final score = agree + mode / 100.0;
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best;
  }

  /// Full dialect detection: delimiter from [sample], line ending from the
  /// decode step, and the caller's header choice (defaults to true).
  static CsvDialect detect(
    String sample, {
    required LineEndingStyle lineEnding,
    bool hasHeader = true,
  }) {
    return CsvDialect(
      delimiter: detectDelimiter(sample),
      lineEnding: lineEnding,
      hasHeader: hasHeader,
    );
  }

  static int _countOutsideQuotes(String line, String delimiter) {
    var count = 0;
    var inQuotes = false;
    final d = delimiter.codeUnitAt(0);
    for (var i = 0; i < line.length; i++) {
      final c = line.codeUnitAt(i);
      if (c == 0x22) {
        // A doubled quote inside a quoted field is an escaped quote, not a
        // toggle; skip the pair.
        if (inQuotes && i + 1 < line.length && line.codeUnitAt(i + 1) == 0x22) {
          i++;
          continue;
        }
        inQuotes = !inQuotes;
      } else if (!inQuotes && c == d) {
        count++;
      }
    }
    return count;
  }

  static int _modeOf(Iterable<int> values) {
    final freq = <int, int>{};
    for (final v in values) {
      freq[v] = (freq[v] ?? 0) + 1;
    }
    var mode = 0;
    var best = -1;
    freq.forEach((value, n) {
      if (n > best || (n == best && value > mode)) {
        best = n;
        mode = value;
      }
    });
    return mode;
  }
}
