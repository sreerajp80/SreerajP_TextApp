import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_front_matter.dart';

void main() {
  test('parses title, author, and inline tags', () {
    const source =
        '---\n'
        'title: My Notes\n'
        'author: Jane Doe\n'
        'tags: [draft, ideas]\n'
        '---\n'
        '# Heading\n'
        'Body text.';
    final fm = MdFrontMatter.parse(source);

    expect(fm.present, isTrue);
    expect(fm.title, 'My Notes');
    expect(fm.author, 'Jane Doe');
    expect(fm.tags, ['draft', 'ideas']);
    expect(fm.body, '# Heading\nBody text.');
  });

  test('parses a block (dash) tag list', () {
    const source =
        '---\n'
        'title: T\n'
        'tags:\n'
        '  - one\n'
        '  - two\n'
        '---\n'
        'body';
    final fm = MdFrontMatter.parse(source);
    expect(fm.tags, ['one', 'two']);
    expect(fm.body, 'body');
  });

  test('strips surrounding quotes', () {
    const source = '---\ntitle: "Quoted Title"\n---\nx';
    final fm = MdFrontMatter.parse(source);
    expect(fm.title, 'Quoted Title');
  });

  test('no front matter → whole file is the body', () {
    const source = '# Just a heading\ntext';
    final fm = MdFrontMatter.parse(source);
    expect(fm.present, isFalse);
    expect(fm.title, isNull);
    expect(fm.tags, isEmpty);
    expect(fm.body, source);
  });

  test('an unclosed fence is tolerated as no front matter', () {
    const source = '---\ntitle: T\nbody with no closing fence';
    final fm = MdFrontMatter.parse(source);
    expect(fm.present, isFalse);
    expect(fm.body, source);
  });

  test('empty input does not crash', () {
    final fm = MdFrontMatter.parse('');
    expect(fm.present, isFalse);
    expect(fm.body, '');
  });

  group('parsed field detail (roadmap 4.4.3)', () {
    test('keeps the original key spelling and the source line', () {
      const source = '---\nTitle: My Notes\n---\n# Body';
      final fm = MdFrontMatter.parse(source);
      expect(fm.parsedFields.length, 1);
      expect(fm.parsedFields.first.key, 'Title');
      expect(fm.parsedFields.first.lowerKey, 'title');
      expect(fm.parsedFields.first.lineIndices, [0]);
      // The lower-cased lookup still works as before.
      expect(fm.title, 'My Notes');
    });

    test('a block list records every line it spans', () {
      const source = '---\ntags:\n  - a\n  - b\n---\nBody';
      final fm = MdFrontMatter.parse(source);
      final tags = fm.parsedFields.firstWhere((f) => f.lowerKey == 'tags');
      expect(tags.isList, isTrue);
      expect(tags.lineIndices, [0, 1, 2]);
      expect(tags.value, 'a, b');
    });

    test('blockLines holds the raw text between the fences', () {
      const source = '---\ntitle: T\n# a comment\n---\nBody';
      final fm = MdFrontMatter.parse(source);
      expect(fm.blockLines, ['title: T', '# a comment']);
    });
  });

  group('applyEdits (roadmap 4.4.3)', () {
    test('changes one field and leaves the rest byte for byte', () {
      const source = '---\ntitle: Old\nauthor: Jane\n---\n# Body';
      final result = MdFrontMatter.applyEdits(source, {'title': 'New'});
      expect(result, '---\ntitle: New\nauthor: Jane\n---\n# Body');
    });

    test('keeps lines the small parser does not understand', () {
      // A comment and a nested map are beyond this parser; an edit must not
      // silently drop them.
      const source =
          '---\n'
          '# a note\n'
          'title: Old\n'
          'nested:\n'
          '  deep: 1\n'
          '---\n'
          'Body';
      final result = MdFrontMatter.applyEdits(source, {'title': 'New'});
      expect(result.contains('# a note'), isTrue);
      expect(result.contains('  deep: 1'), isTrue);
      expect(result.contains('title: New'), isTrue);
    });

    test('a field keeps its position in the block', () {
      const source = '---\na: 1\ntitle: Old\nz: 2\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {'title': 'New'});
      expect(result, '---\na: 1\ntitle: New\nz: 2\n---\nBody');
    });

    test('the original key spelling is kept', () {
      const source = '---\nTitle: Old\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {'title': 'New'});
      expect(result.contains('Title: New'), isTrue);
    });

    test('a new field is appended', () {
      const source = '---\ntitle: T\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {'author': 'Jane'});
      expect(result, '---\ntitle: T\nauthor: Jane\n---\nBody');
    });

    test('an emptied field is removed', () {
      const source = '---\ntitle: T\nauthor: Jane\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {'author': ''});
      expect(result, '---\ntitle: T\n---\nBody');
    });

    test('tags are written as an inline list', () {
      const source = '---\ntitle: T\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {'tags': 'a, b'});
      expect(result.contains('tags: [a, b]'), isTrue);
      expect(MdFrontMatter.parse(result).tags, ['a', 'b']);
    });

    test('a block list is replaced by one inline line', () {
      const source = '---\ntags:\n  - a\n  - b\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {'tags': 'a, b, c'});
      expect(result, '---\ntags: [a, b, c]\n---\nBody');
      expect(MdFrontMatter.parse(result).tags, ['a', 'b', 'c']);
    });

    test('a value holding a colon is quoted so it still reads back', () {
      const source = '---\ntitle: T\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {
        'title': 'Notes: part one',
      });
      expect(MdFrontMatter.parse(result).title, 'Notes: part one');
    });

    test('a file with no front matter gets a new block at the top', () {
      const source = '# Body';
      final result = MdFrontMatter.applyEdits(source, {'title': 'T'});
      expect(result, '---\ntitle: T\n---\n# Body');
      expect(MdFrontMatter.parse(result).body, '# Body');
    });

    test('nothing to write leaves a plain file alone', () {
      const source = '# Body';
      expect(MdFrontMatter.applyEdits(source, {'title': ''}), source);
    });

    test('an edit round-trips through the parser', () {
      const source = '---\ntitle: Old\ntags: [x]\n---\nBody';
      final result = MdFrontMatter.applyEdits(source, {
        'title': 'New',
        'tags': 'x, y',
        'author': 'Jane',
      });
      final fm = MdFrontMatter.parse(result);
      expect(fm.title, 'New');
      expect(fm.tags, ['x', 'y']);
      expect(fm.author, 'Jane');
      expect(fm.body, 'Body');
    });

    test('an unclosed fence is left alone rather than mangled', () {
      const source = '---\ntitle: T\nno closing fence';
      expect(
        MdFrontMatter.applyEdits(source, {'title': 'New'}),
        '---\ntitle: New\n---\n$source',
      );
    });
  });

  group('renderBlock', () {
    test('writes a block that parses back', () {
      final block = MdFrontMatter.renderBlock({'title': 'T', 'tags': 'a, b'});
      final fm = MdFrontMatter.parse('$block\nBody');
      expect(fm.title, 'T');
      expect(fm.tags, ['a', 'b']);
    });

    test('skips empty values', () {
      expect(
        MdFrontMatter.renderBlock({'title': '', 'author': 'Jane'}),
        '---\nauthor: Jane\n---',
      );
    });
  });
}
