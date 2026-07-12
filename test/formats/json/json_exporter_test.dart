import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/export/export_target.dart';
import 'package:text_data/formats/json/json_exporter.dart';

void main() {
  const exporter = JsonExporter();

  TextContent content(String text) =>
      TextContent(displayName: 'data.json', text: text);

  test('JSON -> CSV flattens an array of objects', () async {
    final result = await exporter.export(
      ExportTarget.csv,
      content('[{"name":"Ada","age":36},{"name":"Bea","age":40}]'),
    );
    final csv = utf8.decode(result.bytes);
    expect(csv.split('\n').first.trim(), 'name,age');
    expect(csv.contains('Ada,36'), isTrue);
    expect(result.suggestedName, 'data.csv');
  });

  test('JSON -> YAML emits valid-looking YAML', () async {
    final result = await exporter.export(
      ExportTarget.yaml,
      content('{"name":"Ada","tags":["x","y"]}'),
    );
    final yaml = utf8.decode(result.bytes);
    expect(yaml.contains('name: Ada'), isTrue);
    expect(yaml.contains('- x'), isTrue);
  });

  test('JSON -> PDF starts with the PDF signature', () async {
    final result = await exporter.export(ExportTarget.pdf, content('{"a":1}'));
    final head = String.fromCharCodes(result.bytes.take(5));
    expect(head, '%PDF-');
  });

  test('JSON -> HTML produces an HTML document', () async {
    final result = await exporter.export(ExportTarget.html, content('{"a":1}'));
    final html = utf8.decode(result.bytes);
    expect(html.contains('<!DOCTYPE html>'), isTrue);
  });

  test('CSV export of invalid JSON is rejected cleanly', () async {
    expect(
      () => exporter.export(ExportTarget.csv, content('{bad')),
      throwsA(isA<UnsupportedExportException>()),
    );
  });

  test('an unsupported target throws', () async {
    expect(
      () => exporter.export(ExportTarget.docx, content('{"a":1}')),
      throwsA(isA<UnsupportedExportException>()),
    );
  });
}
