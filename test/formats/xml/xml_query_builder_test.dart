import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/formats/xml/xml_path.dart';
import 'package:text_data/formats/xml/xml_query_builder.dart';
import 'package:xml/xml.dart';

/// Guards the visual XPath builder (roadmap §4.3.2). As with the JSON twin, the
/// built expression must be a real XPath the app's own evaluator can run.
void main() {
  const source = '''
<catalog>
  <book id="b1"><title>One</title></book>
  <book id="b2"><title>Two</title></book>
  <note>hello</note>
</catalog>
''';
  final document = XmlDocument.parse(source);

  group('building the expression', () {
    test('no steps is the document root', () {
      expect(XmlQueryBuilder.buildQuery(const []), '/');
    });

    test('element steps join with slashes', () {
      expect(
        XmlQueryBuilder.buildQuery(const [
          XmlQueryStep.element('catalog'),
          XmlQueryStep.element('book'),
        ]),
        '/catalog/book',
      );
    });

    test('a position refines the step before it', () {
      expect(
        XmlQueryBuilder.buildQuery(const [
          XmlQueryStep.element('catalog'),
          XmlQueryStep.element('book'),
          XmlQueryStep.position(2),
        ]),
        '/catalog/book[2]',
      );
    });

    test('an attribute step uses @', () {
      expect(
        XmlQueryBuilder.buildQuery(const [
          XmlQueryStep.element('catalog'),
          XmlQueryStep.element('book'),
          XmlQueryStep.attribute('id'),
        ]),
        '/catalog/book/@id',
      );
    });

    test('an any-depth step uses //', () {
      expect(
        XmlQueryBuilder.buildQuery(const [XmlQueryStep.anyDepthElement('title')]),
        '//title',
      );
    });
  });

  group('the built expression runs in the app evaluator', () {
    List<XmlNode> run(List<XmlQueryStep> steps) {
      final query = XmlQueryBuilder.buildQuery(steps);
      final result = evaluateXPath(document, query);
      expect(result.error, isNull, reason: 'query was $query');
      return result.matches;
    }

    test('an element path selects what the builder resolved', () {
      const steps = [
        XmlQueryStep.element('catalog'),
        XmlQueryStep.element('book'),
      ];
      expect(run(steps).length, 2);
      expect(XmlQueryBuilder.resolve(document, steps).length, 2);
    });

    test('a position narrows to one match', () {
      const steps = [
        XmlQueryStep.element('catalog'),
        XmlQueryStep.element('book'),
        XmlQueryStep.position(2),
      ];
      expect(XmlQueryBuilder.resolve(document, steps).length, 1);
      expect(run(steps).length, 1);
    });

    test('an any-depth step finds nested elements', () {
      const steps = [XmlQueryStep.anyDepthElement('title')];
      expect(XmlQueryBuilder.resolve(document, steps).length, 2);
      expect(run(steps).length, 2);
    });
  });

  group('resolving', () {
    test('a name that is not there gives an empty result', () {
      expect(
        XmlQueryBuilder.resolve(document, const [XmlQueryStep.element('nope')]),
        isEmpty,
      );
    });

    test('a position past the end gives an empty result', () {
      expect(
        XmlQueryBuilder.resolve(document, const [
          XmlQueryStep.element('catalog'),
          XmlQueryStep.element('book'),
          XmlQueryStep.position(9),
        ]),
        isEmpty,
      );
    });

    test('an attribute step selects the attribute node', () {
      final matches = XmlQueryBuilder.resolve(document, const [
        XmlQueryStep.element('catalog'),
        XmlQueryStep.element('book'),
        XmlQueryStep.position(1),
        XmlQueryStep.attribute('id'),
      ]);
      expect(matches.length, 1);
      expect((matches.first as XmlAttribute).value, 'b1');
    });
  });

  group('suggestions come from the document', () {
    test('the document offers its root element', () {
      final labels =
          XmlQueryBuilder.suggestions(document, const []).map((c) => c.label);
      expect(labels, contains('catalog'));
    });

    test('an element offers its child element names', () {
      final labels = XmlQueryBuilder.suggestions(
        document,
        const [XmlQueryStep.element('catalog')],
      ).map((c) => c.label).toList();
      expect(labels, containsAll(['book', 'note']));
    });

    test('several matches offer positions to narrow with', () {
      final labels = XmlQueryBuilder.suggestions(
        document,
        const [XmlQueryStep.element('catalog'), XmlQueryStep.element('book')],
      ).map((c) => c.label).toList();
      expect(labels, containsAll(['[1]', '[2]']));
    });

    test('a single element offers its attributes', () {
      final labels = XmlQueryBuilder.suggestions(
        document,
        const [
          XmlQueryStep.element('catalog'),
          XmlQueryStep.element('book'),
          XmlQueryStep.position(1),
        ],
      ).map((c) => c.label).toList();
      expect(labels, contains('@id'));
      // Already narrowed, so no more position chips.
      expect(labels.any((l) => l.startsWith('[')), isFalse);
    });

    test('a selection that matches nothing offers nothing', () {
      expect(
        XmlQueryBuilder.suggestions(document, const [
          XmlQueryStep.element('nope'),
        ]),
        isEmpty,
      );
    });
  });

  group('deep element names', () {
    test('lists the names below the selection, sorted', () {
      expect(XmlQueryBuilder.deepElementNames(document, const []),
          ['book', 'catalog', 'note', 'title']);
    });

    test('respects the limit', () {
      expect(
        XmlQueryBuilder.deepElementNames(document, const [], limit: 2).length,
        lessThanOrEqualTo(2),
      );
    });
  });
}
