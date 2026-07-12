import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_stats.dart';

void main() {
  test('empty text is all zero', () {
    final s = MdStats.of('');
    expect(s.words, 0);
    expect(s.characters, 0);
    expect(s.lines, 0);
    expect(s.headings, 0);
    expect(s.links, 0);
  });

  test('counts words, lines, headings, and links', () {
    const source = '# Title\n'
        '\n'
        'Some **bold** text with a [link](https://example.com).\n'
        '\n'
        '## Section\n'
        'More words here.';
    final s = MdStats.of(source);

    expect(s.headings, 2);
    expect(s.links, 1);
    expect(s.lines, 6);
    expect(s.words, greaterThan(5));
  });

  test('a hash inside a code block is not a heading', () {
    const source = '```\n# not a heading\n```\n';
    final s = MdStats.of(source);
    expect(s.headings, 0);
  });
}
