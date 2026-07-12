import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/formats/csv/csv_dialect.dart';
import 'package:text_data/formats/csv/csv_parse.dart';

void main() {
  group('delimiter detection', () {
    test('detects comma', () {
      expect(CsvDialect.detectDelimiter('a,b,c\n1,2,3'), CsvDelimiter.comma);
    });

    test('detects semicolon', () {
      expect(
          CsvDialect.detectDelimiter('a;b;c\n1;2;3'), CsvDelimiter.semicolon);
    });

    test('detects tab', () {
      expect(CsvDialect.detectDelimiter('a\tb\tc\n1\t2\t3'), CsvDelimiter.tab);
    });

    test('detects pipe', () {
      expect(CsvDialect.detectDelimiter('a|b|c\n1|2|3'), CsvDelimiter.pipe);
    });

    test('ignores delimiters inside quoted fields', () {
      // Commas live inside quotes; semicolons are the real separators.
      final d = CsvDialect.detectDelimiter('"a,b";c\n"1,2";3');
      expect(d, CsvDelimiter.semicolon);
    });
  });

  group('parsing', () {
    const dialect = CsvDialect(hasHeader: true, lineEnding: LineEndingStyle.lf);

    test('reads a header and rows', () {
      final table = CsvParse.parse('name,age\nAda,36\nBob,40', dialect);
      expect(table.header, ['name', 'age']);
      expect(table.rowCount, 2);
      expect(table.cell(0, 0), 'Ada');
      expect(table.cell(1, 1), '40');
    });

    test('keeps quoted fields with commas and line breaks intact', () {
      final table = CsvParse.parse(
        'note,value\n"hello, world",1\n"two\nlines",2',
        dialect,
      );
      expect(table.cell(0, 0), 'hello, world');
      expect(table.cell(1, 0), 'two\nlines');
    });

    test('pads ragged rows to the widest row (no crash)', () {
      final table = CsvParse.parse('a,b,c\n1,2\n3', dialect);
      expect(table.columnCount, 3);
      expect(table.cell(0, 2), ''); // padded
      expect(table.cell(1, 1), '');
    });

    test('empty input yields a safe empty table', () {
      final table = CsvParse.parse('', dialect);
      expect(table.rowCount, 0);
      expect(table.columnCount, greaterThanOrEqualTo(1));
    });

    test('without a header, synthesizes column names', () {
      const noHeader =
          CsvDialect(hasHeader: false, lineEnding: LineEndingStyle.lf);
      final table = CsvParse.parse('1,2\n3,4', noHeader);
      expect(table.hasHeader, isFalse);
      expect(table.header, ['Column 1', 'Column 2']);
      expect(table.rowCount, 2);
    });
  });
}
