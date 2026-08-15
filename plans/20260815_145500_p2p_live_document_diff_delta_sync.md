# Serverless P2P Live Document Diff & Delta Sync

**Status:** completed

---

## 1. Overview & Goals

This plan implements **Feature 2: Serverless P2P Live Document Diff & Delta Sync** in TextData (`SreerajP_TextApp`), as specified in `docs/feature_analysis_and_roadmap.md`.

Existing mobile file-sharing tools (such as LocalSend or Syncthing) only transfer static files. TextData establishes a serverless peer-to-peer live editing and diffing session where two Android devices on the same Wi-Fi can:
1. Compare two documents side-by-side or in unified view (TXT, Markdown, CSV, JSON, and XML).
2. Compute accurate line-by-line, word-level, and tabular cell-by-cell diffs in real time with zero cloud infrastructure or Git servers.
3. Interactively resolve conflicts and selectively cherry-pick or merge edits (Local vs. Remote vs. Combined).
4. Broadcast live delta updates bidirectionally over AES-256-GCM encrypted local sockets.
5. Save the merged result back to open tabs or save as a new file through the Storage Access Framework (SAF).

---

## 2. Architecture & Design

### 2.1 Pure Dart Diff & Merge Engine (`lib/sync/diff/`)
- `lib/sync/diff/diff_models.dart`:
  - `DiffType`: `unchanged`, `added`, `deleted`, `modified`.
  - `InlineSegment`: Character- and word-level token highlights for modified lines.
  - `DiffLine`: Line representation with line numbers, text, type, and inline segments.
  - `HunkResolution`: `unresolved`, `acceptLocal`, `acceptRemote`, `acceptBoth`, `customText`.
  - `DiffHunk`: Group of adjacent diff lines with unique ID, type, resolution state, and resolved content.
  - `TextDiffResult`: Diff summary statistics, list of hunks, and line sequence.
  - `CsvCellDiff`: Column index, name, local value, remote value, change status, and resolution.
  - `CsvRowDiff`: Row status (added, deleted, modified, unchanged) and cell diffs.
  - `CsvDiffResult`: Tabular schema, row diffs, and count statistics.
  - `StructuredDiffResult`: Key-path and value diffs for JSON and XML.
- `lib/sync/diff/text_diff_engine.dart`:
  - Fast, pure Dart Myers / LCS line-diff algorithm with inline word-level diffing.
  - Generates logical `DiffHunk` chunks with context.
- `lib/sync/diff/csv_diff_engine.dart`:
  - Compares two CSV matrices.
  - Detects column header alignment, row additions/deletions, cell modifications, and conflicts.
- `lib/sync/diff/merge_engine.dart`:
  - Merges text lines based on hunk resolutions.
  - Merges CSV rows/cells based on tabular resolutions.
  - Implements auto-merge strategies (`acceptAllLocal`, `acceptAllRemote`, `acceptNonConflicting`).

### 2.2 Bidirectional P2P Live Session Protocol (`lib/sync/diff/diff_payload.dart` & `lib/sync/diff/live_diff_controller.dart`)
- `lib/sync/diff/diff_payload.dart`:
  - Encrypted wire protocol messages: `SESSION_INIT`, `DOCUMENT_OFFER`, `DELTA_UPDATE`, `HUNK_RESOLUTION_NOTIFY`, `SESSION_ACK`, `SESSION_CLOSE`.
- `lib/sync/diff/live_diff_controller.dart`:
  - `ChangeNotifier` orchestrating the live diff session:
    - Maintains local and remote document state.
    - Reactively computes diff results on content updates.
    - Tracks hunk and cell resolutions.
    - Handles live socket messaging, broadcasting delta updates and hunk decisions to the peer.
    - Provides 1-tap resolution actions and document export/save methods.

### 2.3 Interactive Material 3 UI (`lib/sync/ui/live_diff_screen.dart` & widgets)
- Accessible via:
  1. Main P2P Sync screen (`SyncHostScreen`, `SyncClientScreen`).
  2. All format overflow menus (`TxtToolbar`, `MdToolbar`, `CsvToolbar`, `JsonToolbar`, `XmlToolbar`).
