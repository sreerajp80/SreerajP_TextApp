import 'package:sqflite/sqflite.dart';

import 'storage_models.dart';

/// CRUD for per-file bookmarks (saved positions inside a file).
class BookmarksRepository {
  final Database _db;

  BookmarksRepository(this._db);

  /// Inserts a bookmark and returns it with its assigned id.
  Future<Bookmark> add(Bookmark bookmark) async {
    final id = await _db.insert('bookmarks', bookmark.toRow());
    return Bookmark(
      id: id,
      fingerprint: bookmark.fingerprint,
      label: bookmark.label,
      position: bookmark.position,
      createdAt: bookmark.createdAt,
    );
  }

  /// Every bookmark across all files, oldest first. Used by P2P sync export
  /// (Phase 12) to gather the syncable bookmark records.
  Future<List<Bookmark>> all() async {
    final rows = await _db.query('bookmarks', orderBy: 'created_at ASC');
    return rows.map(Bookmark.fromRow).toList(growable: false);
  }

  /// All bookmarks for one file, in position order.
  Future<List<Bookmark>> forFile(String fingerprint) async {
    final rows = await _db.query(
      'bookmarks',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      orderBy: 'position ASC',
    );
    return rows.map(Bookmark.fromRow).toList(growable: false);
  }

  Future<void> remove(int id) async {
    await _db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  /// Removes every bookmark for a file (e.g. when the file is forgotten).
  Future<void> clearForFile(String fingerprint) async {
    await _db.delete(
      'bookmarks',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }
}
