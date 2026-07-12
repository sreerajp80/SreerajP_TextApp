import 'package:xml/xml.dart';
import 'package:xml/xpath.dart';

/// The path of an element in slash form, e.g. `root/items/item[2]/name`
/// (task 9.2).
///
/// A positional `[n]` (1-based, XPath-style) is added only when the element has
/// a same-named sibling, so unique elements stay clean. Attribute nodes append
/// `/@name`. Non-element nodes (text, comment, CDATA) fall back to their parent's
/// path plus a `text()` / `comment()` label.
String xmlPathOf(XmlNode node) {
  if (node is XmlAttribute) {
    final owner = node.parent;
    final base = owner == null ? '' : xmlPathOf(owner);
    return '$base/@${node.name.qualified}';
  }

  final segments = <String>[];
  XmlNode? current = node;
  while (current != null && current is! XmlDocument) {
    segments.add(_segmentFor(current));
    current = current.parent;
  }
  final path = segments.reversed.join('/');
  return path.isEmpty ? '/' : path;
}

String _segmentFor(XmlNode node) {
  if (node is XmlElement) {
    final name = node.name.qualified;
    final parent = node.parent;
    if (parent != null) {
      final sameName =
          parent.childElements.where((e) => e.name.qualified == name).toList();
      if (sameName.length > 1) {
        final index = sameName.indexWhere((e) => identical(e, node));
        return '$name[${index + 1}]';
      }
    }
    return name;
  }
  if (node is XmlText) return 'text()';
  if (node is XmlCDATA) return 'cdata()';
  if (node is XmlComment) return 'comment()';
  if (node is XmlProcessing) return 'processing()';
  return 'node()';
}

/// The result of an XPath query (task 9.3): the matching nodes plus a friendly
/// [error] when the query itself could not be understood.
class XmlPathResult {
  final List<XmlNode> matches;
  final String? error;

  const XmlPathResult(this.matches, {this.error});

  bool get hasError => error != null;
}

/// Evaluates an [expression] against [root] using the `xml` package's XPath
/// support (a pragmatic XPath 1.0 subset — plan §3.1).
///
/// A malformed or unsupported query returns a friendly [XmlPathResult.error]
/// rather than throwing (CLAUDE.md §3.4).
XmlPathResult evaluateXPath(XmlNode root, String expression) {
  final trimmed = expression.trim();
  if (trimmed.isEmpty) return const XmlPathResult([]);
  try {
    // The `xml` package marks its XPath support experimental; we deliberately
    // opt in for the optional query feature (plan §3.1) and degrade gracefully.
    // ignore: experimental_member_use
    return XmlPathResult(root.xpath(trimmed).toList());
  } catch (e) {
    return XmlPathResult(const [], error: _friendly(e));
  }
}

String _friendly(Object error) {
  final text = error.toString();
  if (text.contains('XPathParserException')) {
    return 'That XPath query could not be understood.';
  }
  return 'That XPath query could not be run.';
}
