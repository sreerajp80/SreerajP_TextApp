import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/formats/csv/csv_dialect.dart';
import 'package:text_data/formats/csv/csv_table.dart';

void main() {
  const dialect = CsvDialect(hasHeader: true, lineEnding: LineEndingStyle.lf);

  CsvTable sample() => CsvTable(
        header: ['name', 'age'],
        rows: [
          ['Ada', '36'],
          ['Bob', '40'],
        ],
        hasHeader: true,
      );

  test('setCell returns a new table with the value changed', () {
    final t = sample().setCell(0, 1, '37');
    expect(t.cell(0, 1), '37');
  });

  test('insert / delete / move rows', () {
    var t = sample().insertRow(1, ['Cid', '20']);
    expect(t.rowCount, 3);
    expect(t.cell(1, 0), 'Cid');

    t = t.moveRow(0, 2);
    expect(t.cell(2, 0), 'Ada');

    t = t.deleteRow(0);
    expect(t.rowCount, 2);
  });

  test('insert / delete / move columns keep rows aligned', () {
    var t = sample().insertColumn(1, name: 'city');
    expect(t.header, ['name', 'city', 'age']);
    expect(t.cell(0, 1), ''); // new column blank

    t = t.moveColumn(2, 0);
    expect(t.header.first, 'age');

    t = t.deleteColumn(0);
    expect(t.header, ['name', 'city']);
  });

  test('renameHeader changes the column name', () {
    final t = sample().renameHeader(0, 'fullname');
    expect(t.header.first, 'fullname');
  });

  test('serialize round-trips with the detected dialect', () {
    final csv = sample().toCsv(dialect);
    expect(csv, 'name,age\nAda,36\nBob,40');
  });

  test('quotes fields that contain the delimiter', () {
    final t = CsvTable(
      header: ['a', 'b'],
      rows: [
        ['x,y', 'z'],
      ],
      hasHeader: true,
    );
    expect(t.toCsv(dialect), 'a,b\n"x,y",z');
  });

  test('semicolon dialect uses the chosen delimiter', () {
    const semi = CsvDialect(
      delimiter: CsvDelimiter.semicolon,
      hasHeader: true,
      lineEnding: LineEndingStyle.lf,
    );
    expect(sample().toCsv(semi), 'name;age\nAda;36\nBob;40');
  });

  group('duplicate rows', () {
    CsvTable withDups() => CsvTable(
          header: ['id', 'name'],
          rows: [
            ['1', 'Ada'],
            ['2', 'Bob'],
            ['1', 'Ada'], // exact duplicate
            ['3', 'Ada'], // duplicate name, different id
          ],
          hasHeader: true,
        );

    test('detects and removes whole-row duplicates', () {
      final t = withDups();
      expect(t.findDuplicateRows(), [2]);
      final cleaned = t.removeDuplicateRows();
      expect(cleaned.rowCount, 3);
    });

    test('detects duplicates by a key column', () {
      final t = withDups();
      // Column 1 (name): Ada repeats at rows 2 and 3.
      expect(t.findDuplicateRows(keyColumn: 1), [2, 3]);
      final cleaned = t.removeDuplicateRows(keyColumn: 1);
      expect(cleaned.rowCount, 2);
    });
  });

  test('setHasHeader promotes and demotes the first row', () {
    final t = sample().setHasHeader(false);
    expect(t.hasHeader, isFalse);
    expect(t.rowCount, 3); // header became a data row
    final back = t.setHasHeader(true);
    expect(back.hasHeader, isTrue);
    expect(back.header, ['name', 'age']);
  });
}
