import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/export/export_target.dart';
import 'package:text_data/formats/xml/xml_exporter.dart';

void main() {
  const exporter = XmlExporter();
  const content = TextContent(
    displayName: 'people.xml',
    text: '''
<people>
  <person id="1"><name>A</name></person>
  <person id="2"><name>B</name></person>
</people>''',
  );

  test('XML to JSON is valid JSON', () async {
    final result = await exporter.export(ExportTarget.json, content);
    final decoded = jsonDecode(utf8.decode(result.bytes));
    expect(decoded, isA<Map<String, dynamic>>());
    expect(result.suggestedName, 'people.json');
  });

  test('XML to CSV flattens the repeated element', () async {
    final result = await exporter.export(ExportTarget.csv, content);
    final csv = utf8.decode(result.bytes);
    expect(csv, contains('@id,name'));
    expect(csv, contains('1,A'));
  });

  test('XML to PDF starts with the PDF marker', () async {
    final result = await exporter.export(ExportTarget.pdf, content);
    expect(utf8.decode(result.bytes.sublist(0, 5)), '%PDF-');
  });

  test('XML to HTML is HTML', () async {
    final result = await exporter.export(ExportTarget.html, content);
    expect(utf8.decode(result.bytes).toLowerCase(), contains('<html'));
  });

  test('an unsupported target throws', () async {
    expect(
      () => exporter.export(ExportTarget.docx, content),
      throwsA(isA<UnsupportedExportException>()),
    );
  });

  test('invalid XML is rejected for structured targets', () async {
    const broken = TextContent(displayName: 'x.xml', text: '<root><a></b>');
    expect(
      () => exporter.export(ExportTarget.json, broken),
      throwsA(isA<UnsupportedExportException>()),
    );
  });
}
