import 'json_node.dart';

/// The result of parsing a JSON document (task 8.4).
///
/// Never thrown from — [JsonParser.parse] always returns one of these, with
/// [ok] false and a friendly [errorMessage] plus a 1-based [errorLine] /
/// [errorColumn] when the input is not well-formed (CLAUDE.md §3.4).
class JsonParseResult {
  /// Whether the document parsed successfully.
  final bool ok;

  /// The parsed tree, or `null` when [ok] is false.
  final JsonNode? root;

  /// A user-safe reason the parse failed, or `null` when [ok] is true.
  final String? errorMessage;

  /// 1-based line of the error, or `null` when [ok] is true.
  final int? errorLine;

  /// 1-based column of the error, or `null` when [ok] is true.
  final int? errorColumn;

  /// True when lenient-only features (comments, trailing commas, single quotes,
  /// unquoted keys) were used, so the caller can tell the user the file will be
  /// saved as strict JSON (task 8.4).
  final bool lenientFeaturesUsed;

  const JsonParseResult._({
    required this.ok,
    this.root,
    this.errorMessage,
    this.errorLine,
    this.errorColumn,
    this.lenientFeaturesUsed = false,
  });

  factory JsonParseResult.success(JsonNode root, {bool lenientUsed = false}) =>
      JsonParseResult._(ok: true, root: root, lenientFeaturesUsed: lenientUsed);

  factory JsonParseResult.failure(String message, int line, int column) =>
      JsonParseResult._(
        ok: false,
        errorMessage: message,
        errorLine: line,
        errorColumn: column,
      );
}

/// One parsed record from an NDJSON (newline-delimited JSON) document.
class NdjsonRecord {
  /// 1-based line number in the source.
  final int line;

  /// The parsed value for this line, or `null` if the line did not parse.
  final JsonNode? node;

  /// A friendly error for this line, or `null` when it parsed.
  final String? error;

  const NdjsonRecord({required this.line, this.node, this.error});

  bool get ok => node != null;
}

/// A small, tolerant recursive-descent JSON reader (plan §3.1).
///
/// In **strict** mode it accepts standard JSON only (used for the pre-save
/// well-formedness gate and validation). In **lenient** mode it also tolerates a
/// practical JSONC / JSON5 subset: `//` line and `/* */` block comments, trailing
/// commas, single-quoted strings, and unquoted identifier keys. Numbers are kept
/// as their exact source text so nothing is rounded. Every node records its
/// source span. The reader never throws — errors come back as a [JsonParseResult].
class JsonParser {
  const JsonParser();

  /// Parses [source]. When [lenient] is true, comments / trailing commas /
  /// single quotes / unquoted keys are tolerated.
  JsonParseResult parse(String source, {bool lenient = false}) {
    final state = _State(source, lenient);
    try {
      state.skipInsignificant();
      if (state.atEnd) {
        return JsonParseResult.failure('The file has no JSON content.',
            state.line, state.column);
      }
      final root = state.parseValue();
      state.skipInsignificant();
      if (!state.atEnd) {
        throw _ParseError('Unexpected content after the JSON value.', state.pos);
      }
      return JsonParseResult.success(root, lenientUsed: state.lenientUsed);
    } on _ParseError catch (e) {
      final (line, column) = _lineColOf(source, e.pos);
      return JsonParseResult.failure(e.message, line, column);
    }
  }

  /// Reads [source] as NDJSON: each non-blank line is parsed on its own. Lines
  /// are parsed leniently so a comment line does not break the whole file.
  List<NdjsonRecord> parseNdjson(String source) {
    final records = <NdjsonRecord>[];
    final lines = source.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final text = lines[i].trim();
      if (text.isEmpty) continue;
      final result = parse(text, lenient: true);
      records.add(NdjsonRecord(
        line: i + 1,
        node: result.ok ? result.root : null,
        error: result.ok ? null : result.errorMessage,
      ));
    }
    return records;
  }

  /// True when [source] looks like NDJSON: it is not a single JSON value, but
  /// every non-blank line parses on its own and there is more than one.
  bool looksLikeNdjson(String source) {
    if (parse(source, lenient: true).ok) return false;
    final records = parseNdjson(source);
    if (records.length < 2) return false;
    return records.every((r) => r.ok);
  }
}

