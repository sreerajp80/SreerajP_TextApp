import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:text_data/formats/xml/xml_stats.dart';

void main() {
  test('stats count elements, depth, tags, and attributes', () {
    const source = '''
<library name="city">
  <book id="1"><title>A</title></book>
  <book id="2"><title>B</title></book>
  <book id="3"><title>C</title></book>
</library>''';
    final stats = XmlStats.of(XmlDocument.parse(source));

    // library + 3 book + 3 title = 7 elements.
    expect(stats.elementCount, 7);
    expect(stats.rootElement, 'library');
    expect(stats.maxDepth, 3); // library > book > title
    expect(stats.tagCounts['book'], 3);
    expect(stats.tagCounts['title'], 3);
    // id (x3) + name (x1) = 4 attributes.
    expect(stats.attributeCount, 4);
    expect(stats.attributesByTag['book'], contains('id'));
    expect(stats.attributesByTag['library'], contains('name'));
    expect(stats.mostCommonTags.first.value, 3);
  });
}
