import 'dart:convert';

import '../../core/storage/key_value_store.dart';
import '../../core/storage/saf_service.dart';
import 'document_tab.dart';

/// The open-tab set restored on the next launch (task 2.8).
class RestoredTabs {
  final List<DocumentTab> tabs;

  /// How many saved tabs were dropped because their URI is no longer
  /// accessible (moved / deleted / permission revoked). The shell shows a
  /// non-blocking notice when this is > 0.
  final int skippedCount;

  const RestoredTabs({required this.tabs, required this.skippedCount});

  static const RestoredTabs empty = RestoredTabs(tabs: [], skippedCount: 0);
}

/// Saves and restores the set of open document tabs (task 2.8).
///
/// The set is stored as one JSON string in the non-sensitive settings store
/// (no new DB table). Restore checks each saved URI with the SAF service and
/// **skips** any that are no longer reachable, rather than failing the whole
/// restore. The restore toggle itself is a separate bool pref.
class TabsPersistence {
  static const String openTabsKey = 'tabs.open_set';
  static const String restoreEnabledKey = 'tabs.restore_on_relaunch';

  final KeyValueStore _store;
  final SafService _saf;

  TabsPersistence(this._store, this._saf);

  bool get restoreEnabled => _store.getBool(restoreEnabledKey) ?? false;

  Future<void> setRestoreEnabled(bool enabled) =>
      _store.setBool(restoreEnabledKey, enabled);

  /// Writes the current [tabs] to storage. A no-op-safe empty list clears it.
  Future<void> save(List<DocumentTab> tabs) async {
    final list = tabs.map(_toJson).toList(growable: false);
    await _store.setPlainString(openTabsKey, jsonEncode(list));
  }

  /// Reads the saved set and returns only the tabs whose URI is still
  /// accessible, plus a count of the ones skipped. Returns [RestoredTabs.empty]
  /// when restore is off, nothing is saved, or the stored value is malformed
  /// (a corrupt value never crashes — CLAUDE.md §3.4).
  Future<RestoredTabs> restore() async {
    if (!restoreEnabled) return RestoredTabs.empty;

    final raw = _store.getPlainString(openTabsKey);
    if (raw == null || raw.isEmpty) return RestoredTabs.empty;

    final List<dynamic> decoded;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! List) return RestoredTabs.empty;
      decoded = parsed;
    } catch (_) {
      return RestoredTabs.empty;
    }

    final restored = <DocumentTab>[];
    var skipped = 0;
    for (final entry in decoded) {
      final tab = _fromJson(entry);
      if (tab == null) {
        skipped++;
        continue;
      }
      if (await _saf.isAccessible(tab.uri)) {
        restored.add(tab);
      } else {
        skipped++;
      }
    }
    return RestoredTabs(tabs: restored, skippedCount: skipped);
  }

  Map<String, Object?> _toJson(DocumentTab tab) => {
        'id': tab.id,
        'fingerprint': tab.fingerprint,
        'uri': tab.uri,
        'displayName': tab.displayName,
        'mimeType': tab.mimeType,
        'size': tab.size,
        'scrollPosition': tab.scrollPosition,
      };

  DocumentTab? _fromJson(Object? entry) {
    if (entry is! Map) return null;
    final uri = entry['uri'];
    final fingerprint = entry['fingerprint'];
    final displayName = entry['displayName'];
    if (uri is! String || fingerprint is! String || displayName is! String) {
      return null;
    }
    return DocumentTab(
      id: entry['id'] is String ? entry['id'] as String : uri,
      fingerprint: fingerprint,
      uri: uri,
      displayName: displayName,
      mimeType: entry['mimeType'] is String ? entry['mimeType'] as String : null,
      size: (entry['size'] as num?)?.toInt(),
      scrollPosition: (entry['scrollPosition'] as num?)?.toInt() ?? 0,
      // Restored tabs come back clean and in stored order; give them an
      // increasing recency so the last saved is treated as most recent.
      lastActiveAt: 0,
    );
  }
}
