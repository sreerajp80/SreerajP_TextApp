import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/export/export_target.dart';
import 'package:text_data/core/export/md_exporter.dart';

void main() {
  const exporter = MarkdownExporter();
  const content = TextContent(
    displayName: 'notes.md',
    text: '# Title\n\nSome **bold** text and a [link](https://x.com).\n\n'
        '| A | B |\n| - | - |\n| 1 | 2 |',
  );

  test('reports its supported targets', () {
    expect(exporter.formatId, 'md');
    expect(exporter.supportedTargets, contains(ExportTarget.html));
    expect(exporter.supportedTargets, contains(ExportTarget.pdf));
    expect(exporter.supportedTargets, contains(ExportTarget.docx));
  });

  test('HTML export renders the Markdown to real HTML', () async {
    final result = await exporter.export(ExportTarget.html, content);
    final html = utf8.decode(result.bytes);
    expect(result.suggestedName, 'notes.html');
    expect(html, contains('<!DOCTYPE html>'));
    expect(html, contains('<h1'));
    expect(html, contains('Title</h1>'));
    expect(html, contains('<strong>bold</strong>'));
    expect(html, contains('<table>'));
    expect(html, contains('href="https://x.com"'));
  });

  test('PDF export starts with the PDF signature', () async {
    final result = await exporter.export(ExportTarget.pdf, content);
    final head = String.fromCharCodes(result.bytes.take(5));
    expect(head, '%PDF-');
    expect(result.suggestedName, 'notes.pdf');
  });

  test('DOCX export is a valid zip (PK signature)', () async {
    final result = await exporter.export(ExportTarget.docx, content);
    expect(result.bytes[0], 0x50); // 'P'
    expect(result.bytes[1], 0x4B); // 'K'
    expect(result.suggestedName, 'notes.docx');
  });

  test('markdown target passes the source through', () async {
    final result = await exporter.export(ExportTarget.markdown, content);
    expect(utf8.decode(result.bytes), content.text);
  });
}
