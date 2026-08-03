import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_table_source.dart';

/// Guards the visual Markdown table builder's model (roadmap §4.4.2). The whole
/// point of the feature is that the user never lines up `|` characters, so the
/// rendering and the round-trip are what matter most.
void main() {
  const simple = '''
| Name | Age |
| --- | --- |
| Ada | 36 |
| Bob | 40 |''';

  group('parsing', () {
    test('reads the header, rows and cells', () {
      final t = MdTableData.parse(simple)!;
      expect(t.header, ['Name', 'Age']);
      expect(t.rowCount, 2);
      expect(t.cell(0, 0), 'Ada');
      expect(t.cell(1, 1), '40');
    });

    test('reads column alignment', () {
      final t = MdTableData.parse('''
| a | b | c | d |
| :-- | :-: | --: | --- |
| 1 | 2 | 3 | 4 |''')!;
      expect(t.alignments, [
        MdColumnAlign.left,
        MdColumnAlign.center,
        MdColumnAlign.right,
        MdColumnAlign.none,
      ]);
    });

    test('pads a row that is missing cells', () {
      final t = MdTableData.parse('''
| a | b |
| --- | --- |
| 1 |''')!;
      expect(t.rows.first, ['1', '']);
    });

    test('trims a row that has too many cells', () {
      final t = MdTableData.parse('''
| a | b |
| --- | --- |
| 1 | 2 | 3 |''')!;
      expect(t.rows.first, ['1', '2']);
    });

    test('reads an escaped pipe as part of the cell', () {
      final t = MdTableData.parse('''
| a |
| --- |
| x \\| y |''')!;
      expect(t.cell(0, 0), 'x | y');
    });

    test('a table with no body rows still parses', () {
      final t = MdTableData.parse('| a |\n| --- |')!;
      expect(t.columnCount, 1);
      expect(t.rowCount, 0);
    });

    test('text that is not a table gives null', () {
      expect(MdTableData.parse('just a paragraph'), isNull);
      expect(MdTableData.parse(''), isNull);
      expect(MdTableData.parse('| a |'), isNull); // no separator line
      expect(MdTableData.parse('| a |\n| b |'), isNull); // second line is data
    });
  });

  group('rendering', () {
    test('pads every column so the source lines up', () {
      final t = MdTableData(
        header: ['Name', 'A'],
        rows: [
          ['Ada', '1'],
        ],
        alignments: [MdColumnAlign.none, MdColumnAlign.none],
      );
      expect(t.toMarkdown(), '''
| Name | A   |
| ---- | --- |
| Ada  | 1   |''');
    });

    test('writes the alignment markers', () {
      final t = MdTableData(
        header: ['a', 'b', 'c'],
        rows: const [],
        alignments: [
          MdColumnAlign.left,
          MdColumnAlign.center,
          MdColumnAlign.right,
        ],
      );
      expect(t.toMarkdown(), '| a   | b   | c   |\n| :-- | :-: | --: |');
    });

    test('escapes a pipe inside a cell so the table cannot break', () {
      final t = MdTableData(
        header: ['a'],
        rows: [
          ['x | y'],
        ],
        alignments: [MdColumnAlign.none],
      );
      expect(t.toMarkdown().contains(r'x \| y'), isTrue);
      // And it reads back as the original text.
      expect(MdTableData.parse(t.toMarkdown())!.cell(0, 0), 'x | y');
    });

    test('a newline in a cell becomes a line break, not a broken table', () {
      final t = MdTableData(
        header: ['a'],
        rows: [
          ['x\ny'],
        ],
        alignments: [MdColumnAlign.none],
      );
      expect(t.toMarkdown().contains('x<br>y'), isTrue);
      expect(t.toMarkdown().split('\n').length, 3);
    });
  });

  group('round trip', () {
    test('parse then render keeps the content', () {
      final t = MdTableData.parse(simple)!;
      final again = MdTableData.parse(t.toMarkdown())!;
      expect(again.header, t.header);
      expect(again.rows, t.rows);
      expect(again.alignments, t.alignments);
    });
  });

  group('edits', () {
    test('adding and removing columns keeps every row the same width', () {
      final t = MdTableData.parse(simple)!..addColumn();
      expect(t.columnCount, 3);
      expect(t.rows.every((r) => r.length == 3), isTrue);

      t.removeColumn(2);
      expect(t.columnCount, 2);
      expect(t.rows.every((r) => r.length == 2), isTrue);
    });

    test('the last column cannot be removed', () {
      final t = MdTableData.blank(columns: 1, rows: 1);
      t.removeColumn(0);
      expect(t.columnCount, 1);
    });

    test('adding and removing rows', () {
      final t = MdTableData.parse(simple)!..addRow();
      expect(t.rowCount, 3);
      t.removeRow(2);
      expect(t.rowCount, 2);
    });

    test('out-of-range edits are ignored, never throwing', () {
      final t = MdTableData.parse(simple)!;
      expect(() {
        t.setCell(9, 9, 'x');
        t.setHeader(9, 'x');
        t.setAlignment(9, MdColumnAlign.left);
        t.removeRow(9);
        t.removeColumn(9);
      }, returnsNormally);
    });

    test('a blank table starts usable', () {
      final t = MdTableData.blank();
      expect(t.columnCount, 3);
      expect(t.rowCount, 2);
      expect(MdTableData.parse(t.toMarkdown()), isNotNull);
    });
  });

  group('finding the table under the cursor', () {
    const document = 'Intro text\n\n'
        '| a | b |\n'
        '| --- | --- |\n'
        '| 1 | 2 |\n\n'
        'After the table.';

    test('finds the span when the cursor is inside the table', () {
      final offset = document.indexOf('| 1 | 2 |') + 2;
      final span = MdTableData.findTableAt(document, offset)!;
      final text = document.substring(span.start, span.end);
      expect(text, '| a | b |\n| --- | --- |\n| 1 | 2 |');
      expect(MdTableData.parse(text), isNotNull);
    });

    test('finds it from the header line too', () {
      final span = MdTableData.findTableAt(document, document.indexOf('| a'))!;
      expect(document.substring(span.start, span.end).startsWith('| a'), isTrue);
    });

    test('gives null when the cursor is in ordinary text', () {
      expect(MdTableData.findTableAt(document, 2), isNull);
      expect(
        MdTableData.findTableAt(document, document.indexOf('After')),
        isNull,
      );
    });

    test('gives null when the run of pipe lines is not a real table', () {
      const notATable = 'a | b\nc | d';
      expect(MdTableData.findTableAt(notATable, 0), isNull);
    });

    test('empty text and out-of-range offsets do not throw', () {
      expect(MdTableData.findTableAt('', 0), isNull);
      expect(() => MdTableData.findTableAt(document, 99999), returnsNormally);
      expect(() => MdTableData.findTableAt(document, -5), returnsNormally);
    });
  });
}
