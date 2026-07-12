import 'package:xml/xml.dart';

/// Pure DOM edit operations on a parsed XML document (plan §3.4, task 9.5).
///
/// The `xml` package's DOM has no source offsets, so a structural tree edit is
/// applied by **mutating the parsed document and re-serializing** it (pretty,
/// with the chosen [indent]). The returned string is handed to the editor buffer
/// via the session's `applySource`, so undo/redo, dirty tracking, and the save
/// gate keep working. Re-serializing normalizes whitespace across the document;
/// the raw editor stays the precise, free-form path (plan §3.4). The XML
/// declaration is preserved because the package keeps and re-emits it.
///
/// Every method takes the owning [document] plus the target node (which must
/// belong to that document), mutates in place, and returns the new source. After
/// an edit the caller re-parses to refresh node references.
class XmlTreeEdits {
  final String indent;

  const XmlTreeEdits({this.indent = '  '});

  /// Sets a leaf element's text content (task 9.5). Existing text is replaced.
  String setText(XmlDocument document, XmlElement element, String text) {
    element.children.removeWhere((n) => n is XmlText || n is XmlCDATA);
    if (text.isNotEmpty) element.children.insert(0, XmlText(text));
    return _serialize(document);
  }

  /// Adds or updates an attribute on [element] (task 9.5).
  String setAttribute(
    XmlDocument document,
    XmlElement element,
    String name,
    String value,
  ) {
    element.setAttribute(name, value);
    return _serialize(document);
  }

  /// Removes an attribute from [element] (task 9.5). A no-op if it is absent.
  String removeAttribute(
    XmlDocument document,
    XmlElement element,
    String name,
  ) {
    element.removeAttribute(name);
    return _serialize(document);
  }

  /// Renames [element] to [newName], keeping its attributes and children
  /// (task 9.5). A blank name is ignored.
  String renameElement(
    XmlDocument document,
    XmlElement element,
    String newName,
  ) {
    final name = newName.trim();
    if (name.isEmpty) return _serialize(document);
    final replacement = XmlElement(
      XmlName.fromString(name),
      element.attributes.map((a) => a.copy()),
      element.children.map((c) => c.copy()),
      element.isSelfClosing,
    );
    element.replace(replacement);
    return _serialize(document);
  }

  /// Adds a new child element `<`[childName]`>` (optionally with [text]) to
  /// [parent] as its last child (task 9.5).
  String addChild(
    XmlDocument document,
    XmlElement parent,
    String childName, {
    String text = '',
  }) {
    final name = childName.trim();
    if (name.isEmpty) return _serialize(document);
    final child = XmlElement(
      XmlName.fromString(name),
      const [],
      text.isEmpty ? const [] : [XmlText(text)],
    );
    parent.children.add(child);
    return _serialize(document);
  }

  /// Removes [node] from its parent (task 9.5). The document root cannot be
  /// removed (a no-op).
  String deleteNode(XmlDocument document, XmlNode node) {
    if (node.parent == null || node.parent is XmlDocument) {
      // Never leave a document without a root element.
      if (node is XmlElement && identical(node, document.rootElement)) {
        return _serialize(document);
      }
    }
    node.remove();
    return _serialize(document);
  }

  /// Moves an element up (`delta` = -1) or down (`delta` = 1) among its
  /// same-level element siblings (task 9.5). A no-op at an edge or for the root.
  String moveSibling(XmlDocument document, XmlElement element, int delta) {
    final parent = element.parent;
    if (parent == null || parent is XmlDocument) return _serialize(document);
    final elements = parent.childElements.toList();
    final ei = elements.indexWhere((e) => identical(e, element));
    if (ei < 0) return _serialize(document);
    final ni = ei + delta;
    if (ni < 0 || ni >= elements.length) return _serialize(document);

    final target = elements[ni];
    final elementCopy = element.copy();
    final targetCopy = target.copy();
    element.replace(targetCopy);
    target.replace(elementCopy);
    return _serialize(document);
  }

  String _serialize(XmlDocument document) =>
      document.toXmlString(pretty: true, indent: indent);
}
