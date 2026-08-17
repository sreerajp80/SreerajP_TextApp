import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/formats/csv/csv_formula.dart';
import 'package:sreerajp_textapp/formats/csv/csv_table.dart';

/// Guards the calculated formula columns (roadmap §4.2.2), including the
/// failure paths CLAUDE.md §3.4 asks for: a bad formula must give a friendly
/// message, never a crash.
void main() {
  CsvTable table() => CsvTable(
    header: ['qty', 'price', 'note'],
    rows: [
      ['2', '10', 'a'],
      ['3', '20', 'b'],
      ['4', '30', ''],
    ],
    hasHeader: true,
  );

  num? valueOf(String formula, {int row = 0, int? selfColumn}) {
    final result = CsvFormula.evaluate(
      table(),
      formula,
      row,
      selfColumn: selfColumn,
    );
    return result.value;
  }

  String? errorOf(String formula, {int row = 0, int? selfColumn}) {
    return CsvFormula.evaluate(
      table(),
      formula,
      row,
      selfColumn: selfColumn,
    ).error;
  }

  group('column letters', () {
    test('map to and from indices', () {
      expect(CsvFormula.columnLetters(0), 'A');
      expect(CsvFormula.columnLetters(25), 'Z');
      expect(CsvFormula.columnLetters(26), 'AA');
      expect(CsvFormula.columnLetters(27), 'AB');
      expect(CsvFormula.columnIndex('A'), 0);
      expect(CsvFormula.columnIndex('z'), 25);
      expect(CsvFormula.columnIndex('AA'), 26);
      expect(CsvFormula.columnIndex('AB'), 27);
    });

    test('reject text that is not a column', () {
      expect(CsvFormula.columnIndex(''), isNull);
      expect(CsvFormula.columnIndex('A1'), isNull);
      expect(CsvFormula.columnIndex('-'), isNull);
    });
  });

  group('arithmetic', () {
    test('plain numbers and operators', () {
      expect(valueOf('=1+2'), 3);
      expect(valueOf('=2*3+1'), 7);
      expect(valueOf('=2*(3+1)'), 8);
      expect(valueOf('=10/4'), 2.5);
      expect(valueOf('=-3+1'), -2);
    });

    test('the leading = is optional', () {
      expect(valueOf('1+1'), 2);
    });

    test('divide by zero is refused with a message', () {
      expect(errorOf('=1/0'), contains('zero'));
    });
  });

  group('cell references', () {
    test('a bare column letter means this row', () {
      expect(valueOf('=A*B', row: 0), 20); // 2 * 10
      expect(valueOf('=A*B', row: 2), 120); // 4 * 30
    });

    test('an explicit row number is absolute', () {
      expect(valueOf('=B2', row: 0), 20);
      expect(valueOf('=B2', row: 2), 20);
    });

    test('A# is the same as a bare A', () {
      expect(valueOf('=A#+1', row: 1), 4);
    });

    test('a cell holding no number counts as zero', () {
      expect(valueOf('=C+5', row: 0), 5); // C is the text "a"
    });

    test('a reference outside the table counts as zero', () {
      expect(valueOf('=B99'), 0);
    });
  });

  group('functions', () {
    test('SUM over a range', () {
      expect(valueOf('=SUM(A1:A3)'), 9); // 2 + 3 + 4
    });

    test('SUM over a whole column', () {
      expect(valueOf('=SUM(B:B)'), 60);
    });

    test('PRODUCT over separate arguments', () {
      expect(valueOf('=PRODUCT(A, B)', row: 1), 60); // 3 * 20
    });

    test('AVG, MIN, MAX and COUNT', () {
      expect(valueOf('=AVG(A1:A3)'), 3);
      expect(valueOf('=AVERAGE(A1:A3)'), 3);
      expect(valueOf('=MIN(A1:A3)'), 2);
      expect(valueOf('=MAX(A1:A3)'), 4);
      expect(valueOf('=COUNT(A1:A3)'), 3);
    });

    test('COUNT skips cells that hold no number', () {
      expect(valueOf('=COUNT(C1:C3)'), 0);
    });

    test('a function can be mixed into an expression', () {
      expect(valueOf('=SUM(A1:A3)*2+1'), 19);
    });

    test('an unknown function is refused with a message', () {
      expect(errorOf('=VLOOKUP(A1)'), contains('VLOOKUP'));
    });

    test('AVG with nothing to average is refused', () {
      expect(errorOf('=AVG(C1:C3)'), contains('AVG'));
    });
  });

  group('failure paths', () {
    test('an empty formula is refused', () {
      expect(errorOf(''), isNotNull);
      expect(errorOf('   '), isNotNull);
    });

    test('a missing bracket is refused', () {
      expect(errorOf('=SUM(A1:A3'), isNotNull);
      expect(errorOf('=(1+2'), contains(')'));
    });

    test('junk after the formula is refused', () {
      expect(errorOf('=1+2 ?'), isNotNull);
    });

    test('a half-written formula is refused', () {
      expect(errorOf('=1+'), isNotNull);
      expect(errorOf('='), isNotNull);
    });

    test('a formula that uses its own column is refused', () {
      expect(errorOf('=A+1', selfColumn: 0), contains('own column'));
      expect(errorOf('=SUM(A1:A3)', selfColumn: 0), contains('own column'));
      // Another column is fine.
      expect(errorOf('=B+1', selfColumn: 0), isNull);
    });

    test('validate reports the same problems', () {
      expect(CsvFormula.validate(table(), '=A*B'), isNull);
      expect(CsvFormula.validate(table(), '=NOPE()'), isNotNull);
    });
  });

  group('display text', () {
    test('whole numbers lose their decimal point', () {
      final r = CsvFormula.evaluate(table(), '=A*B', 0);
      expect(r.display, '20');
    });

    test('fractions keep a short decimal', () {
      final r = CsvFormula.evaluate(table(), '=10/4', 0);
      expect(r.display, '2.5');
    });

    test('a failed formula displays as an error marker', () {
      final r = CsvFormula.evaluate(table(), '=1/0', 0);
      expect(r.ok, isFalse);
      expect(r.display, '#ERROR');
    });
  });
}
