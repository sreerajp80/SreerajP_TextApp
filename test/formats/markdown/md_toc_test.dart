import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_toc.dart';

void main() {
  test('builds entries with the right levels and text', () {
    const source = '# One\n## Two\n### Three\ntext\n## Another';
    final toc = MdToc.of(source);

    expect(toc.headings.length, 4);
    expect(toc.headings[0].level, 1);
    expect(toc.headings[0].text, 'One');
    expect(toc.headings[1].level, 2);
    expect(toc.headings[2].level, 3);
    expect(toc.headings[3].text, 'Another');
  });

  test('resolves an internal #anchor link to its heading', () {
    const source = '# Getting Started\n## Install Steps\ntext';
    final toc = MdToc.of(source);

    final target = toc.resolve('#install-steps');
    expect(target, isNotNull);
    expect(target!.text, 'Install Steps');
  });

  test('duplicate headings get unique anchors', () {
    const source = '# Notes\n# Notes';
    final toc = MdToc.of(source);
    expect(toc.headings[0].anchor, 'notes');
    expect(toc.headings[1].anchor, 'notes-1');
  });

  test('no headings → empty TOC', () {
    final toc = MdToc.of('just paragraph text');
    expect(toc.isEmpty, isTrue);
  });
}
