import 'package:sqflite/sqflite.dart';

import 'storage_models.dart';

/// CRUD for favorite files.
class FavoritesRepository {
  final Database _db;

  FavoritesRepository(this._db);

  Future<void> add(Favorite favorite) async {
    await _db.insert(
      'favorites',
      favorite.toRow(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Favorite>> all() async {
    final rows = await _db.query('favorites', orderBy: 'added_at DESC');
    return rows.map(Favorite.fromRow).toList(growable: false);
  }

  Future<bool> isFavorite(String fingerprint) async {
    final rows = await _db.query(
      'favorites',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> remove(String fingerprint) async {
    await _db.delete(
      'favorites',
      where: 'fingerprint = ?',
      whereArgs: [fingerprint],
    );
  }
}
