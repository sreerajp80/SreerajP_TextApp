import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_path.dart';

void main() {
  const parser = JsonParser();

  const sample = '{"data": {"users": [{"name": "Ada"}, {"name": "Bea"}, '
      '{"name": "Cy"}, {"name": "Dee"}]}}';

  test('pathOf builds a dotted path with array indexes', () {
    final root = parser.parse(sample).root!;
    // data -> users -> [3] -> name
    final users = root.children.first.children.first;
    final name = users.children[3].children.first;
    expect(pathOf(name), 'data.users[3].name');
  });

  test('root path is \$', () {
    final root = parser.parse('{"a":1}').root!;
    expect(pathOf(root), r'$');
  });

  group('JSONPath queries', () {
    test('a child + index + child query returns the node', () {
      final root = parser.parse(sample).root!;
      final result = evaluateJsonPath(root, r'$.data.users[1].name');
      expect(result.hasError, isFalse);
      expect(result.matches.length, 1);
      expect(result.matches.first.stringValue, 'Bea');
    });

    test('a wildcard returns all elements', () {
      final root = parser.parse(sample).root!;
      final result = evaluateJsonPath(root, r'$.data.users[*].name');
      expect(result.matches.map((n) => n.stringValue),
          ['Ada', 'Bea', 'Cy', 'Dee']);
    });

    test('recursive descent finds a key at any depth', () {
      final root = parser.parse(sample).root!;
      final result = evaluateJsonPath(root, r'$..name');
      expect(result.matches.length, 4);
    });

    test('an invalid query returns empty with an error, no throw', () {
      final root = parser.parse(sample).root!;
      final result = evaluateJsonPath(root, r'$.data.users[');
      expect(result.hasError, isTrue);
      expect(result.matches, isEmpty);
    });
  });
}
