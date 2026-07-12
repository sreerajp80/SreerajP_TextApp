import 'json_node.dart';
import 'json_parser.dart';

/// Thrown when split / merge is asked to work on something that is not a
/// top-level JSON array. Carries a friendly message for the UI.
class JsonSplitMergeException implements Exception {
  final String message;
  const JsonSplitMergeException(this.message);
  @override
  String toString() => 'JsonSplitMergeException: $message';
}

/// Splits and merges **top-level JSON arrays** (task 8.6). Pure Dart over the
/// parser; each produced part is strict, pretty-printed JSON.
class JsonSplitMerge {
  final JsonParser parser;

  const JsonSplitMerge([this.parser = const JsonParser()]);

  /// Splits the top-level array in [source] into parts of at most [perPart]
  /// elements each. Throws [JsonSplitMergeException] if [source] is not a valid
  /// top-level array or [perPart] is below 1.
  List<String> splitByCount(String source, int perPart) {
    if (perPart < 1) {
      throw const JsonSplitMergeException('Choose at least one item per part.');
    }
    final root = _requireArray(source);
    final parts = <String>[];
    for (var i = 0; i < root.children.length; i += perPart) {
      final slice = root.children.sublist(
        i,
        (i + perPart).clamp(0, root.children.length),
      );
      final part = JsonNode(
        kind: JsonKind.array,
        start: 0,
        end: 0,
        children: List<JsonNode>.from(slice),
      );
      parts.add(prettyPrintJson(part));
    }
    return parts;
  }

  /// Concatenates the top-level arrays in [sources] into one array (pretty
  /// JSON). Throws [JsonSplitMergeException] if any source is not a valid array.
  String mergeArrays(List<String> sources) {
    final merged = <JsonNode>[];
    for (final source in sources) {
      final root = _requireArray(source);
      merged.addAll(root.children);
    }
    final node = JsonNode(
      kind: JsonKind.array,
      start: 0,
      end: 0,
      children: merged,
    );
    return prettyPrintJson(node);
  }

  JsonNode _requireArray(String source) {
    final result = parser.parse(source, lenient: true);
    if (!result.ok || result.root == null) {
      throw JsonSplitMergeException(
          result.errorMessage ?? 'The JSON could not be read.');
    }
    if (result.root!.kind != JsonKind.array) {
      throw const JsonSplitMergeException(
          'This works only on a top-level JSON array.');
    }
    return result.root!;
  }
}
