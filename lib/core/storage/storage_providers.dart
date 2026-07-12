import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app_database.dart';
import 'bookmarks_repository.dart';
import 'drafts_index_repository.dart';
import 'favorites_repository.dart';
import 'recents_repository.dart';

/// Opens the app database once and keeps it for the app's lifetime.
///
/// Uses sqflite's default databases directory (no extra permission and no
/// `path_provider` needed). Tests build their own [AppDatabase] with the FFI
/// factory instead of reading this provider.
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  final dir = await getDatabasesPath();
  final path = '$dir/${AppDatabase.defaultFileName}';
  final database = await AppDatabase.open(path: path);
  ref.onDispose(database.close);
  return database;
});

final recentsRepositoryProvider = FutureProvider<RecentsRepository>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return RecentsRepository(database.db);
});

final bookmarksRepositoryProvider =
    FutureProvider<BookmarksRepository>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return BookmarksRepository(database.db);
});

final favoritesRepositoryProvider =
    FutureProvider<FavoritesRepository>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return FavoritesRepository(database.db);
});

final draftsIndexRepositoryProvider =
    FutureProvider<DraftsIndexRepository>((ref) async {
  final database = await ref.watch(appDatabaseProvider.future);
  return DraftsIndexRepository(database.db);
});
