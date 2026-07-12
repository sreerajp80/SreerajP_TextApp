import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/large_file/paged_text.dart';

void main() {
  group('PagedText', () {
    test('empty text has one empty page', () {
      final p = PagedText('', linesPerPage: 10);
      expect(p.lineCount, 0);
      expect(p.pageCount, 1);
      expect(p.page(0), '');
    });

    test('single line, no trailing newline', () {
      final p = PagedText('hello', linesPerPage: 10);
      expect(p.lineCount, 1);
      expect(p.pageCount, 1);
      expect(p.page(0), 'hello');
    });

    test('splits lines into fixed-size pages', () {
      final text = List.generate(25, (i) => 'line$i').join('\n');
      final p = PagedText(text, linesPerPage: 10);
      expect(p.lineCount, 25);
      expect(p.pageCount, 3); // 10 + 10 + 5

      expect(p.page(0).split('\n').first, 'line0');
      expect(p.page(0).split('\n').length, 10);

      expect(p.page(1).split('\n').first, 'line10');
      expect(p.page(1).split('\n').length, 10);

      // Last (partial) page has the remaining 5 lines.
      final last = p.page(2).split('\n');
      expect(last.first, 'line20');
      expect(last.last, 'line24');
      expect(last.length, 5);
    });

    test('concatenating every page reproduces the original text', () {
      final text = List.generate(23, (i) => 'row $i').join('\n');
      final p = PagedText(text, linesPerPage: 7);
      final rebuilt =
          [for (var i = 0; i < p.pageCount; i++) p.page(i)].join('\n');
      expect(rebuilt, text);
      expect(p.pageCount, 4); // 7 + 7 + 7 + 2
    });

    test('page index is clamped into range', () {
      final p = PagedText('a\nb\nc', linesPerPage: 2);
      expect(p.pageCount, 2);
      expect(p.page(-1), p.page(0));
      expect(p.page(99), p.page(1));
    });

    test('linesPerPage below 1 is clamped up', () {
      final p = PagedText('a\nb', linesPerPage: 0);
      expect(p.pageCount, 2);
      expect(p.page(0), 'a');
      expect(p.page(1), 'b');
    });

    test('firstLineNumber is 1-based per page', () {
      final text = List.generate(25, (i) => '$i').join('\n');
      final p = PagedText(text, linesPerPage: 10);
      expect(p.firstLineNumber(0), 1);
      expect(p.firstLineNumber(1), 11);
      expect(p.firstLineNumber(2), 21);
    });
  });
}
