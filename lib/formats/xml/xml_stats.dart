import 'package:xml/xml.dart';

/// Structural insights for an XML document (task 9.6): element count, depth,
/// most-common tags, and the attribute names seen per element type. Pure Dart,
/// no Flutter dependency.
class XmlStats {
  /// Total number of elements in the document.
  final int elementCount;

  /// The deepest element nesting level (the root element is depth 1).
  final int maxDepth;

  /// Total number of attributes across all elements.
  final int attributeCount;

  /// Count of elements per tag name (qualified), highest first.
  final Map<String, int> tagCounts;

  /// For each tag name, the set of attribute names ever seen on it (in
  /// first-seen order).
  final Map<String, List<String>> attributesByTag;

  /// The root element's qualified name, or `null` for an empty document.
  final String? rootElement;

  const XmlStats({
    required this.elementCount,
    required this.maxDepth,
    required this.attributeCount,
    required this.tagCounts,
    required this.attributesByTag,
    required this.rootElement,
  });

  /// The tag names ordered from most to least common.
  List<MapEntry<String, int>> get mostCommonTags {
    final entries = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  factory XmlStats.of(XmlDocument document) {
    var elementCount = 0;
    var maxDepth = 0;
    var attributeCount = 0;
    final tagCounts = <String, int>{};
    final attributesByTag = <String, List<String>>{};

    void visit(XmlElement element, int depth) {
      elementCount++;
      if (depth > maxDepth) maxDepth = depth;
      final tag = element.name.qualified;
      tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      final attrs = attributesByTag.putIfAbsent(tag, () => <String>[]);
      for (final attribute in element.attributes) {
        attributeCount++;
        final name = attribute.name.qualified;
        if (!attrs.contains(name)) attrs.add(name);
      }
      for (final child in element.childElements) {
        visit(child, depth + 1);
      }
    }

    final root = document.rootElement;
    visit(root, 1);

    return XmlStats(
      elementCount: elementCount,
      maxDepth: maxDepth,
      attributeCount: attributeCount,
      tagCounts: tagCounts,
      attributesByTag: attributesByTag,
      rootElement: root.name.qualified,
    );
  }
}
