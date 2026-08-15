import 'package:text_data/formats/json/json_parser.dart';

/// One 1-tap repair the app can offer for a broken JSON file
/// (roadmap §4.3.3).
class JsonQuickFix {
  /// A stable id, so the UI can pick its own label and icon per fix.
  final String id;

  /// The repaired text this fix would produce.
  final String result;

  const JsonQuickFix({required this.id, required this.result});
}

/// Finds quick fixes for the common ways a JSON file is broken
/// (roadmap §4.3.3).
///
/// Each fix is a small, targeted rewrite that a person would recognise: quote
/// the keys, use double quotes, drop the trailing comma, strip the comments,
/// use JSON's own `true` / `false` / `null`. A fix is offered only when it
/// really changes the text, and only while the document is not already valid.
/// [fixAll] is stricter still: it is offered only when applying everything
/// actually produces valid JSON.
///
/// The scanners walk the text character by character and skip over string
/// contents, so a comma or `//` **inside** a string is left alone.
///
/// Pure Dart with no Flutter import, so every fix is host-tested.
class JsonQuickFixes {
  const JsonQuickFixes._();

  static const String quoteKeys = 'quoteKeys';
  static const String doubleQuotes = 'doubleQuotes';
  static const String trailingCommas = 'trailingCommas';
  static const String removeComments = 'removeComments';
  static const String pythonLiterals = 'pythonLiterals';

  static const JsonParser _parser = JsonParser();

  /// The fixes worth offering for [source], in the order they should be shown.
  /// Returns an empty list when the text is already strict JSON.
  static List<JsonQuickFix> forSource(String source) {
    if (source.trim().isEmpty) return const [];
    if (_parser.parse(source).ok) return const [];

    final candidates = <String, String Function(String)>{
      removeComments: stripComments,
      trailingCommas: dropTrailingCommas,
      quoteKeys: quoteUnquotedKeys,
      doubleQuotes: useDoubleQuotes,
      pythonLiterals: usePythonLiterals,
    };

    final fixes = <JsonQuickFix>[];
    for (final entry in candidates.entries) {
      final result = entry.value(source);
      if (result == source) continue;
      fixes.add(JsonQuickFix(id: entry.key, result: result));
    }
    return fixes;
  }

  /// Applying every fix at once, when no single one is enough on its own.
  /// Returns null when the combination changes nothing or does not help.
  static JsonQuickFix? fixAll(String source) {
    if (source.trim().isEmpty) return null;
    if (_parser.parse(source).ok) return null;
    var text = source;
    text = stripComments(text);
    text = usePythonLiterals(text);
    text = useDoubleQuotes(text);
    text = quoteUnquotedKeys(text);
    text = dropTrailingCommas(text);
    if (text == source) return null;
    // Only worth offering when it actually produces valid JSON.
    if (!_parser.parse(text).ok) return null;
    return JsonQuickFix(id: 'fixAll', result: text);
  }

  // --- individual fixes ----------------------------------------------------

  /// Removes `// line` and `/* block */` comments (JSONC), keeping anything
  /// that looks like a comment but sits inside a string.
  static String stripComments(String source) {
    final out = StringBuffer();
    var i = 0;
    while (i < source.length) {
      final c = source[i];
      if (c == '"' || c == "'") {
        final end = _skipString(source, i);
        out.write(source.substring(i, end));
        i = end;
        continue;
      }
      if (c == '/' && i + 1 < source.length) {
        if (source[i + 1] == '/') {
          var j = i + 2;
          while (j < source.length && source[j] != '\n') {
            j++;
          }
          i = j;
          continue;
        }
        if (source[i + 1] == '*') {
          final close = source.indexOf('*/', i + 2);
          i = close < 0 ? source.length : close + 2;
          continue;
        }
      }
      out.write(c);
      i++;
    }
    return out.toString();
  }

  /// Removes a comma that sits just before a `}` or `]`.
  static String dropTrailingCommas(String source) {
    final out = StringBuffer();
    var i = 0;
    while (i < source.length) {
      final c = source[i];
      if (c == '"' || c == "'") {
        final end = _skipString(source, i);
        out.write(source.substring(i, end));
        i = end;
        continue;
      }
      if (c == ',') {
        // Look ahead past whitespace for a closing bracket.
        var j = i + 1;
        while (j < source.length && source[j].trim().isEmpty) {
          j++;
        }
        if (j < source.length && (source[j] == '}' || source[j] == ']')) {
          i++; // drop the comma, keep the whitespace
          continue;
        }
      }
      out.write(c);
      i++;
    }
    return out.toString();
  }

