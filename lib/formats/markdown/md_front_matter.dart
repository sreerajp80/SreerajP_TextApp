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
/// One field of a front-matter block, kept with enough detail to edit it in
/// place (roadmap §4.4.3).
class MdFrontMatterField {
  /// The key exactly as it is written in the file, e.g. `Title`.
  final String key;

  /// The same key lower-cased, which is how [MdFrontMatter.fields] stores it.
  final String lowerKey;

  /// The value as the app shows it (a list is joined with `, `).
  final String value;

  /// True when the source wrote this field as a list — inline `[a, b]` or a
  /// block of `- item` lines.
  final bool isList;

  /// The line indices inside the block this field occupies. A block list spans
  /// several; a plain `key: value` spans one.
  final List<int> lineIndices;

  const MdFrontMatterField({
    required this.key,
    required this.lowerKey,
    required this.value,
    required this.isList,
    required this.lineIndices,
  });
}

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

  /// Every field with its original spelling, order and source lines, so the
  /// form editor can rewrite one field without disturbing the rest
  /// (roadmap §4.4.3).
  final List<MdFrontMatterField> parsedFields;

  /// The raw lines between the `---` fences, exactly as written.
  final List<String> blockLines;

  const MdFrontMatter({
    required this.present,
    required this.title,
    required this.author,
    required this.tags,
    required this.fields,
    required this.body,
    this.parsedFields = const [],
    this.blockLines = const [],
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
    final parsed = _parseBlock(block);
    final fields = {for (final field in parsed) field.lowerKey: field.value};

    return MdFrontMatter(
      present: true,
      title: fields['title'],
      author: fields['author'],
      tags: _splitList(fields['tags']),
      fields: fields,
      body: body,
      parsedFields: parsed,
      blockLines: block,
    );
  }

  /// Reads `key: value` pairs, honoring inline `[a, b]` and block `- item`
  /// lists, and remembering where each field sits so it can be edited in place.
  static List<MdFrontMatterField> _parseBlock(List<String> block) {
    final fields = <MdFrontMatterField>[];
    String? listKey;
    String? listKeyOriginal;
    final listValues = <String>[];
    final listLines = <int>[];

    void flushList() {
      if (listKey != null) {
        fields.add(
          MdFrontMatterField(
            key: listKeyOriginal!,
            lowerKey: listKey!,
            value: listValues.join(', '),
            isList: true,
            lineIndices: List<int>.from(listLines),
          ),
        );
        listKey = null;
        listKeyOriginal = null;
        listValues.clear();
        listLines.clear();
      }
    }

    for (var i = 0; i < block.length; i++) {
      final line = block[i].trimRight();
      if (line.trim().isEmpty) continue;

      // A block-list item under the current key: "  - value".
      final itemMatch = RegExp(r'^\s*-\s+(.*)$').firstMatch(line);
      if (itemMatch != null && listKey != null) {
        listValues.add(_unquote(itemMatch.group(1)!.trim()));
        listLines.add(i);
        continue;
      }

      final colon = line.indexOf(':');
      if (colon <= 0) continue; // not a key line; ignore
      flushList();

      final original = line.substring(0, colon).trim();
      final key = original.toLowerCase();
      final value = line.substring(colon + 1).trim();
      if (key.isEmpty) continue;

      if (value.isEmpty) {
        // Value may follow as a block list on the next lines.
        listKey = key;
        listKeyOriginal = original;
        listLines.add(i);
      } else {
        fields.add(
          MdFrontMatterField(
            key: original,
            lowerKey: key,
            value: _joinInline(value),
            isList: value.startsWith('[') && value.endsWith(']'),
            lineIndices: [i],
          ),
        );
      }
    }
    flushList();
    return fields;
  }

  // --- editing (roadmap 4.4.3) ---------------------------------------------

  /// Rewrites the front matter of [source] with [values], keyed by lower-cased
  /// field name.
  ///
  /// **Only the lines of the fields in [values] are touched.** Every other line
  /// of the block keeps its exact original text, so a YAML feature this small
  /// parser does not understand — a nested map, an anchor, a comment — survives
  /// an edit untouched. That is the whole point: the form must never quietly
  /// throw away part of the file.
  ///
  /// A key that is not in the block yet is appended. A key whose value is set to
  /// an empty string is removed. Keys listed in [listKeys] are written as an
  /// inline `[a, b]` list.
  ///
  /// When [source] has no front matter, a new block is created at the top.
  static String applyEdits(
    String source,
    Map<String, String> values, {
    Set<String> listKeys = const {'tags'},
  }) {
    final current = MdFrontMatter.parse(source);
    if (!current.present) return _createBlock(source, values, listKeys);

    final lines = source.split('\n');
    // The block sits between line 0 (`---`) and the closing fence.
    var close = -1;
    for (var i = 1; i < lines.length; i++) {
      final trimmed = lines[i].trimRight();
      if (trimmed == '---' || trimmed == '...') {
        close = i;
        break;
      }
    }
    if (close == -1) return source;

    final block = List<String>.from(lines.sublist(1, close));
    // Line indices to drop, and the replacement text keyed by first index.
    final drop = <int>{};
    final replace = <int, String>{};
    final handled = <String>{};

    for (final field in current.parsedFields) {
      if (!values.containsKey(field.lowerKey)) continue;
      handled.add(field.lowerKey);
      final newValue = values[field.lowerKey]!;
      // Unchanged fields keep their exact original lines — indentation, quoting
      // and all. Only what the user actually edited gets rewritten.
      if (newValue == field.value) continue;
      final first = field.lineIndices.first;
      // Every line this field owned goes; the first is rewritten in its place,
      // which keeps the field's position in the block.
      drop.addAll(field.lineIndices);
      if (newValue.trim().isEmpty) continue; // removed
      replace[first] = _renderField(field.key, newValue, listKeys);
    }

    final rebuilt = <String>[];
    for (var i = 0; i < block.length; i++) {
      if (replace.containsKey(i)) {
        rebuilt.add(replace[i]!);
        continue;
      }
      if (drop.contains(i)) continue;
      rebuilt.add(block[i]);
    }

    // Fields the block did not have yet.
    for (final entry in values.entries) {
      if (handled.contains(entry.key)) continue;
      if (entry.value.trim().isEmpty) continue;
      rebuilt.add(_renderField(entry.key, entry.value, listKeys));
    }

    return [lines[0], ...rebuilt, ...lines.sublist(close)].join('\n');
  }

  /// The `---` block text alone, used to preview an edit.
  static String renderBlock(
    Map<String, String> values, {
    Set<String> listKeys = const {'tags'},
  }) {
    final lines = <String>['---'];
    for (final entry in values.entries) {
      if (entry.value.trim().isEmpty) continue;
      lines.add(_renderField(entry.key, entry.value, listKeys));
    }
    lines.add('---');
    return lines.join('\n');
  }

  static String _createBlock(
    String source,
    Map<String, String> values,
    Set<String> listKeys,
  ) {
    final block = renderBlock(values, listKeys: listKeys);
    if (block == '---\n---') return source; // nothing worth writing
    return '$block\n$source';
  }

  static String _renderField(String key, String value, Set<String> listKeys) {
    if (listKeys.contains(key.toLowerCase())) {
      final items = _splitList(value);
      return '$key: [${items.join(', ')}]';
    }
    // A value with a `:` or a leading special character needs quoting to stay
    // readable as YAML.
    final needsQuotes =
        value.contains(': ') ||
        value.trimLeft().startsWith('#') ||
        value.trimLeft().startsWith('[') ||
        value.trimLeft().startsWith('&') ||
        value.trimLeft().startsWith('*');
    return needsQuotes
        ? '$key: "${value.replaceAll('"', r'\"')}"'
        : '$key: $value';
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
