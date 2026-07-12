import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_split_merge.dart';

void main() {
  const parser = JsonParser();
  const splitMerge = JsonSplitMerge();

  test('split then merge reproduces the original array', () {
    const source = '[1, 2, 3, 4, 5]';
    final parts = splitMerge.splitByCount(source, 2);
    expect(parts.length, 3); // [1,2] [3,4] [5]

    final merged = splitMerge.mergeArrays(parts);
    // Compare by minified form so whitespace does not matter.
    expect(minifyJson(parser.parse(merged).root!),
        minifyJson(parser.parse(source).root!));
  });

  test('split rejects a non-array document', () {
    expect(
      () => splitMerge.splitByCount('{"a": 1}', 2),
      throwsA(isA<JsonSplitMergeException>()),
    );
  });

  test('merge rejects a per-part below 1', () {
    expect(
      () => splitMerge.splitByCount('[1]', 0),
      throwsA(isA<JsonSplitMergeException>()),
    );
  });
}
