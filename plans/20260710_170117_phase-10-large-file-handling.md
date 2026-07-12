# Plan — Phase 10: Large-file handling

**Status:** completed

Plan for Phase 10 in [implementation-plan.md](../docs/implementation-plan.md)
(tasks 10.1, 10.2, 10.3). Chosen approach: **Way 1 (pragmatic, no new Android
code)** — confirmed by the user. All work is in Dart and can be tested here.

---

## 1. What the issue is

Today every format opens a file by reading the **whole file into memory at once**
(`SafService.readBytes` → the session decodes and parses all of it). This is fine
for small files but risky for very big ones (target limit ~50 MB, arch §11):

- A huge file can use too much memory and make the app slow or crash.
- There is no "this file is too big to edit" path — a big structured file (CSV
  grid, JSON tree, XML DOM) tries to build its full heavy model every time.
- Background tabs keep all their heavy state in memory even when not shown.

Phase 10 must:
- keep memory bounded up to ~50 MB and **never crash** above it (CLAUDE.md §3.4),
- above the limit, show a **raw, paged, view-only** mode with a clear notice that
  editing is off (task 10.2),
- let **background tabs release heavy state and rebuild** on return (task 10.3).

**Way 1 limit (accepted):** the raw bytes are still read whole once. Phase 10
bounds the *heavy work* (parsing, grid/tree building, editor controller) and the
*rendering*, and stops oversized files from building heavy models. True
read-only-from-disk streaming (native ranged read) is **deferred** and noted as a
follow-up. This matches how earlier phases deferred native items (XSD, on-device
SAF checks).

Note: on-screen **rendering is already virtualized** (re_editor, CSV
`TableView.builder`, lazy trees), so task 10.1's "render only visible rows" is
already met; the gap Phase 10 closes is *memory / heavy parsing*, handled by the
size gate below.

---

## 2. The plan for the fix

### 2.1 Shared size policy (core) — foundation for 10.1 / 10.2

A small pure module that decides how to open a file from its size:

- `FileSizeClass { normal, large, oversized }`.
- Thresholds as named constants (one place to tune):
  - `largeThresholdBytes` (~5 MB) — still fully editable, just a hint band.
  - `oversizedThresholdBytes` (~50 MB) — open in degraded view-only mode.
- `classifyBySize(int? sizeBytes)` → a `FileSizeClass`. Unknown size (`null`)
  → `normal` (we cannot gate what we cannot measure; documented).
- A tiny helper `isOversized(int? sizeBytes)` for the workspace.

Pure and fully unit-tested.

### 2.2 Degraded, paged, view-only mode (task 10.2)

One **shared** widget used by all five formats, wired at a **single chokepoint**
(the tabs workspace body), so no per-format editor code changes:

- A pure paginator helper `PagedText`: given decoded text, build page boundaries
  (by a fixed line count per page, e.g. 500 lines) and return a requested page's
  text plus page count. Testable with no widgets.
- `DegradedDocumentView` widget:
  - reads the file bytes once, decodes with the existing `TextCodecService`
    (never throws — friendly failed state on error),
  - shows the current page in a read-only `SelectableText` inside a scroll view,
  - a **prev / next + "Page X of N"** control and a jump-to-page field,
  - a clear top banner: "This file is large. It is open in read-only mode; editing
    is turned off." (idea Risks, arch §11),
  - never crashes on bad/empty input.

Wiring (single place, `tabs_workspace.dart`):
- `_DocumentBody`: if `isOversized(tab.size)` → show `DegradedDocumentView` instead
  of the format view. This means the heavy format session is **never created** for
  an oversized file — that is what bounds memory/parsing.
- `_DocumentToolbar`: for an oversized tab, show a minimal bar (read-only lock +
  file info) instead of the format editor toolbar.

### 2.3 Background tab memory release / rebuild (task 10.3)

- Pure policy `pickReleasableSessions(...)`: given the active tab id, the open tab
  ids in most-recent order, the set of **dirty** tab ids, and a keep-alive budget,
  return the clean, non-active, least-recently-used sessions to release beyond the
  budget. **Dirty tabs are never released** (edits are never lost — CLAUDE.md §3.6).
- Wire into `tabs_workspace.dart`: alongside the existing `retainOnly(openIds)`
  (which frees *closed* tabs), add a call that releases heavy state for clean
  *background* tabs beyond the budget. Each format session manager already exposes
  `release(id)` / `peek(id)`; a released session is re-created and re-`load()`ed by
  `sessionForm` when the user returns to that tab (rebuild-from-file). Reading
  position is already persisted on session dispose.
- Keep-alive budget derived from the existing tab-cap helper (device RAM aware),
  with a safe minimum (always keep the active tab + a couple of recents).

### 2.4 Progress doc

Update [implementation-progress.md](../docs/implementation-progress.md): set
Phase 10 rows to ✅ with notes and the change-log filename; update the summary
table (Phase 10 → Done 3/3; totals 63/86).

---

## 3. Files to be changed

**New (source):**
- `lib/core/large_file/large_file_policy.dart` — size classes, thresholds,
  `classifyBySize` / `isOversized`.
- `lib/core/large_file/paged_text.dart` — pure paginator.
- `lib/shell/tabs/degraded_document_view.dart` — shared paged read-only view.
- `lib/shell/tabs/session_retention.dart` — pure `pickReleasableSessions`.

**Changed (source):**
- `lib/shell/tabs/tabs_workspace.dart` — route oversized tabs to the degraded
  view + minimal toolbar; call the background-release policy.
- (If needed) a shared interface so the workspace can call `release`/`peek`/dirty
  across the five session managers without new coupling — will reuse the existing
  per-manager methods; add a tiny ` SessionManager` marker only if it reduces
  duplication.

**New (tests):**
- `test/core/large_file/large_file_policy_test.dart` — size → class boundaries,
  null size, `isOversized`.
- `test/core/large_file/paged_text_test.dart` — page count, slicing, empty text,
  last partial page.
- `test/shell/tabs/session_retention_test.dart` — LRU choice; dirty never picked;
  budget respected; active kept.
- `test/shell/tabs/degraded_document_view_test.dart` — widget: banner shown,
  page control moves pages, read-only (no editor), friendly state on decode fail.

**Changed (docs):**
- `docs/implementation-progress.md` — Phase 10 status + summary table.

---

## 4. How we know it is done (acceptance)

- Opening a file **over ~50 MB** shows the degraded paged read-only view with the
  "editing is off" notice and never crashes; paging works; small files are
  unchanged and still fully editable. (10.1, 10.2)
- Background clean tabs beyond the keep-alive budget drop their heavy state and
  rebuild from the file when re-shown; a **dirty** background tab is never
  released. (10.3)
- `flutter analyze` clean; `flutter test` green (new unit + widget tests pass).
- Owed (documented, not blocking): a manual on-device pass with a real large file,
  and true from-disk streaming as a later native follow-up.

---

## 5. Out of scope (deferred, noted)

- Native ranged/streaming read (Way 2) — deferred; raw bytes still read whole once.
- Per-format partial parsing/editing of oversized files — degraded mode is
  view-only by design.
