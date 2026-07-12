import 'json_node.dart';
import 'json_parser.dart';

/// The difference between two JSON documents (task 8.6): the paths that were
/// added, removed, or changed going from the first document to the second.
class JsonDiffResult {
  /// Paths present in the second document but not the first.
  final List<String> added;

  /// Paths present in the first document but not the second.
  final List<String> removed;

  /// Paths present in both but with a different value or type.
  final List<String> changed;

  const JsonDiffResult({
    required this.added,
    required this.removed,
    required this.changed,
  });

  bool get isEmpty => added.isEmpty && removed.isEmpty && changed.isEmpty;

  int get total => added.length + removed.length + changed.length;
}

/// Structurally compares two parsed JSON trees. Objects are matched by key,
/// arrays by index; scalars compare by their exact value (numbers by their
/// source text so precision is not lost). Pure Dart.
class JsonDiff {
  const JsonDiff();

  JsonDiffResult compare(JsonNode a, JsonNode b) {
    final added = <String>[];
    final removed = <String>[];
    final changed = <String>[];
    _walk(a, b, r'$', added, removed, changed);
    return JsonDiffResult(added: added, removed: removed, changed: changed);
  }

  void _walk(JsonNode a, JsonNode b, String path, List<String> added,
      List<String> removed, List<String> changed) {
    if (a.kind != b.kind) {
      changed.add(path);
      return;
    }
    switch (a.kind) {
      case JsonKind.object:
        final bByKey = <String, JsonNode>{};
        for (final child in b.children) {
          bByKey.putIfAbsent(child.key ?? '', () => child);
        }
        final seen = <String>{};
        for (final child in a.children) {
          final key = child.key ?? '';
          seen.add(key);
          final other = bByKey[key];
          final childPath = _childPath(path, key);
          if (other == null) {
            removed.add(childPath);
          } else {
            _walk(child, other, childPath, added, removed, changed);
          }
        }
        for (final child in b.children) {
          final key = child.key ?? '';
          if (!seen.contains(key)) added.add(_childPath(path, key));
        }
        break;
      case JsonKind.array:
        final shared = a.childCount < b.childCount ? a.childCount : b.childCount;
        for (var i = 0; i < shared; i++) {
          _walk(a.children[i], b.children[i], '$path[$i]', added, removed,
              changed);
        }
        for (var i = shared; i < a.childCount; i++) {
          removed.add('$path[$i]');
        }
        for (var i = shared; i < b.childCount; i++) {
          added.add('$path[$i]');
        }
        break;
      case JsonKind.string:
        if (a.stringValue != b.stringValue) changed.add(path);
        break;
      case JsonKind.number:
      case JsonKind.boolean:
      case JsonKind.nullValue:
        if (a.rawText != b.rawText) changed.add(path);
        break;
    }
  }

  String _childPath(String parent, String key) {
    if (_isPlainIdentifier(key)) return '$parent.$key';
    return '$parent[${encodeJsonString(key)}]';
  }

  static bool _isPlainIdentifier(String key) {
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
}
