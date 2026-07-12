import 'dart:convert';
import 'dart:typed_data';

import 'package:markdown/markdown.dart' as md;

import 'docx_writer.dart';
import 'export_target.dart';
import 'format_exporter.dart';
import 'pdf_writer.dart';

/// Export capability for Markdown documents (task 6.5).
///
/// Lives in `core/export` alongside [TxtExporter] so the export layer has no
/// dependency on the format UI modules. HTML is genuine rendered HTML (via the
/// `markdown` parser) wrapped in a self-contained, offline page (CLAUDE.md §3.2).
/// PDF and DOCX reuse the shared writers over the Markdown source text for this
/// phase — structure-faithful PDF/DOCX is a later enhancement (plan §8).
/// `markdown` / `plainText` pass the source through unchanged.
class MarkdownExporter implements FormatExporter {
  final PdfWriter _pdf;
  final DocxWriter _docx;

  const MarkdownExporter({
    PdfWriter pdf = const PdfWriter(),
    DocxWriter docx = const DocxWriter(),
  })  : _pdf = pdf,
        _docx = docx;

  @override
  String get formatId => 'md';

  @override
  Set<ExportTarget> get supportedTargets => const {
        ExportTarget.html,
        ExportTarget.pdf,
        ExportTarget.docx,
        ExportTarget.markdown,
        ExportTarget.plainText,
      };

  @override
  Future<ExportResult> export(ExportTarget target, TextContent content) async {
    final Uint8List bytes;
    switch (target) {
      case ExportTarget.html:
        bytes = Uint8List.fromList(
          utf8.encode(_htmlDocument(content.text, content.baseName)),
        );
        break;
      case ExportTarget.pdf:
        bytes = await _pdf.fromText(content.text, title: content.baseName);
        break;
      case ExportTarget.docx:
        bytes = _docx.fromText(content.text);
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
            'Markdown cannot export to ${target.label}.');
    }
    return ExportResult(
      bytes: bytes,
      suggestedName: '${content.baseName}.${target.extension}',
      mimeType: target.mimeType,
      target: target,
    );
  }

  /// Wraps the rendered Markdown body in a minimal, self-contained HTML page.
  String _htmlDocument(String markdown, String title) {
    final body = md.markdownToHtml(
      markdown,
      extensionSet: md.ExtensionSet.gitHubWeb,
    );
    final safeTitle = _escape(title);
    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeTitle</title>
<style>
  body { margin: 1.5rem auto; max-width: 46rem; padding: 0 1rem;
         font-family: system-ui, -apple-system, sans-serif; line-height: 1.6; }
  pre { background: #f4f4f4; padding: 0.75rem; overflow-x: auto; border-radius: 6px; }
  code { font-family: ui-monospace, monospace; }
  table { border-collapse: collapse; }
  th, td { border: 1px solid #ccc; padding: 4px 8px; }
  blockquote { border-left: 4px solid #ccc; margin: 0; padding-left: 1rem; color: #555; }
  img { max-width: 100%; }
</style>
</head>
<body>
$body
</body>
</html>
''';
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
