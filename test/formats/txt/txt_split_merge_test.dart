import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/formats/txt/txt_split_merge.dart';

void main() {
  const sm = TxtSplitMerge();

  group('splitByLines', () {
    test('splits into groups of the given size', () {
      final parts = sm.splitByLines('a\nb\nc\nd\ne', 2);
      expect(parts, ['a\nb', 'c\nd', 'e']);
    });

    test('split then merge reproduces the original', () {
      const text = 'first\nsecond\nthird\nfourth';
      expect(sm.merge(sm.splitByLines(text, 3)), text);
    });

    test('round-trip preserves a trailing newline', () {
      const text = 'a\nb\n';
      final parts = sm.splitByLines(text, 2);
      expect(sm.merge(parts), text);
    });

    test('rejects a part size below one', () {
      expect(() => sm.splitByLines('x', 0), throwsArgumentError);
    });

    test('empty text yields a single empty part that round-trips', () {
      final parts = sm.splitByLines('', 5);
      expect(sm.merge(parts), '');
    });
  });

  group('splitBySize', () {
    test('breaks on line boundaries within the byte cap', () {
      // Each of these lines is 3 bytes; a 7-byte cap fits two lines + the join.
      final parts = sm.splitBySize('abc\ndef\nghi', 7,
          encoding: TextEncodingType.utf8);
      expect(sm.merge(parts), 'abc\ndef\nghi');
      for (final p in parts.take(parts.length - 1)) {
        expect(p.length <= 7, isTrue);
      }
    });

    test('split then merge reproduces the original', () {
      const text = 'alpha\nbeta\ngamma\ndelta\nepsilon';
      final parts = sm.splitBySize(text, 12);
      expect(sm.merge(parts), text);
    });

    test('a single oversized line becomes its own part', () {
      const text = 'short\nthisisaverylongsingleline\nx';
      final parts = sm.splitBySize(text, 10);
      expect(sm.merge(parts), text);
      expect(parts, contains('thisisaverylongsingleline'));
    });

    test('rejects a cap below one', () {
      expect(() => sm.splitBySize('x', 0), throwsArgumentError);
    });
  });

  test('merge concatenates several documents in order', () {
    expect(sm.merge(['one', 'two', 'three']), 'one\ntwo\nthree');
  });
}
