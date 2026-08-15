# Feature 11 — Workspace-Wide SQLite FTS5 Full-Text Search Indexer

**Status:** completed

Plan for: `docs/feature_analysis_and_roadmap.md` §3, Feature 11
(Workspace-Wide SQLite FTS5 Full-Text Search Indexer — Ecosystem Synergy).

---

## 1. What we want

Right now search only works **inside one open document** (`lib/core/search/text_search.dart`
and the per-format find panels). There is no way to ask "which of my files mentions
this word?".

This feature adds an offline, on-device **full-text index** of the files the user
already knows about (recent files and favorites), and one **search screen** that
searches across all of them at once, shows a highlighted snippet per hit, and opens
the file in a tab on tap.

Everything stays local. No network, no new permission, no new heavy package. It uses
SQLite FTS5, which is already inside the `sqflite` we ship.

---

## 2. The issue / gaps to solve

1. There is no table that stores document text for cross-file search.
2. Nothing writes to such an index when a file is opened or saved.
3. There is no UI to run a workspace-wide search.
4. Old index rows must not pile up (removed recents, cleared list, huge files).
5. FTS5 is present on Android 8.0+ SQLite, but we must not crash if a device build
   lacks it, and the host test runner must behave the same way.

---

## 3. Design

### 3.1 Where the data lives

Bump `AppDatabase.version` 1 → 2 and add, in a v2 migration (and in fresh v1 create):

```sql
CREATE TABLE search_docs (           -- one row per indexed file (metadata only)
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  fingerprint   TEXT NOT NULL UNIQUE,
  uri           TEXT NOT NULL,
  display_name  TEXT NOT NULL,
  format        TEXT NOT NULL,       -- txt | md | json | csv | xml | other
  size          INTEGER,
  indexed_at    INTEGER NOT NULL,
  pinned        INTEGER NOT NULL DEFAULT 0   -- 1 = favorite, kept when recents clear
);

CREATE VIRTUAL TABLE search_fts USING fts5(
  body,
  content='',                       -- we manage rows ourselves
  tokenize='unicode61 remove_diacritics 2'
);

-- "trigger on save": deleting the doc row always cleans the FTS row.
CREATE TRIGGER search_docs_ad AFTER DELETE ON search_docs BEGIN
  INSERT INTO search_fts(search_fts, rowid, body) VALUES ('delete', old.id, '');
END;
```

`search_fts.rowid` equals `search_docs.id`, so a hit maps straight back to its file.

**FTS5 fallback.** The `CREATE VIRTUAL TABLE` runs inside a `try`. If the device's
SQLite has no FTS5, we instead create a plain `search_body(doc_id, body)` table and
set `AppDatabase.ftsAvailable = false`. The repository then searches with `LIKE` and
builds the snippet in Dart. Same feature, slower, never a crash.

### 3.2 What text goes in

A small service `SearchIndexService`:

- Decodes bytes with the existing `TextCodecService` (never throws).
- Indexes the **raw text** of the file for every supported format (txt, md, json,
  csv, xml). Raw text is what the user typed, so it matches what they remember.
- Skips a file when:
  - it is oversized (`LargeFilePolicy.isOversized`, ≥ 50 MB), or
  - it sniffs as binary (`txt_content_sniff.dart` helper), or
  - the workspace-index setting is off.
- Caps stored body at **2 MB of text** per file (longer files are indexed up to the
  cap; the UI says the file was indexed partly).

### 3.3 When indexing happens

| Trigger | Where |
|---|---|
| A file is opened (bytes already in hand) | `lib/shell/open_file_action.dart` |
| A save succeeds (`SaveOutcome.saved`) | new `onSaved` callback on each of the 5 document sessions, wired in each session manager |
| A recent is removed / recents cleared | `lib/shell/home/recents_controller.dart` → drop index row unless `pinned` |
| Favorite added/removed | `FavoritesRepository` callers → set/clear `pinned` |
| Backfill of files never indexed | bounded background pass at startup: favorites first, then the 20 newest recents, skipping anything already indexed, one file at a time with `await` gaps so the UI stays smooth |

Indexing is always best-effort: any failure is swallowed into a debug-safe log and the
open/save flow continues unchanged. No file contents ever reach a log.

### 3.4 Searching

`SearchIndexRepository.search(query, {formats, limit})`:

- Sanitises the user's text into a safe FTS5 query: split on whitespace, strip FTS
  operators, wrap each term in double quotes, add `*` to the last term for
  as-you-type prefix matching.
- Runs `SELECT ... FROM search_fts JOIN search_docs ... WHERE search_fts MATCH ?
  ORDER BY bm25(search_fts)` with `snippet(search_fts, 0, char(2), char(3), '…', 12)`.
  The two control characters are internal markers, converted to highlight spans in
  the widget (never shown to the user).
- Returns `SearchHit(fingerprint, uri, displayName, format, snippet, matchCount)`.

### 3.5 UI

New screen `lib/shell/search/workspace_search_screen.dart`, opened from a search icon
in the Home app bar (and from the empty state hint):

