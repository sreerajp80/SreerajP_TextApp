import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/txt/txt_stats.dart';

void main() {
  test('empty text is all zero', () {
    final s = TxtStats.of('');
    expect(s.words, 0);
    expect(s.characters, 0);
    expect(s.charactersNoLineBreaks, 0);
    expect(s.lines, 0);
  });

  test('single line', () {
    final s = TxtStats.of('hello world');
    expect(s.words, 2);
    expect(s.characters, 11);
    expect(s.charactersNoLineBreaks, 11);
    expect(s.lines, 1);
  });

  test('multi-line counts lines and words', () {
    final s = TxtStats.of('one two\nthree\nfour five six');
    expect(s.words, 6);
    expect(s.lines, 3);
    // 27 characters total including the two newlines.
    expect(s.characters, 27);
    expect(s.charactersNoLineBreaks, 25);
  });

  test('trailing newline counts the final empty line', () {
    final s = TxtStats.of('a\nb\n');
    expect(s.lines, 3); // 'a', 'b', ''
    expect(s.words, 2);
  });

  test('whitespace-only text has no words', () {
    final s = TxtStats.of('   \n\t  ');
    expect(s.words, 0);
    expect(s.lines, 2);
  });

  test('multiple spaces between words count as one separator', () {
    final s = TxtStats.of('a    b');
    expect(s.words, 2);
  });

  test('a multi-byte character counts as one character', () {
    final s = TxtStats.of('café 😀');
    // c a f é (4) + space + emoji (1 rune) = 6 characters, 2 words.
    expect(s.characters, 6);
    expect(s.words, 2);
  });
}
