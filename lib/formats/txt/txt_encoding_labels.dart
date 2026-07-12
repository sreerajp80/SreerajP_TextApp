import '../../core/editor/encoding.dart';

/// Human-readable names for encodings and line endings, shown in the encoding
/// switch and save-options UI (tasks 4.2, 4.4).
extension TextEncodingLabel on TextEncodingType {
  String get label {
    switch (this) {
      case TextEncodingType.utf8:
        return 'UTF-8';
      case TextEncodingType.utf8Bom:
        return 'UTF-8 (with BOM)';
      case TextEncodingType.utf16le:
        return 'UTF-16 LE';
      case TextEncodingType.utf16be:
        return 'UTF-16 BE';
      case TextEncodingType.ascii:
        return 'ASCII';
      case TextEncodingType.latin1:
        return 'ISO-8859-1 (Latin-1)';
      case TextEncodingType.windows1252:
        return 'Windows-1252';
    }
  }
}

extension LineEndingLabel on LineEndingStyle {
  String get label {
    switch (this) {
      case LineEndingStyle.lf:
        return 'LF (Unix / Android)';
      case LineEndingStyle.crlf:
        return 'CRLF (Windows)';
      case LineEndingStyle.cr:
        return 'CR (classic Mac)';
    }
  }

  String get shortLabel {
    switch (this) {
      case LineEndingStyle.lf:
        return 'LF';
      case LineEndingStyle.crlf:
        return 'CRLF';
      case LineEndingStyle.cr:
        return 'CR';
    }
  }
}
