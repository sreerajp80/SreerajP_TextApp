import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sreerajp_textapp/core/backup/backup_bundle_service.dart';
import 'package:sreerajp_textapp/core/backup/backup_models.dart';
import 'package:sreerajp_textapp/core/storage/storage_models.dart';

void main() {
  group('BackupBundleService', () {
    const service = BackupBundleService();

    test('packBundle and unpackBundle roundtrip cleanly', () {
      const manifest = BackupManifest(
        createdAt: 1723700000000,
        recentsCount: 1,
        favoritesCount: 1,
        bookmarksCount: 1,
        hasSettings: true,
        files: [
          BackupFileEntry(
            displayName: 'notes.txt',
            relativePath: 'files/notes.txt',
            size: 11,
            sha256: 'abc123hash',
            mimeType: 'text/plain',
          ),
        ],
      );

      final recents = [
        const RecentFile(
          fingerprint: 'fp_recent_1',
          uri: 'content://saf/1',
          displayName: 'doc.txt',
          lastOpenedAt: 1723700000000,
        ),
      ];

      final favorites = [
        const Favorite(
          fingerprint: 'fp_fav_1',
          uri: 'content://saf/2',
          displayName: 'favorite.csv',
          addedAt: 1723700000000,
        ),
      ];

      final bookmarks = [
        const Bookmark(
          id: 1,
          fingerprint: 'fp_recent_1',
          label: 'Chapter 2',
          position: 450,
          createdAt: 1723700000000,
        ),
      ];

      final settings = <String, Object?>{
        'appearance.theme_mode': 'dark',
        'appearance.font_scale': 1.2,
        'appearance.word_wrap': true,
      };

      final files = [
        BackupFileEntry(
          displayName: 'notes.txt',
          relativePath: 'files/notes.txt',
          size: 11,
          sha256: 'abc123hash',
          mimeType: 'text/plain',
          bytes: Uint8List.fromList([
            104,
            101,
            108,
            108,
            111,
            32,
            119,
            111,
            114,
            108,
            100,
          ]), // 'hello world'
        ),
      ];

      final bundleBytes = service.packBundle(
        manifest: manifest,
        recents: recents,
        favorites: favorites,
        bookmarks: bookmarks,
        settings: settings,
        files: files,
      );

      expect(bundleBytes, isNotEmpty);

      final preview = service.unpackBundle(bundleBytes);

      expect(preview.manifest.createdAt, equals(1723700000000));
      expect(preview.recents.length, equals(1));
      expect(preview.recents.first.displayName, equals('doc.txt'));
      expect(preview.favorites.length, equals(1));
      expect(preview.favorites.first.displayName, equals('favorite.csv'));
      expect(preview.bookmarks.length, equals(1));
      expect(preview.bookmarks.first.label, equals('Chapter 2'));
      expect(preview.settings['appearance.theme_mode'], equals('dark'));
      expect(preview.files.length, equals(1));
      expect(preview.files.first.displayName, equals('notes.txt'));
      expect(
        preview.files.first.bytes,
        equals([104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100]),
      );
    });

    test('packBundle and unpackBundle with empty sections', () {
      const manifest = BackupManifest(createdAt: 1723700000000);
      final bundleBytes = service.packBundle(manifest: manifest);

      final preview = service.unpackBundle(bundleBytes);
      expect(preview.manifest.createdAt, equals(1723700000000));
      expect(preview.recents, isEmpty);
      expect(preview.favorites, isEmpty);
      expect(preview.bookmarks, isEmpty);
      expect(preview.settings, isEmpty);
      expect(preview.files, isEmpty);
    });

    test('unpackBundle throws FormatException if manifest is missing', () {
      expect(
        () => service.unpackBundle(Uint8List.fromList([])),
        throwsA(anything),
      );
    });
  });
}
