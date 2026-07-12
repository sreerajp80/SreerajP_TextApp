/// The kinds of value a JSON document can hold (task 8.1/8.2).
enum JsonKind { object, array, string, number, boolean, nullValue }

extension JsonKindLabel on JsonKind {
  /// A short human label used in the tree view and insights.
  String get label {
    switch (this) {
      case JsonKind.object:
        return 'object';
      case JsonKind.array:
        return 'array';
      case JsonKind.string:
        return 'string';
      case JsonKind.number:
        return 'number';
      case JsonKind.boolean:
        return 'boolean';
      case JsonKind.nullValue:
        return 'null';
    }
  }
}

/// One node in a parsed JSON tree (Phase 8).
///
/// This is our **own** node model rather than the plain maps/lists from
/// `dart:convert`, for three reasons the plan calls for (plan §3.1):
///
/// 1. **Exact numbers.** A number keeps its original source text in [rawText],
///    so a large / high-precision value is never rounded on a round-trip.
/// 2. **Source spans.** Every node records where it sits in the source
///    (`[start, end)`), so "copy subtree", tree navigation, and tree editing can
///    map a node back to precise text.
/// 3. **Order + keys.** Object members keep their [key] and original order.
///
/// Pure Dart, no Flutter dependency, so it is unit-tested directly.
class JsonNode {
  /// What kind of value this node is.
  final JsonKind kind;

  /// The object member key this node was stored under (decoded, unescaped), or
  /// `null` for the root and for array elements.
  String? key;

  /// The array index of this node inside its parent array, or `null` otherwise.
  int? index;

  /// Source offset where this value begins (the first character of the value).
  final int start;

  /// Source offset just past the end of this value.
  final int end;

  /// For an object member: source offset where the key token (its opening quote)
  /// begins; `-1` when this node is not an object member.
  final int keyStart;

  /// For an object member: source offset just past the key token.
  final int keyEnd;

  /// For a scalar (string / number / boolean / null): the exact source text of
  /// the value. Empty for containers. For a number this is the value verbatim,
  /// so precision is preserved.
  final String rawText;

  /// For a string node: the decoded (unescaped) string value.
  final String? stringValue;

  /// Members (for an object) or elements (for an array), in document order.
  final List<JsonNode> children;

  /// The parent node, set while building the tree; `null` for the root.
  JsonNode? parent;

  JsonNode({
    required this.kind,
    required this.start,
    required this.end,
    this.key,
    this.index,
    this.keyStart = -1,
    this.keyEnd = -1,
    this.rawText = '',
    this.stringValue,
    List<JsonNode>? children,
  }) : children = children ?? <JsonNode>[];

  /// True for objects and arrays (nodes that can be expanded).
  bool get isContainer => kind == JsonKind.object || kind == JsonKind.array;

  /// The number of members / elements (0 for scalars).
  int get childCount => children.length;

  /// The number value parsed from [rawText], or `null` if it does not fit a Dart
  /// `num`. Used only for insights — never for round-tripping (that uses
  /// [rawText] so precision is kept).
  num? get numberValue =>
      kind == JsonKind.number ? num.tryParse(rawText) : null;

  /// A short one-line preview of a scalar's value for the tree view.
  String get valuePreview {
    switch (kind) {
      case JsonKind.string:
        return '"${stringValue ?? ''}"';
      case JsonKind.number:
      case JsonKind.boolean:
      case JsonKind.nullValue:
        return rawText;
      case JsonKind.object:
        return '{ $childCount }';
      case JsonKind.array:
        return '[ $childCount ]';
    }
  }
}
