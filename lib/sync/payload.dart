// Phase 12 — P2P LAN sync: build, validate, and merge the sync payload.
//
// EVERY payload is treated as hostile (security-rules; architecture.md §9.4):
//   * [validateAndParse] parses, checks the app id / version / mode, enforces
//     caps (max records per category, per-field length, settings count), and
//     drops any setting key that is not on the allow-list — all BEFORE the data
//     touches the database.
//   * [mergeRecords] / [mergeSettings] are ADD-ONLY, CLIENT-WINS: the receiver
//     never has its own data overwritten. Full sync applies all settings;
//     incremental applies settings fill-only (only keys the receiver lacks).
//
// The merge logic is pure (it works over sets of existing keys), so it is fully
// unit-testable with no database. The provider fetches existing keys from the
// repositories, calls these functions, then writes only the records they say to
// add.
//
// Nothing here logs payload contents (security-rules).
library;

import 'dart:convert';

import 'sync_constants.dart';

/// Thrown when a payload is malformed or breaks a cap. User-safe message.
class PayloadException implements Exception {
  final String message;
  const PayloadException(this.message);
  @override
  String toString() => 'PayloadException: $message';
}

/// A parsed, validated payload. [records] maps a category key to its list of
/// record objects; a category is present ONLY if it was part of this sync, so
/// the receiver can tell "0 sent" from "not included". [settings] holds only
/// allow-listed non-sensitive keys.
class SyncPayload {
  final String syncMode;
  final Map<String, List<Map<String, Object?>>> records;
  final Map<String, Object?> settings;

  const SyncPayload({
    required this.syncMode,
    required this.records,
    required this.settings,
  });

  bool get isFull => syncMode == SyncConstants.syncModeFull;

  Map<String, Object?> toJson() => {
        SyncConstants.keyApp: SyncConstants.appId,
        SyncConstants.keyPayloadVersion: SyncConstants.payloadVersion,
        SyncConstants.keySyncMode: syncMode,
        SyncConstants.keyRecords: records,
        SyncConstants.keySettings: settings,
      };

  /// One-line JSON string ready to be sealed and sent.
  String toWireJson() => jsonEncode(toJson());

  /// Builds a payload from already-fetched data. Only the [categories] listed
  /// are included; [settings] must already be filtered to the allow-list (the
  /// builder filters again as a guard).
  static SyncPayload build({
    required String syncMode,
    required List<String> categories,
    required Map<String, List<Map<String, Object?>>> recordsByCategory,
    required Map<String, Object?> settings,
  }) {
    if (syncMode != SyncConstants.syncModeFull &&
        syncMode != SyncConstants.syncModeIncremental) {
      throw PayloadException('Unknown sync mode: $syncMode');
    }
    final records = <String, List<Map<String, Object?>>>{};
    for (final c in categories) {
      if (!SyncConstants.allCategories.contains(c)) {
        throw PayloadException('Unknown category: $c');
      }
      records[c] = recordsByCategory[c] ?? const [];
    }
    // Guard: never let a non-allow-listed or sensitive key into settings.
    final safeSettings = <String, Object?>{};
    for (final entry in settings.entries) {
      if (SyncConstants.neverSyncKeys.contains(entry.key)) {
        throw PayloadException('Refusing to sync a protected key.');
      }
      if (SyncConstants.syncableSettingKeys.contains(entry.key)) {
        safeSettings[entry.key] = entry.value;
      }
    }
    return SyncPayload(
      syncMode: syncMode,
      records: records,
      settings: safeSettings,
    );
  }

  /// Parses and validates a received JSON string, treating it as hostile.
  static SyncPayload validateAndParse(String json) {
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } catch (_) {
      throw const PayloadException('The received data was not valid.');
    }
    if (decoded is! Map<String, Object?>) {
      throw const PayloadException('The received data had the wrong shape.');
    }
    final map = decoded;

    if (map[SyncConstants.keyApp] != SyncConstants.appId) {
      throw const PayloadException('This data is from a different app.');
    }
    final version = map[SyncConstants.keyPayloadVersion];
    if (version is! int || version > SyncConstants.payloadVersion) {
      throw const PayloadException('This data is a newer, unsupported version.');
    }
    final mode = map[SyncConstants.keySyncMode];
    if (mode != SyncConstants.syncModeFull &&
        mode != SyncConstants.syncModeIncremental) {
      throw const PayloadException('The data has an unknown sync mode.');
    }

