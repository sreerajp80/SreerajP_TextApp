import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/json/json_parser.dart';
import 'package:text_data/formats/json/json_table.dart';

/// Guards the JSON array-to-table grid view (roadmap §4.3.1), including the
/// failure paths: anything that is not a usable array gives an empty table
/// rather than an error (CLAUDE.md §3.4).
void main() {
  const parser = JsonParser();

  JsonTable tableFor(String source) {
    final result = parser.parse(source);
    return JsonTable.fromNode(result.root);
  }

  group('detecting a tabular array', () {
    test('an array of objects is tabular', () {
      final root = parser.parse('[{"a":1},{"a":2}]').root;
      expect(JsonTable.isTabular(root), isTrue);
    });

    test('an array of plain values is tabular', () {
      final root = parser.parse('[1,2,3]').root;
      expect(JsonTable.isTabular(root), isTrue);
    });

    test('an object is not tabular', () {
      final root = parser.parse('{"a":1}').root;
      expect(JsonTable.isTabular(root), isFalse);
    });

    test('an empty array is not tabular', () {
      expect(JsonTable.isTabular(parser.parse('[]').root), isFalse);
    });

    test('a mix of objects and plain values is not tabular', () {
      final root = parser.parse('[{"a":1}, 2]').root;
      expect(JsonTable.isTabular(root), isFalse);
    });

    test('null is not tabular', () {
      expect(JsonTable.isTabular(null), isFalse);
    });
  });

  group('building the grid', () {
    test('one row per element, one column per key', () {
      final t = tableFor('[{"name":"Ada","age":36},{"name":"Bob","age":40}]');
      expect(t.columns, ['name', 'age']);
      expect(t.rowCount, 2);
      expect(t.cell(0, 0), 'Ada');
      expect(t.cell(1, 1), '40');
    });

    test('columns are the union of keys, in first-seen order', () {
      final t = tableFor('[{"a":1},{"b":2},{"a":3,"c":4}]');
      expect(t.columns, ['a', 'b', 'c']);
    });

    test('a record missing a key leaves that cell blank', () {
      final t = tableFor('[{"a":1,"b":2},{"a":3}]');
      expect(t.cell(1, 1), '');
    });

    test('strings lose their quotes but numbers keep their exact text', () {
      final t = tableFor('[{"s":"hi","n":1.500}]');
      expect(t.cell(0, 0), 'hi');
      expect(t.cell(0, 1), '1.500');
    });

    test('a nested value shows its size instead of being flattened', () {
      final t = tableFor('[{"o":{"x":1,"y":2},"a":[1,2,3]}]');
      expect(t.cell(0, 0), '{ 2 }');
      expect(t.cell(0, 1), '[ 3 ]');
    });

    test('an array of plain values becomes one value column', () {
      final t = tableFor('["a","b"]');
      expect(t.isValueList, isTrue);
      expect(t.columns, [JsonTable.valueColumnName]);
      expect(t.cell(1, 0), 'b');
    });

    test('a node that is not tabular gives an empty table', () {
      final t = tableFor('{"a":1}');
      expect(t.isEmpty, isTrue);
      expect(t.cell(0, 0), '');
    });

    test('objects with no keys at all give an empty table', () {
      expect(tableFor('[{},{}]').isEmpty, isTrue);
    });

    test('out-of-range cells read as blank, never throwing', () {
      final t = tableFor('[{"a":1}]');
      expect(t.cell(-1, 0), '');
      expect(t.cell(0, 9), '');
      expect(t.cell(9, 0), '');
    });
  });

  group('sorting', () {
    test('a number column sorts numerically, not as text', () {
      final t = tableFor('[{"n":9},{"n":10},{"n":1}]');
      expect(t.sortedRowIndices(0, JsonSortDirection.ascending), [2, 0, 1]);
    });

    test('a text column sorts without case', () {
      final t = tableFor('[{"s":"b"},{"s":"A"},{"s":"c"}]');
      expect(t.sortedRowIndices(0, JsonSortDirection.ascending), [1, 0, 2]);
    });

    test('descending reverses the order', () {
      final t = tableFor('[{"n":1},{"n":2}]');
      expect(t.sortedRowIndices(0, JsonSortDirection.descending), [1, 0]);
    });

    test('none leaves the document order alone', () {
      final t = tableFor('[{"n":2},{"n":1}]');
      expect(t.sortedRowIndices(0, JsonSortDirection.none), [0, 1]);
    });

    test('blank cells sort last', () {
      final t = tableFor('[{"a":1,"b":2},{"a":3},{"a":2,"b":1}]');
      expect(t.sortedRowIndices(1, JsonSortDirection.ascending), [2, 0, 1]);
    });

    test('a column outside the table is ignored', () {
      final t = tableFor('[{"n":2},{"n":1}]');
      expect(t.sortedRowIndices(9, JsonSortDirection.ascending), [0, 1]);
    });
  });

  group('CSV export', () {
    test('writes a header row and quotes what needs it', () {
      final t = tableFor('[{"a":"x,y","b":"say \\"hi\\""}]');
      expect(t.toCsv(), 'a,b\n"x,y","say ""hi"""');
    });
  });
}
