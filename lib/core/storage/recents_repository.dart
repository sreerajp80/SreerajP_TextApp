import 'package:sqflite/sqflite.dart';

import 'storage_models.dart';

/// CRUD for recently opened files, newest first.
class RecentsRepository {
  final Database _db;

  RecentsRepository(this._db);

  /// Inserts or updates a recent entry (keyed by fingerprint).
  Future<void> upsert(RecentFile file) async {
    await _db.insert(
      'recents',
      file.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All recents, most recently opened first. Pass [limit] to cap the list.
  Future<List<RecentFile>> all({int? limit}) async {
    final rows = await _db.query(
      'recents',
      orderBy: 'last_opened_at DESC',
      limit: limit,
    );
    return rows.map(RecentFile.fromRow).toList(growable: false);
  }

  Future<RecentFile?> byFingerprint(String fingerprint) async {
    final rows = await _db.query(
      'recents',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return RecentFile.fromRow(rows.first);
  }

  /// Updates only the remembered scroll position for a file.
  Future<void> updateScrollPosition(String fingerprint, int position) async {
    await _db.update(
      'recents',
      {'scroll_position': position},
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }

  Future<void> remove(String fingerprint) async {
    await _db.delete('recents', where: 'fingerprint = ?', whereArgs: [fingerprint]);
  }

  /// Removes any rows that point at the same [uri] but carry a different
  /// fingerprint. Used when re-opening a file whose content changed (its
  /// fingerprint changed) so the Recent list keeps one entry per file location
  /// instead of a new row for every edit.
  Future<void> removeOtherUris(String uri, String keepFingerprint) async {
    await _db.delete(
      'recents',
      where: 'uri = ? AND fingerprint != ?',
      whereArgs: [uri, keepFingerprint],
    );
  }

  Future<void> clear() async {
    await _db.delete('recents');
  }
}
