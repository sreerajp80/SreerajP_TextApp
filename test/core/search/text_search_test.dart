import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/search/search_options.dart';
import 'package:text_data/core/search/text_search.dart';

void main() {
  const search = TextSearch();

  test('literal, case-insensitive by default', () {
    final outcome = search.find('The cat sat on the Cat', 'cat',
        const SearchOptions());
    expect(outcome.hasError, isFalse);
    expect(outcome.matches, [const SearchMatch(4, 7), const SearchMatch(19, 22)]);
  });

  test('case-sensitive limits matches', () {
    final outcome = search.find('cat Cat CAT', 'Cat',
        const SearchOptions(caseSensitive: true));
    expect(outcome.count, 1);
    expect(outcome.matches.first, const SearchMatch(4, 7));
  });

  test('whole-word does not match inside a word', () {
    final outcome = search.find('cat category cat', 'cat',
        const SearchOptions(wholeWord: true));
    expect(outcome.count, 2);
    expect(outcome.matches, [const SearchMatch(0, 3), const SearchMatch(13, 16)]);
  });

  test('regex mode matches a pattern', () {
    final outcome = search.find('a1 b2 c3', r'\w\d',
        const SearchOptions(regex: true));
    expect(outcome.count, 3);
  });

  test('literal query with regex metacharacters is escaped', () {
    final outcome = search.find('price is 3.50 not 3x50', '3.50',
        const SearchOptions());
    // '.' is literal here, so only the real "3.50" matches.
    expect(outcome.count, 1);
    expect(outcome.matches.first, const SearchMatch(9, 13));
  });

  test('invalid regex returns a friendly error, never throws', () {
    final outcome = search.find('abc', '(unclosed',
        const SearchOptions(regex: true));
    expect(outcome.hasError, isTrue);
    expect(outcome.errorMessage, contains('Invalid search pattern'));
    expect(outcome.matches, isEmpty);
  });

  test('empty query returns no matches', () {
    final outcome = search.find('abc', '', const SearchOptions());
    expect(outcome.count, 0);
    expect(outcome.hasError, isFalse);
  });
}
