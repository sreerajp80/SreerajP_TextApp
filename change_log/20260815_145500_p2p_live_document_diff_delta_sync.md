# Change Log: Serverless P2P Live Document Diff & Delta Sync

**Plan Reference:** `plans/20260815_145500_p2p_live_document_diff_delta_sync.md`  
**Date:** 2026-08-15  
**Author:** Antigravity  

---

## 1. Summary

Implemented **Feature 2: Serverless P2P Live Document Diff & Delta Sync** in TextData (`SreerajP_TextApp`).

This feature introduces a fully offline, zero-cloud peer-to-peer live editing and visual comparison engine. Two Android devices connected over local Wi-Fi or hotspot can now compare documents side-by-side or in unified view, highlight word-level and tabular cell-level differences, selectively resolve hunk conflicts, synchronize delta edits in real time over AES-256-GCM encrypted sockets, and persist merged outputs safely via Scoped Storage (Storage Access Framework).

---

## 2. Changes Made

### 2.1 Pure Dart Diff & Merge Subsystem (`lib/sync/diff/`)
- `lib/sync/diff/diff_models.dart`: Created core data structures including `DiffType`, `InlineSegment`, `DiffLine`, `DiffHunk`, `HunkResolution`, `TextDiffResult`, `CsvCellDiff`, `CsvRowDiff`, and `CsvDiffResult`.
- `lib/sync/diff/text_diff_engine.dart`: Built pure Dart Myers/LCS algorithm for fast text and code comparison with fine-grained word tokenization and inline diff spans.
- `lib/sync/diff/csv_diff_engine.dart`: Built 2D tabular CSV comparison engine tracking header alignment, row insertions/deletions, and individual cell changes.
- `lib/sync/diff/merge_engine.dart`: Implemented deterministic merge routines (`mergeText`, `mergeCsv`) with conflict resolution algorithms (`acceptAllLocal`, `acceptAllRemote`, `acceptNonConflicting`).
- `lib/sync/diff/diff_payload.dart`: Defined secure wire protocol payloads (`SESSION_INIT`, `DOCUMENT_OFFER`, `DELTA_UPDATE`, `HUNK_RESOLUTION_NOTIFY`, `SESSION_CLOSE`) with strict schema validation and path traversal sanitization.
- `lib/sync/diff/live_diff_controller.dart`: Built Riverpod/ChangeNotifier controller managing document comparison state, live socket broadcasting, peer notification banners, and merge outputs.
- `lib/sync/diff/diff_dialog_helper.dart`: Created `LiveDiffLauncher` helper to invoke comparison sessions from document toolbars, open tabs, local storage, or P2P peers.

### 2.2 UI & Screens (`lib/sync/ui/`)
- `lib/sync/ui/widgets/text_diff_view.dart`: Built interactive Side-by-Side and Unified text diff views with inline token coloring and per-hunk resolution toggle bars.
- `lib/sync/ui/widgets/csv_diff_view.dart`: Built 2D tabular comparison grid with cell change highlighting and row resolution actions.
- `lib/sync/ui/live_diff_screen.dart`: Built comprehensive live diff screen with top metrics pill bar, view mode segmented selector, peer notice banner, and bottom action bar.
- `lib/sync/ui/p2p_live_diff_tab.dart`: Added dedicated host tab in `SyncHostScreen` for picking local documents or open tabs and offering live diff sessions to connected peers.
- `lib/sync/ui/sync_host_screen.dart`: Integrated `P2pLiveDiffTab` as a primary navigation tab.
- `lib/sync/ui/sync_client_screen.dart`: Added `_ReceivedDiffSessionView` to accept live diff offers and match them against local files or open tabs.

### 2.3 Format Integration
- Integrated `Live P2P Diff & Sync` action in overflow menus for:
  - `lib/formats/txt/txt_toolbar.dart`
  - `lib/formats/markdown/md_toolbar.dart`
  - `lib/formats/csv/csv_toolbar.dart`
  - `lib/formats/json/json_toolbar.dart`
  - `lib/formats/xml/xml_toolbar.dart`

### 2.4 Localization
- `lib/l10n/app_en.arb`: Added English string keys and descriptions for diff actions, modes, and dialogs.
- `lib/l10n/app_ml.arb`: Added Malayalam translations for all diff and sync strings.

### 2.5 Testing & Verification
- `test/sync/diff/text_diff_engine_test.dart`: Unit tests for Myers/LCS text diffing, line insertions/deletions, modifications, and hunk grouping.
- `test/sync/diff/csv_diff_engine_test.dart`: Unit tests for tabular CSV diffing, cell change tracking, and row addition/deletion.
- `test/sync/diff/merge_engine_test.dart`: Unit tests for text merging, bulk resolution helpers, and non-conflicting auto-merge.
- `test/sync/diff/diff_payload_test.dart`: Unit tests for wire payload serialization, path traversal security, and input validation.
- `test/sync/diff/live_diff_controller_test.dart`: Unit tests for diff controller state, live updates, and merge compilation.
- `test/sync/diff/live_diff_screen_test.dart`: Widget test verifying diff screen rendering and auto-merge interactions.

---

## 3. Verification Results

- `flutter test test/sync/diff/`: 19 tests passed (0 failures).
- `flutter test`: 1144 tests passed (0 failures).
- `flutter analyze`: Clean (0 issues found).
- `dart format lib test`: Fully formatted according to Dart style guide.
