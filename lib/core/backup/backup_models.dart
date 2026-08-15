import 'dart:typed_data';

import 'package:text_data/core/backup/backup_constants.dart';
import 'package:text_data/core/storage/storage_models.dart';

/// Metadata for one document file stored inside a backup archive.
class BackupFileEntry {
  final String displayName;
  final String relativePath;
  final int size;
  final String sha256;
  final String? mimeType;
  final Uint8List? bytes;

  const BackupFileEntry({
    required this.displayName,
    required this.relativePath,
    required this.size,
    required this.sha256,
    this.mimeType,
    this.bytes,
  });

  Map<String, Object?> toJson() => {
    'display_name': displayName,
    'relative_path': relativePath,
    'size': size,
    'sha256': sha256,
    'mime_type': mimeType,
  };

  factory BackupFileEntry.fromJson(
    Map<String, Object?> json, [
    Uint8List? fileBytes,
  ]) => BackupFileEntry(
    displayName: json['display_name'] as String? ?? 'untitled',
    relativePath: json['relative_path'] as String? ?? '',
    size: (json['size'] as num?)?.toInt() ?? 0,
    sha256: json['sha256'] as String? ?? '',
    mimeType: json['mime_type'] as String?,
    bytes: fileBytes,
  );

  BackupFileEntry copyWith({
    String? displayName,
    String? relativePath,
    int? size,
    String? sha256,
    String? mimeType,
    Uint8List? bytes,
  }) {
    return BackupFileEntry(
      displayName: displayName ?? this.displayName,
      relativePath: relativePath ?? this.relativePath,
      size: size ?? this.size,
      sha256: sha256 ?? this.sha256,
      mimeType: mimeType ?? this.mimeType,
      bytes: bytes ?? this.bytes,
    );
  }
}

/// Metadata header describing the contents of a backup bundle.
class BackupManifest {
  final int version;
  final String appId;
  final int createdAt; // epoch millis
  final int recentsCount;
  final int favoritesCount;
  final int bookmarksCount;
  final bool hasSettings;
  final List<BackupFileEntry> files;

  const BackupManifest({
    this.version = BackupConstants.formatVersion,
    this.appId = BackupConstants.appId,
    required this.createdAt,
    this.recentsCount = 0,
    this.favoritesCount = 0,
    this.bookmarksCount = 0,
    this.hasSettings = false,
    this.files = const [],
  });

  Map<String, Object?> toJson() => {
    'version': version,
    'app_id': appId,
    'created_at': createdAt,
    'recents_count': recentsCount,
    'favorites_count': favoritesCount,
    'bookmarks_count': bookmarksCount,
    'has_settings': hasSettings,
    'files': files.map((f) => f.toJson()).toList(),
  };

  factory BackupManifest.fromJson(Map<String, Object?> json) {
    final rawFiles = json['files'] as List<dynamic>? ?? [];
    final parsedFiles = <BackupFileEntry>[];
    for (final f in rawFiles) {
      if (f is Map) {
        parsedFiles.add(BackupFileEntry.fromJson(Map<String, Object?>.from(f)));
      }
    }

    return BackupManifest(
      version:
          (json['version'] as num?)?.toInt() ?? BackupConstants.formatVersion,
      appId: json['app_id'] as String? ?? BackupConstants.appId,
      createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
      recentsCount: (json['recents_count'] as num?)?.toInt() ?? 0,
      favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
      bookmarksCount: (json['bookmarks_count'] as num?)?.toInt() ?? 0,
      hasSettings: json['has_settings'] as bool? ?? false,
      files: parsedFiles,
    );
  }
}

/// User options when exporting a new backup archive.
class BackupExportOptions {
  final bool includeRecents;
  final bool includeFavorites;
  final bool includeBookmarks;
  final bool includeSettings;
  final List<BackupFileEntry> files;

  const BackupExportOptions({
    this.includeRecents = true,
    this.includeFavorites = true,
    this.includeBookmarks = true,
    this.includeSettings = true,
    this.files = const [],
  });

  BackupExportOptions copyWith({
    bool? includeRecents,
    bool? includeFavorites,
    bool? includeBookmarks,
    bool? includeSettings,
    List<BackupFileEntry>? files,
  }) {
    return BackupExportOptions(
      includeRecents: includeRecents ?? this.includeRecents,
      includeFavorites: includeFavorites ?? this.includeFavorites,
      includeBookmarks: includeBookmarks ?? this.includeBookmarks,
      includeSettings: includeSettings ?? this.includeSettings,
      files: files ?? this.files,
    );
  }
}

/// Decrypted preview of a backup archive presented to the user before restore.
class BackupPreview {
  final BackupManifest manifest;
  final List<RecentFile> recents;
  final List<Favorite> favorites;
  final List<Bookmark> bookmarks;
  final Map<String, Object?> settings;
  final List<BackupFileEntry> files;

  const BackupPreview({
    required this.manifest,
    this.recents = const [],
    this.favorites = const [],
    this.bookmarks = const [],
    this.settings = const {},
    this.files = const [],
  });
}

/// User choices when restoring from a backup archive.
class BackupRestoreOptions {
  final bool restoreRecents;
  final bool restoreFavorites;
  final bool restoreBookmarks;
  final bool restoreSettings;
  final bool restoreFiles;
  final bool mergeMode; // true = merge/add-only, false = overwrite existing

  const BackupRestoreOptions({
    this.restoreRecents = true,
    this.restoreFavorites = true,
    this.restoreBookmarks = true,
    this.restoreSettings = true,
    this.restoreFiles = true,
    this.mergeMode = true,
  });

  BackupRestoreOptions copyWith({
    bool? restoreRecents,
    bool? restoreFavorites,
    bool? restoreBookmarks,
    bool? restoreSettings,
    bool? restoreFiles,
    bool? mergeMode,
  }) {
    return BackupRestoreOptions(
      restoreRecents: restoreRecents ?? this.restoreRecents,
      restoreFavorites: restoreFavorites ?? this.restoreFavorites,
      restoreBookmarks: restoreBookmarks ?? this.restoreBookmarks,
      restoreSettings: restoreSettings ?? this.restoreSettings,
      restoreFiles: restoreFiles ?? this.restoreFiles,
      mergeMode: mergeMode ?? this.mergeMode,
    );
  }
}

/// Summary report after completing a restore operation.
class BackupRestoreResult {
  final int restoredRecents;
  final int restoredFavorites;
  final int restoredBookmarks;
  final int restoredSettings;
  final int restoredFiles;
  final List<String> warnings;

  const BackupRestoreResult({
    this.restoredRecents = 0,
    this.restoredFavorites = 0,
    this.restoredBookmarks = 0,
    this.restoredSettings = 0,
    this.restoredFiles = 0,
    this.warnings = const [],
  });

  bool get isSuccessful => warnings.isEmpty;
}
