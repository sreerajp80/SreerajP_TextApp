import 'document_tab.dart';

/// What to do when the user opens a document past the tab cap (architecture.md
/// §8.3, task 2.6).
enum OverLimitBehavior {
  /// Silently close the least-recently-used tab to make room.
  closeLeastRecentlyUsed,

  /// Ask the user what to close.
  ask;

  String get label {
    switch (this) {
      case OverLimitBehavior.closeLeastRecentlyUsed:
        return 'Close least-recently-used';
      case OverLimitBehavior.ask:
        return 'Ask me';
    }
  }

  String get prefValue => name;

  static OverLimitBehavior fromPrefValue(String? value) {
    for (final b in OverLimitBehavior.values) {
      if (b.prefValue == value) return b;
    }
    return OverLimitBehavior.closeLeastRecentlyUsed;
  }
}

/// Picks the tab to close when [tabs] is at or above [cap] and one more must
/// open. Returns the least-recently-used **closable** tab, or `null` if none can
/// be closed.
///
/// A tab with unsaved edits is never chosen — it must not be closed silently
/// (CLAUDE.md §3.6). Pure and side-effect free so it is unit-tested on its own.
DocumentTab? pickLruClosable(List<DocumentTab> tabs, int cap) {
  if (cap <= 0) return null;
  if (tabs.length < cap) return null; // room to spare, nothing to close

  DocumentTab? lru;
  for (final tab in tabs) {
    if (tab.isDirty) continue; // never auto-close unsaved work
    if (lru == null || tab.lastActiveAt < lru.lastActiveAt) {
      lru = tab;
    }
  }
  return lru;
}
