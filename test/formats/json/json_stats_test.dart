import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_node.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_stats.dart';

void main() {
  const parser = JsonParser();

  test('counts keys, depth, arrays, and a type breakdown', () {
    const source = '{"a": 1, "b": {"c": [true, false, null]}, "d": "x"}';
    final stats = JsonStats.of(parser.parse(source).root!);

    // Keys: a, b, c, d.
    expect(stats.keyCount, 4);
    // object > object > array > scalars = depth 4.
    expect(stats.maxDepth, 4);
    expect(stats.arrayCount, 1);
    expect(stats.largestArray, 3);
    expect(stats.topLevelType, JsonKind.object);
    expect(stats.topLevelItemCount, 3);
    expect(stats.typeBreakdown[JsonKind.boolean], 2);
    expect(stats.typeBreakdown[JsonKind.nullValue], 1);
  });

  test('reports a top-level array', () {
    final stats = JsonStats.of(parser.parse('[1, 2, 3]').root!);
    expect(stats.topLevelType, JsonKind.array);
    expect(stats.topLevelItemCount, 3);
    expect(stats.keyCount, 0);
  });
}
