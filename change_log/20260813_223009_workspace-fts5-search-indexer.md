# Change log — Workspace-Wide SQLite FTS5 Full-Text Search Indexer

Implements: `plans/20260813_221800_workspace-fts5-search-indexer.md`
(Feature 11 in `docs/feature_analysis_and_roadmap.md`).

---

## What this adds

The app can now search **inside all your files at once**, not just the open one.
Files you open — and files you marked as favorites — are indexed on the device, and a
new search screen finds any word in them, shows a short piece of the matching text
with the word highlighted, and opens the file in a tab when you tap it.

Everything is local. No new permission, no network, no new package.

---

## Database (schema v1 → v2)

`lib/core/storage/app_database.dart`

- Version bumped to 2 with an **additive** migration — no existing table is touched.
- New `search_docs` table: one row per indexed file (fingerprint, SAF URI, display
  name, format, size, indexed-at, `truncated`, `pinned`).
- New `search_fts` FTS5 table holding the file text, with its `rowid` equal to
  `search_docs.id`.
- New `AFTER DELETE` trigger on `search_docs` that deletes the matching body row.
- `AppDatabase.ftsAvailable` records whether the device's SQLite has FTS5. When it
  does not, a plain `search_body` table is created instead and search falls back to
  `LIKE`.

**Deviation from the plan:** the plan sketched the FTS5 table with `content=''`
(contentless). That form cannot return `snippet()` results, so the table stores the
body normally. Everything else in the design is unchanged.

---

## New files

| File | What it does |
|------|--------------|
| `lib/core/index/search_index_models.dart` | `IndexFormat`, `IndexedDoc`, `SearchHit`, `SnippetSpan` |
| `lib/core/index/search_index_repository.dart` | Index CRUD, FTS5 search with `bm25()` + `snippet()`, `LIKE` fallback, query sanitiser, snippet parsing |
| `lib/core/index/search_index_service.dart` | Eligibility (size / binary), decoding, 2 MB cap, best-effort index + search |
| `lib/core/index/search_index_backfill.dart` | Bounded pass over favorites + the 20 newest recents |
| `lib/core/index/index_hooks.dart` | Small helpers the open / save / recents flows call; swallow every failure |
| `lib/core/index/index_providers.dart` | Riverpod providers + the on/off setting |
| `lib/shell/search/workspace_search_controller.dart` | Query state, 250 ms debounce, format filters, availability cache |
| `lib/shell/search/workspace_search_screen.dart` | The search screen (field, filter chips, results, empty states) |
| `lib/shell/search/search_hit_tile.dart` | One result row with highlighted snippet |
| `test/core/index/search_index_repository_test.dart` | 23 tests: query handling, snippets, search, removal, `LIKE` fallback, v1 → v2 migration |
| `test/core/index/search_index_service_test.dart` | 13 tests: eligibility, indexing, cap, bad encoding, backfill |
| `test/shell/search/workspace_search_screen_widget_test.dart` | 6 widget tests: states, typing, filter chip, opening a hit, dropping a dead file |

---

## Changed files

- `lib/core/storage/app_database.dart` — schema v2, FTS5 probe, migration (above).
- `lib/shell/open_file_action.dart` — indexes a file while its bytes are already in
  hand; runs alongside the open flow, never blocks it.
- `lib/shell/home/recents_controller.dart` — removing a recent drops its index entry;
  clearing recents drops every entry that is not a favorite.
- `lib/shell/home/home_screen.dart` — search action in the app bar.
- `lib/shell/app_shell.dart` — runs the backfill once after the first frame.
- `lib/formats/{txt,markdown,json,csv,xml}/*_document_session.dart` — new optional
  `onSaved(text)` callback, called after a successful overwrite save (same pattern as
  the existing `onDirtyChanged`).
- `lib/formats/{txt,markdown,json,csv,xml}/*_session_manager.dart` — wire `onSaved` to
  re-index the tab's file.
- `lib/shell/settings/sections/files_tabs_section.dart` — "Workspace search index"
  switch (default on), how many files are indexed, **Rebuild** and **Clear** actions.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` — 27 new strings, English + Malayalam.
- `docs/architecture.md` — new §13 describing the index, plus the two new folders in
  the module layout.
- `docs/project_structure.md` — `core/index/` row.
- `docs/features.md` — the feature under §2.7.
- `docs/security.md` — what the index stores, when it is deleted, and a new entry in
  the open-risks list (the index keeps a plain copy of document text, like drafts).
- `docs/feature_analysis_and_roadmap.md` — Feature 11 marked implemented.

---

## Behaviour details

- **Indexed content**: the file's raw text, for all five formats.
- **Skipped**: files ≥ 50 MB (`LargeFilePolicy`), anything that sniffs as binary, and
  everything while the setting is off.
- **Cap**: 2 MB of text per file. Longer files are indexed up to the cap and the
  result row says "Long file — only the first part is searched".
- **Query safety**: everything that is not a letter, digit or underscore becomes a
  separator, so FTS5 operators can never reach the engine. All terms must match; the
  last term matches as a prefix, so results appear while typing.
- **Never breaks a file operation**: every index call is wrapped — a closed or missing
  database simply means nothing is indexed.

---

## Not done (and why)

- **Favorites pinning has no UI trigger.** The app has a `FavoritesRepository` but no
  screen that adds or removes favorites yet, so `pinned` is set by the backfill from
  the favorites table. When a favorites UI is added, it should call
  `WorkspaceIndexHooks.setPinned`.
- **No jump to the match inside the opened file.** Tapping a result opens the file;
  positioning the cursor at the match was out of scope in the plan.
- **No folder scanning.** Scoped storage only — the app indexes what the user has
  already opened or favorited.

---

## Checks

- `dart format lib test` — clean.
- `flutter analyze` — **No issues found**.
- `flutter test` — **935 tests, all passing** (42 of them new).
