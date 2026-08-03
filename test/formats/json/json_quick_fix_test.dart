import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_quick_fix.dart';

/// Guards the JSON quick fixes (roadmap §4.3.3). Every fix must leave text a
/// person would recognise, and must never touch what is inside a string.
void main() {
  const parser = JsonParser();

  bool isValid(String text) => parser.parse(text).ok;

  List<String> fixIds(String source) =>
      JsonQuickFixes.forSource(source).map((f) => f.id).toList();

  String? resultOf(String source, String id) {
    for (final fix in JsonQuickFixes.forSource(source)) {
      if (fix.id == id) return fix.result;
    }
    return null;
  }

  group('when fixes are offered', () {
    test('valid JSON needs no fixes', () {
      expect(JsonQuickFixes.forSource('{"a": 1}'), isEmpty);
    });

    test('empty text offers no fixes', () {
      expect(JsonQuickFixes.forSource(''), isEmpty);
      expect(JsonQuickFixes.forSource('   '), isEmpty);
    });

    test('a broken file offers the fixes that apply to it', () {
      expect(fixIds('{a: 1}'), contains(JsonQuickFixes.quoteKeys));
      expect(fixIds("{'a': 1}"), contains(JsonQuickFixes.doubleQuotes));
      expect(fixIds('{"a": 1,}'), contains(JsonQuickFixes.trailingCommas));
      expect(fixIds('{"a": 1} // note'),
          contains(JsonQuickFixes.removeComments));
      expect(fixIds('{"a": True}'), contains(JsonQuickFixes.pythonLiterals));
    });
  });

  group('quoting bare keys', () {
    test('quotes a bare key', () {
      expect(resultOf('{a: 1}', JsonQuickFixes.quoteKeys), '{"a": 1}');
    });

    test('quotes several keys, nested too', () {
      final fixed =
          JsonQuickFixes.quoteUnquotedKeys('{a: 1, b: {c: 2}}');
      expect(fixed, '{"a": 1, "b": {"c": 2}}');
      expect(isValid(fixed), isTrue);
    });

    test('leaves already-quoted keys alone', () {
      expect(JsonQuickFixes.quoteUnquotedKeys('{"a": 1}'), '{"a": 1}');
    });

    test('does not touch a bare word that is a value, not a key', () {
      // `true` is a value here, so it must not gain quotes.
      expect(JsonQuickFixes.quoteUnquotedKeys('{"a": true}'), '{"a": true}');
    });

    test('does not touch words inside an array', () {
      expect(JsonQuickFixes.quoteUnquotedKeys('[true, false]'),
          '[true, false]');
    });

    test('does not touch text that only looks like a key inside a string', () {
      expect(JsonQuickFixes.quoteUnquotedKeys('{"a": "b: 1"}'),
          '{"a": "b: 1"}');
    });
  });

  group('single to double quotes', () {
    test('swaps the quotes', () {
      final fixed = JsonQuickFixes.useDoubleQuotes("{'a': 'x'}");
      expect(fixed, '{"a": "x"}');
      expect(isValid(fixed), isTrue);
    });

    test('escapes a double quote that was inside', () {
      expect(JsonQuickFixes.useDoubleQuotes("{'a': 'say \"hi\"'}"),
          r'{"a": "say \"hi\""}');
    });

    test('leaves a single quote inside a double-quoted string alone', () {
      expect(JsonQuickFixes.useDoubleQuotes('{"a": "it\'s"}'),
          '{"a": "it\'s"}');
    });
  });

  group('trailing commas', () {
    test('drops a comma before a closing brace', () {
      expect(JsonQuickFixes.dropTrailingCommas('{"a": 1,}'), '{"a": 1}');
    });

    test('drops a comma before a closing bracket, across lines', () {
      final fixed = JsonQuickFixes.dropTrailingCommas('[\n  1,\n  2,\n]');
      expect(fixed, '[\n  1,\n  2\n]');
      expect(isValid(fixed), isTrue);
    });

    test('keeps commas that separate real values', () {
      expect(JsonQuickFixes.dropTrailingCommas('[1, 2]'), '[1, 2]');
    });

    test('leaves a comma inside a string alone', () {
      expect(JsonQuickFixes.dropTrailingCommas('{"a": "x,}"}'), '{"a": "x,}"}');
    });
  });

  group('comments', () {
    test('removes a line comment', () {
      final fixed = JsonQuickFixes.stripComments('{"a": 1} // note');
      expect(isValid(fixed), isTrue);
      expect(fixed.contains('note'), isFalse);
    });

    test('removes a block comment', () {
      expect(JsonQuickFixes.stripComments('{/* hi */"a": 1}'), '{"a": 1}');
    });

    test('leaves a slash inside a string alone', () {
      expect(JsonQuickFixes.stripComments('{"url": "http://x"}'),
          '{"url": "http://x"}');
    });

    test('an unterminated block comment does not crash', () {
      expect(JsonQuickFixes.stripComments('{"a": 1} /* oops'), '{"a": 1} ');
    });
  });

  group('Python literals', () {
    test('swaps True, False and None', () {
      final fixed =
          JsonQuickFixes.usePythonLiterals('{"a": True, "b": False, "c": None}');
      expect(fixed, '{"a": true, "b": false, "c": null}');
      expect(isValid(fixed), isTrue);
    });

    test('leaves the words alone inside a string', () {
      expect(JsonQuickFixes.usePythonLiterals('{"a": "True"}'),
          '{"a": "True"}');
    });
  });

  group('fix everything at once', () {
    test('repairs a file with several problems', () {
      const broken = "{\n  // config\n  name: 'TextData',\n  ok: True,\n}";
      final fix = JsonQuickFixes.fixAll(broken);
      expect(fix, isNotNull);
      expect(isValid(fix!.result), isTrue);
    });

    test('is not offered for valid JSON', () {
      expect(JsonQuickFixes.fixAll('{"a": 1}'), isNull);
    });

    test('is not offered when it cannot actually repair the file', () {
      // A missing closing brace is not something these fixes can mend.
      expect(JsonQuickFixes.fixAll('{"a": 1'), isNull);
    });

    test('an unterminated string does not crash the scanners', () {
      expect(() => JsonQuickFixes.forSource('{"a": "unterminated'),
          returnsNormally);
    });
  });
}
