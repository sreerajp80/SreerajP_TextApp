import 'package:flutter/material.dart';

/// Picks a Material icon for a file from its name/extension or MIME type.
///
/// Covers the formats the app edits (TXT, MD, CSV, JSON, XML) and falls back to
/// a generic document icon for anything else.
IconData fileTypeIcon({String? displayName, String? mimeType}) {
  final ext = _extensionOf(displayName);
  switch (ext) {
    case 'txt':
      return Icons.text_snippet_outlined;
    case 'md':
    case 'markdown':
      return Icons.notes_outlined;
    case 'csv':
      return Icons.table_chart_outlined;
    case 'json':
      return Icons.data_object_outlined;
    case 'xml':
      return Icons.code_outlined;
  }

  final mime = mimeType?.toLowerCase() ?? '';
  if (mime.contains('json')) return Icons.data_object_outlined;
  if (mime.contains('xml')) return Icons.code_outlined;
  if (mime.contains('csv')) return Icons.table_chart_outlined;
  if (mime.contains('markdown')) return Icons.notes_outlined;
  if (mime.startsWith('text/')) return Icons.text_snippet_outlined;

  return Icons.insert_drive_file_outlined;
}

String? _extensionOf(String? name) {
  if (name == null) return null;
  final dot = name.lastIndexOf('.');
  if (dot < 0 || dot == name.length - 1) return null;
  return name.substring(dot + 1).toLowerCase();
}
