import 'dart:convert';

import 'package:xml/xml.dart';

/// Converts a parsed XML document to a JSON string (task 9.6).
///
/// Convention (a common, lossless-enough mapping):
/// - The result is `{ "<root>": <value> }`.
/// - An element's attributes become `"@name"` keys.
/// - Child elements are grouped by tag name; a repeated tag becomes an array.
/// - Text content becomes the element's string value when it has no attributes
///   and no child elements, otherwise a `"#text"` key (when non-blank).
String xmlToJson(XmlDocument document, {String indent = '  '}) {
  final root = document.rootElement;
  final map = {root.name.qualified: _elementValue(root)};
  return JsonEncoder.withIndent(indent).convert(map);
}

Object? _elementValue(XmlElement element) {
  final map = <String, Object?>{};

  for (final attribute in element.attributes) {
    map['@${attribute.name.qualified}'] = attribute.value;
  }

  final childElements = element.childElements.toList();
  final byTag = <String, List<XmlElement>>{};
  for (final child in childElements) {
    byTag.putIfAbsent(child.name.qualified, () => []).add(child);
  }
  for (final entry in byTag.entries) {
    final values = entry.value.map(_elementValue).toList();
    map[entry.key] = values.length == 1 ? values.first : values;
  }

  final text = _directText(element);
  if (map.isEmpty) return text.isEmpty ? null : text;
  if (text.isNotEmpty) map['#text'] = text;
  return map;
}

/// The element's own direct text (and CDATA), trimmed, ignoring child elements.
String _directText(XmlElement element) {
  final buffer = StringBuffer();
  for (final child in element.children) {
    if (child is XmlText || child is XmlCDATA) buffer.write(child.value);
  }
  return buffer.toString().trim();
}

/// Flattens a repeated `<`[tag]`>` child of the document root into CSV text
/// (task 9.6).
///
/// The header is the union — in first-seen order — of each matching element's
/// attribute names (`@name`) and its child element tag names. A cell is the
/// attribute value, or the child element's text (its inner XML when the child
/// itself has children). Missing fields are blank.
String xmlToCsv(XmlDocument document, String tag) {
  final root = document.rootElement;
  final rows =
      root.childElements.where((e) => e.name.qualified == tag).toList();

  final headers = <String>[];
  final rowMaps = <Map<String, String>>[];
  for (final row in rows) {
    final map = <String, String>{};
    for (final attribute in row.attributes) {
      final key = '@${attribute.name.qualified}';
      map[key] = attribute.value;
      if (!headers.contains(key)) headers.add(key);
    }
    for (final child in row.childElements) {
      final key = child.name.qualified;
      map[key] = child.childElements.isEmpty
          ? child.innerText.trim()
          : child.toXmlString();
      if (!headers.contains(key)) headers.add(key);
    }
    rowMaps.add(map);
  }

  final buffer = StringBuffer();
  buffer.writeln(headers.map(_csvField).join(','));
  for (final map in rowMaps) {
    buffer.writeln(headers.map((h) => _csvField(map[h] ?? '')).join(','));
  }
  return buffer.toString();
}

/// The document root's most-common repeated child tag, used as the default
/// row element for CSV export (task 9.6). Falls back to the first child tag, or
/// an empty string when the root has no child elements.
String bestRepeatedTag(XmlDocument document) {
  final counts = <String, int>{};
  for (final child in document.rootElement.childElements) {
    final tag = child.name.qualified;
    counts[tag] = (counts[tag] ?? 0) + 1;
  }
  if (counts.isEmpty) return '';
  String best = counts.keys.first;
  var bestCount = 0;
  for (final entry in counts.entries) {
    if (entry.value > bestCount) {
      best = entry.key;
      bestCount = entry.value;
    }
  }
  return best;
}

String _csvField(String value) {
  if (value.contains(',') ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
