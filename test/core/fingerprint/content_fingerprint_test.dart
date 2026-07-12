import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/fingerprint/content_fingerprint.dart';

void main() {
  group('ContentFingerprint', () {
    test('same bytes give the same fingerprint', () {
      final a = ContentFingerprint.fromBytes(utf8.encode('hello world'));
      final b = ContentFingerprint.fromBytes(utf8.encode('hello world'));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.size, 11);
    });

    test('one changed byte gives a different fingerprint', () {
      final a = ContentFingerprint.fromBytes(utf8.encode('hello world'));
      final b = ContentFingerprint.fromBytes(utf8.encode('hello worlD'));
      expect(a, isNot(equals(b)));
      expect(a.sha256Hex, isNot(equals(b.sha256Hex)));
    });

    test('empty content is valid and stable', () {
      final a = ContentFingerprint.fromBytes(const []);
      final b = ContentFingerprint.fromBytes(const []);
      expect(a, equals(b));
      expect(a.size, 0);
    });

    test('stream hashing matches in-memory hashing', () async {
      final bytes = utf8.encode('the quick brown fox jumps over the lazy dog');
      final fromBytes = ContentFingerprint.fromBytes(bytes);

      // Feed the same bytes in several chunks.
      Stream<List<int>> chunks() async* {
        yield bytes.sublist(0, 10);
        yield bytes.sublist(10, 25);
        yield bytes.sublist(25);
      }

      final fromStream = await ContentFingerprint.fromStream(chunks());
      expect(fromStream, equals(fromBytes));
      expect(fromStream.size, bytes.length);
    });

    test('key round-trips through tryParse', () {
      final fp = ContentFingerprint.fromBytes(utf8.encode('abc'));
      final parsed = ContentFingerprint.tryParse(fp.key);
      expect(parsed, equals(fp));
    });

    test('tryParse rejects malformed keys without throwing', () {
      expect(ContentFingerprint.tryParse(''), isNull);
      expect(ContentFingerprint.tryParse('nope'), isNull);
      expect(ContentFingerprint.tryParse('-abc'), isNull);
      expect(ContentFingerprint.tryParse('12-'), isNull);
      expect(ContentFingerprint.tryParse('12-xyz'), isNull);
      // Right shape but hash too short.
      expect(ContentFingerprint.tryParse('12-abcd'), isNull);
    });
  });
}
