import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:text_data/formats/xml/xml_path.dart';

void main() {
  const source = '''
<root>
  <items>
    <item><name>A</name></item>
    <item><name>B</name></item>
  </items>
  <meta id="7"/>
</root>''';

  final document = XmlDocument.parse(source);

  group('xmlPathOf', () {
    test('unique elements have no index, repeated ones do', () {
      final items = document.rootElement.childElements.first; // <items>
      final secondItem = items.childElements.toList()[1]; // <item>[2]
      final name = secondItem.childElements.first; // <name>
      expect(xmlPathOf(name), 'root/items/item[2]/name');
    });

    test('attribute paths end with /@name', () {
      final meta = document.rootElement.childElements.last; // <meta>
      final attr = meta.attributes.first; // id
      expect(xmlPathOf(attr), 'root/meta/@id');
    });
  });

  group('evaluateXPath', () {
    test('a valid query returns the expected nodes', () {
      final result = evaluateXPath(document, '//item');
      expect(result.hasError, isFalse);
      expect(result.matches.length, 2);
    });

    test('a query for names returns both name elements', () {
      final result = evaluateXPath(document, '//name');
      expect(result.matches.length, 2);
    });

    test('an invalid query degrades to an error, never throws', () {
      final result = evaluateXPath(document, '///[[[');
      expect(result.hasError, isTrue);
      expect(result.matches, isEmpty);
    });

    test('an empty query returns no matches and no error', () {
      final result = evaluateXPath(document, '   ');
      expect(result.hasError, isFalse);
      expect(result.matches, isEmpty);
    });
  });
}
