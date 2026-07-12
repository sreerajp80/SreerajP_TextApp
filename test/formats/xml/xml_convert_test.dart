import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:text_data/formats/xml/xml_convert.dart';

void main() {
  group('xmlToJson', () {
    test('maps elements, attributes, text, and repeated tags', () {
      const source = '''
<library name="city">
  <book id="1"><title>A</title></book>
  <book id="2"><title>B</title></book>
</library>''';
      final json = xmlToJson(XmlDocument.parse(source));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final library = decoded['library'] as Map<String, dynamic>;
      expect(library['@name'], 'city');
      final books = library['book'] as List<dynamic>;
      expect(books.length, 2);
      expect((books.first as Map)['@id'], '1');
      expect((books.first as Map)['title'], 'A');
    });

    test('a text-only element becomes a string', () {
      final json = xmlToJson(XmlDocument.parse('<root>hello</root>'));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['root'], 'hello');
    });
  });

  group('xmlToCsv', () {
    test('flattens a repeated element into rows', () {
      const source = '''
<people>
  <person id="1"><name>A</name><age>30</age></person>
  <person id="2"><name>B</name><age>25</age></person>
</people>''';
      final csv = xmlToCsv(XmlDocument.parse(source), 'person');
      final lines = const LineSplitter().convert(csv.trim());
      expect(lines.first, '@id,name,age');
      expect(lines[1], '1,A,30');
      expect(lines[2], '2,B,25');
    });
  });

  group('bestRepeatedTag', () {
    test('picks the most common repeated child', () {
      const source = '<root><a/><b/><b/><b/></root>';
      expect(bestRepeatedTag(XmlDocument.parse(source)), 'b');
    });

    test('empty root yields empty string', () {
      expect(bestRepeatedTag(XmlDocument.parse('<root/>')), '');
    });
  });
}
