import 'json_node.dart';
import 'json_parser.dart';

/// The path of a node in dotted form, e.g. `data.users[3].name` (task 8.2).
///
/// Object keys that are plain identifiers use `.key`; anything else uses
/// `["the key"]`. Array elements use `[index]`. The root node returns `$`.
String pathOf(JsonNode node) {
  final chain = <JsonNode>[];
  for (JsonNode? c = node; c != null && c.parent != null; c = c.parent) {
    chain.add(c);
  }
  final ordered = chain.reversed.toList();
  final buffer = StringBuffer();
  for (var i = 0; i < ordered.length; i++) {
    final n = ordered[i];
    if (n.index != null) {
      buffer.write('[${n.index}]');
    } else {
      final key = n.key ?? '';
      if (_isPlainIdentifier(key)) {
        if (i != 0) buffer.write('.');
        buffer.write(key);
      } else {
        buffer.write('[${encodeJsonString(key)}]');
      }
    }
  }
  final result = buffer.toString();
  return result.isEmpty ? r'$' : result;
}

/// The result of a JSONPath query (task 8.3): the matching nodes plus a friendly
/// [error] when the query itself could not be understood.
class JsonPathResult {
  final List<JsonNode> matches;
  final String? error;

  const JsonPathResult(this.matches, {this.error});

  bool get hasError => error != null;
}

/// Evaluates a **subset** of JSONPath against [root] (plan §3.5).
///
/// Supported: `$` (root), `.key`, `['key']` / `["key"]`, `[index]`, `[*]` / `.*`
/// (all children), and `..key` / `..*` (recursive descent). Anything else yields
/// a friendly error rather than a throw (CLAUDE.md §3.4).
JsonPathResult evaluateJsonPath(JsonNode root, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return const JsonPathResult([]);
  final List<_Step> steps;
  try {
    steps = _parseSteps(trimmed);
  } on _QueryError catch (e) {
    return JsonPathResult(const [], error: e.message);
  }

  var current = <JsonNode>[root];
  for (final step in steps) {
    final next = <JsonNode>[];
    for (final node in current) {
      step.apply(node, next);
    }
    current = next;
  }
  return JsonPathResult(current);
}

abstract class _Step {
  void apply(JsonNode node, List<JsonNode> out);
}

class _ChildKey implements _Step {
  final String key;
  _ChildKey(this.key);
  @override
  void apply(JsonNode node, List<JsonNode> out) {
    if (node.kind != JsonKind.object) return;
    for (final child in node.children) {
      if (child.key == key) out.add(child);
    }
  }
}

class _ChildIndex implements _Step {
  final int index;
  _ChildIndex(this.index);
  @override
  void apply(JsonNode node, List<JsonNode> out) {
    if (node.kind != JsonKind.array) return;
    if (index >= 0 && index < node.children.length) out.add(node.children[index]);
  }
}

class _Wildcard implements _Step {
  @override
  void apply(JsonNode node, List<JsonNode> out) {
    if (node.isContainer) out.addAll(node.children);
  }
}

class _Recursive implements _Step {
  final String? key; // null means all descendants (`..*`)
  _Recursive(this.key);
  @override
  void apply(JsonNode node, List<JsonNode> out) {
    void walk(JsonNode n) {
      for (final child in n.children) {
        if (key == null || child.key == key) out.add(child);
        walk(child);
      }
    }

    walk(node);
  }
}

class _QueryError implements Exception {
  final String message;
  _QueryError(this.message);
}

List<_Step> _parseSteps(String query) {
  var i = 0;
  final steps = <_Step>[];
  if (query.startsWith(r'$')) i = 1;

  while (i < query.length) {
    final c = query[i];
    if (c == '.') {
      if (i + 1 < query.length && query[i + 1] == '.') {
        // Recursive descent: ..name or ..*
        i += 2;
        if (i < query.length && query[i] == '*') {
          steps.add(_Recursive(null));
          i++;
        } else {
          final name = _readName(query, i);
          if (name.value.isEmpty) throw _QueryError('A name was expected after "..".');
          steps.add(_Recursive(name.value));
          i = name.next;
        }
      } else {
        i++;
        if (i < query.length && query[i] == '*') {
          steps.add(_Wildcard());
          i++;
        } else {
          final name = _readName(query, i);
          if (name.value.isEmpty) throw _QueryError('A name was expected after ".".');
          steps.add(_ChildKey(name.value));
          i = name.next;
        }
      }
    } else if (c == '[') {
      final close = query.indexOf(']', i);
      if (close < 0) throw _QueryError('A "]" is missing.');
      final inside = query.substring(i + 1, close).trim();
      steps.add(_parseBracket(inside));
      i = close + 1;
    } else {
      throw _QueryError('Unexpected character "$c" in the query.');
    }
  }
  return steps;
}

_Step _parseBracket(String inside) {
  if (inside == '*') return _Wildcard();
  if (inside.length >= 2 &&
      ((inside.startsWith("'") && inside.endsWith("'")) ||
          (inside.startsWith('"') && inside.endsWith('"')))) {
    return _ChildKey(inside.substring(1, inside.length - 1));
  }
  final index = int.tryParse(inside);
  if (index == null) throw _QueryError('"$inside" is not a valid index or key.');
  return _ChildIndex(index);
}

class _Name {
  final String value;
  final int next;
  _Name(this.value, this.next);
}

_Name _readName(String query, int from) {
  var i = from;
  final buffer = StringBuffer();
  while (i < query.length && query[i] != '.' && query[i] != '[') {
    buffer.write(query[i]);
    i++;
  }
  return _Name(buffer.toString(), i);
}

bool _isPlainIdentifier(String key) {
  if (key.isEmpty) return false;
  for (var i = 0; i < key.length; i++) {
    final c = key.codeUnitAt(i);
    final ok = (c >= 0x41 && c <= 0x5A) ||
        (c >= 0x61 && c <= 0x7A) ||
        c == 0x5F ||
        c == 0x24 ||
        (i > 0 && c >= 0x30 && c <= 0x39);
    if (!ok) return false;
  }
  return true;
}
