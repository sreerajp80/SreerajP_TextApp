import 'package:xml/xml.dart';

import 'xml_parser.dart';

/// Thrown when split / merge cannot work on the given input. Carries a friendly
/// message for the UI.
class XmlSplitMergeException implements Exception {
  final String message;
  const XmlSplitMergeException(this.message);
  @override
  String toString() => 'XmlSplitMergeException: $message';
}

/// Splits an XML document by a **repeated child element** and merges several
/// documents **under a new wrapper root** (task 9.6). Pure Dart over the
/// `xml` package; each produced part is pretty-printed XML.
class XmlSplitMerge {
  final XmlDocumentParser parser;

  const XmlSplitMerge([this.parser = const XmlDocumentParser()]);

  /// Splits [source] into parts, each holding at most [perPart] of the root's
  /// `<`[tag]`>` children (in document order). Every part keeps the same root
  /// element name and its attributes, so the parts can be merged back.
  ///
  /// Throws [XmlSplitMergeException] when [source] is not valid XML, when
  /// [perPart] is below 1, or when the root has no `<`[tag]`>` children.
  List<String> splitByElement(String source, String tag, int perPart) {
    if (perPart < 1) {
      throw const XmlSplitMergeException('Choose at least one item per part.');
    }
    final root = _rootOf(source);
    final matches =
        root.childElements.where((e) => e.name.qualified == tag).toList();
    if (matches.isEmpty) {
      throw XmlSplitMergeException('No <$tag> elements were found to split.');
    }

    final parts = <String>[];
    for (var i = 0; i < matches.length; i += perPart) {
      final slice = matches.sublist(
        i,
        (i + perPart).clamp(0, matches.length),
      );
      final wrapper = XmlElement(
        root.name.copy(),
        root.attributes.map((a) => a.copy()),
        slice.map((e) => e.copy()),
      );
      parts.add(_serialize(wrapper));
    }
    return parts;
  }

  /// Merges the root children of every document in [sources] under one new
  /// [wrapperName] root element (task 9.6). Throws [XmlSplitMergeException] when
  /// any source is not valid XML.
  String mergeUnderWrapper(List<String> sources, String wrapperName) {
    final name = wrapperName.trim().isEmpty ? 'root' : wrapperName.trim();
    final children = <XmlNode>[];
    for (final source in sources) {
      final root = _rootOf(source);
      for (final child in root.childElements) {
        children.add(child.copy());
      }
    }
    final wrapper = XmlElement(XmlName.fromString(name), const [], children);
    return _serialize(wrapper);
  }

  XmlElement _rootOf(String source) {
    final result = parser.parse(source);
    if (!result.ok || result.document == null) {
      throw XmlSplitMergeException(
          result.errorMessage ?? 'The XML could not be read.');
    }
    return result.document!.rootElement;
  }

  String _serialize(XmlElement root) {
    final doc = XmlDocument([root]);
    return doc.toXmlString(pretty: true, indent: '  ');
  }
}
