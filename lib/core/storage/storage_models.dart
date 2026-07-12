// Plain data models stored in the local DB. Each is keyed by the file's content
// fingerprint where it makes sense (architecture.md §11), with the persisted SAF
// URI kept as the fast path back to the file.

/// A file the user opened recently.
class RecentFile {
  final String fingerprint;
  final String uri;
  final String displayName;
  final String? mimeType;
  final int? size;
  final int lastOpenedAt; // epoch millis
  final int scrollPosition; // remembered reading position

  const RecentFile({
    required this.fingerprint,
    required this.uri,
    required this.displayName,
    this.mimeType,
    this.size,
    required this.lastOpenedAt,
    this.scrollPosition = 0,
  });

  Map<String, Object?> toRow() => {
        'fingerprint': fingerprint,
        'uri': uri,
        'display_name': displayName,
        'mime_type': mimeType,
        'size': size,
        'last_opened_at': lastOpenedAt,
        'scroll_position': scrollPosition,
      };

  factory RecentFile.fromRow(Map<String, Object?> row) => RecentFile(
        fingerprint: row['fingerprint'] as String,
        uri: row['uri'] as String,
        displayName: row['display_name'] as String,
        mimeType: row['mime_type'] as String?,
        size: (row['size'] as num?)?.toInt(),
        lastOpenedAt: (row['last_opened_at'] as num).toInt(),
        scrollPosition: (row['scroll_position'] as num?)?.toInt() ?? 0,
      );
}

/// A saved position inside a file.
class Bookmark {
  final int? id; // null until inserted
  final String fingerprint;
  final String label;
  final int position;
  final int createdAt; // epoch millis

  const Bookmark({
    this.id,
    required this.fingerprint,
    required this.label,
    required this.position,
    required this.createdAt,
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'fingerprint': fingerprint,
        'label': label,
        'position': position,
        'created_at': createdAt,
      };

  factory Bookmark.fromRow(Map<String, Object?> row) => Bookmark(
        id: (row['id'] as num?)?.toInt(),
        fingerprint: row['fingerprint'] as String,
        label: row['label'] as String,
        position: (row['position'] as num).toInt(),
        createdAt: (row['created_at'] as num).toInt(),
      );
}

/// A file the user marked as a favorite.
class Favorite {
  final String fingerprint;
  final String uri;
  final String displayName;
  final int addedAt; // epoch millis

  const Favorite({
    required this.fingerprint,
    required this.uri,
    required this.displayName,
    required this.addedAt,
  });

  Map<String, Object?> toRow() => {
        'fingerprint': fingerprint,
        'uri': uri,
        'display_name': displayName,
        'added_at': addedAt,
      };

  factory Favorite.fromRow(Map<String, Object?> row) => Favorite(
        fingerprint: row['fingerprint'] as String,
        uri: row['uri'] as String,
        displayName: row['display_name'] as String,
        addedAt: (row['added_at'] as num).toInt(),
      );
}

/// A pointer to an in-progress draft saved for crash recovery (Phase 3 writes
/// the draft file itself; this table just indexes it).
class DraftIndexEntry {
  final String fingerprint;
  final String draftPath;
  final int updatedAt; // epoch millis

  const DraftIndexEntry({
    required this.fingerprint,
    required this.draftPath,
    required this.updatedAt,
  });

  Map<String, Object?> toRow() => {
        'fingerprint': fingerprint,
        'draft_path': draftPath,
        'updated_at': updatedAt,
      };

  factory DraftIndexEntry.fromRow(Map<String, Object?> row) => DraftIndexEntry(
        fingerprint: row['fingerprint'] as String,
        draftPath: row['draft_path'] as String,
        updatedAt: (row['updated_at'] as num).toInt(),
      );
}
