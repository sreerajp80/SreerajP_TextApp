import 'dart:convert';
import 'dart:typed_data';

import 'package:sreerajp_textapp/core/export/docx_writer.dart';
import 'package:sreerajp_textapp/core/export/export_target.dart';
import 'package:sreerajp_textapp/core/export/format_exporter.dart';
import 'package:sreerajp_textapp/core/export/html_writer.dart';
import 'package:sreerajp_textapp/core/export/pdf_writer.dart';

/// Export capability for TXT documents (task 5.4).
///
/// TXT is the first consumer of the shared export service. Its "natural"
/// output is its own text, so Markdown/plain-text targets are the text
/// verbatim, while PDF/DOCX/HTML wrap that text using the shared writers.
class TxtExporter implements FormatExporter {
  final PdfWriter _pdf;
  final DocxWriter _docx;
  final HtmlWriter _html;

  const TxtExporter({
    this._pdf = const PdfWriter(),
    this._docx = const DocxWriter(),
    this._html = const HtmlWriter(),
  });

  @override
  String get formatId => 'txt';

  @override
  Set<ExportTarget> get supportedTargets => const {
    ExportTarget.pdf,
    ExportTarget.docx,
    ExportTarget.html,
    ExportTarget.markdown,
    ExportTarget.plainText,
  };

  @override
  Future<ExportResult> export(ExportTarget target, TextContent content) async {
    final Uint8List bytes;
    switch (target) {
      case ExportTarget.pdf:
        bytes = await _pdf.fromText(content.text, title: content.baseName);
        break;
      case ExportTarget.docx:
        bytes = _docx.fromText(content.text);
        break;
      case ExportTarget.html:
        bytes = _html.fromText(content.text, title: content.baseName);
        break;
      case ExportTarget.markdown:
      case ExportTarget.plainText:
        bytes = Uint8List.fromList(utf8.encode(content.text));
        break;
      case ExportTarget.csv:
      case ExportTarget.yaml:
      case ExportTarget.json:
      case ExportTarget.xlsx:
        throw UnsupportedExportException(
          'TXT cannot export to ${target.label}.',
        );
    }
    return ExportResult(
      bytes: bytes,
      suggestedName: '${content.baseName}.${target.extension}',
      mimeType: target.mimeType,
      target: target,
    );
  }
}
