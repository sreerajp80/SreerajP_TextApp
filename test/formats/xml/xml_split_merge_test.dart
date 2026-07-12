import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:text_data/formats/xml/xml_split_merge.dart';

void main() {
  const splitMerge = XmlSplitMerge();

  const source = '''
<items>
  <item>one</item>
  <item>two</item>
  <item>three</item>
  <item>four</item>
  <item>five</item>
</items>''';

  test('splitByElement makes parts of the chosen size', () {
    final parts = splitMerge.splitByElement(source, 'item', 2);
    expect(parts.length, 3); // 2 + 2 + 1
    for (final part in parts) {
      expect(() => XmlDocument.parse(part), returnsNormally);
    }
  });

  test('split then merge under a wrapper reproduces the items', () {
    final parts = splitMerge.splitByElement(source, 'item', 2);
    final merged = splitMerge.mergeUnderWrapper(parts, 'items');

    final original = XmlDocument.parse(source)
        .rootElement
        .childElements
        .where((e) => e.name.qualified == 'item')
        .map((e) => e.innerText)
        .toList();
    final result = XmlDocument.parse(merged)
        .rootElement
        .childElements
        .where((e) => e.name.qualified == 'item')
        .map((e) => e.innerText)
        .toList();

    expect(result, original);
  });

  test('splitting on a missing tag is a friendly error', () {
    expect(
      () => splitMerge.splitByElement(source, 'nope', 2),
      throwsA(isA<XmlSplitMergeException>()),
    );
  });

  test('perPart below 1 is rejected', () {
    expect(
      () => splitMerge.splitByElement(source, 'item', 0),
      throwsA(isA<XmlSplitMergeException>()),
    );
  });

  test('merging invalid XML is a friendly error', () {
    expect(
      () => splitMerge.mergeUnderWrapper(['<broken'], 'root'),
      throwsA(isA<XmlSplitMergeException>()),
    );
  });
}
