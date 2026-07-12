import '../editor/encoding.dart';
import '../storage/saf_service.dart';

/// The facts the app shows about an open file (architecture.md §6, §9 "About").
///
/// Size, name, encoding, and line-ending style are always present. Dates are
/// nullable because the SAF provider does not always report them. A per-format
/// hook fills [formatFields] with extra rows (e.g. CSV row/column counts, JSON
/// top-level type) in later phases.
class FileMetadata {
  final String name;
  final int? size; // bytes; null when the provider did not report it
  final DateTime? createdAt;
  final DateTime? modifiedAt;
  final TextEncodingType encoding;
  final LineEndingStyle lineEnding;

  /// Extra, format-specific rows keyed by a human label. Empty for plain text.
  final Map<String, String> formatFields;

  const FileMetadata({
    required this.name,
    this.size,
    this.createdAt,
    this.modifiedAt,
    required this.encoding,
    required this.lineEnding,
    this.formatFields = const {},
  });

  FileMetadata copyWith({
    Map<String, String>? formatFields,
  }) {
    return FileMetadata(
      name: name,
      size: size,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      encoding: encoding,
      lineEnding: lineEnding,
      formatFields: formatFields ?? this.formatFields,
    );
  }
}

/// Builds [FileMetadata] from what the app already knows about an open file.
///
/// The encoding and line ending come from the decode step (task 3.1); the name
/// and size from the picked [SafFile]; the modified time from the SAF service
/// when available (task 3.9). Pure logic — the async variant just fills the date
/// from the platform.
class MetadataService {
  final SafService _saf;

  const MetadataService(this._saf);

  /// Builds metadata without touching the platform (size/name/encoding only).
  /// A format module may pass [formatFields] for its own rows.
  FileMetadata build({
    required SafFile file,
    required DecodedText decoded,
    Map<String, String> formatFields = const {},
    DateTime? modifiedAt,
    DateTime? createdAt,
  }) {
    return FileMetadata(
      name: file.displayName,
      size: file.size ?? decoded.text.length,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
      encoding: decoded.encoding,
      lineEnding: decoded.lineEnding,
      formatFields: formatFields,
    );
  }

  /// Same as [build] but also asks the platform for the file's modified time
  /// (best-effort; null when the provider does not report one).
  Future<FileMetadata> buildWithDates({
    required SafFile file,
    required DecodedText decoded,
    Map<String, String> formatFields = const {},
  }) async {
    final millis = await _saf.modifiedTime(file.uri);
    final modified =
        millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
    return build(
      file: file,
      decoded: decoded,
      formatFields: formatFields,
      modifiedAt: modified,
    );
  }
}
