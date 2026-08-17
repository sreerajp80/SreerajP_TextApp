import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/formats/json/json_parser.dart';
import 'package:sreerajp_textapp/formats/json/json_path.dart';
import 'package:sreerajp_textapp/formats/json/json_query_builder.dart';

/// Guards the visual JSONPath builder (roadmap §4.3.2). The point of the
/// feature is that the built query is a real JSONPath the app's own evaluator
/// runs, so most tests check both halves: the text produced, and what it
/// selects when run.
void main() {
  const parser = JsonParser();
  const source = '''
{
  "users": [
    {"name": "Ada", "roles": ["admin", "dev"]},
    {"name": "Bob", "roles": ["dev"]}
  ],
  "site name": "TextData"
}
''';

  final root = parser.parse(source).root!;

  group('building the query text', () {
    test('no steps is the root', () {
      expect(JsonQueryBuilder.buildQuery(const []), r'$');
    });

    test('a plain key uses dot form', () {
      expect(
        JsonQueryBuilder.buildQuery(const [JsonQueryStep.key('users')]),
        r'$.users',
      );
    });

    test('a key that is not a plain word uses bracket form', () {
      expect(
        JsonQueryBuilder.buildQuery(const [JsonQueryStep.key('site name')]),
        r"$['site name']",
      );
    });

    test('positions, wildcards and any-depth steps', () {
      expect(
        JsonQueryBuilder.buildQuery(const [
          JsonQueryStep.key('users'),
          JsonQueryStep.index(1),
        ]),
        r'$.users[1]',
      );
      expect(
        JsonQueryBuilder.buildQuery(const [
          JsonQueryStep.key('users'),
          JsonQueryStep.allChildren(),
        ]),
        r'$.users[*]',
      );
      expect(
        JsonQueryBuilder.buildQuery(const [JsonQueryStep.anyDepthKey('name')]),
        r'$..name',
      );
      expect(
        JsonQueryBuilder.buildQuery(const [JsonQueryStep.anyDepthAll()]),
        r'$..*',
      );
    });
  });

  group('the built query runs in the app evaluator', () {
    List<String> run(List<JsonQueryStep> steps) {
      final query = JsonQueryBuilder.buildQuery(steps);
      final result = evaluateJsonPath(root, query);
      expect(result.error, isNull, reason: 'query was $query');
      return result.matches.map(pathOf).toList();
    }

    test('a key path selects the same node the builder resolved', () {
      const steps = [JsonQueryStep.key('users'), JsonQueryStep.index(0)];
      expect(run(steps).length, 1);
      expect(JsonQueryBuilder.resolve(root, steps).length, 1);
    });

    test('a wildcard selects every element', () {
      const steps = [JsonQueryStep.key('users'), JsonQueryStep.allChildren()];
      expect(run(steps).length, 2);
      expect(JsonQueryBuilder.resolve(root, steps).length, 2);
    });

    test('an any-depth key finds nested matches', () {
      const steps = [JsonQueryStep.anyDepthKey('name')];
      expect(run(steps).length, 2);
      expect(JsonQueryBuilder.resolve(root, steps).length, 2);
    });

    test('a key with a space round-trips through bracket form', () {
      const steps = [JsonQueryStep.key('site name')];
      expect(run(steps).length, 1);
    });
  });

  group('resolving', () {
    test('a step that matches nothing gives an empty result', () {
      expect(
        JsonQueryBuilder.resolve(root, const [JsonQueryStep.key('nope')]),
        isEmpty,
      );
    });

    test('a position past the end of an array gives an empty result', () {
      expect(
        JsonQueryBuilder.resolve(root, const [
          JsonQueryStep.key('users'),
          JsonQueryStep.index(9),
        ]),
        isEmpty,
      );
    });

    test('a key step on an array selects nothing rather than throwing', () {
      expect(
        JsonQueryBuilder.resolve(root, const [
          JsonQueryStep.key('users'),
          JsonQueryStep.key('name'),
        ]),
        isEmpty,
      );
    });
  });

  group('suggestions come from the document', () {
    test('the root offers its real keys', () {
      final labels = JsonQueryBuilder.suggestions(
        root,
        const [],
      ).map((c) => c.label);
      expect(labels, containsAll(['users', 'site name']));
    });

    test('an array offers element positions and the wildcard', () {
      final labels = JsonQueryBuilder.suggestions(root, const [
        JsonQueryStep.key('users'),
      ]).map((c) => c.label).toList();
      expect(labels.first, '[*]');
      expect(labels, containsAll(['[0]', '[1]']));
    });

    test('an element offers the keys of that record', () {
      final labels = JsonQueryBuilder.suggestions(root, const [
        JsonQueryStep.key('users'),
        JsonQueryStep.index(0),
      ]).map((c) => c.label);
      expect(labels, containsAll(['name', 'roles']));
    });

    test('positions are capped so a huge array stays usable', () {
      final big = parser.parse('[${List.filled(100, '1').join(',')}]').root!;
      final positions = JsonQueryBuilder.suggestions(
        big,
        const [],
        maxIndexChoices: 5,
      ).where((c) => c.label.startsWith('[')).toList();
      // Five positions plus the leading wildcard chip.
      expect(positions.length, 6);
    });

    test('a selection that matches nothing offers nothing', () {
      expect(
        JsonQueryBuilder.suggestions(root, const [JsonQueryStep.key('nope')]),
        isEmpty,
      );
    });

    test('a scalar has nothing to offer', () {
      expect(
        JsonQueryBuilder.suggestions(root, const [
          JsonQueryStep.key('site name'),
        ]),
        isEmpty,
      );
    });
  });

  group('deep key names', () {
    test('lists the key names below the selection, sorted', () {
      expect(JsonQueryBuilder.deepKeys(root, const []), [
        'name',
        'roles',
        'site name',
        'users',
      ]);
    });

    test('respects the limit', () {
      expect(
        JsonQueryBuilder.deepKeys(root, const [], limit: 2).length,
        lessThanOrEqualTo(2),
      );
    });
  });
}
