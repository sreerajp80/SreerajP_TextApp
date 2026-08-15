import 'package:flutter/foundation.dart';

/// The kind of change for a diff item.
enum DiffType { unchanged, added, deleted, modified }

/// A slice of text within a modified line for highlighting word/char-level differences.
@immutable
class InlineSegment {
  final String text;
  final bool isChanged;

  const InlineSegment(this.text, {this.isChanged = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InlineSegment &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          isChanged == other.isChanged;

  @override
  int get hashCode => Object.hash(text, isChanged);
}

/// A line in a text diff comparison.
@immutable
class DiffLine {
  final int? localLineNumber;
  final int? remoteLineNumber;
  final String localText;
  final String remoteText;
  final DiffType type;
  final List<InlineSegment> localSegments;
  final List<InlineSegment> remoteSegments;

  const DiffLine({
    this.localLineNumber,
    this.remoteLineNumber,
    this.localText = '',
    this.remoteText = '',
    required this.type,
    this.localSegments = const [],
    this.remoteSegments = const [],
  });

  bool get isConflict => type == DiffType.modified;
}

/// User's resolution choice for a diff hunk or cell.
enum HunkResolution {
  unresolved,
  acceptLocal,
  acceptRemote,
  acceptBoth,
  customText,
}

/// A grouped chunk of changed/context lines for selective merging.
class DiffHunk {
  final String id;
  final int startLocalLine;
  final int startRemoteLine;
  final List<DiffLine> lines;
  final DiffType type;
  HunkResolution resolution;
  String? customText;

  DiffHunk({
    required this.id,
    required this.startLocalLine,
    required this.startRemoteLine,
    required this.lines,
    required this.type,
    this.resolution = HunkResolution.unresolved,
    this.customText,
  });

  bool get isUnresolved => resolution == HunkResolution.unresolved;
  bool get hasChanges => type != DiffType.unchanged;

  /// Returns the resolved lines of text based on current resolution choice.
  List<String> getResolvedLines() {
    switch (resolution) {
      case HunkResolution.acceptLocal:
        return lines
            .where((l) => l.type != DiffType.added)
            .map((l) => l.localText)
            .toList();
      case HunkResolution.acceptRemote:
        return lines
            .where((l) => l.type != DiffType.deleted)
            .map((l) => l.remoteText)
            .toList();
      case HunkResolution.acceptBoth:
        final result = <String>[];
        for (final l in lines) {
          if (l.localText.isNotEmpty && l.type != DiffType.added) {
            result.add(l.localText);
          }
        }
        for (final l in lines) {
          if (l.remoteText.isNotEmpty && l.type != DiffType.deleted) {
            result.add(l.remoteText);
          }
        }
        return result;
      case HunkResolution.customText:
        return (customText ?? '').split('\n');
      case HunkResolution.unresolved:
        // Default to local if unresolved
        return lines
            .where((l) => l.type != DiffType.added)
            .map((l) => l.localText)
            .toList();
    }
  }
}

/// The result of comparing two text documents.
@immutable
class TextDiffResult {
  final List<DiffHunk> hunks;
  final List<DiffLine> lines;
  final int addedCount;
  final int deletedCount;
  final int modifiedCount;
  final int unchangedCount;

  const TextDiffResult({
    required this.hunks,
    required this.lines,
    required this.addedCount,
    required this.deletedCount,
    required this.modifiedCount,
    required this.unchangedCount,
  });

  bool get isIdentical =>
      addedCount == 0 && deletedCount == 0 && modifiedCount == 0;
  int get totalDifferences => addedCount + deletedCount + modifiedCount;
}

/// A cell difference in CSV comparison.
@immutable
class CsvCellDiff {
  final int columnIndex;
  final String columnName;
  final String localValue;
  final String remoteValue;
  final bool isChanged;

  const CsvCellDiff({
    required this.columnIndex,
    required this.columnName,
    required this.localValue,
    required this.remoteValue,
    required this.isChanged,
  });
}

/// A row difference in CSV comparison.
class CsvRowDiff {
  final int id;
  final int? localRowIndex;
  final int? remoteRowIndex;
  final DiffType type;
  final List<CsvCellDiff> cells;
  HunkResolution resolution;

  CsvRowDiff({
    required this.id,
    this.localRowIndex,
    this.remoteRowIndex,
    required this.type,
    required this.cells,
    this.resolution = HunkResolution.unresolved,
  });

  bool get isChanged => type != DiffType.unchanged;
}

/// The result of comparing two CSV documents.
@immutable
class CsvDiffResult {
  final List<String> headers;
  final List<CsvRowDiff> rows;
  final int addedRowCount;
  final int deletedRowCount;
  final int modifiedRowCount;
  final int unchangedRowCount;

  const CsvDiffResult({
    required this.headers,
    required this.rows,
    required this.addedRowCount,
    required this.deletedRowCount,
    required this.modifiedRowCount,
    required this.unchangedRowCount,
  });

  bool get isIdentical =>
      addedRowCount == 0 && deletedRowCount == 0 && modifiedRowCount == 0;
  int get totalDifferences =>
      addedRowCount + deletedRowCount + modifiedRowCount;
}
