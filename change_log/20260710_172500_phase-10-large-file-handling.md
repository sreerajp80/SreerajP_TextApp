# Change log — Phase 10: Large-file handling

**Implements:** [plans/20260710_170117_phase-10-large-file-handling.md](../plans/20260710_170117_phase-10-large-file-handling.md)
**Date:** 2026-07-10
**Approach:** Way 1 (pragmatic size-gate, no new Android code) — user decision.

---

## What changed and why

Before this change, every format opened a file by reading the **whole file into
memory** and building its full heavy model (decoded text, parsed grid/tree/DOM,
editor controller). A very large file (target limit ~50 MB, arch §11) could use
too much memory and make the app slow or crash. There was also no "too big to
edit" path, and background tabs kept all their heavy state loaded.

Phase 10 adds a size-based safety gate, a degraded read-only view for oversized
files, and background memory release — all in Dart (Way 1), so it is fully
testable here.

## New source files

- `lib/core/large_file/large_file_policy.dart` — pure `LargeFilePolicy`:
  `FileSizeClass` (normal / large / oversized), thresholds (`largeThresholdBytes`
  ~5 MB, `oversizedThresholdBytes` ~50 MB), `classifyBySize` / `isOversized`.
  Unknown size → normal (documented Way-1 limit).
- `lib/core/large_file/paged_text.dart` — pure `PagedText`: splits decoded text
  into fixed-size pages of lines using a line-start index (no per-page copies);
  handles empty text, trailing newline, and page-index clamping.
- `lib/shell/tabs/degraded_document_view.dart` — shared read-only paged view for
  oversized files: reads bytes once, decodes with the shared codec, shows one
  page at a time with prev/next + jump, a "large file — editing off" banner, and
  a friendly failure state (never crashes). Holds no session/editor, so it is
  naturally cheap to drop and rebuild.
- `lib/shell/tabs/session_retention.dart` — pure `pickReleasableSessions`: keeps
  the most-recently-used sessions up to a budget; beyond it, releases clean,
  non-active sessions; **never** releases the active or a dirty tab (edits are
  never lost — CLAUDE.md §3.6).

## Changed source files

- `lib/shell/tabs/tabs_workspace.dart`
  - `_DocumentBody`: an oversized tab (`LargeFilePolicy.isOversized(tab.size)`)
    now opens `DegradedDocumentView` instead of the heavy format view — so the
    heavy session is never even created.
  - `_DocumentToolbar`: an oversized tab shows the minimal (read-only) toolbar.
  - `build`: after the existing `retainOnly` (frees closed tabs), calls the new
    `_releaseBackgroundSessions`, which applies `pickReleasableSessions` across
    all five session managers (budget `_maxLoadedSessions = 3`) and releases the
    chosen background tabs. They rebuild from the file when shown again.
- `lib/formats/{txt,markdown,json,csv,xml}/*_session_manager.dart` — each gains
  `Iterable<String> get liveIds` so the workspace can see which tabs hold heavy
  state.

## Tests added

- `test/core/large_file/large_file_policy_test.dart` — size → class boundaries,
  null/negative size, `isOversized`.
- `test/core/large_file/paged_text_test.dart` — page count/slicing, empty text,
  trailing-newline handling, round-trip, clamping, `firstLineNumber`.
- `test/shell/tabs/session_retention_test.dart` — LRU release beyond budget,
  active never released, dirty never released, budget clamping, unknown ids.
- `test/shell/tabs/degraded_document_view_test.dart` — banner + first page,
  page navigation, read-only (only the page-jump field is editable), friendly
  failure on read error.

## Verification

- `flutter analyze` — no issues.
- `flutter test` — all 428 tests pass (23 new Phase 10 tests included).

## Known limits / owed

- Raw bytes are still read whole once (Way 1). True from-disk streaming via a
  native ranged read is deferred as a later follow-up.
- One manual on-device pass with a real >50 MB file is owed (open in degraded
  paged mode, page through, confirm editing is off and no crash).
