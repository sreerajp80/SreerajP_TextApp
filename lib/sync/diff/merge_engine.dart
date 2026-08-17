import 'package:sreerajp_textapp/formats/csv/csv_dialect.dart';
import 'package:sreerajp_textapp/formats/csv/csv_table.dart';
import 'package:sreerajp_textapp/sync/diff/diff_models.dart';

/// Conflict resolution and merge engine for text and CSV documents.
class MergeEngine {
  const MergeEngine();

  /// Merges a [TextDiffResult] into a single string based on hunk resolutions.
  String mergeText(TextDiffResult diffResult, {String lineEnding = '\n'}) {
    final mergedLines = <String>[];

    for (final hunk in diffResult.hunks) {
      final resolved = hunk.getResolvedLines();
      mergedLines.addAll(resolved);
    }

    return mergedLines.join(lineEnding);
  }

  /// Merges a [CsvDiffResult] into a CSV string based on row resolutions.
  String mergeCsv(
    CsvDiffResult diffResult, {
    CsvDialect dialect = const CsvDialect(),
  }) {
    final mergedRows = <List<String>>[];

    for (final rowDiff in diffResult.rows) {
      switch (rowDiff.resolution) {
        case HunkResolution.acceptLocal:
        case HunkResolution.unresolved:
          if (rowDiff.type != DiffType.added) {
            mergedRows.add(rowDiff.cells.map((c) => c.localValue).toList());
          }
          break;
        case HunkResolution.acceptRemote:
          if (rowDiff.type != DiffType.deleted) {
            mergedRows.add(rowDiff.cells.map((c) => c.remoteValue).toList());
          }
          break;
        case HunkResolution.acceptBoth:
          if (rowDiff.type != DiffType.added) {
            mergedRows.add(rowDiff.cells.map((c) => c.localValue).toList());
          }
          if (rowDiff.type != DiffType.deleted) {
            mergedRows.add(rowDiff.cells.map((c) => c.remoteValue).toList());
          }
          break;
        case HunkResolution.customText:
          mergedRows.add(rowDiff.cells.map((c) => c.localValue).toList());
          break;
      }
    }

    final table = CsvTable(
      header: diffResult.headers,
      rows: mergedRows,
      hasHeader: true,
    );

    return table.toCsv(dialect);
  }

  /// Sets all hunks to accept local version.
  void acceptAllLocal(List<DiffHunk> hunks) {
    for (final hunk in hunks) {
      if (hunk.hasChanges) {
        hunk.resolution = HunkResolution.acceptLocal;
      }
    }
  }

  /// Sets all hunks to accept remote peer's version.
  void acceptAllRemote(List<DiffHunk> hunks) {
    for (final hunk in hunks) {
      if (hunk.hasChanges) {
        hunk.resolution = HunkResolution.acceptRemote;
      }
    }
  }

  /// Automatically accepts non-conflicting additions and deletions while leaving
  /// modified conflicts for manual review.
  void acceptNonConflicting(List<DiffHunk> hunks) {
    for (final hunk in hunks) {
      if (hunk.type == DiffType.added) {
        hunk.resolution = HunkResolution.acceptRemote;
      } else if (hunk.type == DiffType.deleted) {
        hunk.resolution = HunkResolution.acceptLocal;
      }
    }
  }

  /// Sets all CSV row diffs to accept local version.
  void acceptAllLocalCsv(List<CsvRowDiff> rows) {
    for (final row in rows) {
      if (row.isChanged) {
        row.resolution = HunkResolution.acceptLocal;
      }
    }
  }

  /// Sets all CSV row diffs to accept remote version.
  void acceptAllRemoteCsv(List<CsvRowDiff> rows) {
    for (final row in rows) {
      if (row.isChanged) {
        row.resolution = HunkResolution.acceptRemote;
      }
    }
  }

  /// Auto-resolves non-conflicting CSV rows.
  void acceptNonConflictingCsv(List<CsvRowDiff> rows) {
    for (final row in rows) {
      if (row.type == DiffType.added) {
        row.resolution = HunkResolution.acceptRemote;
      } else if (row.type == DiffType.deleted) {
        row.resolution = HunkResolution.acceptLocal;
      }
    }
  }
}
