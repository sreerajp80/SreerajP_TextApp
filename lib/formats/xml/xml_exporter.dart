import 'dart:convert';
import 'dart:typed_data';

import '../../core/export/export_target.dart';
import '../../core/export/format_exporter.dart';
import '../../core/export/html_writer.dart';
import '../../core/export/pdf_writer.dart';
import 'xml_convert.dart';
import 'xml_parser.dart';

/// Export capability for XML documents (task 9.6).
///
/// Implements the shared [FormatExporter] interface (defined in `core/export`)
/// but lives in the XML module because it needs the XML parser. Targets: JSON
/// (element→object mapping), CSV (flattening the most-common repeated child
/// element), PDF, HTML, and plain text. PDF/HTML use the pretty-printed XML; an
/// invalid document falls back to the raw text so export never crashes
/// (CLAUDE.md §3.4).
class XmlExporter implements FormatExporter {
  final PdfWriter _pdf;
  final HtmlWriter _html;
  final XmlDocumentParser _parser;

  const XmlExporter({
    PdfWriter pdf = const PdfWriter(),
    HtmlWriter html = const HtmlWriter(),
    XmlDocumentParser parser = const XmlDocumentParser(),
  })  : _pdf = pdf,
        _html = html,
        _parser = parser;

  @override
  String get formatId => 'xml';

  @override
  Set<ExportTarget> get supportedTargets => const {
        ExportTarget.json,
        ExportTarget.csv,
        ExportTarget.pdf,
        ExportTarget.html,
        ExportTarget.plainText,
      };

  @override
  Future<ExportResult> export(ExportTarget target, TextContent content) async {
    final parsed = _parser.parse(content.text);
    final document = parsed.document;
    final pretty =
        document != null ? _parser.pretty(document) : content.text;

    final Uint8List bytes;
    switch (target) {
      case ExportTarget.json:
        _requireParsed(document != null, 'JSON');
        bytes = Uint8List.fromList(utf8.encode(xmlToJson(document!)));
        break;
      case ExportTarget.csv:
        _requireParsed(document != null, 'CSV');
        final tag = bestRepeatedTag(document!);
        bytes = Uint8List.fromList(utf8.encode(xmlToCsv(document, tag)));
        break;
      case ExportTarget.pdf:
        bytes = await _pdf.fromText(pretty, title: content.baseName);
        break;
      case ExportTarget.html:
        bytes = _html.fromText(pretty, title: content.baseName);
        break;
      case ExportTarget.plainText:
        bytes = Uint8List.fromList(utf8.encode(content.text));
        break;
      case ExportTarget.markdown:
      case ExportTarget.docx:
      case ExportTarget.yaml:
      case ExportTarget.xlsx:
        throw UnsupportedExportException(
            'XML cannot export to ${target.label}.');
    }
    return ExportResult(
      bytes: bytes,
      suggestedName: '${content.baseName}.${target.extension}',
      mimeType: target.mimeType,
      target: target,
    );
  }

  void _requireParsed(bool ok, String targetName) {
    if (!ok) {
      throw UnsupportedExportException(
          'Fix the XML errors before exporting to $targetName.');
    }
  }
}
