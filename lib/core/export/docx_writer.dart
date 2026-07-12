import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Builds a minimal, valid `.docx` (Office Open XML) file from plain text
/// (task 5.4) — **no Syncfusion, no commercial SDK** (CLAUDE.md §3.1).
///
/// A `.docx` is just a ZIP of XML parts. This writer emits the three core
/// parts an OOXML reader needs — the content-types map, the package
/// relationships, and the main document body — with one paragraph per input
/// line. All text is XML-escaped so `&`, `<`, `>` (and quotes) never corrupt
/// the document.
class DocxWriter {
  const DocxWriter();

  Uint8List fromText(String text) {
    final archive = Archive()
      ..addFile(_part('[Content_Types].xml', _contentTypes))
      ..addFile(_part('_rels/.rels', _packageRels))
      ..addFile(_part('word/_rels/document.xml.rels', _documentRels))
      ..addFile(_part('word/document.xml', _documentXml(text)));

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  ArchiveFile _part(String name, String xml) {
    final bytes = utf8.encode(xml);
    return ArchiveFile(name, bytes.length, bytes);
  }

  static const _contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

  static const _packageRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  static const _documentRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"></Relationships>''';

  String _documentXml(String text) {
    final lines = text.isEmpty ? const [''] : text.split('\n');
    final paragraphs = lines.map((line) {
      // xml:space="preserve" keeps leading/trailing spaces in each line.
      return '<w:p><w:r><w:t xml:space="preserve">${_escape(line)}</w:t></w:r></w:p>';
    }).join();
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
<w:body>$paragraphs</w:body>
</w:document>''';
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');
}