- Search field at the top, debounced ~250 ms.
- Format filter chips (All / TXT / MD / JSON / CSV / XML).
- Result list: file icon, file name, highlighted snippet, "unavailable" mark when the
  SAF URI no longer resolves.
- Tap a hit → the existing `OpenFileAction.openRecent`-style flow opens the file as a
  tab and jumps to the Editor destination.
- Empty states: nothing typed, no results, indexing off.

Settings › Files & Tabs gets two rows: a **Workspace search index** on/off switch
(default on) and **Rebuild index** / **Clear index** actions.

All strings go through `AppLocalizations` (`app_en.arb` + `app_ml.arb`).

### 3.6 Privacy & security

- The index holds file text in the app's private database — the same place drafts
  already live. No new permission, no export, nothing leaves the device.
- Snippets are never logged. `clear index` really deletes the rows and runs
  `VACUUM`-free `DELETE`, plus `INSERT INTO search_fts(search_fts) VALUES('delete-all')`.
- The switch off + clear gives the user a full opt-out.
- Docs updated so the stored-text decision is written down, not hidden.

---

## 4. Files to change / add

**New**

- `lib/core/index/search_index_models.dart` — `IndexedDoc`, `SearchHit`, `IndexFormat`.
- `lib/core/index/search_index_repository.dart` — FTS5 (or LIKE fallback) CRUD + query.
- `lib/core/index/search_index_service.dart` — eligibility, decode, cap, index/remove.
- `lib/core/index/search_index_backfill.dart` — bounded startup backfill.
- `lib/core/index/index_providers.dart` — Riverpod providers.
- `lib/shell/search/workspace_search_controller.dart` — query state, debounce, filters.
- `lib/shell/search/workspace_search_screen.dart` — the search UI.
- `lib/shell/search/search_hit_tile.dart` — one result row + snippet highlighting.
- `test/core/index/search_index_repository_test.dart`
- `test/core/index/search_index_service_test.dart`
- `test/shell/search/workspace_search_screen_widget_test.dart`

**Changed**

- `lib/core/storage/app_database.dart` — version 2, new schema + migration + FTS5 probe.
- `lib/core/storage/storage_providers.dart` — expose the new repository.
- `lib/shell/open_file_action.dart` — index on open.
- `lib/shell/home/recents_controller.dart` — remove index rows on remove/clear.
- `lib/shell/home/home_screen.dart` — search action in the app bar.
- `lib/shell/app_shell.dart` — kick off the backfill after the first frame.
- `lib/formats/txt/txt_document_session.dart` + `txt_session_manager.dart`
- `lib/formats/markdown/md_document_session.dart` + `md_session_manager.dart`
- `lib/formats/json/json_document_session.dart` + `json_session_manager.dart`
- `lib/formats/csv/csv_document_session.dart` + `csv_session_manager.dart`
- `lib/formats/xml/xml_document_session.dart` + `xml_session_manager.dart`
  (each: optional `onSaved` callback, called after a successful overwrite save)
- `lib/shell/settings/sections/files_tabs_section.dart` — index switch + clear/rebuild.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` — new strings.
- `docs/architecture.md`, `docs/project_structure.md`, `docs/features.md`,
  `docs/feature_analysis_and_roadmap.md` (mark Feature 11 implemented),
  `docs/security.md` (what the index stores).

---

## 5. Tests

- Repository: insert/update/delete a doc, search finds it, snippet markers present,
  delete trigger removes the FTS row, `LIKE` fallback path gives the same results.
- Service: oversized file skipped, binary file skipped, 2 MB cap applied, corrupt /
  wrong-encoding bytes never throw, re-index replaces the old body.
- Query sanitiser: quotes, `*`, `AND`/`OR`/`NEAR`, empty query, only-punctuation query.
- Widget: typing shows hits, chips filter, tapping a hit opens the tab.
- Existing DB tests still pass across the v1 → v2 migration (add a migration test that
  opens a v1 database and upgrades it with the rows intact).

---

## 6. Work order

1. DB schema v2 + migration + FTS5 probe, with tests.
2. Models + repository + query sanitiser, with tests.
3. Service (eligibility, decode, cap) + providers, with tests.
4. Index on open + on save (session `onSaved` wiring) + removal on recents changes.
5. Backfill pass.
6. Search screen, controller, tile, Home entry point, strings.
7. Settings switch + clear / rebuild.
8. Docs, `dart format lib test`, `flutter analyze` (zero issues), `flutter test`.
9. Change log in `change_log/`.

---

## 7. Risks and how we handle them

| Risk | Handling |
|---|---|
| Device SQLite without FTS5 | Probe once, fall back to `LIKE` search; feature still works |
| Index grows large | 2 MB per-file cap, only recents + favorites, clear/rebuild in Settings |
| Indexing slows opening a file | Runs after the tab is opened, off the critical path, failures ignored |
| Stored text feels private | Default-on switch with a plain explanation, one-tap clear, private DB only |
| v1 → v2 migration risk | Additive only — no existing table is touched or dropped; covered by a test |

---

## 8. Out of scope (not in this change)

- Indexing files the user has never opened (no folder scanning — scoped storage only).
- Jumping to the exact match position inside the opened file (opens the file only).
- Sharing or exporting the index.
