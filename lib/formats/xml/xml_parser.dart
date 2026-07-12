import 'package:xml/xml.dart';

/// The result of trying to read an XML document (task 9.4).
///
/// The [XmlDocumentParser] never throws on bad input (CLAUDE.md §3.4); instead a
/// failed parse returns [ok] `false` with a friendly [errorMessage] and the
/// 1-based [errorLine] / [errorColumn] the underlying parser reported.
class XmlParseResult {
  /// True when the text was well-formed XML.
  final bool ok;

  /// The parsed document, or `null` when [ok] is false.
  final XmlDocument? document;

  /// A short, human-friendly reason the parse failed (`null` when [ok]).
  final String? errorMessage;

  /// 1-based line where the error was detected (`0` when unknown / [ok]).
  final int errorLine;

  /// 1-based column where the error was detected (`0` when unknown / [ok]).
  final int errorColumn;

  const XmlParseResult._({
    required this.ok,
    this.document,
    this.errorMessage,
    this.errorLine = 0,
    this.errorColumn = 0,
  });

  const XmlParseResult.valid(XmlDocument document)
      : this._(ok: true, document: document);

  const XmlParseResult.invalid(
    String message, {
    int line = 0,
    int column = 0,
  }) : this._(
          ok: false,
          errorMessage: message,
          errorLine: line,
          errorColumn: column,
        );
}

/// A thin, never-throwing wrapper over the `xml` package's [XmlDocument.parse]
/// plus the serializers the views and save pipeline need (task 9.4).
///
/// Pure Dart (no Flutter), so it is unit-tested directly. Parsing decodes the
/// built-in and numeric entities into text; serializing re-escapes them, so text
/// is never corrupted on a round-trip (task 9.4). The XML declaration is kept as
/// a node and re-emitted, so the declared encoding survives a re-format.
class XmlDocumentParser {
  const XmlDocumentParser();

  /// Parses [text]. Returns a friendly [XmlParseResult] — never throws.
  XmlParseResult parse(String text) {
    if (text.trim().isEmpty) {
      return const XmlParseResult.invalid('The file is empty.', line: 1);
    }
    try {
      return XmlParseResult.valid(XmlDocument.parse(text));
    } on XmlException catch (e) {
      // Both syntax errors (XmlParserException) and tag mismatches
      // (XmlTagException) mix in XmlFormatException, which carries the 1-based
      // line/column when the parser recorded a position.
      if (e is XmlFormatException) {
        final located = e as XmlFormatException;
        return XmlParseResult.invalid(
          e.message,
          line: located.line,
          column: located.column,
        );
      }
      return XmlParseResult.invalid(e.message);
    } catch (_) {
      return const XmlParseResult.invalid('This is not valid XML.');
    }
  }

  /// Pretty-prints a parsed [document] with the given [indent] (task 9.4).
  String pretty(XmlDocument document, {String indent = '  '}) =>
      document.toXmlString(pretty: true, indent: indent);

  /// Serializes a parsed [document] on a single line (task 9.4).
  ///
  /// Works on a copy and drops insignificant whitespace — text nodes that are
  /// entirely whitespace and sit alongside child elements (i.e. indentation).
  /// Significant text (a leaf element's value, or text in mixed content) is kept,
  /// so nothing is corrupted.
  String minify(XmlDocument document) {
    final copy = XmlDocument(document.children.map((c) => c.copy()));
    _stripIndentWhitespace(copy);
    return copy.toXmlString();
  }

  void _stripIndentWhitespace(XmlNode node) {
    final hasElementChildren = node.children.any((c) => c is XmlElement);
    if (hasElementChildren) {
      node.children
          .removeWhere((c) => c is XmlText && c.value.trim().isEmpty);
    }
    for (final child in node.children) {
      _stripIndentWhitespace(child);
    }
  }

  /// The declared encoding from the XML declaration (e.g. `UTF-8`), or `null`.
  String? declaredEncoding(XmlDocument document) =>
      document.declaration?.encoding;

  /// The distinct namespace URIs declared anywhere in the document, in
  /// first-seen order (task 9.4 — "show namespaces").
  List<String> namespaces(XmlDocument document) {
    final seen = <String>[];
    for (final element in document.descendantElements) {
      for (final attribute in element.attributes) {
        final name = attribute.name;
        final isNs = name.qualified == 'xmlns' || name.prefix == 'xmlns';
        if (isNs) {
          final uri = attribute.value;
          if (uri.isNotEmpty && !seen.contains(uri)) seen.add(uri);
        }
      }
    }
    return seen;
  }
}
