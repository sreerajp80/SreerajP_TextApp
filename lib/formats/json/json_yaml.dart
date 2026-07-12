import 'json_node.dart';

/// A small YAML emitter used by the JSON → YAML export target (task 8.6).
///
/// It covers the shapes a JSON document produces: objects → `key: value`,
/// arrays → `- item`, and the four scalar kinds. Strings are quoted only when
/// they need it. Not a full YAML writer — anchors, tags, and multi-line block
/// scalars are out of scope (plan §8); the output is still valid YAML.
String jsonToYaml(JsonNode root) {
  final buffer = StringBuffer();
  _emit(root, buffer, 0, atLineStart: true);
  final text = buffer.toString();
  return text.endsWith('\n') ? text : '$text\n';
}

void _emit(JsonNode node, StringBuffer out, int indent,
    {required bool atLineStart}) {
  switch (node.kind) {
    case JsonKind.object:
      if (node.children.isEmpty) {
        out.write('{}\n');
        return;
      }
      if (!atLineStart) out.write('\n');
      for (final child in node.children) {
        out.write(_pad(indent));
        out.write(_scalarKey(child.key ?? ''));
        out.write(':');
        if (child.isContainer && child.children.isNotEmpty) {
          _emit(child, out, indent + 1, atLineStart: false);
        } else {
          out.write(' ');
          _emit(child, out, indent + 1, atLineStart: false);
        }
      }
      break;
    case JsonKind.array:
      if (node.children.isEmpty) {
        out.write('[]\n');
        return;
      }
      if (!atLineStart) out.write('\n');
      for (final child in node.children) {
        out.write(_pad(indent));
        out.write('- ');
        if (child.isContainer && child.children.isNotEmpty) {
          // Nest the container one level in, on following lines.
          _emit(child, out, indent + 1, atLineStart: false);
        } else {
          _emit(child, out, indent + 1, atLineStart: false);
        }
      }
      break;
    case JsonKind.string:
      out.write(_scalarString(node.stringValue ?? ''));
      out.write('\n');
      break;
    case JsonKind.number:
    case JsonKind.boolean:
    case JsonKind.nullValue:
      out.write(node.rawText);
      out.write('\n');
      break;
  }
}

String _pad(int indent) => '  ' * indent;

String _scalarKey(String key) => _needsQuote(key) ? _quote(key) : key;

String _scalarString(String value) =>
    _needsQuote(value) ? _quote(value) : value;

bool _needsQuote(String s) {
  if (s.isEmpty) return true;
  if (s != s.trim()) return true;
  // Quote if it could be read as another YAML type or has special chars.
  const reserved = {'true', 'false', 'null', 'yes', 'no', '~'};
  if (reserved.contains(s.toLowerCase())) return true;
  if (num.tryParse(s) != null) return true;
  for (final ch in const [':', '#', '-', '?', '[', ']', '{', '}', ',', '&',
    '*', '!', '|', '>', "'", '"', '%', '@', '`']) {
    if (s.contains(ch)) return true;
  }
  return false;
}

String _quote(String s) {
  final escaped = s.replaceAll('\\', r'\\').replaceAll('"', r'\"');
  return '"$escaped"';
}
