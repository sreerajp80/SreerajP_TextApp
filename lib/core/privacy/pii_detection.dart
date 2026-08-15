import 'package:text_data/core/privacy/pii_type.dart';

/// A single detected sensitive entity within a document.
class PiiMatch {
  final String id;
  final PiiType type;
  final String rawValue;
  final int start;
  final int end;
  final int line;
  final int column;
  final bool isSelected;

  const PiiMatch({
    required this.id,
    required this.type,
    required this.rawValue,
    required this.start,
    required this.end,
    required this.line,
    required this.column,
    this.isSelected = true,
  });

  PiiMatch copyWith({
    String? id,
    PiiType? type,
    String? rawValue,
    int? start,
    int? end,
    int? line,
    int? column,
    bool? isSelected,
  }) {
    return PiiMatch(
      id: id ?? this.id,
      type: type ?? this.type,
      rawValue: rawValue ?? this.rawValue,
      start: start ?? this.start,
      end: end ?? this.end,
      line: line ?? this.line,
      column: column ?? this.column,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PiiMatch &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          rawValue == other.rawValue &&
          start == other.start &&
          end == other.end &&
          line == other.line &&
          column == other.column &&
          isSelected == other.isSelected;

  @override
  int get hashCode =>
      Object.hash(id, type, rawValue, start, end, line, column, isSelected);
}

/// The result of an offline PII scan on document text.
class PiiScanResult {
  final List<PiiMatch> matches;
  final Duration scanDuration;

  const PiiScanResult({
    required this.matches,
    this.scanDuration = Duration.zero,
  });

  int get totalCount => matches.length;

  int get selectedCount => matches.where((m) => m.isSelected).length;

  bool get isEmpty => matches.isEmpty;

  bool get isNotEmpty => matches.isNotEmpty;

  Map<PiiType, int> get countsByType {
    final counts = <PiiType, int>{};
    for (final match in matches) {
      counts[match.type] = (counts[match.type] ?? 0) + 1;
    }
    return counts;
  }

  Map<PiiType, int> get selectedCountsByType {
    final counts = <PiiType, int>{};
    for (final match in matches) {
      if (match.isSelected) {
        counts[match.type] = (counts[match.type] ?? 0) + 1;
      }
    }
    return counts;
  }

  PiiScanResult copyWith({List<PiiMatch>? matches, Duration? scanDuration}) {
    return PiiScanResult(
      matches: matches ?? this.matches,
      scanDuration: scanDuration ?? this.scanDuration,
    );
  }
}
