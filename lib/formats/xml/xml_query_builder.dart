import 'package:xml/xml.dart';

/// What one step of a built XPath does (roadmap §4.3.2).
enum XmlStepKind {
  /// A child element by name: `/item`
  element,

  /// A same-named sibling by position: `[2]` on the step before it.
  position,

  /// An attribute of the current element: `/@id`
  attribute,

  /// An element of that name at any depth below here: `//item`
  anyDepthElement,
}

/// One step of a visually built XPath.
class XmlQueryStep {
  final XmlStepKind kind;

  /// The element or attribute name. Empty for [XmlStepKind.position].
  final String name;

  /// The 1-based position, for [XmlStepKind.position].
  final int position;

  const XmlQueryStep.element(this.name)
      : kind = XmlStepKind.element,
        position = 0;
  const XmlQueryStep.position(this.position)
      : kind = XmlStepKind.position,
        name = '';
  const XmlQueryStep.attribute(this.name)
      : kind = XmlStepKind.attribute,
        position = 0;
  const XmlQueryStep.anyDepthElement(this.name)
      : kind = XmlStepKind.anyDepthElement,
        position = 0;

  @override
  bool operator ==(Object other) =>
      other is XmlQueryStep &&
      other.kind == kind &&
      other.name == name &&
      other.position == position;

  @override
  int get hashCode => Object.hash(kind, name, position);
}

/// A choice the builder offers as the next step, read from the document.
class XmlStepChoice {
  final XmlQueryStep step;
  final String label;
  final String detail;

  const XmlStepChoice({
    required this.step,
    required this.label,
    required this.detail,
  });
}

/// Builds XPath expressions from picked steps (roadmap §4.3.2).
///
/// The twin of the JSON query builder: the user picks element names,
/// positions and attributes that really exist in the open document, and this
/// turns them into an XPath string the app's existing `evaluateXPath` runs — no
/// hand-written syntax.
///
/// Pure Dart apart from the `xml` node types, so it is host-tested.
class XmlQueryBuilder {
  const XmlQueryBuilder._();

  /// The XPath text for [steps]. An empty list selects the document root.
  static String buildQuery(List<XmlQueryStep> steps) {
    if (steps.isEmpty) return '/';
    final buffer = StringBuffer();
    for (final step in steps) {
      switch (step.kind) {
        case XmlStepKind.element:
          buffer.write('/${step.name}');
          break;
        case XmlStepKind.position:
          // A position refines the step before it rather than adding one.
          buffer.write('[${step.position}]');
          break;
        case XmlStepKind.attribute:
          buffer.write('/@${step.name}');
          break;
        case XmlStepKind.anyDepthElement:
          buffer.write('//${step.name}');
          break;
      }
    }
    return buffer.toString();
  }

  /// The nodes [steps] currently select. Never throws.
  static List<XmlNode> resolve(XmlDocument document, List<XmlQueryStep> steps) {
    var current = <XmlNode>[document];
    for (final step in steps) {
      // A position narrows the whole current set — it refines the step before
      // it rather than descending, which is what `item[2]` means in XPath.
      if (step.kind == XmlStepKind.position) {
        final at = step.position - 1;
        current = at >= 0 && at < current.length ? [current[at]] : <XmlNode>[];
        continue;
      }
      final next = <XmlNode>[];
      for (final node in current) {
        _applyStep(step, node, next);
      }
      current = next;
      if (current.isEmpty) break;
    }
    return current;
  }

  /// The steps worth offering after [steps]: the child element names present,
  /// a position when the last step matched several same-named elements, and the
  /// attributes of the selected element.
  static List<XmlStepChoice> suggestions(
    XmlDocument document,
    List<XmlQueryStep> steps, {
    int maxPositions = 20,
  }) {
    final current = resolve(document, steps);
    if (current.isEmpty) return const [];

    final choices = <XmlStepChoice>[];

    // Narrowing to one of several same-named matches.
    final lastIsPosition =
        steps.isNotEmpty && steps.last.kind == XmlStepKind.position;
    if (!lastIsPosition && current.length > 1) {
      final count = current.length < maxPositions ? current.length : maxPositions;
      for (var i = 1; i <= count; i++) {
        choices.add(XmlStepChoice(
          step: XmlQueryStep.position(i),
          label: '[$i]',
          detail: 'match $i',
        ));
      }
    }

    final seenElements = <String>{};
    final seenAttributes = <String>{};
    for (final node in current) {
      for (final child in node.childElements) {
        final name = child.name.qualified;
        if (!seenElements.add(name)) continue;
        choices.add(XmlStepChoice(
          step: XmlQueryStep.element(name),
          label: name,
          detail: _detail(child),
        ));
      }
      if (node is XmlElement) {
        for (final attribute in node.attributes) {
          final name = attribute.name.qualified;
          if (!seenAttributes.add(name)) continue;
          choices.add(XmlStepChoice(
            step: XmlQueryStep.attribute(name),
            label: '@$name',
            detail: 'attribute',
          ));
        }
      }
    }
    return choices;
  }

  /// Element names found anywhere below the current selection, for the
  /// "at any depth" shortcut.
  static List<String> deepElementNames(
    XmlDocument document,
    List<XmlQueryStep> steps, {
    int limit = 40,
  }) {
    final current = resolve(document, steps);
    final names = <String>{};
    void walk(XmlNode node) {
      for (final child in node.childElements) {
        if (names.length >= limit) return;
        names.add(child.name.qualified);
        walk(child);
      }
    }

    for (final node in current) {
      walk(node);
      if (names.length >= limit) break;
    }
    final sorted = names.toList()..sort();
    return sorted;
  }

  static void _applyStep(XmlQueryStep step, XmlNode node, List<XmlNode> out) {
    switch (step.kind) {
      case XmlStepKind.element:
        for (final child in node.childElements) {
          if (child.name.qualified == step.name) out.add(child);
        }
        break;
      case XmlStepKind.position:
        // Handled in resolve: a position picks from the whole current set, not
        // from each node's children.
        break;
      case XmlStepKind.attribute:
        if (node is XmlElement) {
          for (final attribute in node.attributes) {
            if (attribute.name.qualified == step.name) out.add(attribute);
          }
        }
        break;
      case XmlStepKind.anyDepthElement:
        void walk(XmlNode n) {
          for (final child in n.childElements) {
            if (child.name.qualified == step.name) out.add(child);
            walk(child);
          }
        }

        walk(node);
        break;
    }
  }

  static String _detail(XmlElement element) {
    final children = element.childElements.length;
    if (children > 0) return '$children children';
    final text = element.innerText.trim();
    if (text.isEmpty) return 'empty';
    return text.length <= 24 ? text : '${text.substring(0, 24)}…';
  }
}
