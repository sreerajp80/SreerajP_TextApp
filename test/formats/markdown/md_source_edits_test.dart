import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_source_edits.dart';

void main() {
  group('inline wraps', () {
    test('bold wraps the selection and keeps it selected', () {
      const text = 'hello world';
      final e = MdSourceEdits.bold(text, 6, 11); // "world"
      expect(e.text, 'hello **world**');
      expect(e.text.substring(e.selectionStart, e.selectionEnd), 'world');
    });

    test('italic on an empty selection inserts markers with caret between', () {
      final e = MdSourceEdits.italic('', 0, 0);
      expect(e.text, '**');
      expect(e.selectionStart, 1);
      expect(e.selectionEnd, 1);
    });

    test('strikethrough wraps with ~~', () {
      final e = MdSourceEdits.strikethrough('abc', 0, 3);
      expect(e.text, '~~abc~~');
    });

    test('inline code wraps with backticks', () {
      final e = MdSourceEdits.inlineCode('abc', 0, 3);
      expect(e.text, '`abc`');
    });
  });

  group('line prefixes', () {
    test('heading prefixes the line and replaces an existing marker', () {
      final e = MdSourceEdits.heading('Title', 0, 0, 2);
      expect(e.text, '## Title');
      final again = MdSourceEdits.heading(e.text, 0, 0, 1);
      expect(again.text, '# Title');
    });

    test('bullet list prefixes each selected line', () {
      const text = 'one\ntwo';
      final e = MdSourceEdits.bulletList(text, 0, text.length);
      expect(e.text, '- one\n- two');
    });

    test('numbered list increments per line', () {
      const text = 'a\nb\nc';
      final e = MdSourceEdits.numberedList(text, 0, text.length);
      expect(e.text, '1. a\n2. b\n3. c');
    });

    test('task list uses checkbox syntax', () {
      final e = MdSourceEdits.taskList('do it', 0, 5);
      expect(e.text, '- [ ] do it');
    });

    test('blockquote prefixes with >', () {
      final e = MdSourceEdits.blockquote('quote', 0, 5);
      expect(e.text, '> quote');
    });
  });

  group('block and inline inserts', () {
    test('code block fences the selection', () {
      final e = MdSourceEdits.codeBlock('print()', 0, 7);
      expect(e.text, '```\nprint()\n```');
    });

    test('table inserts a starter grid with the first cell selected', () {
      final e = MdSourceEdits.table('', 0, 0);
      expect(e.text.startsWith('| Column 1 | Column 2 |'), isTrue);
      expect(
        e.text.substring(e.selectionStart, e.selectionEnd),
        'Column 1',
      );
    });

    test('link with a selection uses it as the text and selects url', () {
      const text = 'click here';
      final e = MdSourceEdits.link(text, 0, 5); // "click"
      expect(e.text, '[click](url) here');
      expect(e.text.substring(e.selectionStart, e.selectionEnd), 'url');
    });

    test('link with no selection inserts a template selecting the text', () {
      final e = MdSourceEdits.link('', 0, 0);
      expect(e.text, '[link](url)');
      expect(e.text.substring(e.selectionStart, e.selectionEnd), 'link');
    });

    test('a block inserted mid-line is pushed onto its own line', () {
      const text = 'abc';
      final e = MdSourceEdits.codeBlock(text, 3, 3); // caret at end
      expect(e.text, 'abc\n```\n\n```');
    });
  });
}
