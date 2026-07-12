import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:text_data/core/export/export_service.dart';
import 'package:text_data/core/export/export_target.dart';
import 'package:text_data/core/export/txt_exporter.dart';

void main() {
  final service = ExportService([const TxtExporter()]);
  const content = TextContent(
    displayName: 'notes.txt',
    text: 'Hello & welcome\nSecond <line>\n',
  );

  group('ExportService — TXT targets', () {
    test('supportedTargets lists the TXT targets', () {
      expect(
        service.supportedTargets('txt'),
        containsAll(<ExportTarget>[
          ExportTarget.pdf,
          ExportTarget.docx,
          ExportTarget.html,
          ExportTarget.markdown,
          ExportTarget.plainText,
        ]),
      );
    });

    test('TXT→PDF produces valid, openable PDF bytes', () async {
      final result = await service.export('txt', ExportTarget.pdf, content);
      expect(result.suggestedName, 'notes.pdf');
      expect(result.mimeType, 'application/pdf');
      // A PDF file starts with the "%PDF-" header and ends near "%%EOF".
      final head = String.fromCharCodes(result.bytes.sublist(0, 5));
      expect(head, '%PDF-');
      expect(result.bytes.length, greaterThan(100));
    });

    test('TXT→DOCX produces a valid zip with the escaped text', () async {
      final result = await service.export('txt', ExportTarget.docx, content);
      expect(result.suggestedName, 'notes.docx');

      final archive = ZipDecoder().decodeBytes(result.bytes);
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, contains('[Content_Types].xml'));
      expect(names, contains('word/document.xml'));

      final doc = archive.files.firstWhere((f) => f.name == 'word/document.xml');
      final xml = utf8.decode(doc.content as List<int>);
      // Special chars must be escaped, not raw.
      expect(xml, contains('Hello &amp; welcome'));
      expect(xml, contains('Second &lt;line&gt;'));
      expect(xml, isNot(contains('Hello & welcome')));
    });

    test('TXT→plainText returns the text verbatim', () async {
      final result =
          await service.export('txt', ExportTarget.plainText, content);
      expect(utf8.decode(result.bytes), content.text);
    });

    test('unknown format is rejected cleanly', () {
      expect(
        () => service.export('csv', ExportTarget.pdf, content),
        throwsA(isA<UnsupportedExportException>()),
      );
    });
  });
}
