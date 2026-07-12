import 'dart:convert';
import 'dart:typed_data';

import '../../core/export/export_target.dart';
import '../../core/export/format_exporter.dart';
import '../../core/export/html_writer.dart';
import '../../core/export/pdf_writer.dart';
import 'json_node.dart';
import 'json_parser.dart';
import 'json_yaml.dart';

/// Export capability for JSON documents (task 8.6).
///
/// Implements the shared [FormatExporter] interface (defined in `core/export`)
/// but lives in the JSON module because it needs the JSON parser. Targets:
/// CSV (flattening a top-level array of objects), YAML, PDF, HTML, and plain
/// text. PDF/HTML use the pretty-printed JSON; an invalid document falls back to
/// the raw text so export never crashes (CLAUDE.md §3.4).
class JsonExporter implements FormatExporter {
  final PdfWriter _pdf;
  final HtmlWriter _html;
  final JsonParser _parser;

  const JsonExporter({
    PdfWriter pdf = const PdfWriter(),
    HtmlWriter html = const HtmlWriter(),
    JsonParser parser = const JsonParser(),
  })  : _pdf = pdf,
        _html = html,
        _parser = parser;

  @override
  String get formatId => 'json';

  @override
  Set<ExportTarget> get supportedTargets => const {
        ExportTarget.json,
        ExportTarget.csv,
        ExportTarget.yaml,
        ExportTarget.pdf,
        ExportTarget.html,
        ExportTarget.plainText,
      };

  @override
  Future<ExportResult> export(ExportTarget target, TextContent content) async {
    final parsed = _parser.parse(content.text, lenient: true);
    final root = parsed.root;
    final pretty = root != null ? prettyPrintJson(root) : content.text;

    final Uint8List bytes;
    switch (target) {
      case ExportTarget.json:
        // Self-export: strict, re-formatted JSON (falls back to raw on error).
        bytes = Uint8List.fromList(utf8.encode(pretty));
        break;
      case ExportTarget.csv:
        _requireParsed(root, 'CSV');
        bytes = Uint8List.fromList(utf8.encode(jsonToCsv(root!)));
        break;
      case ExportTarget.yaml:
        _requireParsed(root, 'YAML');
        bytes = Uint8List.fromList(utf8.encode(jsonToYaml(root!)));
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
      case ExportTarget.xlsx:
        throw UnsupportedExportException(
            'JSON cannot export to ${target.label}.');
    }
    return ExportResult(
      bytes: bytes,
      suggestedName: '${content.baseName}.${target.extension}',
      mimeType: target.mimeType,
      target: target,
    );
  }

  void _requireParsed(JsonNode? root, String targetName) {
    if (root == null) {
      throw UnsupportedExportException(
          'Fix the JSON errors before exporting to $targetName.');
    }
  }
}

/// Flattens a top-level JSON array of objects into CSV text (task 8.6).
///
/// The header is the union of the objects' keys in first-seen order. A scalar
/// cell is its value; a nested object/array cell is its minified JSON. A
/// document that is not an array of objects becomes a single-column CSV of its
/// minified value(s), so the export still produces something usable.
String jsonToCsv(JsonNode root) {
  if (root.kind == JsonKind.array &&
      root.children.every((c) => c.kind == JsonKind.object)) {
    final headers = <String>[];
    for (final row in root.children) {
      for (final member in row.children) {
        final key = member.key ?? '';
        if (!headers.contains(key)) headers.add(key);
      }
    }
    final buffer = StringBuffer();
    buffer.writeln(headers.map(_csvField).join(','));
    for (final row in root.children) {
      final byKey = {for (final m in row.children) (m.key ?? ''): m};
      final cells = headers.map((h) {
        final node = byKey[h];
        return node == null ? '' : _csvCell(node);
      });
      buffer.writeln(cells.map(_csvField).join(','));
    }
    return buffer.toString();
  }

  // Fallback: one value per row.
  final buffer = StringBuffer();
  buffer.writeln('value');
  if (root.kind == JsonKind.array) {
    for (final child in root.children) {
      buffer.writeln(_csvField(_csvCell(child)));
    }
  } else {
    buffer.writeln(_csvField(_csvCell(root)));
  }
  return buffer.toString();
}

String _csvCell(JsonNode node) {
  switch (node.kind) {
    case JsonKind.string:
      return node.stringValue ?? '';
    case JsonKind.number:
    case JsonKind.boolean:
    case JsonKind.nullValue:
      return node.rawText;
    case JsonKind.object:
    case JsonKind.array:
      return minifyJson(node);
  }
}

String _csvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
