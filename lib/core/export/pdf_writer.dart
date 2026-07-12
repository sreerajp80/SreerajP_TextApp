import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a simple, paged PDF from plain text (task 5.4).
///
/// Uses the `pdf` package's built-in Courier (monospace) font so text lines
/// keep their layout. Long lines soft-wrap; the document flows across pages
/// automatically via [pw.MultiPage]. Kept small and format-agnostic so any
/// format's exporter can reuse it for its "natural" text output.
class PdfWriter {
  const PdfWriter();

  Future<Uint8List> fromText(String text, {String? title}) async {
    final doc = pw.Document(title: title);
    final style = pw.TextStyle(font: pw.Font.courier(), fontSize: 10);

    // Split into lines so blank lines are preserved; MultiPage paginates the
    // list. A single Text with the whole body would not page-break well.
    final lines = text.isEmpty ? const [''] : text.split('\n');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          for (final line in lines)
            pw.Text(
              line.isEmpty ? ' ' : line,
              style: style,
              softWrap: true,
            ),
        ],
      ),
    );

    return doc.save();
  }

  /// Builds a paged PDF that lays [rows] out as a table with an optional bold
  /// [header] row (task 7.6, CSV export). Reused by any format with tabular
  /// output. Cells use the built-in Helvetica font; the table paginates via
  /// [pw.MultiPage].
  Future<Uint8List> fromTable(
    List<String> header,
    List<List<String>> rows, {
    String? title,
  }) async {
    final doc = pw.Document(title: title);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: header.isEmpty ? null : header,
            data: rows,
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle:
                pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
          ),
        ],
      ),
    );
    return doc.save();
  }
}
