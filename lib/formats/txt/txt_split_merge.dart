import '../../core/editor/encoding.dart';

/// Splits and merges plain-text content (task 4.5).
///
/// Both split functions partition the document on **line boundaries** and never
/// break a line in the middle. Because every split keeps the line segments in
/// order and [merge] rejoins them with a single `\n`, `merge(split(text))`
/// reproduces the original exactly — the round-trip the tests guard.
///
/// Pure Dart; the byte-size split uses the shared [TextCodecService] only to
/// measure how large a part would be in a given encoding.
class TxtSplitMerge {
  final TextCodecService _codec;

  const TxtSplitMerge([this._codec = const TextCodecService()]);

  /// Splits [text] into parts of at most [linesPerPart] lines each, keeping line
  /// order. Throws [ArgumentError] if [linesPerPart] is below 1.
  ///
  /// A single trailing empty line (from a trailing newline) is preserved as its
  /// own segment, so the round-trip with [merge] is exact.
  List<String> splitByLines(String text, int linesPerPart) {
    if (linesPerPart < 1) {
      throw ArgumentError.value(
          linesPerPart, 'linesPerPart', 'must be at least 1');
    }
    if (text.isEmpty) return const [''];

    final segments = text.split('\n');
    final parts = <String>[];
    for (var i = 0; i < segments.length; i += linesPerPart) {
      final end =
          (i + linesPerPart) < segments.length ? i + linesPerPart : segments.length;
      parts.add(segments.sublist(i, end).join('\n'));
    }
    return parts;
  }

  /// Splits [text] into parts whose encoded size stays at or under [maxBytes],
  /// breaking only on line boundaries in [encoding]. Throws [ArgumentError] if
  /// [maxBytes] is below 1.
  ///
  /// A single line larger than [maxBytes] cannot be split without breaking the
  /// round-trip, so it becomes its own oversized part (documented behavior).
  List<String> splitBySize(
    String text,
    int maxBytes, {
    TextEncodingType encoding = TextEncodingType.utf8,
  }) {
    if (maxBytes < 1) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'must be at least 1');
    }
    if (text.isEmpty) return const [''];

    final segments = text.split('\n');
    final parts = <String>[];
    final current = <String>[];

    for (final segment in segments) {
      if (current.isEmpty) {
        current.add(segment);
        continue;
      }
      final candidate = [...current, segment].join('\n');
      if (_byteLength(candidate, encoding) <= maxBytes) {
        current.add(segment);
      } else {
        parts.add(current.join('\n'));
        current
          ..clear()
          ..add(segment);
      }
    }
    parts.add(current.join('\n'));
    return parts;
  }

  /// Concatenates [parts] in the given order, separated by a single `\n`. This is
  /// the inverse of both split functions and the way several TXT files are merged
  /// into one.
  String merge(List<String> parts) => parts.join('\n');

  int _byteLength(String text, TextEncodingType encoding) {
    // Line endings are `\n` in memory; measuring with LF is what the split cares
    // about (the caller re-applies the real ending on save).
    return _codec.encode(text, encoding, LineEndingStyle.lf).length;
  }
}
