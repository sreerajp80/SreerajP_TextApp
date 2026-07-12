import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_front_matter.dart';

void main() {
  test('parses title, author, and inline tags', () {
    const source = '---\n'
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
    const source = '---\n'
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
}
