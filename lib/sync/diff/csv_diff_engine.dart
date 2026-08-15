import 'package:text_data/core/editor/encoding.dart';
import 'package:text_data/formats/csv/csv_dialect.dart';
import 'package:text_data/formats/csv/csv_parse.dart';
import 'package:text_data/formats/csv/csv_table.dart';
import 'package:text_data/sync/diff/diff_models.dart';

/// Pure Dart diff engine for tabular CSV data.
class CsvDiffEngine {
  const CsvDiffEngine();

  /// Compares two CSV string contents and returns detailed row and cell diffs.
  CsvDiffResult compare(String localCsv, String remoteCsv) {
    final localDialect = CsvDialect.detect(
      localCsv,
      lineEnding: LineEndingStyle.lf,
      hasHeader: true,
    );
    final remoteDialect = CsvDialect.detect(
      remoteCsv,
      lineEnding: LineEndingStyle.lf,
      hasHeader: true,
    );

    final localTable = CsvParse.parse(localCsv, localDialect);
    final remoteTable = CsvParse.parse(remoteCsv, remoteDialect);

    return compareTables(localTable, remoteTable);
  }

  /// Compares two parsed [CsvTable] instances.
  CsvDiffResult compareTables(CsvTable local, CsvTable remote) {
    // Unify headers: local headers take precedence, then any extra remote headers
    final headers = <String>[...local.header];
    for (final h in remote.header) {
      if (!headers.contains(h)) {
        headers.add(h);
      }
    }

    final rowDiffs = <CsvRowDiff>[];
    var idCounter = 1;

    var addedRows = 0;
    var deletedRows = 0;
    var modifiedRows = 0;
    var unchangedRows = 0;

    final maxRows = local.rowCount > remote.rowCount
        ? local.rowCount
        : remote.rowCount;

    for (var r = 0; r < maxRows; r++) {
      if (r < local.rowCount && r < remote.rowCount) {
        final localRow = local.rows[r];
        final remoteRow = remote.rows[r];

        var rowChanged = false;
        final cellDiffs = <CsvCellDiff>[];

        for (var c = 0; c < headers.length; c++) {
          final headerName = headers[c];
          final localColIdx = local.header.indexOf(headerName);
          final remoteColIdx = remote.header.indexOf(headerName);

          final localVal = (localColIdx >= 0 && localColIdx < localRow.length)
              ? localRow[localColIdx]
              : '';
          final remoteVal =
              (remoteColIdx >= 0 && remoteColIdx < remoteRow.length)
              ? remoteRow[remoteColIdx]
              : '';

          final cellChanged = localVal != remoteVal;
          if (cellChanged) rowChanged = true;

          cellDiffs.add(
            CsvCellDiff(
              columnIndex: c,
              columnName: headerName,
              localValue: localVal,
              remoteValue: remoteVal,
              isChanged: cellChanged,
            ),
          );
        }

        if (rowChanged) {
          modifiedRows++;
          rowDiffs.add(
            CsvRowDiff(
              id: idCounter++,
              localRowIndex: r,
              remoteRowIndex: r,
              type: DiffType.modified,
              cells: cellDiffs,
            ),
          );
        } else {
          unchangedRows++;
          rowDiffs.add(
            CsvRowDiff(
              id: idCounter++,
              localRowIndex: r,
              remoteRowIndex: r,
              type: DiffType.unchanged,
              cells: cellDiffs,
            ),
          );
        }
      } else if (r >= local.rowCount) {
        // Row added in remote
        addedRows++;
        final remoteRow = remote.rows[r];
        final cellDiffs = <CsvCellDiff>[];

        for (var c = 0; c < headers.length; c++) {
          final headerName = headers[c];
          final remoteColIdx = remote.header.indexOf(headerName);
          final remoteVal =
              (remoteColIdx >= 0 && remoteColIdx < remoteRow.length)
              ? remoteRow[remoteColIdx]
              : '';

          cellDiffs.add(
            CsvCellDiff(
              columnIndex: c,
              columnName: headerName,
              localValue: '',
              remoteValue: remoteVal,
              isChanged: true,
            ),
          );
        }

        rowDiffs.add(
          CsvRowDiff(
            id: idCounter++,
            remoteRowIndex: r,
            type: DiffType.added,
            cells: cellDiffs,
          ),
        );
      } else {
        // Row deleted from local
        deletedRows++;
        final localRow = local.rows[r];
        final cellDiffs = <CsvCellDiff>[];

        for (var c = 0; c < headers.length; c++) {
          final headerName = headers[c];
          final localColIdx = local.header.indexOf(headerName);
          final localVal = (localColIdx >= 0 && localColIdx < localRow.length)
              ? localRow[localColIdx]
              : '';

          cellDiffs.add(
            CsvCellDiff(
              columnIndex: c,
              columnName: headerName,
              localValue: localVal,
              remoteValue: '',
              isChanged: true,
            ),
          );
        }

        rowDiffs.add(
          CsvRowDiff(
            id: idCounter++,
            localRowIndex: r,
            type: DiffType.deleted,
            cells: cellDiffs,
          ),
        );
      }
    }

    return CsvDiffResult(
      headers: headers,
      rows: rowDiffs,
      addedRowCount: addedRows,
      deletedRowCount: deletedRows,
      modifiedRowCount: modifiedRows,
      unchangedRowCount: unchangedRows,
    );
  }
}
