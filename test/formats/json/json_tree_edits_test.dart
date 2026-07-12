import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_tree_edits.dart';

void main() {
  const parser = JsonParser();
  const edits = JsonTreeEdits();

  test('setScalarValue replaces a value in place', () {
    const source = '{"a": 1, "b": 2}';
    final root = parser.parse(source).root!;
    final a = root.children.first;
    final next = edits.setScalarValue(source, a, '42');
    expect(next, '{"a": 42, "b": 2}');
    expect(parser.parse(next).ok, isTrue);
  });

  test('setKey renames a member key', () {
    const source = '{"a": 1}';
    final root = parser.parse(source).root!;
    final next = edits.setKey(source, root.children.first, 'renamed');
    expect(next, '{"renamed": 1}');
  });

  test('deleteNode removes a middle member with its comma', () {
    const source = '{"a": 1, "b": 2, "c": 3}';
    final root = parser.parse(source).root!;
    final next = edits.deleteNode(source, root.children[1]);
    final reparsed = parser.parse(next);
    expect(reparsed.ok, isTrue);
    expect(reparsed.root!.children.map((c) => c.key), ['a', 'c']);
  });

  test('deleteNode removes the last array element', () {
    const source = '[1, 2, 3]';
    final root = parser.parse(source).root!;
    final next = edits.deleteNode(source, root.children.last);
    final reparsed = parser.parse(next);
    expect(reparsed.ok, isTrue);
    expect(reparsed.root!.children.length, 2);
  });

  test('addChild inserts a new object member', () {
    const source = '{"a": 1}';
    final root = parser.parse(source).root!;
    final next = edits.addChild(source, root, key: 'b', rawValue: '2');
    final reparsed = parser.parse(next);
    expect(reparsed.ok, isTrue);
    expect(reparsed.root!.children.map((c) => c.key), ['a', 'b']);
  });

  test('addChild inserts into an empty array', () {
    const source = '[]';
    final root = parser.parse(source).root!;
    final next = edits.addChild(source, root, rawValue: '"x"');
    final reparsed = parser.parse(next);
    expect(reparsed.ok, isTrue);
    expect(reparsed.root!.children.single.stringValue, 'x');
  });
}
