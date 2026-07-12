import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/export/docx_writer.dart';

void main() {
  const writer = DocxWriter();

  String documentXml(List<int> docxBytes) {
    final archive = ZipDecoder().decodeBytes(docxBytes);
    final doc = archive.files.firstWhere((f) => f.name == 'word/document.xml');
    return utf8.decode(doc.content as List<int>);
  }

  group('DocxWriter', () {
    test('emits the three core OOXML parts', () {
      final archive = ZipDecoder().decodeBytes(writer.fromText('hi'));
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, containsAll(<String>[
        '[Content_Types].xml',
        '_rels/.rels',
        'word/document.xml',
      ]));
    });

    test('one paragraph per line', () {
      final xml = documentXml(writer.fromText('a\nb\nc'));
      expect('<w:p>'.allMatches(xml).length, 3);
    });

    test('escapes special characters', () {
      final xml = documentXml(writer.fromText('a & b < c > d " e'));
      expect(xml, contains('a &amp; b &lt; c &gt; d &quot; e'));
    });

    test('empty text still yields a valid single-paragraph document', () {
      final xml = documentXml(writer.fromText(''));
      expect(xml, contains('<w:body>'));
      expect('<w:p>'.allMatches(xml).length, 1);
    });
  });
}
