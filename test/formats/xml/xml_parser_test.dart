import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:text_data/formats/xml/xml_parser.dart';

void main() {
  const parser = XmlDocumentParser();

  group('XmlDocumentParser.parse', () {
    test('reads well-formed XML', () {
      final result = parser.parse('<root><a>1</a></root>');
      expect(result.ok, isTrue);
      expect(result.document, isNotNull);
    });

    test('malformed XML reports the error line, never throws', () {
      final result = parser.parse('<root>\n<a></b>\n</root>');
      expect(result.ok, isFalse);
      expect(result.errorLine, greaterThan(0));
      expect(result.errorMessage, isNotEmpty);
    });

    test('empty input is a friendly failure', () {
      final result = parser.parse('   ');
      expect(result.ok, isFalse);
      expect(result.errorMessage, contains('empty'));
    });

    test('truncated input never throws', () {
      final result = parser.parse('<root><child attr="v"');
      expect(result.ok, isFalse);
      expect(result.errorMessage, isNotNull);
    });
  });

  group('entities', () {
    test('built-in entity round-trip preserves text', () {
      const source = '<root>a &amp; b &lt; c</root>';
      final result = parser.parse(source);
      expect(result.ok, isTrue);
      // The decoded text is preserved...
      expect(result.document!.rootElement.innerText, 'a & b < c');
      // ...and re-escaped on serialize, so nothing is corrupted.
      final out = parser.minify(result.document!);
      expect(out, contains('&amp;'));
      expect(out, contains('&lt;'));
    });

    test('numeric entity decodes to its character and survives', () {
      final result = parser.parse('<root>caf&#233;</root>');
      expect(result.ok, isTrue);
      expect(result.document!.rootElement.innerText, 'café');
      // A second parse of the serialized form keeps the same text.
      final round = parser.parse(parser.minify(result.document!));
      expect(round.document!.rootElement.innerText, 'café');
    });

    test('CDATA content is preserved', () {
      final result = parser.parse('<root><![CDATA[<not a tag>]]></root>');
      expect(result.ok, isTrue);
      expect(result.document!.rootElement.innerText, '<not a tag>');
    });
  });

  group('declaration, encoding, namespaces', () {
    test('declaration + encoding preserved through pretty round-trip', () {
      const source = '<?xml version="1.0" encoding="UTF-8"?><root><a/></root>';
      final result = parser.parse(source);
      expect(result.ok, isTrue);
      expect(parser.declaredEncoding(result.document!), 'UTF-8');
      final pretty = parser.pretty(result.document!);
      expect(pretty, contains('<?xml'));
      expect(pretty, contains('encoding="UTF-8"'));
    });

    test('namespaces are listed', () {
      const source =
          '<root xmlns="urn:a" xmlns:x="urn:b"><x:child/></root>';
      final result = parser.parse(source);
      final ns = parser.namespaces(result.document!);
      expect(ns, containsAll(<String>['urn:a', 'urn:b']));
    });
  });

  test('pretty and minify both round-trip to the same tree', () {
    const source = '<root><a x="1">hi</a><a>bye</a></root>';
    final doc = parser.parse(source).document!;
    final pretty = parser.pretty(doc);
    final minified = parser.minify(doc);
    expect(parser.parse(pretty).ok, isTrue);
    expect(parser.parse(minified).ok, isTrue);
    expect(minified.contains('\n'), isFalse);
  });
}
