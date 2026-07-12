import 'dart:convert';
import 'dart:typed_data';

import '../../formats/csv/csv_dialect.dart';
import '../../formats/csv/csv_parse.dart';
import '../../formats/csv/csv_table.dart';
import 'export_target.dart';
import 'format_exporter.dart';
import 'pdf_writer.dart';
import 'xlsx_writer.dart';

/// Export capability for CSV documents (task 7.6).
///
/// Lives in `core/export` alongside the other exporters. It is handed the
/// document's current CSV text (already limited to the selected/filtered rows by
/// the session when the user asks for "selected rows only"), re-parses it into a
/// [CsvTable], and produces the requested target:
///
/// - **PDF** — a bordered table via the shared [PdfWriter].
/// - **JSON** — an array of objects keyed by the header row.
/// - **HTML** — a self-contained `<table>` page (offline, CLAUDE.md §3.2).
/// - **XLSX** — a hand-built OOXML spreadsheet via [XlsxWriter] (no Syncfusion).
///
/// The first row is treated as the header for JSON keys and the HTML/PDF header;
/// files without a header still export, using that first row as the labels.
class CsvExporter implements FormatExporter {
  final PdfWriter _pdf;
  final XlsxWriter _xlsx;

  const CsvExporter({
    PdfWriter pdf = const PdfWriter(),
    XlsxWriter xlsx = const XlsxWriter(),
  })  : _pdf = pdf,
        _xlsx = xlsx;

  @override
  String get formatId => 'csv';

  @override
  Set<ExportTarget> get supportedTargets => const {
        ExportTarget.pdf,
        ExportTarget.json,
        ExportTarget.html,
        ExportTarget.xlsx,
      };

  @override
  Future<ExportResult> export(ExportTarget target, TextContent content) async {
    final dialect = CsvDialect.detect(
      content.text,
      lineEnding: const CsvDialect().lineEnding,
      hasHeader: true,
    );
    final table = CsvParse.parse(content.text, dialect);

    final Uint8List bytes;
    switch (target) {
      case ExportTarget.pdf:
        bytes = await _pdf.fromTable(
          table.header,
          table.rows,
          title: content.baseName,
        );
        break;
      case ExportTarget.json:
        bytes = Uint8List.fromList(utf8.encode(_toJson(table)));
        break;
      case ExportTarget.html:
        bytes = Uint8List.fromList(
          utf8.encode(_toHtml(table, content.baseName)),
        );
        break;
      case ExportTarget.xlsx:
        bytes = _xlsx.fromRows([table.header, ...table.rows]);
        break;
      case ExportTarget.docx:
      case ExportTarget.markdown:
      case ExportTarget.plainText:
      case ExportTarget.csv:
      case ExportTarget.yaml:
        throw UnsupportedExportException(
            'CSV cannot export to ${target.label}.');
    }

    return ExportResult(
      bytes: bytes,
      suggestedName: '${content.baseName}.${target.extension}',
      mimeType: target.mimeType,
      target: target,
    );
  }

  String _toJson(CsvTable table) {
    final keys = _uniqueKeys(table.header);
    final records = [
      for (final row in table.rows)
        {
          for (var i = 0; i < keys.length; i++)
            keys[i]: i < row.length ? row[i] : '',
        },
    ];
    return const JsonEncoder.withIndent('  ').convert(records);
  }

  /// Makes the header names safe, non-empty, and unique for JSON keys.
  List<String> _uniqueKeys(List<String> header) {
    final used = <String>{};
    final keys = <String>[];
    for (var i = 0; i < header.length; i++) {
      var key = header[i].trim();
      if (key.isEmpty) key = 'column_${i + 1}';
      var candidate = key;
      var n = 2;
      while (!used.add(candidate)) {
        candidate = '${key}_$n';
        n++;
      }
      keys.add(candidate);
    }
    return keys;
  }

  String _toHtml(CsvTable table, String title) {
    final safeTitle = _escape(title);
    final headCells =
        table.header.map((h) => '<th>${_escape(h)}</th>').join();
    final bodyRows = table.rows
        .map((r) =>
            '<tr>${r.map((c) => '<td>${_escape(c)}</td>').join()}</tr>')
        .join('\n');
    return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$safeTitle</title>
<style>
  body { margin: 1.5rem; font-family: system-ui, -apple-system, sans-serif; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border: 1px solid #ccc; padding: 4px 8px; text-align: left; }
  thead th { background: #f0f0f0; }
  tbody tr:nth-child(even) { background: #fafafa; }
</style>
</head>
<body>
<table>
<thead><tr>$headCells</tr></thead>
<tbody>
$bodyRows
</tbody>
</table>
</body>
</html>
''';
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}