- Features:
  - Header: Document name, format chip, live encrypted connection status chip, stats banner (`+add`, `-del`, `~mod`, `!conflicts`).
  - View modes:
    - **Side-by-Side (Split)**: Dual-pane synchronized scrolling for landscape/tablets.
    - **Unified Diff**: Compact unified view with diff gutters for phones.
    - **Merged Preview**: Live rendering of the resulting document as hunks are resolved.
  - Format-specific renderers:
    - **Text / Markdown**: Line numbers, gutter highlights, inline char highlights, inline hunk action buttons (`← Mine`, `Peer →`, `Both`).
    - **CSV Grid Diff**: Tabular cell grid highlighting added/deleted rows and modified cells with before/after pills.
    - **JSON / XML**: Structured path diffs & formatted syntax diffs.
  - Bottom action bar:
    - "Push Delta to Peer" (instant socket update).
    - "Accept All Mine" / "Accept All Peer" / "Auto-Merge".
    - "Save Merged Document" (write to tab or SAF picker).

### 2.4 Localization (`lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`)
- Full English and Malayalam translations for all diff actions, view modes, merge options, and status labels.

---

## 3. Files to Create and Modify

### New Files:
1. `lib/sync/diff/diff_models.dart` — Core diff data models, hunk models, and result classes.
2. `lib/sync/diff/text_diff_engine.dart` — Pure Dart line & inline token diff engine.
3. `lib/sync/diff/csv_diff_engine.dart` — Pure Dart CSV tabular cell & row diff engine.
4. `lib/sync/diff/merge_engine.dart` — Conflict resolution and 2-way merge engine.
5. `lib/sync/diff/diff_payload.dart` — Wire payload serialization for live diff sessions.
6. `lib/sync/diff/live_diff_controller.dart` — Live diff session controller and state orchestration.
7. `lib/sync/ui/live_diff_screen.dart` — Main live diff & delta sync workspace UI.
8. `lib/sync/ui/widgets/text_diff_view.dart` — Side-by-side & unified text diff widget.
9. `lib/sync/ui/widgets/csv_diff_view.dart` — Tabular CSV grid diff widget.
10. `test/sync/diff/text_diff_engine_test.dart` — Text diff unit tests.
11. `test/sync/diff/csv_diff_engine_test.dart` — CSV diff unit tests.
12. `test/sync/diff/merge_engine_test.dart` — Merge engine unit tests.
13. `test/sync/diff/diff_payload_test.dart` — Payload serialization unit tests.
14. `test/sync/diff/live_diff_controller_test.dart` — Session controller unit tests.
15. `test/sync/diff/live_diff_screen_test.dart` — Widget test for Live Diff UI.

### Modified Files:
1. `lib/sync/sync_constants.dart` — Add diff payload constants.
2. `lib/sync/ui/sync_host_screen.dart` — Add Live Diff session entry point tab.
3. `lib/sync/ui/sync_client_screen.dart` — Add Live Diff session reception flow.
4. `lib/formats/txt/txt_toolbar.dart` — Add "Live P2P Diff & Sync" menu action.
5. `lib/formats/md/md_toolbar.dart` — Add "Live P2P Diff & Sync" menu action.
6. `lib/formats/csv/csv_toolbar.dart` — Add "Live P2P Diff & Sync" menu action.
7. `lib/formats/json/json_toolbar.dart` — Add "Live P2P Diff & Sync" menu action.
8. `lib/formats/xml/xml_toolbar.dart` — Add "Live P2P Diff & Sync" menu action.
9. `lib/l10n/app_en.arb` — Add English strings.
10. `lib/l10n/app_ml.arb` — Add Malayalam strings.
11. `docs/feature_analysis_and_roadmap.md` — Update Feature 2 status in roadmap.

---

## 4. Verification Plan

### Automated Tests:
- `flutter test test/sync/diff/text_diff_engine_test.dart`
- `flutter test test/sync/diff/csv_diff_engine_test.dart`
- `flutter test test/sync/diff/merge_engine_test.dart`
- `flutter test test/sync/diff/diff_payload_test.dart`
- `flutter test test/sync/diff/live_diff_controller_test.dart`
- `flutter test test/sync/diff/live_diff_screen_test.dart`
- `flutter test`
- `flutter analyze`
- `dart format lib test`
