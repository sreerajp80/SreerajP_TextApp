/// Parses the optional YAML front matter at the top of a Markdown file
/// (task 6.3).
///
/// Front matter is a block fenced by `---` lines at the very start of the file:
///
/// ```
/// ---
/// title: My Notes
/// author: Jane Doe
/// tags: [draft, ideas]
/// ---
/// # Heading …
/// ```
///
/// This is a **small, tolerant** reader — it understands `key: value`, inline
/// `[a, b]` lists, and block `- item` lists, which is all the app shows (title /
/// author / tags). Anything it does not understand is ignored rather than
/// treated as an error, so a malformed block never crashes the viewer
/// (CLAUDE.md §3.4). Full YAML (anchors, nested maps) is out of scope (see the
/// plan's §8).
class MdFrontMatter {
  /// True when a well-formed `---` … `---` block was found at the top.
  final bool present;

  /// The `title` field, if any.
  final String? title;

  /// The `author` field, if any.
  final String? author;

  /// The `tags` field as a list (empty when absent).
  final List<String> tags;

  /// Every parsed key mapped to its raw string value (lists are joined by
  /// `, `), so the info sheet can show extra fields.
  final Map<String, String> fields;

  /// The document body with the front-matter block removed. This is what the
  /// renderer, TOC, and stats work on; the raw editor still shows the whole file.
  final String body;

  const MdFrontMatter({
    required this.present,
    required this.title,
    required this.author,
    required this.tags,
    required this.fields,
    required this.body,
  });

  /// Empty front matter whose body is the whole [source].
  factory MdFrontMatter.none(String source) => MdFrontMatter(
        present: false,
        title: null,
        author: null,
        tags: const [],
        fields: const {},
        body: source,
      );

  /// Splits [source] into its front matter (if any) and body.
  factory MdFrontMatter.parse(String source) {
    final lines = source.split('\n');
    // Must open with a `---` line on the very first line.
    if (lines.isEmpty || lines.first.trimRight() != '---') {
      return MdFrontMatter.none(source);
    }

    // Find the closing `---`.
    var close = -1;
    for (var i = 1; i < lines.length; i++) {
      final trimmed = lines[i].trimRight();
      if (trimmed == '---' || trimmed == '...') {
        close = i;
        break;
      }
    }
    if (close == -1) {
      // No closing fence — treat the whole file as body (tolerant).
      return MdFrontMatter.none(source);
    }

    final block = lines.sublist(1, close);
    final body = lines.sublist(close + 1).join('\n');
    final fields = _parseBlock(block);

    return MdFrontMatter(
      present: true,
      title: fields['title'],
      author: fields['author'],
      tags: _splitList(fields['tags']),
      fields: fields,
      body: body,
    );
  }

  /// Reads `key: value` pairs, honoring inline `[a, b]` and block `- item` lists.
  static Map<String, String> _parseBlock(List<String> block) {
    final fields = <String, String>{};
    String? listKey;
    final listValues = <String>[];

    void flushList() {
      if (listKey != null) {
        fields[listKey!] = listValues.join(', ');
        listKey = null;
        listValues.clear();
      }
    }

    for (final raw in block) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) continue;

      // A block-list item under the current key: "  - value".
      final itemMatch = RegExp(r'^\s*-\s+(.*)$').firstMatch(line);
      if (itemMatch != null && listKey != null) {
        listValues.add(_unquote(itemMatch.group(1)!.trim()));
        continue;
      }

      final colon = line.indexOf(':');
      if (colon <= 0) continue; // not a key line; ignore
      flushList();

      final key = line.substring(0, colon).trim().toLowerCase();
      final value = line.substring(colon + 1).trim();
      if (key.isEmpty) continue;

      if (value.isEmpty) {
        // Value may follow as a block list on the next lines.
        listKey = key;
      } else {
        fields[key] = _joinInline(value);
      }
    }
    flushList();
    return fields;
  }

  /// Turns an inline value into its stored form: `[a, b]` → `a, b`, quotes
  /// stripped.
  static String _joinInline(String value) {
    if (value.startsWith('[') && value.endsWith(']')) {
      return _splitInlineList(value).join(', ');
    }
    return _unquote(value);
  }

  /// Splits a stored value (already `a, b, c`) into a list.
  static List<String> _splitList(String? value) {
    if (value == null || value.trim().isEmpty) return const [];
    return value
        .split(',')
        .map((s) => _unquote(s.trim()))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<String> _splitInlineList(String value) {
    final inner = value.substring(1, value.length - 1);
    return inner
        .split(',')
        .map((s) => _unquote(s.trim()))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _unquote(String s) {
    if (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }
}
