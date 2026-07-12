import '../shell/tabs/document_tab.dart';

/// The formats the app can open. Only [txt] has a viewer in Phase 4; the others
/// arrive in Phases 6–9 and fall back to a placeholder until then.
enum DocumentFormat { txt, markdown, csv, json, xml, other }

/// Picks a document's format from its name / MIME type, so the workspace can
/// show the right viewer (arch §7). Detection is by extension first, then MIME —
/// content sniffing happens later inside the format module.
DocumentFormat detectFormat(DocumentTab tab) {
  final name = tab.displayName.toLowerCase();
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot + 1) : '';
  final mime = tab.mimeType?.toLowerCase() ?? '';

  const txtExts = {'txt', 'text', 'log', 'ini', 'conf', 'cfg', 'properties'};
  if (txtExts.contains(ext) || mime == 'text/plain') return DocumentFormat.txt;

  const mdExts = {'md', 'markdown', 'mdown', 'mkd', 'mkdn', 'mdwn', 'mdtxt'};
  if (mdExts.contains(ext) || mime == 'text/markdown') {
    return DocumentFormat.markdown;
  }

  // Known future formats (routed to placeholder for now so their real MIME is
  // not misread as plain text).
  if (ext == 'csv' || mime == 'text/csv') return DocumentFormat.csv;
  const jsonExts = {'json', 'jsonc', 'json5', 'ndjson'};
  if (jsonExts.contains(ext) ||
      mime == 'application/json' ||
      mime == 'application/x-ndjson') {
    return DocumentFormat.json;
  }
  const xmlExts = {'xml', 'xsd', 'xsl', 'xslt', 'svg', 'xhtml', 'rss', 'atom'};
  if (xmlExts.contains(ext) ||
      mime == 'application/xml' ||
      mime == 'text/xml' ||
      mime == 'image/svg+xml' ||
      mime == 'application/xhtml+xml') {
    return DocumentFormat.xml;
  }

  return DocumentFormat.other;
}
