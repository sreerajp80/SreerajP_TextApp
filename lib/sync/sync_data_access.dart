// Phase 12 — P2P LAN sync: the bridge between the sync engine and the app's
// data (favorites, bookmarks, recents, allow-listed settings).
//
// Behind an interface so the [SyncController] stays testable: tests inject a
// fake or an in-memory (FFI) repository-backed instance and never need a
// device (arch §12).
//
// This is the ONLY place sync touches app data. It exports records as plain
// maps and imports only the records the pure merge said to add. It reads and
// writes settings strictly through the allow-list (security-rules).
library;

import '../core/storage/bookmarks_repository.dart';
import '../core/storage/favorites_repository.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/recents_repository.dart';
import '../core/storage/storage_models.dart';
import 'sync_constants.dart';

/// What the sync engine needs from the app's data layer.
abstract class SyncDataAccess {
  /// Records for [category] as plain maps, ready for a payload.
  Future<List<Map<String, Object?>>> exportCategory(String category);

  /// The natural keys the receiver already has for [category] (for add-only
  /// merge).
  Future<Set<String>> existingKeys(String category);

  /// Adds the given records for [category]. Callers pass only records the merge
  /// said are new.
  Future<void> addRecords(String category, List<Map<String, Object?>> records);

  /// Allow-listed non-sensitive settings currently set on this device.
  Map<String, Object?> exportSettings();

  /// Which allow-listed setting keys are already set on this device.
  Set<String> existingSettingKeys();

  /// Applies allow-listed settings (write-through to the store).
  Future<void> applySettings(Map<String, Object?> settings);
}

/// Real [SyncDataAccess] backed by the Phase 1 repositories and settings store.
class RepositorySyncDataAccess implements SyncDataAccess {
  final FavoritesRepository favorites;
  final BookmarksRepository bookmarks;
  final RecentsRepository recents;
  final KeyValueStore store;

  RepositorySyncDataAccess({
    required this.favorites,
    required this.bookmarks,
    required this.recents,
    required this.store,
  });

  @override
  Future<List<Map<String, Object?>>> exportCategory(String category) async {
    switch (category) {
      case SyncConstants.categoryFavorites:
        final all = await favorites.all();
        return all
            .map((f) => {
                  'fingerprint': f.fingerprint,
                  'uri': f.uri,
                  'displayName': f.displayName,
                  'addedAt': f.addedAt,
                })
            .toList(growable: false);
      case SyncConstants.categoryBookmarks:
        final all = await bookmarks.all();
        return all
            .map((b) => {
                  'fingerprint': b.fingerprint,
                  'label': b.label,
                  'position': b.position,
                  'createdAt': b.createdAt,
                })
            .toList(growable: false);
      case SyncConstants.categoryRecents:
        final all = await recents.all();
        return all
            .map((r) => {
                  'fingerprint': r.fingerprint,
                  'uri': r.uri,
                  'displayName': r.displayName,
                  'mimeType': r.mimeType,
                  'size': r.size,
                  'lastOpenedAt': r.lastOpenedAt,
                })
            .toList(growable: false);
      default:
        return const [];
    }
  }

  @override
  Future<Set<String>> existingKeys(String category) async {
    switch (category) {
      case SyncConstants.categoryFavorites:
        final all = await favorites.all();
        return all.map((f) => f.fingerprint).toSet();
      case SyncConstants.categoryRecents:
        final all = await recents.all();
        return all.map((r) => r.fingerprint).toSet();
      case SyncConstants.categoryBookmarks:
        final all = await bookmarks.all();
        return all
            .map((b) => '${b.fingerprint}|${b.position}|${b.label}')
            .toSet();
      default:
        return <String>{};
    }
  }

  @override
  Future<void> addRecords(
      String category, List<Map<String, Object?>> records) async {
    switch (category) {
      case SyncConstants.categoryFavorites:
        for (final r in records) {
          await favorites.add(Favorite(
            fingerprint: r['fingerprint'] as String,
            uri: (r['uri'] as String?) ?? '',
            displayName: (r['displayName'] as String?) ?? '',
            addedAt: (r['addedAt'] as num?)?.toInt() ?? 0,
          ));
        }
        break;
      case SyncConstants.categoryBookmarks:
        for (final r in records) {
          // Drop any incoming id; the local DB assigns its own.
          await bookmarks.add(Bookmark(
            fingerprint: r['fingerprint'] as String,
            label: (r['label'] as String?) ?? '',
            position: (r['position'] as num?)?.toInt() ?? 0,
            createdAt: (r['createdAt'] as num?)?.toInt() ?? 0,
          ));
        }
        break;
      case SyncConstants.categoryRecents:
        for (final r in records) {
          await recents.upsert(RecentFile(
            fingerprint: r['fingerprint'] as String,
            uri: (r['uri'] as String?) ?? '',
            displayName: (r['displayName'] as String?) ?? '',
            mimeType: r['mimeType'] as String?,
            size: (r['size'] as num?)?.toInt(),
            lastOpenedAt: (r['lastOpenedAt'] as num?)?.toInt() ?? 0,
          ));
        }
        break;
    }
  }

  @override
  Map<String, Object?> exportSettings() {
    final out = <String, Object?>{};
    for (final key in SyncConstants.syncableSettingKeys) {
      final value = _readAny(key);
      if (value != null) out[key] = value;
    }
    return out;
  }

  @override
  Set<String> existingSettingKeys() {
    final out = <String>{};
    for (final key in SyncConstants.syncableSettingKeys) {
      if (_readAny(key) != null) out.add(key);
    }
    return out;
  }

  /// Reads a value of unknown type. The typed store getters throw when the
  /// stored value is a different type, so each read is guarded and we return
  /// the first type that matches. Only allow-listed (non-sensitive) keys are
  /// ever passed here.
  Object? _readAny(String key) {
    for (final read in <Object? Function()>[
      () => store.getBool(key),
      () => store.getInt(key),
      () => store.getDouble(key),
      () => store.getPlainString(key),
    ]) {
      try {
        final v = read();
        if (v != null) return v;
      } catch (_) {
        // Wrong type for this getter — try the next.
      }
    }
    return null;
  }

  @override
  Future<void> applySettings(Map<String, Object?> settings) async {
    for (final entry in settings.entries) {
      final key = entry.key;
      // Guard again: never write a non-allow-listed or sensitive key.
      if (!SyncConstants.syncableSettingKeys.contains(key)) continue;
      final v = entry.value;
      if (v is bool) {
        await store.setBool(key, v);
      } else if (v is int) {
        await store.setInt(key, v);
      } else if (v is double) {
        await store.setDouble(key, v);
      } else if (v is String) {
        await store.setPlainString(key, v);
      }
    }
  }
}
