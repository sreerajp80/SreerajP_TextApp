/// How a document is being shown in its tab. Real formats add their own modes in
/// later phases; the shell only needs a stable per-tab value to remember.
enum TabViewMode { view, edit }

/// One open document in the multi-document workspace (architecture.md §5).
///
/// Each tab keeps its **own** view state — scroll position, unsaved-edits flag,
/// read-only lock, and view mode — so tabs never share state (task 2.5). The
/// real per-format viewer/editor (Phase 3/4) reads and updates these fields; for
/// now a placeholder view shows the file details.
class DocumentTab {
  /// Stable id for this open instance (not the fingerprint — the same file may
  /// in principle be opened again).
  final String id;

  /// Content fingerprint (size + hash) — the file identity (Phase 1.2).
  final String fingerprint;

  /// Persisted SAF URI, the fast path back to the file (Phase 1.1).
  final String uri;

  final String displayName;
  final String? mimeType;
  final int? size;

  /// Remembered reading position (keyed to the file elsewhere; mirrored here for
  /// the live tab).
  final int scrollPosition;

  /// True when the tab holds unsaved edits. Nothing sets this in Phase 2 (there
  /// is no editor yet); the close guards already respect it so an unsaved tab is
  /// never closed silently (CLAUDE.md §3.6).
  final bool isDirty;

  /// Per-file read-only lock (Phase 3.8 wires the toggle; the field lives here).
  final bool isReadOnly;

  final TabViewMode viewMode;

  /// Epoch millis of the last time this tab was the active one. Drives the
  /// least-recently-used choice when the tab cap is exceeded (task 2.6).
  final int lastActiveAt;

  const DocumentTab({
    required this.id,
    required this.fingerprint,
    required this.uri,
    required this.displayName,
    this.mimeType,
    this.size,
    this.scrollPosition = 0,
    this.isDirty = false,
    this.isReadOnly = false,
    this.viewMode = TabViewMode.view,
    required this.lastActiveAt,
  });

  DocumentTab copyWith({
    int? scrollPosition,
    bool? isDirty,
    bool? isReadOnly,
    TabViewMode? viewMode,
    int? lastActiveAt,
  }) {
    return DocumentTab(
      id: id,
      fingerprint: fingerprint,
      uri: uri,
      displayName: displayName,
      mimeType: mimeType,
      size: size,
      scrollPosition: scrollPosition ?? this.scrollPosition,
      isDirty: isDirty ?? this.isDirty,
      isReadOnly: isReadOnly ?? this.isReadOnly,
      viewMode: viewMode ?? this.viewMode,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }
}
