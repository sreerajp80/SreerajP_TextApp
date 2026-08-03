import 'json_node.dart';

/// What one step of a built query does (roadmap §4.3.2).
enum JsonStepKind {
  /// Go into an object member by name: `.key`
  key,

  /// Go into an array element by position: `[2]`
  position,

  /// Every child of the current node: `[*]`
  allChildren,

  /// A named key at any depth below here: `..key`
  anyDepthKey,

  /// Everything below here: `..*`
  anyDepthAll,
}

/// One step of a visually built query.
class JsonQueryStep {
  final JsonStepKind kind;

  /// The key name, for [JsonStepKind.key] and [JsonStepKind.anyDepthKey].
  final String name;

  /// The element position, for [JsonStepKind.position].
  final int index;

  const JsonQueryStep.key(this.name)
      : kind = JsonStepKind.key,
        index = 0;
  const JsonQueryStep.index(this.index)
      : kind = JsonStepKind.position,
        name = '';
  const JsonQueryStep.allChildren()
      : kind = JsonStepKind.allChildren,
        name = '',
        index = 0;
  const JsonQueryStep.anyDepthKey(this.name)
      : kind = JsonStepKind.anyDepthKey,
        index = 0;
  const JsonQueryStep.anyDepthAll()
      : kind = JsonStepKind.anyDepthAll,
        name = '',
        index = 0;

  @override
  bool operator ==(Object other) =>
      other is JsonQueryStep &&
      other.kind == kind &&
      other.name == name &&
      other.index == index;

  @override
  int get hashCode => Object.hash(kind, name, index);
}

/// A choice the builder can offer as the next step, read from the document
/// itself so the user picks real keys instead of typing them.
class JsonStepChoice {
  final JsonQueryStep step;

  /// What to show on the chip: the key name, `[2]`, and so on.
  final String label;

  /// A short note about what is there, e.g. `object` or `3 items`.
  final String detail;

  const JsonStepChoice({
    required this.step,
    required this.label,
    required this.detail,
  });
}

/// Builds JSONPath queries from a list of picked steps (roadmap §4.3.2).
///
/// The point is that the user never types raw syntax: the builder reads the
/// open document, offers the keys and positions that actually exist, and turns
/// the picks into a JSONPath string the app's existing `evaluateJsonPath` runs.
///
/// Pure Dart with no Flutter import, so it is host-tested.
class JsonQueryBuilder {
  const JsonQueryBuilder._();

  /// The JSONPath text for [steps], always starting at the root `$`.
  static String buildQuery(List<JsonQueryStep> steps) {
    final buffer = StringBuffer(r'$');
    for (final step in steps) {
      switch (step.kind) {
        case JsonStepKind.key:
          buffer.write(_isPlainIdentifier(step.name)
              ? '.${step.name}'
              : "['${step.name.replaceAll("'", r"\'")}']");
          break;
        case JsonStepKind.position:
          buffer.write('[${step.index}]');
          break;
        case JsonStepKind.allChildren:
          buffer.write('[*]');
          break;
        case JsonStepKind.anyDepthKey:
          buffer.write('..${step.name}');
          break;
        case JsonStepKind.anyDepthAll:
          buffer.write('..*');
          break;
      }
    }
    return buffer.toString();
  }

  /// The nodes [steps] currently select, so the builder can preview the result
  /// and work out what to offer next. Never throws.
  static List<JsonNode> resolve(JsonNode root, List<JsonQueryStep> steps) {
    var current = <JsonNode>[root];
    for (final step in steps) {
      final next = <JsonNode>[];
      for (final node in current) {
        _applyStep(step, node, next);
      }
      current = next;
      if (current.isEmpty) break;
    }
    return current;
  }

  /// The steps worth offering after [steps], read from the document.
  ///
  /// Object members are offered by key, array elements by position (capped, so
  /// a 10,000-element array does not produce 10,000 chips), plus the
  /// "every child" and "at any depth" shortcuts when they make sense.
  static List<JsonStepChoice> suggestions(
    JsonNode root,
    List<JsonQueryStep> steps, {
    int maxIndexChoices = 20,
    int maxKeyChoices = 60,
  }) {
    final current = resolve(root, steps);
    if (current.isEmpty) return const [];

    final choices = <JsonStepChoice>[];
    final seenKeys = <String>{};
    var sawArray = false;
    var sawObject = false;

    for (final node in current) {
      if (node.kind == JsonKind.object) {
        sawObject = true;
        for (final member in node.children) {
          final key = member.key ?? '';
          if (!seenKeys.add(key)) continue;
          if (choices.length >= maxKeyChoices) break;
          choices.add(JsonStepChoice(
            step: JsonQueryStep.key(key),
            label: key,
            detail: _detail(member),
          ));
        }
      } else if (node.kind == JsonKind.array) {
        sawArray = true;
      }
    }

    // Positions only make sense when exactly one array is selected; with
    // several, `[*]` is the honest offer.
    if (sawArray && current.length == 1) {
      final array = current.first;
      final count = array.children.length < maxIndexChoices
          ? array.children.length
          : maxIndexChoices;
      for (var i = 0; i < count; i++) {
        choices.add(JsonStepChoice(
          step: JsonQueryStep.index(i),
          label: '[$i]',
          detail: _detail(array.children[i]),
        ));
      }
    }

    if (sawArray || sawObject) {
      choices.insert(
        0,
        const JsonStepChoice(
          step: JsonQueryStep.allChildren(),
          label: '[*]',
          detail: 'every item',
        ),
      );
    }
    return choices;
  }

  /// Key names found anywhere below the current selection, for the "at any
  /// depth" shortcut.
  static List<String> deepKeys(
    JsonNode root,
    List<JsonQueryStep> steps, {
    int limit = 40,
  }) {
    final current = resolve(root, steps);
    final keys = <String>{};
    void walk(JsonNode node) {
      for (final child in node.children) {
        if (keys.length >= limit) return;
        final key = child.key;
        if (key != null && key.isNotEmpty) keys.add(key);
        walk(child);
      }
    }

    for (final node in current) {
      walk(node);
      if (keys.length >= limit) break;
    }
    final sorted = keys.toList()..sort();
    return sorted;
  }

  static void _applyStep(
    JsonQueryStep step,
    JsonNode node,
    List<JsonNode> out,
  ) {
    switch (step.kind) {
      case JsonStepKind.key:
        if (node.kind != JsonKind.object) return;
        for (final child in node.children) {
          if (child.key == step.name) out.add(child);
        }
        break;
      case JsonStepKind.position:
        if (node.kind != JsonKind.array) return;
        if (step.index >= 0 && step.index < node.children.length) {
          out.add(node.children[step.index]);
        }
        break;
      case JsonStepKind.allChildren:
        if (node.isContainer) out.addAll(node.children);
        break;
      case JsonStepKind.anyDepthKey:
        _walkDeep(node, step.name, out);
        break;
      case JsonStepKind.anyDepthAll:
        _walkDeep(node, null, out);
        break;
    }
  }

  static void _walkDeep(JsonNode node, String? key, List<JsonNode> out) {
    for (final child in node.children) {
      if (key == null || child.key == key) out.add(child);
      _walkDeep(child, key, out);
    }
  }

  static String _detail(JsonNode node) {
    switch (node.kind) {
      case JsonKind.object:
        return '${node.childCount} keys';
      case JsonKind.array:
        return '${node.childCount} items';
      default:
        return node.kind.label;
    }
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
