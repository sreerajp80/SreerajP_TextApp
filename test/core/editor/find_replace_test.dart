import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/find_replace.dart';
import 'package:text_data/core/search/search_options.dart';

void main() {
  const fr = FindReplace();

  test('replaceAll on a literal query', () {
    final r = fr.replaceAll('cat cat cat', 'cat', 'dog', const SearchOptions());
    expect(r.replacedCount, 3);
    expect(r.text, 'dog dog dog');
  });

  test('regex replace with a \$1 capture reference', () {
    final r = fr.replaceAll(
      'John Smith, Jane Doe',
      r'(\w+) (\w+)',
      r'$2 $1',
      const SearchOptions(regex: true),
    );
    expect(r.replacedCount, 2);
    expect(r.text, 'Smith John, Doe Jane');
  });

  test('\$\$ becomes a literal dollar sign', () {
    final r = fr.replaceAll(
      'price 5',
      r'(\d+)',
      r'$$$1',
      const SearchOptions(regex: true),
    );
    expect(r.text, r'price $5');
  });

  test('scope limits the replace to a range', () {
    // Only replace within [0, 3): the first "ab".
    const text = 'ab ab ab';
    final r = fr.replaceAll(
      text,
      'ab',
      'X',
      const SearchOptions(),
      scope: const ReplaceScope(0, 3),
    );
    expect(r.replacedCount, 1);
    expect(r.text, 'X ab ab');
  });

  test('match count preview equals the actual replace count', () {
    const text = 'one two one two one';
    const options = SearchOptions();
    final preview = fr.matchCount(text, 'one', options);
    final result = fr.replaceAll(text, 'one', 'X', options);
    expect(preview, 3);
    expect(result.replacedCount, preview);
  });

  test('invalid regex is reported and nothing changes', () {
    final r = fr.replaceAll('abc', '(bad', 'X',
        const SearchOptions(regex: true));
    expect(r.hasError, isTrue);
    expect(r.replacedCount, 0);
    expect(r.text, 'abc');
    expect(fr.matchCount('abc', '(bad', const SearchOptions(regex: true)), -1);
  });

  test('replaceFirstFrom replaces only the match at or after an offset', () {
    const text = 'cat cat cat';
    final r = fr.replaceFirstFrom(text, 'cat', 'dog', const SearchOptions(), 4);
    expect(r.replacedCount, 1);
    expect(r.text, 'cat dog cat');
  });
}
