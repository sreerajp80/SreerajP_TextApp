import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/column_selection.dart';

void main() {
  group('ColumnSelectionEngine', () {
    const sampleLf = 'apple\nbanana\ncherry\ndate\nelderberry';
    const sampleCrlf = 'apple\r\nbanana\r\ncherry\r\ndate\r\nelderberry';

    test('applyPrefix adds prefix to specified lines', () {
      final res = ColumnSelectionEngine.applyPrefix(
        sampleLf,
        startLineIndex: 1,
        endLineIndex: 3,
        prefix: '- ',
      );
      expect(res.text, 'apple\n- banana\n- cherry\n- date\nelderberry');
      expect(res.affectedLineCount, 3);
      expect(res.startLineIndex, 1);
      expect(res.endLineIndex, 3);
    });

    test('applyPrefix preserves CRLF line endings', () {
      final res = ColumnSelectionEngine.applyPrefix(
        sampleCrlf,
        startLineIndex: 0,
        endLineIndex: 1,
        prefix: '// ',
      );
      expect(res.text, '// apple\r\n// banana\r\ncherry\r\ndate\r\nelderberry');
    });

    test('applySuffix appends suffix to specified lines', () {
      final res = ColumnSelectionEngine.applySuffix(
        sampleLf,
        startLineIndex: 0,
        endLineIndex: 2,
        suffix: ';',
      );
      expect(res.text, 'apple;\nbanana;\ncherry;\ndate\nelderberry');
    });

    test('applyWrap wraps specified lines with prefix and suffix', () {
      final res = ColumnSelectionEngine.applyWrap(
        sampleLf,
        startLineIndex: 1,
        endLineIndex: 2,
        prefix: '<item>',
        suffix: '</item>',
      );
      expect(
        res.text,
        'apple\n<item>banana</item>\n<item>cherry</item>\ndate\nelderberry',
      );
    });

    test('applyInsertAtColumn inserts at column index with padding', () {
      const text = 'ab\nabcde\na';
      final res = ColumnSelectionEngine.applyInsertAtColumn(
        text,
        startLineIndex: 0,
        endLineIndex: 2,
        column: 3,
        insertText: '|',
        padShorterLines: true,
      );
      expect(
        res.text,
        'ab |'
        '\n'
        'abc|de'
        '\n'
        'a  |',
      );
    });

    test(
      'applyInsertAtColumn appends without padding when padShorterLines is false',
      () {
        const text = 'ab\nabcde\na';
        final res = ColumnSelectionEngine.applyInsertAtColumn(
          text,
          startLineIndex: 0,
          endLineIndex: 2,
          column: 3,
          insertText: '|',
          padShorterLines: false,
        );
        expect(
          res.text,
          'ab|\n'
          'abc|de\n'
          'a|',
        );
      },
    );

    test('extractColumnBlock extracts rectangular slice', () {
      const text = '123456\nabcdef\nABCDEF';
      final res = ColumnSelectionEngine.extractColumnBlock(
        text,
        startLineIndex: 0,
        endLineIndex: 2,
        startCol: 2,
        endCol: 5,
      );
      expect(res.extractedBlock, '345\ncde\nCDE');
    });

    test('extractColumnBlock handles ragged and shorter lines gracefully', () {
      const text = '12\nabcdef\nA';
      final res = ColumnSelectionEngine.extractColumnBlock(
        text,
        startLineIndex: 0,
        endLineIndex: 2,
        startCol: 2,
        endCol: 5,
      );
      expect(res.extractedBlock, '\ncde\n');
    });

    test('replaceColumnBlock replaces character rectangle across lines', () {
      const text = '123456\nabcdef\nABCDEF';
      final res = ColumnSelectionEngine.replaceColumnBlock(
        text,
        startLineIndex: 0,
        endLineIndex: 2,
        startCol: 1,
        endCol: 4,
        replacement: '---',
      );
      expect(res.text, '1---56\na---ef\nA---EF');
    });

    test('deleteColumnBlock deletes rectangular slice across lines', () {
      const text = '123456\nabcdef\nABCDEF';
      final res = ColumnSelectionEngine.deleteColumnBlock(
        text,
        startLineIndex: 0,
        endLineIndex: 2,
        startCol: 2,
        endCol: 4,
      );
      expect(res.text, '1256\nabef\nABEF');
    });

    test('applyNumbering formats auto-incrementing numbers', () {
      final res = ColumnSelectionEngine.applyNumbering(
        sampleLf,
        startLineIndex: 0,
        endLineIndex: 2,
        startNumber: 1,
        step: 1,
        format: '%d. ',
      );
      expect(res.text, '1. apple\n2. banana\n3. cherry\ndate\nelderberry');
    });

    test('applyNumbering supports zero padding and custom step', () {
      final res = ColumnSelectionEngine.applyNumbering(
        sampleLf,
        startLineIndex: 1,
        endLineIndex: 3,
        startNumber: 10,
        step: 10,
        format: '[%d] ',
        padding: 3,
      );
      expect(
        res.text,
        'apple\n[010] banana\n[020] cherry\n[030] date\nelderberry',
      );
    });

    test('applyTrim trims leading and trailing whitespace', () {
      const text = '   one   \n\t  two  \n three';
      final res = ColumnSelectionEngine.applyTrim(
        text,
        startLineIndex: 0,
        endLineIndex: 2,
        trimLeading: true,
        trimTrailing: true,
      );
      expect(res.text, 'one\ntwo\nthree');
    });

    test('clamps out-of-bounds line indices safely', () {
      final res = ColumnSelectionEngine.applyPrefix(
        sampleLf,
        startLineIndex: -5,
        endLineIndex: 100,
        prefix: '# ',
      );
      expect(res.affectedLineCount, 5);
      expect(res.text, '# apple\n# banana\n# cherry\n# date\n# elderberry');
    });
  });
}
