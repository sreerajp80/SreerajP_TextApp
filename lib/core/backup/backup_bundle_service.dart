import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'package:sreerajp_textapp/core/backup/backup_constants.dart';
import 'package:sreerajp_textapp/core/backup/backup_models.dart';
import 'package:sreerajp_textapp/core/storage/storage_models.dart';

/// Packs and unpacks the unencrypted internal ZIP container within `.txdata` archives.
class BackupBundleService {
  const BackupBundleService();

  /// Packages all provided components into a single unencrypted ZIP payload buffer.
  Uint8List packBundle({
    required BackupManifest manifest,
    List<RecentFile> recents = const [],
    List<Favorite> favorites = const [],
    List<Bookmark> bookmarks = const [],
    Map<String, Object?> settings = const {},
    List<BackupFileEntry> files = const [],
  }) {
    final archive = Archive();

    // 1. Manifest
    final manifestJson = utf8.encode(jsonEncode(manifest.toJson()));
    archive.addFile(
      ArchiveFile(
        BackupConstants.manifestFileName,
        manifestJson.length,
        manifestJson,
      ),
    );

    // 2. Recents
    if (recents.isNotEmpty) {
      final recentsJson = utf8.encode(
        jsonEncode(recents.map((r) => r.toRow()).toList()),
      );
      archive.addFile(
        ArchiveFile(
          BackupConstants.recentsFileName,
          recentsJson.length,
          recentsJson,
        ),
      );
    }

    // 3. Favorites
    if (favorites.isNotEmpty) {
      final favJson = utf8.encode(
        jsonEncode(favorites.map((f) => f.toRow()).toList()),
      );
      archive.addFile(
        ArchiveFile(BackupConstants.favoritesFileName, favJson.length, favJson),
      );
    }

    // 4. Bookmarks
    if (bookmarks.isNotEmpty) {
      final bmJson = utf8.encode(
        jsonEncode(bookmarks.map((b) => b.toRow()).toList()),
      );
      archive.addFile(
        ArchiveFile(BackupConstants.bookmarksFileName, bmJson.length, bmJson),
      );
    }

    // 5. Settings
    if (settings.isNotEmpty) {
      final settingsJson = utf8.encode(jsonEncode(settings));
      archive.addFile(
        ArchiveFile(
          BackupConstants.settingsFileName,
          settingsJson.length,
          settingsJson,
        ),
      );
    }

    // 6. Files
    for (final file in files) {
      final bytes = file.bytes;
      if (bytes != null) {
        archive.addFile(ArchiveFile(file.relativePath, bytes.length, bytes));
      }
    }

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Extracts an unencrypted ZIP payload back into structured data models.
  BackupPreview unpackBundle(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final filesMap = <String, Uint8List>{};

    for (final file in archive.files) {
      if (file.isFile) {
        filesMap[file.name] = Uint8List.fromList(file.content as List<int>);
      }
    }

    // Parse manifest
    final manifestBytes = filesMap[BackupConstants.manifestFileName];
    if (manifestBytes == null) {
      throw const FormatException('Archive is missing backup_manifest.json');
    }

    final manifestMap = Map<String, Object?>.from(
      jsonDecode(utf8.decode(manifestBytes)) as Map,
    );
    final manifest = BackupManifest.fromJson(manifestMap);

    // Parse recents
    final recents = <RecentFile>[];
    final recentsBytes = filesMap[BackupConstants.recentsFileName];
    if (recentsBytes != null) {
      final raw = jsonDecode(utf8.decode(recentsBytes)) as List<dynamic>;
      for (final r in raw) {
        if (r is Map) {
          recents.add(RecentFile.fromRow(Map<String, Object?>.from(r)));
        }
      }
    }

    // Parse favorites
    final favorites = <Favorite>[];
    final favBytes = filesMap[BackupConstants.favoritesFileName];
    if (favBytes != null) {
      final raw = jsonDecode(utf8.decode(favBytes)) as List<dynamic>;
      for (final f in raw) {
        if (f is Map) {
          favorites.add(Favorite.fromRow(Map<String, Object?>.from(f)));
        }
      }
    }

    // Parse bookmarks
    final bookmarks = <Bookmark>[];
    final bmBytes = filesMap[BackupConstants.bookmarksFileName];
    if (bmBytes != null) {
      final raw = jsonDecode(utf8.decode(bmBytes)) as List<dynamic>;
      for (final b in raw) {
        if (b is Map) {
          bookmarks.add(Bookmark.fromRow(Map<String, Object?>.from(b)));
        }
      }
    }

    // Parse settings
    var settings = <String, Object?>{};
    final settingsBytes = filesMap[BackupConstants.settingsFileName];
    if (settingsBytes != null) {
      settings = Map<String, Object?>.from(
        jsonDecode(utf8.decode(settingsBytes)) as Map,
      );
    }

    // Match files
    final extractedFiles = <BackupFileEntry>[];
    for (final entry in manifest.files) {
      final fileData = filesMap[entry.relativePath];
      extractedFiles.add(entry.copyWith(bytes: fileData));
    }

    return BackupPreview(
      manifest: manifest,
      recents: recents,
      favorites: favorites,
      bookmarks: bookmarks,
      settings: settings,
      files: extractedFiles,
    );
  }
}
