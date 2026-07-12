import 'dart:typed_data';

/// The kinds of output the export/convert service can produce (task 5.4).
///
/// Each format module declares which of these it supports; asking for an
/// unsupported one is rejected cleanly with an [UnsupportedExportException]
/// rather than crashing (CLAUDE.md §3.4).
enum ExportTarget {
  pdf,
  docx,
  html,
  markdown,
  plainText,
  csv,
  yaml,
  json,
  xlsx,
}

extension ExportTargetInfo on ExportTarget {
  /// File extension (no dot) for a produced file of this target.
  String get extension {
    switch (this) {
      case ExportTarget.pdf:
        return 'pdf';
      case ExportTarget.docx:
        return 'docx';
      case ExportTarget.html:
        return 'html';
      case ExportTarget.markdown:
        return 'md';
      case ExportTarget.plainText:
        return 'txt';
      case ExportTarget.csv:
        return 'csv';
      case ExportTarget.yaml:
        return 'yaml';
      case ExportTarget.json:
        return 'json';
      case ExportTarget.xlsx:
        return 'xlsx';
    }
  }

  /// MIME type for a produced file of this target.
  String get mimeType {
    switch (this) {
      case ExportTarget.pdf:
        return 'application/pdf';
      case ExportTarget.docx:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case ExportTarget.html:
        return 'text/html';
      case ExportTarget.markdown:
        return 'text/markdown';
      case ExportTarget.plainText:
        return 'text/plain';
      case ExportTarget.csv:
        return 'text/csv';
      case ExportTarget.yaml:
        return 'application/yaml';
      case ExportTarget.json:
        return 'application/json';
      case ExportTarget.xlsx:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
  }

  /// Short human label for the picker UI.
  String get label {
    switch (this) {
      case ExportTarget.pdf:
        return 'PDF';
      case ExportTarget.docx:
        return 'Word (DOCX)';
      case ExportTarget.html:
        return 'HTML';
      case ExportTarget.markdown:
        return 'Markdown';
      case ExportTarget.plainText:
        return 'Plain text';
      case ExportTarget.csv:
        return 'CSV';
      case ExportTarget.yaml:
        return 'YAML';
      case ExportTarget.json:
        return 'JSON';
      case ExportTarget.xlsx:
        return 'Excel (XLSX)';
    }
  }
}

/// Neutral input to the export service: the document content plus enough
/// identity to name the output. Any format maps its content to this so the
/// export service stays format-agnostic.
class TextContent {
  /// The current display name of the source document (e.g. `notes.txt`).
  final String displayName;

  /// The full text to export.
  final String text;

  const TextContent({required this.displayName, required this.text});

  /// The display name without its extension, used to build the output name.
  String get baseName {
    final dot = displayName.lastIndexOf('.');
    if (dot <= 0) return displayName;
    return displayName.substring(0, dot);
  }
}

/// The bytes produced by an export, ready to share, print, or save as a copy.
class ExportResult {
  final Uint8List bytes;
  final String suggestedName;
  final String mimeType;
  final ExportTarget target;

  const ExportResult({
    required this.bytes,
    required this.suggestedName,
    required this.mimeType,
    required this.target,
  });
}

/// Thrown when a format is asked for a target it does not support, or for an
/// unknown format id. Carries a friendly message for the UI.
class UnsupportedExportException implements Exception {
  final String message;
  const UnsupportedExportException(this.message);

  @override
  String toString() => 'UnsupportedExportException: $message';
}
