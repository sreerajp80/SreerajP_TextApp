/// Splits a block of already-decoded text into fixed-size pages of lines, so the
/// degraded large-file viewer (Phase 10, task 10.2) can show one page at a time
/// and keep the on-screen widget tree small.
///
/// This is pure and holds only the original text plus a list of line start
/// offsets — it does **not** copy the text per page. A page's text is sliced on
/// demand. Fully testable without widgets.
class PagedText {
  /// The full decoded text.
  final String text;

  /// How many lines make up one page.
  final int linesPerPage;

  /// Character offset at which each line starts (plus a final sentinel equal to
  /// `text.length`), so any line range can be sliced without re-scanning.
  final List<int> _lineStarts;

  PagedText._(this.text, this.linesPerPage, this._lineStarts);

  /// Builds a paginator over [text].
  ///
  /// [linesPerPage] must be at least 1; smaller values are clamped up.
  factory PagedText(String text, {int linesPerPage = 500}) {
    final perPage = linesPerPage < 1 ? 1 : linesPerPage;
    final starts = <int>[0];
    for (var i = 0; i < text.length; i++) {
      if (text.codeUnitAt(i) == 0x0A) {
        // Line feed.
        starts.add(i + 1);
      }
    }
    // Sentinel end offset, unless a trailing newline already put a start there
    // (so a trailing newline does not create a phantom empty line).
    if (starts.last != text.length) starts.add(text.length);
    return PagedText._(text, perPage, starts);
  }

  /// The number of text lines (a trailing newline does not add an empty line).
  int get lineCount => _lineStarts.length - 1;

  /// The number of pages. An empty text still has one (empty) page.
  int get pageCount {
    if (lineCount == 0) return 1;
    return ((lineCount - 1) ~/ linesPerPage) + 1;
  }

  /// Returns the text of page [pageIndex] (0-based, clamped into range).
  ///
  /// The single newline that separates this page from the next is not included,
  /// so joining every page back with `'\n'` reproduces the original text and a
  /// page's line count is exact.
  String page(int pageIndex) {
    if (lineCount == 0) return '';
    final clamped = pageIndex.clamp(0, pageCount - 1);
    final firstLine = clamped * linesPerPage;
    final lastLineExclusive = (firstLine + linesPerPage).clamp(0, lineCount);
    final start = _lineStarts[firstLine];
    // The end offset is the start of the line after the last one on this page,
    // which the sentinel guarantees exists.
    var end = _lineStarts[lastLineExclusive];
    // Drop the trailing line-feed that separates this page from the next.
    if (end > start && text.codeUnitAt(end - 1) == 0x0A) end -= 1;
    return text.substring(start, end);
  }

  /// The 1-based line number of the first line on page [pageIndex] (for a
  /// "lines X–Y" style label). Returns 1 for an empty text.
  int firstLineNumber(int pageIndex) {
    if (lineCount == 0) return 1;
    final clamped = pageIndex.clamp(0, pageCount - 1);
    return clamped * linesPerPage + 1;
  }
}
