import 'json_node.dart';
import 'json_parser.dart';

/// Pure text-span edits on a JSON source string (plan §3.3, task 8.5).
///
/// The raw source text is the single source of truth; a tree edit is applied as
/// a precise replacement using a node's recorded `[start, end)` span, so the
/// change flows back through the editor (undo/redo, dirty tracking, and the save
/// gate keep working). Each method takes a node that was parsed from the **same**
/// [source] string and returns the new source. After an edit the caller re-parses
/// to refresh spans.
class JsonTreeEdits {
  const JsonTreeEdits();

  /// Replaces a scalar node's value with [newRawValue] (already-formatted JSON,
  /// e.g. `"hi"`, `42`, `true`, `null`).
  String setScalarValue(String source, JsonNode node, String newRawValue) {
    return source.replaceRange(node.start, node.end, newRawValue);
  }

  /// Renames an object member's key to [newKey].
  String setKey(String source, JsonNode node, String newKey) {
    if (node.keyStart < 0) return source;
    return source.replaceRange(
        node.keyStart, node.keyEnd, encodeJsonString(newKey));
  }

  /// Removes [node] (a member or an element) from its parent, taking one
  /// neighbouring comma with it so the result stays well-formed.
  String deleteNode(String source, JsonNode node) {
    final removeStart = node.keyStart >= 0 ? node.keyStart : node.start;
    var start = removeStart;
    var end = node.end;

    // Prefer to eat a following comma; otherwise eat a preceding one.
    var after = end;
    while (after < source.length && _isWhitespace(source.codeUnitAt(after))) {
      after++;
    }
    if (after < source.length && source[after] == ',') {
      end = after + 1;
    } else {
      var before = removeStart - 1;
      while (before >= 0 && _isWhitespace(source.codeUnitAt(before))) {
        before--;
      }
      if (before >= 0 && source[before] == ',') {
        start = before;
      }
    }
    return source.replaceRange(start, end, '');
  }

  /// Adds a child to a container [node]. Pass [key] for an object member; omit it
  /// for an array element. [rawValue] is already-formatted JSON.
  String addChild(String source, JsonNode node,
      {String? key, required String rawValue}) {
    final member =
        key == null ? rawValue : '${encodeJsonString(key)}: $rawValue';
    if (node.children.isEmpty) {
      // Insert just after the opening bracket.
      return source.replaceRange(node.start + 1, node.start + 1, member);
    }
    final insertAt = node.children.last.end;
    return source.replaceRange(insertAt, insertAt, ', $member');
  }

  static bool _isWhitespace(int c) =>
      c == 0x20 || c == 0x09 || c == 0x0A || c == 0x0D;
}
