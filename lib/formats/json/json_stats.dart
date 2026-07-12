import 'json_node.dart';

/// Structural insights for a JSON document (task 8.6): key count, depth, array
/// sizes, and a per-type breakdown. Pure Dart, no Flutter dependency.
class JsonStats {
  /// Total number of object-member keys across the whole tree.
  final int keyCount;

  /// The deepest nesting level (root value is depth 1).
  final int maxDepth;

  /// Number of arrays in the document.
  final int arrayCount;

  /// The largest array's element count (0 when there are no arrays).
  final int largestArray;

  /// Count of nodes by kind.
  final Map<JsonKind, int> typeBreakdown;

  /// The kind of the top-level value.
  final JsonKind topLevelType;

  /// Members / elements directly under the top-level value.
  final int topLevelItemCount;

  const JsonStats({
    required this.keyCount,
    required this.maxDepth,
    required this.arrayCount,
    required this.largestArray,
    required this.typeBreakdown,
    required this.topLevelType,
    required this.topLevelItemCount,
  });

  factory JsonStats.of(JsonNode root) {
    var keyCount = 0;
    var maxDepth = 0;
    var arrayCount = 0;
    var largestArray = 0;
    final breakdown = <JsonKind, int>{};

    void visit(JsonNode node, int depth) {
      if (depth > maxDepth) maxDepth = depth;
      breakdown[node.kind] = (breakdown[node.kind] ?? 0) + 1;
      if (node.kind == JsonKind.array) {
        arrayCount++;
        if (node.childCount > largestArray) largestArray = node.childCount;
      }
      for (final child in node.children) {
        if (child.key != null) keyCount++;
        visit(child, depth + 1);
      }
    }

    visit(root, 1);

    return JsonStats(
      keyCount: keyCount,
      maxDepth: maxDepth,
      arrayCount: arrayCount,
      largestArray: largestArray,
      typeBreakdown: breakdown,
      topLevelType: root.kind,
      topLevelItemCount: root.childCount,
    );
  }
}
