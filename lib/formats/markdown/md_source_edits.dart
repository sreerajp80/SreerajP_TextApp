/// The result of a formatting-toolbar action: the new full source plus where the
/// selection should sit afterwards.
class MdEdit {
  final String text;
  final int selectionStart;
  final int selectionEnd;

  const MdEdit(this.text, this.selectionStart, this.selectionEnd);
}

/// Pure text transforms behind the Markdown formatting toolbar (task 6.4).
///
/// Every action takes the current `source` and a selection range
/// `[start, end)` and returns an [MdEdit] with the new source and selection. No
/// Flutter dependency, so each action is unit-tested directly ("each toolbar
/// action produces the expected Markdown around a selection"). The UI layer
/// (`md_format_toolbar.dart`) just applies the result to the editor controller.
class MdSourceEdits {
  const MdSourceEdits._();

  // --- inline wraps --------------------------------------------------------

  /// `**bold**`
  static MdEdit bold(String text, int start, int end) =>
      _wrapInline(text, start, end, '**');

  /// `*italic*`
  static MdEdit italic(String text, int start, int end) =>
      _wrapInline(text, start, end, '*');

  /// `~~strikethrough~~`
  static MdEdit strikethrough(String text, int start, int end) =>
      _wrapInline(text, start, end, '~~');

  /// `` `code` ``
  static MdEdit inlineCode(String text, int start, int end) =>
      _wrapInline(text, start, end, '`');

  // --- line prefixes -------------------------------------------------------

  /// Prefixes each selected line with `#`×[level] (replacing any existing
  /// heading marker). [level] is clamped to 1–6.
  static MdEdit heading(String text, int start, int end, int level) {
    final hashes = '#' * level.clamp(1, 6);
    return _prefixLines(
      text,
      start,
      end,
      (line, i) => '$hashes ',
      stripHeading: true,
    );
  }

  /// Prefixes each selected line with `- ` (bullet list).
  static MdEdit bulletList(String text, int start, int end) =>
      _prefixLines(text, start, end, (line, i) => '- ');

  /// Prefixes each selected line with an incrementing `1. `, `2. `, … (numbered
  /// list).
  static MdEdit numberedList(String text, int start, int end) =>
      _prefixLines(text, start, end, (line, i) => '${i + 1}. ');

  /// Prefixes each selected line with `- [ ] ` (task list).
  static MdEdit taskList(String text, int start, int end) =>
      _prefixLines(text, start, end, (line, i) => '- [ ] ');

  /// Prefixes each selected line with `> ` (blockquote).
  static MdEdit blockquote(String text, int start, int end) =>
      _prefixLines(text, start, end, (line, i) => '> ');

  // --- block / inline inserts ---------------------------------------------

  /// Wraps the selection (or an empty line) in a fenced code block.
  static MdEdit codeBlock(String text, int start, int end) {
    final (s, e) = _clamp(text, start, end);
    final sel = text.substring(s, e);
    final block = '```\n$sel\n```';
    const inner = 4; // just after "```\n"
    return _insertBlock(
      text,
      s,
      e,
      block,
      selStart: inner,
      selEnd: inner + sel.length,
    );
  }

  /// Inserts a starter GFM table at the cursor, selecting the first header cell.
  static MdEdit table(String text, int start, int end) {
    const block =
        '| Column 1 | Column 2 |\n| --- | --- |\n| Cell | Cell |';
    // "| " is 2 chars, then "Column 1" (8 chars).
    return _insertBlock(text, start, end, block, selStart: 2, selEnd: 10);
  }

  /// Inserts a link. With a selection, the selected text becomes the link text
  /// and `url` is selected for typing; with no selection, `[link](url)` is
  /// inserted with `link` selected.
  static MdEdit link(String text, int start, int end) {
    final (s, e) = _clamp(text, start, end);
    final before = text.substring(0, s);
    final sel = text.substring(s, e);
    final after = text.substring(e);
    if (sel.isEmpty) {
      final newText = '$before[link](url)$after';
      return MdEdit(newText, s + 1, s + 5); // select "link"
    }
    final newText = '$before[$sel](url)$after';
    final urlStart = s + 1 + sel.length + 2; // '[' + sel + ']('
    return MdEdit(newText, urlStart, urlStart + 3); // select "url"
  }

  // --- helpers -------------------------------------------------------------

  static MdEdit _wrapInline(String text, int start, int end, String marker) {
    final (s, e) = _clamp(text, start, end);
    final before = text.substring(0, s);
    final sel = text.substring(s, e);
    final after = text.substring(e);
    final newText = '$before$marker$sel$marker$after';
    final ns = s + marker.length;
    return MdEdit(newText, ns, ns + sel.length);
  }

  static MdEdit _prefixLines(
    String text,
    int start,
    int end,
    String Function(String line, int indexInBlock) prefix, {
    bool stripHeading = false,
  }) {
    final (s, e) = _clamp(text, start, end);
    final lineStart = _lineStart(text, s);
    final lineEnd = _lineEnd(text, e);
    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');
    final out = <String>[];
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (stripHeading) {
        line = line.replaceFirst(RegExp(r'^#{1,6}\s+'), '');
      }
      out.add('${prefix(line, i)}$line');
    }
    final newBlock = out.join('\n');
    final newText =
        text.substring(0, lineStart) + newBlock + text.substring(lineEnd);
    return MdEdit(newText, lineStart, lineStart + newBlock.length);
  }

  static MdEdit _insertBlock(
    String text,
    int start,
    int end,
    String block, {
    required int selStart,
    required int selEnd,
  }) {
    final (s, e) = _clamp(text, start, end);
    final before = text.substring(0, s);
    final after = text.substring(e);
    final lead = (before.isNotEmpty && !before.endsWith('\n')) ? '\n' : '';
    final trail = (after.isNotEmpty && !after.startsWith('\n')) ? '\n' : '';
    final newText = '$before$lead$block$trail$after';
    final base = s + lead.length;
    return MdEdit(newText, base + selStart, base + selEnd);
  }

  static (int, int) _clamp(String text, int start, int end) {
    final s = start.clamp(0, text.length);
    final e = end.clamp(s, text.length);
    return (s, e);
  }

  static int _lineStart(String text, int pos) {
    var i = pos.clamp(0, text.length);
    while (i > 0 && text[i - 1] != '\n') {
      i--;
    }
    return i;
  }

  static int _lineEnd(String text, int pos) {
    var i = pos.clamp(0, text.length);
    while (i < text.length && text[i] != '\n') {
      i++;
    }
    return i;
  }
}