    // Records: only known categories, capped counts, capped field lengths.
    final records = <String, List<Map<String, Object?>>>{};
    final rawRecords = map[SyncConstants.keyRecords];
    if (rawRecords != null) {
      if (rawRecords is! Map<String, Object?>) {
        throw const PayloadException('The records section was malformed.');
      }
      for (final entry in rawRecords.entries) {
        if (!SyncConstants.allCategories.contains(entry.key)) {
          // Unknown category — ignore it rather than fail the whole sync.
          continue;
        }
        final list = entry.value;
        if (list is! List) {
          throw PayloadException('The "${entry.key}" records were malformed.');
        }
        if (list.length > SyncConstants.maxRecordsPerCategory) {
          throw PayloadException('Too many "${entry.key}" records.');
        }
        final parsed = <Map<String, Object?>>[];
        for (final item in list) {
          if (item is! Map<String, Object?>) {
            throw PayloadException('A "${entry.key}" record was malformed.');
          }
          _checkFieldLengths(item, entry.key);
          parsed.add(item);
        }
        records[entry.key] = parsed;
      }
    }

    // Settings: keep only allow-listed keys, capped count, no sensitive keys.
    final settings = <String, Object?>{};
    final rawSettings = map[SyncConstants.keySettings];
    if (rawSettings != null) {
      if (rawSettings is! Map<String, Object?>) {
        throw const PayloadException('The settings section was malformed.');
      }
      if (rawSettings.length > SyncConstants.maxSettingsEntries) {
        throw const PayloadException('Too many settings.');
      }
      for (final entry in rawSettings.entries) {
        if (SyncConstants.neverSyncKeys.contains(entry.key)) {
          // A hostile payload trying to push a protected key — reject outright.
          throw const PayloadException('The data tried to change protected settings.');
        }
        if (!SyncConstants.syncableSettingKeys.contains(entry.key)) {
          continue; // silently drop anything not on the allow-list
        }
        final v = entry.value;
        if (v is String && v.length > SyncConstants.maxFieldLength) {
          throw const PayloadException('A setting value was too long.');
        }
        settings[entry.key] = v;
      }
    }

    return SyncPayload(
      syncMode: mode as String,
      records: records,
      settings: settings,
    );
  }

  static void _checkFieldLengths(Map<String, Object?> record, String category) {
    for (final v in record.values) {
      if (v is String && v.length > SyncConstants.maxFieldLength) {
        throw PayloadException('A "$category" field was too long.');
      }
    }
  }
}

/// The natural key each category merges on. Two records with the same natural
/// key are "the same record" for add-only merge.
class NaturalKey {
  NaturalKey._();

  static String? of(String category, Map<String, Object?> record) {
    switch (category) {
      case SyncConstants.categoryFavorites:
      case SyncConstants.categoryRecents:
        final fp = record['fingerprint'];
        return fp is String && fp.isNotEmpty ? fp : null;
      case SyncConstants.categoryBookmarks:
        final fp = record['fingerprint'];
        final pos = record['position'];
        final label = record['label'];
        if (fp is String && fp.isNotEmpty && pos is num) {
          return '$fp|$pos|${label ?? ''}';
        }
        return null;
      default:
        return null;
    }
  }
}

/// The outcome of merging one category: which records to add, and the counts
/// for the summary UI.
class RecordMergeResult {
  final List<Map<String, Object?>> toAdd;
  final int added;
  final int kept; // already present on the receiver, left untouched

  const RecordMergeResult({
    required this.toAdd,
    required this.added,
    required this.kept,
  });
}

/// The outcome of merging settings.
class SettingsMergeResult {
  final Map<String, Object?> toApply;
  final int applied;
  final int kept;

  const SettingsMergeResult({
    required this.toApply,
    required this.applied,
    required this.kept,
  });
}

/// Pure add-only merge. Given the incoming [records] for a [category] and the
/// [existingKeys] the receiver already has, returns only the records to add.
/// Records with a null natural key are skipped as malformed.
RecordMergeResult mergeRecords({
  required String category,
  required List<Map<String, Object?>> records,
  required Set<String> existingKeys,
}) {
  final toAdd = <Map<String, Object?>>[];
  final seen = <String>{...existingKeys};
  var kept = 0;
  for (final record in records) {
    final key = NaturalKey.of(category, record);
    if (key == null) continue; // malformed — skip
    if (seen.contains(key)) {
      kept++;
      continue; // client-wins: receiver keeps its own
    }
    seen.add(key);
    toAdd.add(record);
  }
  return RecordMergeResult(toAdd: toAdd, added: toAdd.length, kept: kept);
}

/// Pure settings merge. Full sync applies every incoming setting (overwrite);
/// incremental applies fill-only (only keys the receiver does not already
/// have). Never returns a sensitive key (they are filtered at parse time).
SettingsMergeResult mergeSettings({
  required Map<String, Object?> incoming,
  required Set<String> existingKeys,
  required bool isFull,
}) {
  final toApply = <String, Object?>{};
  var kept = 0;
  for (final entry in incoming.entries) {
    if (!SyncConstants.syncableSettingKeys.contains(entry.key)) continue;
    if (!isFull && existingKeys.contains(entry.key)) {
      kept++; // fill-only: the receiver already set this — keep it
      continue;
    }
    toApply[entry.key] = entry.value;
  }
  return SettingsMergeResult(
    toApply: toApply,
    applied: toApply.length,
    kept: kept,
  );
}
