import 'package:sqflite/sqflite.dart';

import 'storage_models.dart';

/// Index of in-progress drafts saved for crash recovery. The draft file itself
/// is written by the editor's draft store in Phase 3; this table just points to
/// it, keyed by the file's content fingerprint (architecture.md §6).
class DraftsIndexRepository {
  final Database _db;

  DraftsIndexRepository(this._db);

  /// Records (or updates) the draft pointer for a file.
  Future<void> upsert(DraftIndexEntry entry) async {
    await _db.insert(
      'drafts_index',
      entry.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<DraftIndexEntry?> byFingerprint(String fingerprint) async {
    final rows = await _db.query(
      'drafts_index',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DraftIndexEntry.fromRow(rows.first);
  }

  Future<List<DraftIndexEntry>> all() async {
    final rows = await _db.query('drafts_index', orderBy: 'updated_at DESC');
    return rows.map(DraftIndexEntry.fromRow).toList(growable: false);
  }

  /// Clears the draft pointer after a real save (architecture.md §6).
  Future<void> remove(String fingerprint) async {
    await _db.delete(
      'drafts_index',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }
}
