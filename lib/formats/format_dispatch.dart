import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sreerajp_textapp/core/editor/editor_settings_controller.dart';
import 'package:sreerajp_textapp/formats/json/json_document_session.dart';
import 'package:sreerajp_textapp/formats/json/json_session_manager.dart';
import 'package:sreerajp_textapp/formats/markdown/md_document_session.dart';
import 'package:sreerajp_textapp/formats/markdown/md_session_manager.dart';
import 'package:sreerajp_textapp/formats/txt/txt_session_manager.dart';
import 'package:sreerajp_textapp/formats/xml/xml_document_session.dart';
import 'package:sreerajp_textapp/formats/xml/xml_session_manager.dart';
import 'package:sreerajp_textapp/shell/tabs/document_tab.dart';

/// The formats the app can open.
enum DocumentFormat { txt, markdown, csv, json, xml, vault, other }

/// Picks a document's format from its name / MIME type, so the workspace can
/// show the right viewer (arch §7). Detection is by extension first, then MIME —
/// content sniffing happens later inside the format module.
DocumentFormat detectFormat(DocumentTab tab) {
  final name = tab.displayName.toLowerCase();
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot + 1) : '';
  final mime = tab.mimeType?.toLowerCase() ?? '';

  if (ext == 'txvault' || name.endsWith('.txvault')) {
    return DocumentFormat.vault;
  }

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

/// The live session for [tab] as a plain [Listenable], so the shell can rebuild
/// when the document's mode changes without knowing which format it is.
///
/// Uses `sessionFor`, not `peek`: the caller needs something to listen to from
/// the first frame, and the session it returns is the same cached one the body
/// builds a moment later. Null for formats with no editor.
Listenable? tabSessionListenable(WidgetRef ref, DocumentTab tab) {
  switch (detectFormat(tab)) {
    case DocumentFormat.txt:
      return ref.read(txtSessionManagerProvider).sessionFor(tab);
    case DocumentFormat.markdown:
      return ref.read(mdSessionManagerProvider).sessionFor(tab);
    case DocumentFormat.json:
      return ref.read(jsonSessionManagerProvider).sessionFor(tab);
    case DocumentFormat.xml:
      return ref.read(xmlSessionManagerProvider).sessionFor(tab);
    case DocumentFormat.csv:
    case DocumentFormat.vault:
    case DocumentFormat.other:
      return null;
  }
}

/// True when [tab] is currently being edited, whatever its format.
///
/// Every format keeps its own mode enum, so this is the one place that maps them
/// all onto the single question the shell actually asks. Uses `peek`, never
/// `sessionFor`, so asking never builds a session that does not exist yet.
///
/// A locked (read-only) tab is never "editing", even if its session still
/// remembers an edit mode — the same rule the toolbars use.
bool isTabEditing(WidgetRef ref, DocumentTab tab) {
  if (tab.isReadOnly) return false;
  switch (detectFormat(tab)) {
    case DocumentFormat.txt:
      final s = ref.read(txtSessionManagerProvider).peek(tab.id);
      return s != null && s.viewMode == TabViewMode.edit;
    case DocumentFormat.markdown:
      return ref.read(mdSessionManagerProvider).peek(tab.id)?.isEditing ??
          false;
    case DocumentFormat.json:
      return ref.read(jsonSessionManagerProvider).peek(tab.id)?.isEditing ??
          false;
    case DocumentFormat.xml:
      return ref.read(xmlSessionManagerProvider).peek(tab.id)?.isEditing ??
          false;
    // CSV has table and raw views, not an edit mode, so there is nothing to
    // leave. Other formats have no editor at all.
    case DocumentFormat.csv:
    case DocumentFormat.vault:
    case DocumentFormat.other:
      return false;
  }
}

/// Takes [tab] out of edit mode and back to its format's normal view.
///
/// Only switches the view — the text, the undo history, and any unsaved edits
/// stay exactly as they are (CLAUDE.md §3.6). Callers that need to ask about
/// unsaved work must do that before calling this. Safe to call on a tab that is
/// not editing.
void exitTabEditMode(WidgetRef ref, DocumentTab tab) {
  switch (detectFormat(tab)) {
    case DocumentFormat.txt:
      ref
          .read(txtSessionManagerProvider)
          .peek(tab.id)
          ?.setViewMode(TabViewMode.view);
    case DocumentFormat.markdown:
      ref.read(mdSessionManagerProvider).peek(tab.id)?.setMode(MdMode.rendered);
    case DocumentFormat.json:
      ref
          .read(jsonSessionManagerProvider)
          .peek(tab.id)
          ?.setMode(JsonViewMode.pretty);
    case DocumentFormat.xml:
      ref
          .read(xmlSessionManagerProvider)
          .peek(tab.id)
          ?.setMode(XmlViewMode.pretty);
    case DocumentFormat.csv:
    case DocumentFormat.vault:
    case DocumentFormat.other:
      break;
  }
}

/// Leaves edit mode after a save that actually wrote the file, when Settings ›
/// Editor says to (default on).
///
/// Saving usually means "I am finished", and staying in edit mode keeps the
/// keyboard and the editing tools in the way. Call only with [saved] true — a
/// failed or cancelled save must leave the user where they were.
void exitEditModeAfterSave(
  WidgetRef ref,
  DocumentTab tab, {
  required bool saved,
}) {
  if (!saved) return;
  if (!ref.read(editorSettingsProvider).exitEditAfterSave) return;
  exitTabEditMode(ref, tab);
}