/// Re-emits a parsed tree as **strict**, indented JSON (task 8.4 format).
///
/// Strings are re-escaped so single-quoted / unquoted lenient input becomes
/// valid strict JSON; numbers keep their exact source text, so precision is
/// preserved.
String prettyPrintJson(JsonNode node, {String indent = '  '}) {
  final buffer = StringBuffer();
  _write(node, buffer, indent, 0, true);
  return buffer.toString();
}

/// Re-emits a parsed tree as strict, single-line JSON (task 8.4 minify).
String minifyJson(JsonNode node) {
  final buffer = StringBuffer();
  _write(node, buffer, '', 0, false);
  return buffer.toString();
}

void _write(JsonNode node, StringBuffer out, String indent, int depth,
    bool pretty) {
  switch (node.kind) {
    case JsonKind.object:
      if (node.children.isEmpty) {
        out.write('{}');
        return;
      }
      out.write('{');
      _writeChildren(node.children, out, indent, depth, pretty, isObject: true);
      _writeCloser('}', out, indent, depth, pretty);
      break;
    case JsonKind.array:
      if (node.children.isEmpty) {
        out.write('[]');
        return;
      }
      out.write('[');
      _writeChildren(node.children, out, indent, depth, pretty, isObject: false);
      _writeCloser(']', out, indent, depth, pretty);
      break;
    case JsonKind.string:
      out.write(encodeJsonString(node.stringValue ?? ''));
      break;
    case JsonKind.number:
    case JsonKind.boolean:
    case JsonKind.nullValue:
      out.write(node.rawText);
      break;
  }
}

void _writeChildren(List<JsonNode> children, StringBuffer out, String indent,
    int depth, bool pretty, {required bool isObject}) {
  final pad = pretty ? indent * (depth + 1) : '';
  for (var i = 0; i < children.length; i++) {
    if (pretty) out.write('\n');
    out.write(pad);
    final child = children[i];
    if (isObject) {
      out.write(encodeJsonString(child.key ?? ''));
      out.write(pretty ? ': ' : ':');
    }
    _write(child, out, indent, depth + 1, pretty);
    if (i != children.length - 1) out.write(',');
  }
}

void _writeCloser(
    String closer, StringBuffer out, String indent, int depth, bool pretty) {
  if (pretty) {
    out.write('\n');
    out.write(indent * depth);
  }
  out.write(closer);
}

/// Encodes [value] as a strict JSON string literal (with surrounding quotes).
String encodeJsonString(String value) {
  final out = StringBuffer('"');
  for (final unit in value.runes) {
    switch (unit) {
      case 0x22:
        out.write(r'\"');
        break;
      case 0x5C:
        out.write(r'\\');
        break;
      case 0x08:
        out.write(r'\b');
        break;
      case 0x0C:
        out.write(r'\f');
        break;
      case 0x0A:
        out.write(r'\n');
        break;
      case 0x0D:
        out.write(r'\r');
        break;
      case 0x09:
        out.write(r'\t');
        break;
      default:
        if (unit < 0x20) {
          out.write('\\u${unit.toRadixString(16).padLeft(4, '0')}');
        } else {
          out.write(String.fromCharCode(unit));
        }
    }
  }
  out.write('"');
  return out.toString();
}

/// A parse failure at a source offset. Internal to the parser.
class _ParseError implements Exception {
  final String message;
  final int pos;
  _ParseError(this.message, this.pos);
}

/// The mutable cursor + helpers for one parse run.
class _State {
  final String src;
  final bool lenient;
  int pos = 0;
  bool lenientUsed = false;

  _State(this.src, this.lenient);

  bool get atEnd => pos >= src.length;

  int get _char => src.codeUnitAt(pos);

  int get line => _lineColOf(src, pos).$1;
  int get column => _lineColOf(src, pos).$2;

  /// Skips whitespace and, in lenient mode, `//` and `/* */` comments.
  void skipInsignificant() {
    while (!atEnd) {
      final c = _char;
      if (c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D) {
        pos++;
        continue;
      }
      if (lenient && c == 0x2F && pos + 1 < src.length) {
        final next = src.codeUnitAt(pos + 1);
        if (next == 0x2F) {
          lenientUsed = true;
          pos += 2;
          while (!atEnd && _char != 0x0A) {
            pos++;
          }
          continue;
        }
        if (next == 0x2A) {
          lenientUsed = true;
          pos += 2;
          while (pos + 1 < src.length &&
              !(_char == 0x2A && src.codeUnitAt(pos + 1) == 0x2F)) {
            pos++;
          }
          if (pos + 1 < src.length) {
            pos += 2;
          } else {
            throw _ParseError('A block comment was never closed.', pos);
          }
          continue;
        }
      }
      break;
    }
  }

