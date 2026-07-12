import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Builds a minimal, valid `.xlsx` (Office Open XML spreadsheet) from a grid of
/// strings (task 7.6) — **no Syncfusion, no commercial SDK** (CLAUDE.md §3.1).
///
/// An `.xlsx` is a ZIP of XML parts, the same technique as [DocxWriter]. This
/// writer emits the content-types map, the package + workbook relationships, the
/// workbook, and one worksheet whose cells use inline strings (`t="inlineStr"`)
/// so no shared-strings table is needed. All text is XML-escaped so `&`, `<`,
/// `>`, and quotes never corrupt the file.
class XlsxWriter {
  const XlsxWriter();

  /// Builds the workbook from [rows] (each row a list of cell strings). Every
  /// row is written as-is; the caller decides whether the first row is a header.
  Uint8List fromRows(List<List<String>> rows) {
    final archive = Archive()
      ..addFile(_part('[Content_Types].xml', _contentTypes))
      ..addFile(_part('_rels/.rels', _packageRels))
      ..addFile(_part('xl/workbook.xml', _workbook))
      ..addFile(_part('xl/_rels/workbook.xml.rels', _workbookRels))
      ..addFile(_part('xl/worksheets/sheet1.xml', _sheet(rows)));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  ArchiveFile _part(String name, String xml) {
    final bytes = utf8.encode(xml);
    return ArchiveFile(name, bytes.length, bytes);
  }

  String _sheet(List<List<String>> rows) {
    final buffer = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
      ..write('<worksheet xmlns="http://schemas.openxmlformats.org/'
          'spreadsheetml/2006/main"><sheetData>');
    for (var r = 0; r < rows.length; r++) {
      final rowNum = r + 1;
      buffer.write('<row r="$rowNum">');
      final cells = rows[r];
      for (var c = 0; c < cells.length; c++) {
        final ref = '${_columnLetters(c)}$rowNum';
        buffer.write('<c r="$ref" t="inlineStr"><is><t xml:space="preserve">'
            '${_escape(cells[c])}</t></is></c>');
      }
      buffer.write('</row>');
    }
    buffer.write('</sheetData></worksheet>');
    return buffer.toString();
  }

  /// 0 → A, 25 → Z, 26 → AA, … for the cell reference.
  static String _columnLetters(int index) {
    var n = index;
    final letters = StringBuffer();
    do {
      final rem = n % 26;
      letters.write(String.fromCharCode(65 + rem));
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return String.fromCharCodes(letters.toString().codeUnits.reversed);
  }

  String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static const _contentTypes =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''';

  static const _packageRels =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

  static const _workbook =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/></sheets>
</workbook>''';

  static const _workbookRels =
      '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''';
}
