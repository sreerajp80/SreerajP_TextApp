import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_diff.dart';
import 'package:text_data/formats/json/json_parser.dart';

void main() {
  const parser = JsonParser();
  const diff = JsonDiff();

  test('reports added, removed, and changed paths', () {
    final a = parser.parse('{"keep": 1, "gone": 2, "num": 3}').root!;
    final b = parser.parse('{"keep": 1, "num": 4, "new": 5}').root!;
    final result = diff.compare(a, b);

    expect(result.removed, contains(r'$.gone'));
    expect(result.added, contains(r'$.new'));
    expect(result.changed, contains(r'$.num'));
  });

  test('compares arrays by index', () {
    final a = parser.parse('[1, 2, 3]').root!;
    final b = parser.parse('[1, 9]').root!;
    final result = diff.compare(a, b);

    expect(result.changed, contains(r'$[1]'));
    expect(result.removed, contains(r'$[2]'));
  });

  test('identical documents show no difference', () {
    final a = parser.parse('{"a": [1, {"b": true}]}').root!;
    final b = parser.parse('{"a": [1, {"b": true}]}').root!;
    expect(diff.compare(a, b).isEmpty, isTrue);
  });
}
