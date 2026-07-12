import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/markdown/md_split_merge.dart';

void main() {
  const sm = MdSplitMerge();

  test('splits at each top-level heading', () {
    const source = '# First\nalpha\n\n# Second\nbeta\n\n# Third\ngamma';
    final parts = sm.splitByTopHeading(source);
    expect(parts.length, 3);
    expect(parts[0], '# First\nalpha');
    expect(parts[1], '# Second\nbeta');
    expect(parts[2], '# Third\ngamma');
  });

  test('content before the first heading is its own part', () {
    const source = 'intro line\n# Section\nbody';
    final parts = sm.splitByTopHeading(source);
    expect(parts.length, 2);
    expect(parts[0], 'intro line');
    expect(parts[1], '# Section\nbody');
  });

  test('a # inside a fenced code block does not split', () {
    const source = '# Real\n```\n# not a heading\n```\ntail';
    final parts = sm.splitByTopHeading(source);
    expect(parts.length, 1);
  });

  test('## sub-heading does not start a new part', () {
    const source = '# Top\n## Sub\nbody';
    final parts = sm.splitByTopHeading(source);
    expect(parts.length, 1);
  });

  test('split then merge reproduces the parts in order', () {
    const source = '# A\none\n\n# B\ntwo';
    final parts = sm.splitByTopHeading(source);
    expect(sm.merge(parts), '# A\none\n\n# B\ntwo');
  });

  test('no top-level heading → single part', () {
    const source = '## only sub\ntext';
    final parts = sm.splitByTopHeading(source);
    expect(parts.length, 1);
    expect(parts[0], source);
  });
}
