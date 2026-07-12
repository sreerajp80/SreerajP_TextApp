/// Splits and merges Markdown content by top-level heading (task 6.5).
///
/// [splitByTopHeading] starts a new part at every top-level `#` heading; any
/// content before the first heading becomes its own leading part. [merge]
/// concatenates parts with a blank line between them. Pure Dart, so the
/// split/merge round-trip is unit-tested without a device.
///
/// A `#` inside a fenced code block (```` ``` ````) is **not** treated as a
/// heading, so code that contains comments does not accidentally split a file.
class MdSplitMerge {
  const MdSplitMerge();

  /// Splits [source] into parts, each beginning at a top-level (`# `) heading.
  ///
  /// Content before the first top-level heading is returned as the first part.
  /// A document with no top-level heading returns a single part (the whole
  /// text). Empty input returns a single empty part.
  List<String> splitByTopHeading(String source) {
    if (source.isEmpty) return const [''];

    final lines = source.split('\n');
    final parts = <String>[];
    final current = <String>[];
    var inFence = false;

    void flush() {
      // Drop a single trailing empty line so parts join cleanly.
      while (current.isNotEmpty && current.last.isEmpty) {
        current.removeLast();
      }
      if (current.isNotEmpty) {
        parts.add(current.join('\n'));
      }
      current.clear();
    }

    for (final line in lines) {
      if (_isFence(line)) {
        inFence = !inFence;
        current.add(line);
        continue;
      }
      if (!inFence && _isTopHeading(line) && current.isNotEmpty) {
        flush();
      }
      current.add(line);
    }
    flush();

    return parts.isEmpty ? const [''] : parts;
  }

  /// Concatenates [parts] in order, separated by a blank line.
  String merge(List<String> parts) {
    return parts.where((p) => p.isNotEmpty).join('\n\n');
  }

  static bool _isTopHeading(String line) =>
      RegExp(r'^#\s+\S').hasMatch(line);

  static bool _isFence(String line) {
    final trimmed = line.trimLeft();
    return trimmed.startsWith('```') || trimmed.startsWith('~~~');
  }
}
