import 'package:sreerajp_textapp/formats/csv/csv_table.dart';
import 'package:sreerajp_textapp/formats/csv/csv_types.dart';

/// The outcome of evaluating one formula for one row (roadmap §4.2.2).
///
/// Either [value] is set (the formula worked) or [error] is (it did not). The
/// evaluator never throws — a bad formula shows a short message in the cell
/// instead, per CLAUDE.md §3.4.
class FormulaResult {
  final num? value;
  final String? error;

  const FormulaResult.value(num this.value) : error = null;
  const FormulaResult.failure(String this.error) : value = null;

  bool get ok => error == null;

  /// The text written into the cell: a tidy number, or `#ERROR`.
  String get display {
    final v = value;
    if (v == null) return '#ERROR';
    if (v is int) return v.toString();
    if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
    return v
        .toStringAsFixed(4)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}

/// A small spreadsheet-formula evaluator over a [CsvTable] (roadmap §4.2.2).
///
/// It is deliberately **small**: enough for the calculated columns the app
/// offers, not a spreadsheet engine. What it understands:
///
/// - Numbers: `12`, `-3.5`
/// - Arithmetic: `+ - * /` and brackets, with normal precedence
/// - A cell in this row by column letter: `B` (or `B#`)
/// - An absolute cell: `A1` — column A, data row 1 (1-based, header excluded)
/// - A range: `A1:A10`, or a whole column `A:A`
/// - Functions: `SUM`, `PRODUCT`, `AVG` / `AVERAGE`, `MIN`, `MAX`, `COUNT`
///
/// A leading `=` is optional. Column letters follow spreadsheet order:
/// `A`…`Z`, then `AA`, `AB`, … Anything else is a friendly error.
///
/// Pure Dart with no Flutter import, so it is host-tested.
class CsvFormula {
  const CsvFormula._();

  /// Evaluates [formula] for data row [row] (0-based) of [table].
  ///
  /// [selfColumn] is the column the formula is being written into. A formula
  /// that reads its own column would depend on its own result, so that is
  /// refused with a clear message rather than looping.
  static FormulaResult evaluate(
    CsvTable table,
    String formula,
    int row, {
    int? selfColumn,
  }) {
    final source = formula.trim();
    if (source.isEmpty) {
      return const FormulaResult.failure('The formula is empty.');
    }
    final body = source.startsWith('=') ? source.substring(1) : source;
    try {
      final parser = _Parser(body, table, row, selfColumn);
      final value = parser.parseExpression();
      parser.expectEnd();
      if (value.isNaN || value.isInfinite) {
        return const FormulaResult.failure('The result is not a number.');
      }
      return FormulaResult.value(value);
    } on _FormulaError catch (e) {
      return FormulaResult.failure(e.message);
    }
  }

  /// Checks a formula once without needing a row — used to show the user a
  /// problem while they are typing. Returns null when it looks usable, or a
  /// friendly message when it does not.
  static String? validate(CsvTable table, String formula, {int? selfColumn}) {
    final result = evaluate(table, formula, 0, selfColumn: selfColumn);
    return result.ok ? null : result.error;
  }

  /// The spreadsheet letters for a 0-based column index: 0 → `A`, 25 → `Z`,
  /// 26 → `AA`.
  static String columnLetters(int index) {
    if (index < 0) return '';
    var n = index;
    final buffer = StringBuffer();
    while (true) {
      buffer.write(String.fromCharCode(0x41 + (n % 26)));
      n = n ~/ 26 - 1;
      if (n < 0) break;
    }
    return String.fromCharCodes(buffer.toString().codeUnits.reversed);
  }

  /// The 0-based column index for spreadsheet [letters], or null when the text
  /// is not a run of letters.
  static int? columnIndex(String letters) {
    if (letters.isEmpty) return null;
    var value = 0;
    for (var i = 0; i < letters.length; i++) {
      final c = letters.codeUnitAt(i);
      final upper = (c >= 0x61 && c <= 0x7A) ? c - 32 : c;
      if (upper < 0x41 || upper > 0x5A) return null;
      value = value * 26 + (upper - 0x41 + 1);
    }
    return value - 1;
  }
}

class _FormulaError implements Exception {
  final String message;
  _FormulaError(this.message);
}

/// A hand-written recursive-descent parser and evaluator in one pass. The
/// formulas are short, so there is no benefit in building a tree first.
class _Parser {
  final String src;
  final CsvTable table;
  final int row;
  final int? selfColumn;
  int pos = 0;

