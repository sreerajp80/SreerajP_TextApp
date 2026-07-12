import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/export/csv_exporter.dart';
import 'package:text_data/core/export/export_target.dart';

void main() {
  const exporter = CsvExporter();
  const content = TextContent(
    displayName: 'people.csv',
    text: 'name,age\nAda,36\nBob,40',
  );

  test('reports its supported targets', () {
    expect(exporter.formatId, 'csv');
    expect(exporter.supportedTargets, {
      ExportTarget.pdf,
      ExportTarget.json,
      ExportTarget.html,
      ExportTarget.xlsx,
    });
  });

  test('PDF export starts with the PDF signature', () async {
    final result = await exporter.export(ExportTarget.pdf, content);
    final head = String.fromCharCodes(result.bytes.take(5));
    expect(head, '%PDF-');
    expect(result.suggestedName, 'people.pdf');
  });

  test('JSON export is an array of header-keyed objects', () async {
    final result = await exporter.export(ExportTarget.json, content);
    final decoded = jsonDecode(utf8.decode(result.bytes)) as List;
    expect(decoded.length, 2);
    expect(decoded.first, {'name': 'Ada', 'age': '36'});
    expect(result.suggestedName, 'people.json');
  });

  test('HTML export renders a table', () async {
    final result = await exporter.export(ExportTarget.html, content);
    final html = utf8.decode(result.bytes);
    expect(html, contains('<table>'));
    expect(html, contains('<th>name</th>'));
    expect(html, contains('<td>Ada</td>'));
  });

  test('XLSX export is a valid zip containing the worksheet', () async {
    final result = await exporter.export(ExportTarget.xlsx, content);
    expect(result.bytes[0], 0x50); // 'P'
    expect(result.bytes[1], 0x4B); // 'K'
    final archive = ZipDecoder().decodeBytes(result.bytes);
    final names = archive.files.map((f) => f.name).toList();
    expect(names, contains('xl/worksheets/sheet1.xml'));
    expect(names, contains('xl/workbook.xml'));
    final sheet = utf8.decode(
      archive.files.firstWhere((f) => f.name == 'xl/worksheets/sheet1.xml')
          .content as List<int>,
    );
    expect(sheet, contains('Ada'));
  });

  test('export of only selected rows exports just those rows', () async {
    // Simulate the session handing over a subset (header + one row).
    const subset = TextContent(
      displayName: 'people.csv',
      text: 'name,age\nBob,40',
    );
    final result = await exporter.export(ExportTarget.json, subset);
    final decoded = jsonDecode(utf8.decode(result.bytes)) as List;
    expect(decoded.length, 1);
    expect(decoded.first, {'name': 'Bob', 'age': '40'});
  });

  test('an unsupported target is rejected cleanly', () async {
    expect(
      () => exporter.export(ExportTarget.docx, content),
      throwsA(isA<UnsupportedExportException>()),
    );
  });
}