  JsonNode parseValue() {
    skipInsignificant();
    if (atEnd) throw _ParseError('A value was expected here.', pos);
    final c = _char;
    if (c == 0x7B) return _parseObject();
    if (c == 0x5B) return _parseArray();
    if (c == 0x22) return _parseString();
    if (lenient && c == 0x27) return _parseString();
    if (c == 0x2D || (c >= 0x30 && c <= 0x39)) return _parseNumber();
    if (lenient && (c == 0x2B || c == 0x2E)) return _parseNumber();
    return _parseKeyword();
  }

  JsonNode _parseObject() {
    final start = pos;
    pos++; // '{'
    final children = <JsonNode>[];
    skipInsignificant();
    if (!atEnd && _char == 0x7D) {
      pos++;
      return JsonNode(
          kind: JsonKind.object, start: start, end: pos, children: children);
    }
    while (true) {
      skipInsignificant();
      final keyStart = pos;
      final key = _parseKey();
      final keyEnd = pos;
      skipInsignificant();
      if (atEnd || _char != 0x3A) {
        throw _ParseError("A ':' was expected after the key.", pos);
      }
      pos++; // ':'
      final value = parseValue();
      // Rebuild the value node so it carries the key + key span too.
      final member = JsonNode(
        kind: value.kind,
        start: value.start,
        end: value.end,
        key: key,
        keyStart: keyStart,
        keyEnd: keyEnd,
        rawText: value.rawText,
        stringValue: value.stringValue,
        children: value.children,
      );
      for (final grand in member.children) {
        grand.parent = member;
      }
      children.add(member);
      skipInsignificant();
      if (atEnd) throw _ParseError("A '}' was expected.", pos);
      if (_char == 0x2C) {
        pos++; // ','
        skipInsignificant();
        if (!atEnd && _char == 0x7D) {
          if (!lenient) {
            throw _ParseError('A trailing comma is not allowed.', pos);
          }
          lenientUsed = true;
          pos++;
          break;
        }
        continue;
      }
      if (_char == 0x7D) {
        pos++;
        break;
      }
      throw _ParseError("A ',' or '}' was expected.", pos);
    }
    final node = JsonNode(
        kind: JsonKind.object, start: start, end: pos, children: children);
    for (final child in children) {
      child.parent = node;
    }
    return node;
  }

  JsonNode _parseArray() {
    final start = pos;
    pos++; // '['
    final children = <JsonNode>[];
    skipInsignificant();
    if (!atEnd && _char == 0x5D) {
      pos++;
      return JsonNode(
          kind: JsonKind.array, start: start, end: pos, children: children);
    }
    var i = 0;
    while (true) {
      final value = parseValue()..index = i;
      children.add(value);
      i++;
      skipInsignificant();
      if (atEnd) throw _ParseError("A ']' was expected.", pos);
      if (_char == 0x2C) {
        pos++; // ','
        skipInsignificant();
        if (!atEnd && _char == 0x5D) {
          if (!lenient) {
            throw _ParseError('A trailing comma is not allowed.', pos);
          }
          lenientUsed = true;
          pos++;
          break;
        }
        continue;
      }
      if (_char == 0x5D) {
        pos++;
        break;
      }
      throw _ParseError("A ',' or ']' was expected.", pos);
    }
    final node = JsonNode(
        kind: JsonKind.array, start: start, end: pos, children: children);
    for (final child in children) {
      child.parent = node;
    }
    return node;
  }

  /// Parses an object key: a quoted string, or (lenient) an unquoted identifier.
  String _parseKey() {
    if (atEnd) throw _ParseError('A key was expected.', pos);
    final c = _char;
    if (c == 0x22 || (lenient && c == 0x27)) {
      final node = _parseString();
      return node.stringValue ?? '';
    }
    if (lenient && _isIdentifierStart(c)) {
      lenientUsed = true;
      final buffer = StringBuffer();
      while (!atEnd && _isIdentifierPart(_char)) {
        buffer.writeCharCode(_char);
        pos++;
      }
      return buffer.toString();
    }
    throw _ParseError('A key was expected.', pos);
  }