  _Parser(this.src, this.table, this.row, this.selfColumn);

  // --- tokens --------------------------------------------------------------

  void _skipSpace() {
    while (pos < src.length && src[pos].trim().isEmpty) {
      pos++;
    }
  }

  bool _eat(String ch) {
    _skipSpace();
    if (pos < src.length && src[pos] == ch) {
      pos++;
      return true;
    }
    return false;
  }

  String? _peek() {
    _skipSpace();
    return pos < src.length ? src[pos] : null;
  }

  void expectEnd() {
    _skipSpace();
    if (pos < src.length) {
      throw _FormulaError('"${src[pos]}" was not expected here.');
    }
  }

  // --- grammar -------------------------------------------------------------

  double parseExpression() {
    var value = _parseTerm();
    while (true) {
      if (_eat('+')) {
        value += _parseTerm();
      } else if (_eat('-')) {
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseUnary();
    while (true) {
      if (_eat('*')) {
        value *= _parseUnary();
      } else if (_eat('/')) {
        final divisor = _parseUnary();
        if (divisor == 0) throw _FormulaError('Cannot divide by zero.');
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseUnary() {
    if (_eat('-')) return -_parseUnary();
    if (_eat('+')) return _parseUnary();
    return _parseAtom();
  }

  double _parseAtom() {
    final ch = _peek();
    if (ch == null) throw _FormulaError('The formula ends too early.');

    if (ch == '(') {
      pos++;
      final value = parseExpression();
      if (!_eat(')')) throw _FormulaError('A ")" is missing.');
      return value;
    }

    if (_isDigit(ch) || ch == '.') return _parseNumber();
    if (_isLetter(ch)) return _parseNameOrReference();

    throw _FormulaError('"$ch" was not expected here.');
  }

  double _parseNumber() {
    final start = pos;
    while (pos < src.length && (_isDigit(src[pos]) || src[pos] == '.')) {
      pos++;
    }
    final text = src.substring(start, pos);
    final value = double.tryParse(text);
    if (value == null) throw _FormulaError('"$text" is not a number.');
    return value;
  }

  /// Reads a run of letters, then decides what it was: a function call when a
  /// `(` follows, otherwise a cell or column reference.
  double _parseNameOrReference() {
    final start = pos;
    while (pos < src.length && _isLetter(src[pos])) {
      pos++;
    }
    final letters = src.substring(start, pos);

    if (_peek() == '(') {
      pos++;
      return _parseFunction(letters.toUpperCase());
    }

    // A reference: letters, then an optional row number, then an optional
    // `:` range end.
    final first = _readReferenceTail(letters);
    if (_peek() == ':') {
      pos++;
      _skipSpace();
      final endStart = pos;
      while (pos < src.length && _isLetter(src[pos])) {
        pos++;
      }
      final endLetters = src.substring(endStart, pos);
      if (endLetters.isEmpty) {
        throw _FormulaError('A column is missing after ":".');
      }
      final second = _readReferenceTail(endLetters);
      final values = _rangeValues(first, second);
      if (values.length != 1) {
        throw _FormulaError(
          'A range needs to be inside SUM, AVG, MIN, MAX, COUNT or PRODUCT.',
        );
      }
      return values.first;
    }
    return _cellValue(first.column, first.row ?? row);
  }

  _Ref _readReferenceTail(String letters) {
    final column = CsvFormula.columnIndex(letters);
    if (column == null) throw _FormulaError('"$letters" is not a column.');
    // An optional 1-based data-row number; `#` means "this row".
    if (pos < src.length && src[pos] == '#') {
      pos++;
      return _Ref(column, null);
    }
    final start = pos;
    while (pos < src.length && _isDigit(src[pos])) {
      pos++;
    }
    if (start == pos) return _Ref(column, null);
    final number = int.tryParse(src.substring(start, pos));
    if (number == null || number < 1) {
      throw _FormulaError(
        '"${src.substring(start, pos)}" is not a row number.',
      );
    }
    return _Ref(column, number - 1);
  }

  double _parseFunction(String name) {
    final args = <double>[];
    if (!_eat(')')) {
      while (true) {
        args.addAll(_parseArgument());
        if (_eat(',')) continue;
        if (_eat(')')) break;
        throw _FormulaError('A ")" is missing in $name.');
      }
    }

    switch (name) {
      case 'SUM':
        return args.fold<double>(0, (a, b) => a + b);
      case 'PRODUCT':
        if (args.isEmpty) return 0;
        return args.fold<double>(1, (a, b) => a * b);
      case 'AVG':
      case 'AVERAGE':
        if (args.isEmpty) throw _FormulaError('AVG needs at least one value.');
        return args.fold<double>(0, (a, b) => a + b) / args.length;
      case 'MIN':
        if (args.isEmpty) throw _FormulaError('MIN needs at least one value.');
        return args.reduce((a, b) => a < b ? a : b);
      case 'MAX':
        if (args.isEmpty) throw _FormulaError('MAX needs at least one value.');
        return args.reduce((a, b) => a > b ? a : b);
      case 'COUNT':
        return args.length.toDouble();
      default:
        throw _FormulaError('"$name" is not a function this app knows.');
    }
  }

  /// One argument of a function call. A range argument expands to many values;
  /// anything else is a single expression.
  List<double> _parseArgument() {
    final save = pos;
    final range = _tryParseRange();
    if (range != null) return range;
    pos = save;
    return [parseExpression()];
  }

  /// Reads `A1:B5` / `A:A` when the text at [pos] is one, otherwise returns
  /// null and leaves [pos] wherever it got to (the caller restores it).
  List<double>? _tryParseRange() {
    _skipSpace();
    final start = pos;
    while (pos < src.length && _isLetter(src[pos])) {
      pos++;
    }
    if (pos == start) return null;
    final letters = src.substring(start, pos);
    if (CsvFormula.columnIndex(letters) == null) return null;
    if (pos < src.length && src[pos] == '(') return null; // a function call
    final first = _readReferenceTail(letters);
    if (_peek() != ':') return null;
    pos++;
    _skipSpace();
    final endStart = pos;
    while (pos < src.length && _isLetter(src[pos])) {
      pos++;
    }
    final endLetters = src.substring(endStart, pos);
    if (endLetters.isEmpty) {
      throw _FormulaError('A column is missing after ":".');
    }
    final second = _readReferenceTail(endLetters);
    return _rangeValues(first, second);
  }

  /// Every numeric value in the rectangle between two references. A reference
  /// with no row number covers the whole column.
  List<double> _rangeValues(_Ref a, _Ref b) {
    final fromCol = a.column < b.column ? a.column : b.column;
    final toCol = a.column < b.column ? b.column : a.column;
    final wholeColumn = a.row == null || b.row == null;
    final fromRow = wholeColumn ? 0 : (a.row! < b.row! ? a.row! : b.row!);
    final toRow = wholeColumn
        ? table.rowCount - 1
        : (a.row! < b.row! ? b.row! : a.row!);

    for (var c = fromCol; c <= toCol; c++) {
      _guardSelf(c);
    }

    final values = <double>[];
    for (var r = fromRow; r <= toRow; r++) {
      if (r < 0 || r >= table.rowCount) continue;
      for (var c = fromCol; c <= toCol; c++) {
        final n = _numberAt(r, c);
        // Cells that hold no number are skipped, the way a spreadsheet does.
        if (n != null) values.add(n);
      }
    }
    return values;
  }

  double _cellValue(int column, int atRow) {
    _guardSelf(column);
    final n = _numberAt(atRow, column);
    if (n == null) {
      // An empty or non-numeric cell counts as zero, so one gap in the data
      // does not break the whole column.
      return 0;
    }
    return n;
  }

  void _guardSelf(int column) {
    if (selfColumn != null && column == selfColumn) {
      throw _FormulaError('A formula cannot use its own column.');
    }
  }

  double? _numberAt(int r, int c) {
    if (r < 0 || r >= table.rowCount) return null;
    if (c < 0 || c >= table.columnCount) return null;
    final raw = table.cell(r, c);
    final n = parseNumber(raw) ?? parseCurrency(raw);
    return n?.toDouble();
  }

  static bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }

  static bool _isLetter(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A);
  }
}

class _Ref {
  /// 0-based column index.
  final int column;

  /// 0-based data-row index, or null for "this row" / "the whole column".
  final int? row;

  const _Ref(this.column, this.row);
}