  /// Puts double quotes around bare object keys: `{name: 1}` → `{"name": 1}`.
  static String quoteUnquotedKeys(String source) {
    final out = StringBuffer();
    var i = 0;
    // True while the next token would be a key (just after `{` or a `,` inside
    // an object). A small bracket stack keeps arrays out of it.
    final stack = <String>[];
    var expectingKey = false;

    while (i < source.length) {
      final c = source[i];
      if (c == '"' || c == "'") {
        final end = _skipString(source, i);
        out.write(source.substring(i, end));
        i = end;
        expectingKey = false;
        continue;
      }
      if (c == '{') {
        stack.add('{');
        expectingKey = true;
        out.write(c);
        i++;
        continue;
      }
      if (c == '[') {
        stack.add('[');
        expectingKey = false;
        out.write(c);
        i++;
        continue;
      }
      if (c == '}' || c == ']') {
        if (stack.isNotEmpty) stack.removeLast();
        expectingKey = false;
        out.write(c);
        i++;
        continue;
      }
      if (c == ',') {
        expectingKey = stack.isNotEmpty && stack.last == '{';
        out.write(c);
        i++;
        continue;
      }
      if (c == ':') {
        expectingKey = false;
        out.write(c);
        i++;
        continue;
      }
      if (expectingKey && _isIdentifierStart(c)) {
        var j = i;
        while (j < source.length && _isIdentifierPart(source[j])) {
          j++;
        }
        // Only a bare word directly followed by a colon is a key.
        var k = j;
        while (k < source.length && source[k].trim().isEmpty) {
          k++;
        }
        if (k < source.length && source[k] == ':') {
          out.write('"${source.substring(i, j)}"');
          i = j;
          expectingKey = false;
          continue;
        }
      }
      // Whitespace between `{` and the key is fine; anything else means we are
      // past the key position.
      if (c.trim().isNotEmpty) expectingKey = false;
      out.write(c);
      i++;
    }
    return out.toString();
  }

  /// Turns single-quoted strings into double-quoted ones, escaping any double
  /// quote that was inside them.
  static String useDoubleQuotes(String source) {
    final out = StringBuffer();
    var i = 0;
    while (i < source.length) {
      final c = source[i];
      if (c == '"') {
        final end = _skipString(source, i);
        out.write(source.substring(i, end));
        i = end;
        continue;
      }
      if (c == "'") {
        final end = _skipString(source, i);
        // The body without its quotes, with the escaping swapped over.
        final body = source.substring(i + 1, end > i + 1 ? end - 1 : i + 1);
        out.write('"');
        out.write(body.replaceAll(r"\'", "'").replaceAll('"', r'\"'));
        out.write('"');
        i = end;
        continue;
      }
      out.write(c);
      i++;
    }
    return out.toString();
  }

  /// Replaces Python's `True` / `False` / `None` with JSON's own words.
  static String usePythonLiterals(String source) {
    final out = StringBuffer();
    var i = 0;
    const swaps = {'True': 'true', 'False': 'false', 'None': 'null'};
    while (i < source.length) {
      final c = source[i];
      if (c == '"' || c == "'") {
        final end = _skipString(source, i);
        out.write(source.substring(i, end));
        i = end;
        continue;
      }
      if (_isIdentifierStart(c)) {
        var j = i;
        while (j < source.length && _isIdentifierPart(source[j])) {
          j++;
        }
        final word = source.substring(i, j);
        out.write(swaps[word] ?? word);
        i = j;
        continue;
      }
      out.write(c);
      i++;
    }
    return out.toString();
  }

  // --- helpers -------------------------------------------------------------

  /// The offset just past the string that starts at [start] (whose character is
  /// the opening quote). An unterminated string runs to the end of the text.
  static int _skipString(String source, int start) {
    final quote = source[start];
    var i = start + 1;
    while (i < source.length) {
      final c = source[i];
      if (c == r'\') {
        i += 2;
        continue;
      }
      if (c == quote) return i + 1;
      i++;
    }
    return source.length;
  }

  static bool _isIdentifierStart(String ch) {
    final c = ch.codeUnitAt(0);
    return (c >= 0x41 && c <= 0x5A) ||
        (c >= 0x61 && c <= 0x7A) ||
        c == 0x5F ||
        c == 0x24;
  }

  static bool _isIdentifierPart(String ch) {
    final c = ch.codeUnitAt(0);
    return _isIdentifierStart(ch) || (c >= 0x30 && c <= 0x39);
  }
}