  JsonNode _parseString() {
    final start = pos;
    final quote = _char; // '"' or (lenient) '\''
    if (quote == 0x27) lenientUsed = true;
    pos++;
    final value = StringBuffer();
    while (true) {
      if (atEnd) throw _ParseError('A string was never closed.', start);
      final c = _char;
      if (c == quote) {
        pos++;
        break;
      }
      if (c == 0x5C) {
        pos++;
        if (atEnd) throw _ParseError('A string was never closed.', start);
        final esc = _char;
        switch (esc) {
          case 0x22:
            value.writeCharCode(0x22);
            break;
          case 0x27:
            value.writeCharCode(0x27);
            break;
          case 0x5C:
            value.writeCharCode(0x5C);
            break;
          case 0x2F:
            value.writeCharCode(0x2F);
            break;
          case 0x62:
            value.writeCharCode(0x08);
            break;
          case 0x66:
            value.writeCharCode(0x0C);
            break;
          case 0x6E:
            value.writeCharCode(0x0A);
            break;
          case 0x72:
            value.writeCharCode(0x0D);
            break;
          case 0x74:
            value.writeCharCode(0x09);
            break;
          case 0x75:
            value.writeCharCode(_readUnicodeEscape());
            break;
          default:
            throw _ParseError('An invalid escape was found in a string.', pos);
        }
        pos++;
        continue;
      }
      if (c < 0x20 && !lenient) {
        throw _ParseError('A control character is not allowed in a string.', pos);
      }
      value.writeCharCode(c);
      pos++;
    }
    return JsonNode(
      kind: JsonKind.string,
      start: start,
      end: pos,
      rawText: src.substring(start, pos),
      stringValue: value.toString(),
    );
  }

  int _readUnicodeEscape() {
    if (pos + 4 >= src.length) {
      throw _ParseError('A \\u escape is incomplete.', pos);
    }
    final hex = src.substring(pos + 1, pos + 5);
    final code = int.tryParse(hex, radix: 16);
    if (code == null) {
      throw _ParseError('A \\u escape has invalid hex digits.', pos);
    }
    pos += 4;
    return code;
  }

  JsonNode _parseNumber() {
    final start = pos;
    if (!atEnd && (_char == 0x2D || (lenient && _char == 0x2B))) pos++;
    while (!atEnd && _isNumberChar(_char)) {
      pos++;
    }
    final raw = src.substring(start, pos);
    if (raw.isEmpty || raw == '-' || raw == '+') {
      throw _ParseError('A number was expected here.', start);
    }
    return JsonNode(
        kind: JsonKind.number, start: start, end: pos, rawText: raw);
  }

  JsonNode _parseKeyword() {
    final start = pos;
    if (_matches('true')) {
      return JsonNode(
          kind: JsonKind.boolean, start: start, end: pos, rawText: 'true');
    }
    if (_matches('false')) {
      return JsonNode(
          kind: JsonKind.boolean, start: start, end: pos, rawText: 'false');
    }
    if (_matches('null')) {
      return JsonNode(
          kind: JsonKind.nullValue, start: start, end: pos, rawText: 'null');
    }
    throw _ParseError('An unexpected token was found.', pos);
  }

  bool _matches(String word) {
    if (pos + word.length > src.length) return false;
    if (src.substring(pos, pos + word.length) != word) return false;
    pos += word.length;
    return true;
  }

  static bool _isNumberChar(int c) =>
      (c >= 0x30 && c <= 0x39) || // 0-9
      c == 0x2E || // .
      c == 0x2B || // +
      c == 0x2D || // -
      c == 0x65 || // e
      c == 0x45; // E

  static bool _isIdentifierStart(int c) =>
      (c >= 0x41 && c <= 0x5A) ||
      (c >= 0x61 && c <= 0x7A) ||
      c == 0x5F ||
      c == 0x24;

  static bool _isIdentifierPart(int c) =>
      _isIdentifierStart(c) || (c >= 0x30 && c <= 0x39);
}

/// The 1-based (line, column) of a flat character [offset] in [source].
(int, int) _lineColOf(String source, int offset) {
  var line = 1;
  var column = 1;
  final limit = offset.clamp(0, source.length);
  for (var i = 0; i < limit; i++) {
    if (source.codeUnitAt(i) == 0x0A) {
      line++;
      column = 1;
    } else {
      column++;
    }
  }
  return (line, column);
}
