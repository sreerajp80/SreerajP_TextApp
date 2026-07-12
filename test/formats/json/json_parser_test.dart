import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_node.dart';
import 'package:text_data/formats/json/json_parser.dart';

void main() {
  const parser = JsonParser();

  group('valid parsing', () {
    test('parses an object and array with typed scalars', () {
      final result = parser.parse('{"a": 1, "b": [true, null, "x"]}');
      expect(result.ok, isTrue);
      final root = result.root!;
      expect(root.kind, JsonKind.object);
      expect(root.children.first.key, 'a');
      expect(root.children.first.kind, JsonKind.number);
      final b = root.children[1];
      expect(b.kind, JsonKind.array);
      expect(b.children.map((c) => c.kind), [
        JsonKind.boolean,
        JsonKind.nullValue,
        JsonKind.string,
      ]);
      expect(b.children[1].index, 1);
    });

    test('records source spans that slice back to the value', () {
      const source = '{"name": "Ada"}';
      final root = parser.parse(source).root!;
      final value = root.children.first;
      expect(source.substring(value.start, value.end), '"Ada"');
      expect(source.substring(value.keyStart, value.keyEnd), '"name"');
    });
  });

  group('invalid parsing', () {
    test('reports the error line for a broken document', () {
      final result = parser.parse('{\n  "a": 1,\n  "b":\n}');
      expect(result.ok, isFalse);
      expect(result.errorMessage, isNotNull);
      expect(result.errorLine, isNotNull);
      expect(result.errorLine, greaterThanOrEqualTo(1));
    });

    test('an empty document is not valid JSON but does not throw', () {
      final result = parser.parse('   ');
      expect(result.ok, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('strict mode rejects a trailing comma', () {
      final result = parser.parse('[1, 2, ]');
      expect(result.ok, isFalse);
    });
  });

  group('lenient JSONC / JSON5', () {
    test('tolerates comments and trailing commas and flags it', () {
      const source = '''
{
  // a line comment
  "a": 1, /* block */
  "b": 2,
}''';
      final result = parser.parse(source, lenient: true);
      expect(result.ok, isTrue);
      expect(result.lenientFeaturesUsed, isTrue);
      expect(result.root!.children.length, 2);
    });

    test('tolerates single quotes and unquoted keys', () {
      final result = parser.parse("{name: 'Ada'}", lenient: true);
      expect(result.ok, isTrue);
      expect(result.root!.children.first.key, 'name');
      expect(result.root!.children.first.stringValue, 'Ada');
    });
  });

  group('big numbers', () {
    test('keeps a high-precision number as exact text through a round-trip', () {
      const big = '{"n": 123456789012345678901234567890.123456789}';
      final root = parser.parse(big).root!;
      final number = root.children.first;
      expect(number.rawText, '123456789012345678901234567890.123456789');
      // Re-emitting keeps the exact digits (dart:convert would have rounded).
      expect(minifyJson(root), '{"n":123456789012345678901234567890.123456789}');
    });
  });

  group('pretty / minify', () {
    test('pretty then re-parse then minify is stable', () {
      const source = '{"a":[1,2],"b":{"c":true}}';
      final root = parser.parse(source).root!;
      final pretty = prettyPrintJson(root);
      expect(pretty.contains('\n'), isTrue);
      final reparsed = parser.parse(pretty).root!;
      expect(minifyJson(reparsed), source);
    });

    test('single-quoted lenient input is saved as strict double-quoted', () {
      final root = parser.parse("{'a': 'b'}", lenient: true).root!;
      expect(minifyJson(root), '{"a":"b"}');
    });
  });

  group('NDJSON', () {
    test('detects and parses newline-delimited records', () {
      const source = '{"a":1}\n{"a":2}\n{"a":3}';
      expect(parser.looksLikeNdjson(source), isTrue);
      final records = parser.parseNdjson(source);
      expect(records.length, 3);
      expect(records.every((r) => r.ok), isTrue);
      expect(records[1].node!.children.first.rawText, '2');
    });

    test('a single JSON value is not treated as NDJSON', () {
      expect(parser.looksLikeNdjson('{"a":1}'), isFalse);
    });
  });
}
