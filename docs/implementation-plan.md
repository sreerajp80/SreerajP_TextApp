# Implementation Plan — SreerajP_TextApp

**Purpose.** This document turns the design into a **build order**. The design docs say
*what* to build and *how* it is structured; this doc says *in what order*, *what each
part depends on*, and *how we know a task is done*.

Read these first:
- [CLAUDE.md](../CLAUDE.md) — project rules.
- [TextData-Idea.md](TextData-Idea.md) — the product idea (the "what").
- [architecture.md](architecture.md) — the technical design (the "how"). Section numbers
  below (e.g. "arch §6") point here.
- [security-rules.md](security-rules.md) — security rules, read before any
  security-sensitive work.

Track build progress in [implementation-progress.md](implementation-progress.md).

---

## 1. How to read this plan

The app is built in **15 phases (0–14)**. Each phase has:

- **Goal** — one line on why the phase exists.
- **Depends on** — the phases that must be done (or usable) first.
- **Introduces (packages)** — new open-source packages first added in this phase.
- **Tasks** — the concrete units of work. Each task lists:
  - **Acceptance** — how we know the task is done (observable behavior).
  - **Test** — the test that guards it (ties to arch §12).
  - **Files** — the main target file paths (from arch §4). Paths are a guide, not a
    contract; create siblings as needed.

**Rule reminder:** every package named here must be **open source** (CLAUDE.md §3.1).
Confirm the license before adding any new one. Syncfusion is banned.

---

## 2. Dependency map

Critical path (top to bottom) and the parallel sync track on the right:

```
                        Phase 0  Project scaffold
                            |
                        Phase 1  Data & platform foundation ------------------+
                            |                                                  |
                +-----------+-----------+                                      |
                |                       |                                      v
            Phase 2                 Phase 3                              Phase 12
          App shell   <---------  Shared editor core                   P2P LAN sync
          (tabs/home)  integrates  + shared read services            (parallel track,
                |                       |                              needs only P1)
                +-----------+-----------+                                      |
                            |                                                  |
                        Phase 4  TXT (first vertical slice)                    |
                            |                                                  |
                        Phase 5  Output & utility services                     |
                            |     (share, zip, print, export, TTS)            |
                            |                                                  |
        +---------+---------+---------+---------+                              |
        |         |         |         |                                        |
    Phase 6   Phase 7   Phase 8   Phase 9                                      |
    Markdown    CSV      JSON       XML                                        |
        |         |         |         |                                        |
        +---------+----+----+---------+                                        |
                       |                                                       |
                  Phase 10  Large-file handling (cross-cutting; per format)    |
                       |                                                       |
                  Phase 11  Settings completion  <---------------- toggles ----+
                       |                                                       |
                  Phase 13  Security / a11y / localization / polish <----------+
                       |
                  Phase 14  Testing & release
```

**Overlap notes.**
- **Phase 2 and Phase 3** can be built together: the shell (2) gives a place to show the
  editor, and the editor core (3) plugs into a tab from (2). Neither needs the other
  *finished* to start, but both must be usable before Phase 4.
- **Phases 6–9** (Markdown, CSV, JSON, XML) are independent of each other. Once Phase 5
  is in place they can be built in parallel or in any order.
- **Phase 12 (sync)** only needs Phase 1. It can run at any time after that, in parallel
  with the format work. It feeds toggles into Phase 11 and hardening into Phase 13.
- **Phase 10** is cross-cutting: start it after the first format (Phase 4) and apply it to
  each format as that format lands.

**Critical path** (longest chain that sets the minimum schedule):
`0 → 1 → 3 → 4 → 5 → (6|7|8|9) → 10 → 11 → 13 → 14`.

---

## Phase 0 — Project scaffold

**Goal.** A running, empty Flutter app with the agreed structure, state management, and
Material 3 base, so every later phase has a home.

**Depends on.** None.

**Introduces (packages).** `flutter_riverpod`.

### Tasks

**0.1 Create the Flutter project and pin tool versions.**
- Acceptance: `flutter run` builds and shows a blank Material 3 home on an Android
  emulator (minSdk 26). Flutter ≥ 3.41.9, Dart ≥ 3.11.5 pinned.
- Test: CI/`flutter analyze` passes with zero issues; `flutter test` runs (even with one
  placeholder test).
- Files: `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `android/app/build.gradle`
  (minSdk 26).

**0.2 Lay out the module folders.**
- Acceptance: the folder tree from arch §4 exists (`core/`, `formats/`, `shell/`,
  `sync/`, `assets/config/`, `test/`) with placeholder files so imports resolve.
- Test: `flutter analyze` passes.
- Files: whole `lib/` tree per arch §4.

**0.3 Wire Riverpod and a base Material 3 app.**
- Acceptance: `ProviderScope` wraps the app; `useMaterial3: true`; a placeholder home
  route renders.
- Test: widget test — app builds and finds the home widget.
- Files: `lib/main.dart`, `lib/app.dart`.

**0.4 Set up lint, format, and test scaffolding.**
- Acceptance: `flutter_lints` (or stricter) active; `test/` has a passing smoke test.
- Test: `flutter analyze` and `flutter test` both green.
- Files: `analysis_options.yaml`, `test/smoke_test.dart`.

---

## Phase 1 — Data & platform foundation

**Goal.** The bottom layer of arch §2: file access, identity, and persistence. Nothing
above this can open or remember a file without it.

**Depends on.** Phase 0.

**Introduces (packages).** `file_picker` (+ SAF persistable-URI helper / platform
channel), `flutter_secure_storage`, `shared_preferences`, `sqflite` or `drift`,
`package_info_plus`, `system_info2` (or platform channel for RAM).

### Tasks

**1.1 SAF file access + persistable URIs.**
- Acceptance: user can pick a file via the system picker; the app takes a **persistable
  URI permission**; re-opening from a saved URI works; a stale/denied URI returns a clear
  error, not a crash. No broad storage permission requested (CLAUDE.md §3.3).
- Test: instrumented/manual — pick, persist, re-open, and revoke; unit tests for the
  URI-permission wrapper's error paths.
- Files: `lib/core/storage/saf_service.dart`.

**1.2 Content fingerprint (file identity).**
- Acceptance: a file maps to a stable fingerprint (size + hash); an edited file yields a
  new fingerprint (treated as a new document, arch §11).
- Test: unit — same bytes → same fingerprint; one byte changed → different.
- Files: `lib/core/fingerprint/`.

**1.3 Preferences and secure storage.**
- Acceptance: non-sensitive prefs read/write via `shared_preferences`; sensitive values
  via `flutter_secure_storage` (Keystore-backed). A helper hides the split.
- Test: unit — round-trip both stores (secure store mocked).
- Files: `lib/core/storage/` (prefs + secure wrappers).

**1.4 Local DB for recents, bookmarks, favorites, drafts index.**
- Acceptance: schema created and migratable; repositories expose CRUD for each entity,
  keyed by fingerprint where relevant.
- Test: unit — insert/read/delete on an in-memory DB.
- Files: `lib/core/storage/recents_repository.dart`,
  `bookmarks_repository.dart`, `favorites_repository.dart`, plus a drafts index table.

**1.5 ConfigService + `app_config.json`.**
- Acceptance: `app_config.json` loads at startup via `rootBundle` into a typed
  `AppConfig`; version cross-checked with `package_info_plus`; missing/malformed config
  degrades gracefully.
- Test: unit — valid config parses; malformed config gives a safe fallback, no crash.
- Files: `lib/core/config/config_service.dart`, `app_config.dart`,
  `assets/config/app_config.json`.

**1.6 Device-memory reader (for the tab cap).**
- Acceptance: returns total device RAM; used later to compute the Auto tab cap.
- Test: unit — the Auto-cap function maps sample RAM values to expected caps.
- Files: `lib/core/storage/` or a small platform helper.

---

## Phase 2 — App shell

**Goal.** The frame the user lives in: themes, navigation, Home/Recent, onboarding, and
the multi-tab system.

**Depends on.** Phase 1. (Integrates the editor from Phase 3 as it lands.)

**Introduces (packages).** None new required (uses Flutter + Phase 1 packages).

### Tasks

**2.1 Theme system (light / dark / sepia / follow system).**
- Acceptance: a central `ThemeController` switches themes live; Material 3 dynamic color
  where available with a safe fallback; font size / family / line spacing adjustable.
- Test: widget — theme switch changes the visible scheme.
- Files: `lib/core/theme/`.

**2.2 Adaptive navigation.**
- Acceptance: `NavigationRail` on wide screens, compact/bottom layout on phones; portrait
  and landscape; respects system font scaling.
- Test: widget — layout differs across a narrow vs wide test viewport.
- Files: `lib/app.dart`, `lib/shell/`.

**2.3 Home / Recent Files screen + empty state.**
- Acceptance: lists recent files (name, type icon, path, last-opened) from persisted
  URIs; re-open in one tap; remove one / clear all; stale entries shown as unavailable
  with a remove option; friendly empty state with "Open a file".
- Test: widget — populated list renders; empty list shows the empty state.
- Files: `lib/shell/home/`.

**2.4 First-run onboarding.**
- Acceptance: a short, skippable intro on first launch; never shown again after skip/finish.
- Test: widget — shows on first run flag, hidden after.
- Files: `lib/shell/onboarding/`.

**2.5 Multi-document tabs.**
- Acceptance: several files open at once, each a tab with its own state (view mode,
  scroll, search, unsaved edits); tab strip; tap to switch; close (with unsaved prompt),
  close others / all.
- Test: widget/state — opening two files yields two independent tab states.
- Files: `lib/shell/tabs/`.

**2.6 Memory-aware tab cap + over-limit behavior.**
- Acceptance: Auto cap computed from device RAM (Phase 1.6), shown as e.g. "Auto — 5
  tabs"; opening past the cap closes least-recently-used or asks (a setting); a tab with
  unsaved edits is never closed silently.
- Test: unit — over-limit rule picks LRU; state test — unsaved tab blocks silent close.
- Files: `lib/shell/tabs/`.

**2.7 Left/right swipe between tabs.**
- Acceptance: horizontal swipe moves prev/next; on horizontally scrolling content (wide
  CSV) the gesture is bound to an edge/tab-strip swipe so it does not fight content.
- Test: widget — swipe changes the active tab; edge-binding respected.
- Files: `lib/shell/tabs/`.

**2.8 Restore tabs on relaunch (optional toggle).**
- Acceptance: with the setting on, previously open files re-open at their saved reading
  position when their URIs are still accessible.
- Test: state — saved tab set restores; inaccessible URIs are skipped with a notice.
- Files: `lib/shell/tabs/`, recents/tabs persistence.

---

## Phase 3 — Shared editor core + shared read services

**Goal.** The one editing engine (arch §6) and the read-side shared services every format
reuses. This is the highest-value, highest-risk shared code.

**Depends on.** Phase 1 (SAF, fingerprint, DB, prefs). Plugs into the shell from Phase 2.

**Introduces (packages).** A text-editing surface helper (custom `TextEditingController`;
optionally an open-source `re_editor`/`code_text_field`-style editor for line numbers +
highlighting). `flutter_highlight` / `highlight` for optional syntax highlight.

### Tasks

**3.1 Encoding detect / convert + line endings.**
- Acceptance: detects UTF-8 / UTF-16 / ASCII / Windows code pages and CRLF vs LF on open;
  converts on demand; preserves by default on save.
- Test: unit — round-trip each encoding and line-ending style; wrong-encoding input gives
  a friendly result, never a crash (CLAUDE.md §3.4).
- Files: `lib/core/editor/encoding.dart`.

**3.2 Editor controller + undo/redo.**
- Acceptance: edit content with a command-stack undo/redo; large edits stay responsive.
- Test: unit — a sequence of edits + undo/redo returns exact prior states.
- Files: `lib/core/editor/editor_controller.dart`, `undo_redo.dart`.

**3.3 Shared search (case / whole-word / regex).**
- Acceptance: find, highlight, jump between matches; case-sensitive, whole-word, and
  regex toggles; a bad regex shows a friendly "invalid pattern" hint (idea Shared
  Capabilities), never a crash.
- Test: unit — each option returns correct match sets; invalid regex is caught.
- Files: `lib/core/search/`.

**3.4 Find & replace (power options + scope).**
- Acceptance: replace one/all honoring search options and `$1` capture-group refs; scope
  = whole file / selection / format-specific (CSV column, JSON/XML subtree); match-count
  preview before "Replace all".
- Test: unit — regex replace with capture refs; scope limits the replace; preview count
  matches actual.
- Files: `lib/core/editor/find_replace.dart`.

**3.5 Draft / auto-save store (crash recovery).**
- Acceptance: in-progress edits periodically written to a private draft store keyed to
  the fingerprint; on next open, offer restore or discard; draft cleared after a real
  save.
- Test: unit — simulate a kill mid-edit; next open surfaces the draft; save clears it.
- Files: `lib/core/editor/draft_store.dart`.

**3.6 Atomic save + well-formedness gate.**
- Acceptance: writes to a temp file then replaces via the SAF URI (temp-write-then-
  replace, CLAUDE.md §3.5); a failed save never corrupts the original; Save (overwrite)
  and Save as a copy both work; read-only URI offers only "Save as a copy"; structured
  formats can register a pre-save well-formedness check that blocks a broken save.
- Test: unit — interrupted save leaves the original intact; read-only path offers copy
  only; gate blocks invalid content.
- Files: `lib/core/editor/atomic_saver.dart`.

**3.7 Unsaved-changes handling.**
- Acceptance: leaving, closing a tab, switching away, or exiting with unsaved edits shows
  Save / Save as a copy / Discard; edits are never lost silently (CLAUDE.md §3.6).
- Test: state/widget — each exit path triggers the prompt.
- Files: `lib/core/editor/` + shell hooks in `lib/shell/tabs/`.

**3.8 Read-only lock toggle.**
- Acceptance: a per-file lock disables editing gestures and shows a clear "locked" state
  until the user explicitly unlocks.
- Test: widget — locked editor rejects edits; unlock restores them.
- Files: `lib/core/editor/`.

**3.9 Metadata service.**
- Acceptance: returns size, created/modified date, encoding, plus a hook for per-format
  fields.
- Test: unit — metadata for a sample file matches expected values.
- Files: `lib/core/metadata/`.

---

## Phase 4 — TXT format (first vertical slice)

**Goal.** Prove the whole open → view → edit → save slice on the simplest format before
scaling to the others.

**Depends on.** Phase 2 (shell/tabs), Phase 3 (editor core, search, encoding, metadata).

**Introduces (packages).** None new (optional `flutter_highlight` for the code-looking
case, already in Phase 3).

### Tasks

**4.1 TXT viewer.**
- Acceptance: word-wrap on/off; scroll; jump-to-line; line-number gutter; adjustable
  font size/family/line spacing; light/dark/sepia; remembers last scroll position (keyed
  to fingerprint); clickable URLs.
- Test: widget — wrap toggle, jump-to-line, and position restore behave.
- Files: `lib/formats/txt/`.

**4.2 TXT editor via the core.**
- Acceptance: full text editing with undo/redo and find & replace; Save and Save as a
  copy; choose encoding and line ending on save.
- Test: unit/widget — edit → save round-trips through the atomic saver preserving
  encoding/line endings.
- Files: `lib/formats/txt/`.

**4.3 Stats + metadata.**
- Acceptance: word / character / line counts; TXT metadata (size, dates, encoding).
- Test: unit — counts correct on sample inputs including empty and multi-line.
- Files: `lib/formats/txt/`.

**4.4 Encoding switch UI + failure path.**
- Acceptance: user can view/switch detected encoding; a corrupt/truncated/empty/wrong-
  encoding file shows a friendly message, never a crash.
- Test: parser failure-path tests (corrupt, truncated, empty, wrong encoding) — arch §12.
- Files: `lib/formats/txt/`.

**4.5 Split / merge TXT.**
- Acceptance: split by line count or size; merge several TXT files by concatenation in a
  chosen order.
- Test: unit — split then merge reproduces the original ordering.
- Files: `lib/formats/txt/`.

---

## Phase 5 — Output & utility services

**Goal.** The shared "send it somewhere" services, built once and wired into TXT first,
then every later format.

**Depends on.** Phase 3. (First consumed by Phase 4.)

**Introduces (packages).** `share_plus`, `archive` (zip + OOXML), `pdf` + `printing`
(PDF export and print), `flutter_tts`. DOCX/XLSX via open-source OOXML generation built on
`archive` (no Syncfusion).

### Tasks

**5.1 Share service.**
- Acceptance: share the file or exported output via the Android share sheet.
- Test: unit — share intent built with the right MIME/path (platform mocked).
- Files: `lib/core/share/`.

**5.2 Zip / compress-for-sharing.**
- Acceptance: zip the current file or exported output before sharing; available for all
  formats.
- Test: unit — zip then unzip reproduces the bytes.
- Files: `lib/core/zip/`.

**5.3 Print service.**
- Acceptance: shared print for every format using its natural output.
- Test: unit — print job built for a sample document (platform mocked).
- Files: `lib/core/print/`.

**5.4 Export / convert service.**
- Acceptance: a single conversion service; each format declares supported targets (PDF,
  HTML, DOCX, plain text, images, and format-specific JSON/CSV/XLSX). TXT targets
  (PDF/MD/DOCX) work end to end.
- Test: unit — TXT→PDF and TXT→DOCX produce valid, openable output; unsupported target
  is rejected cleanly.
- Files: `lib/core/export/`.

**5.5 TTS module (English + Malayalam guided install).**
- Acceptance: read content aloud in English; Malayalam behind a Settings toggle that
  checks `ml-IN`, guides install via `INSTALL_TTS_DATA` / system TTS settings / Play
  Store, auto-disables with a notice if the voice goes missing; reader screens ask the
  module for state and never show a dead button (idea Risks).
- Test: unit — state machine returns ready / needs-install / unavailable for mocked voice
  states.
- Files: `lib/core/tts/`.

---

## Phase 6 — Markdown

**Goal.** Rendered + raw Markdown with editing and a formatting toolbar.

**Depends on.** Phase 3 (editor/search), Phase 5 (share/print/export).

**Introduces (packages).** `flutter_markdown` (+ `markdown`), `flutter_math_fork` (LaTeX,
planned).

### Tasks

**6.1 Rendered / raw toggle + scroll.**
- Acceptance: rendered view (headings, bold/italic, lists, tables, blockquotes, code
  blocks) and raw source view, toggle between them; remembers last position.
- Test: widget — toggle switches views; sample renders correctly.
- Files: `lib/formats/markdown/`.

**6.2 GFM + optional extensions.**
- Acceptance: tables, task lists (checkboxes), strikethrough, autolinks; optional
  footnotes/emoji; a `mermaid` block shows as a plain code block (out of scope, does not
  break); LaTeX via `flutter_math_fork`, unsupported math degrades to `$$...$$` source.
- Test: unit/widget — each GFM feature renders; mermaid falls back; bad LaTeX degrades.
- Files: `lib/formats/markdown/`.

**6.3 TOC + jump-to-heading + front matter.**
- Acceptance: auto TOC from headings, tap to jump; internal `#` links jump; YAML front
  matter shows title/author/tags.
- Test: widget — TOC entries jump to the right heading; front matter parsed.
- Files: `lib/formats/markdown/`.

**6.4 Editor + formatting toolbar + live preview.**
- Acceptance: edit raw source with undo/redo and find & replace; live/preview toggle;
  toolbar for bold, italic, strikethrough, headings, bullet/numbered/task lists, links,
  inline code / code blocks, blockquotes, tables — each wraps the selection or inserts
  syntax at the cursor; Save / Save as a copy.
- Test: unit — each toolbar action produces the expected Markdown around a selection.
- Files: `lib/formats/markdown/`.

**6.5 Export / metadata / split-merge / failure path.**
- Acceptance: MD→HTML/PDF/DOCX; metadata (size, modified, word/heading count); split by
  top-level heading, merge by concatenation; corrupt/empty input shows a friendly message.
- Test: parser failure-path tests; export produces valid output.
- Files: `lib/formats/markdown/`.

---

## Phase 7 — CSV

**Goal.** A real table grid with parsing, insights, and in-grid editing.

**Depends on.** Phase 3, Phase 5.

**Introduces (packages).** `csv`.

### Tasks

**7.1 Parsing & format handling.**
- Acceptance: detect delimiter (comma/semicolon/tab/pipe); handle quoted fields with
  commas/line breaks; detect encoding and line endings; first-row-as-header toggle; infer
  types (number, date, text, boolean, currency).
- Test: unit — each delimiter, quoted fields, and type inference; malformed rows handled
  without crash (failure-path test).
- Files: `lib/formats/csv/`.

**7.2 Table view & navigation.**
- Acceptance: real grid with headers; freeze header row and first column; hide/show
  columns; horizontal + vertical scroll; resize/auto-fit; sort by header; filter/search
  rows; jump to row; row/column counts; alternating colors/grid lines.
- Test: widget — freeze, sort, filter, and jump behave on a sample grid.
- Files: `lib/formats/csv/`.

**7.3 Raw view toggle.**
- Acceptance: toggle between table and raw comma-separated text.
- Test: widget — toggle preserves content.
- Files: `lib/formats/csv/`.

**7.4 Light data insights (read-only).**
- Acceptance: per-column count/min/max/sum/average for numeric columns; unique/empty
  counts; (advanced) a simple chart from a chosen column.
- Test: unit — stats correct on sample columns.
- Files: `lib/formats/csv/`.

**7.5 In-grid editing.**
- Acceptance: edit cells; add/delete/reorder rows and columns; edit header; edit raw text
  in raw mode; duplicate-row detection/removal (whole row or key column); undo/redo, find
  & replace; save preserves delimiter/quoting/encoding/line endings (or chosen set); Save
  / Save as a copy.
- Test: unit — edit → save round-trips with detected delimiter/quoting; dup removal works.
- Files: `lib/formats/csv/`.

**7.6 Output & file-level ops.**
- Acceptance: export CSV→PDF/JSON/HTML/XLSX(+XLS); export selected/filtered rows only;
  print table; copy cell/row/table; metadata (size, modified, row/col count, delimiter,
  encoding); split by row count/size (header repeated) / merge (same columns).
- Test: unit — export selected rows exports only those; split repeats the header.
- Files: `lib/formats/csv/`.

---

## Phase 8 — JSON

**Goal.** Multiple views, validation, lenient reading, and safe editing of JSON.

**Depends on.** Phase 3, Phase 5.

**Introduces (packages).** Dart core `dart:convert`; a custom lenient reader for
JSONC/JSON5 and NDJSON.

### Tasks

**8.1 Views: pretty / tree / raw / minified.**
- Acceptance: indented color-coded pretty view, collapsible tree, raw as-is, single-line
  minified; toggle between them.
- Test: widget — each view renders a sample document; toggle preserves content.
- Files: `lib/formats/json/`.

**8.2 Tree navigation.**
- Acceptance: expand/collapse one or all; keys with value types; array indexes and child
  counts; copy a node's path (`data.users[3].name`); copy subtree/value.
- Test: widget/unit — path copy and child counts correct.
- Files: `lib/formats/json/`.

**8.3 Search + optional JSONPath.**
- Acceptance: search by key or value, jump between matches; filter tree to matches;
  optional JSONPath query; line numbers + bracket matching in raw/pretty.
- Test: unit — key/value search and a JSONPath query return expected nodes.
- Files: `lib/formats/json/`.

**8.4 Validation + variants + big numbers.**
- Acceptance: validate (well-formed, error line if not); optional JSON Schema validation
  listing errors; format/minify; NDJSON shown as a record list; lenient JSONC/JSON5 read
  (tolerates `//`, `/* */`, trailing commas) that **saves strict JSON** and tells the
  user; large/high-precision numbers kept as exact original text.
- Test: unit — invalid JSON reports the error line; NDJSON parses to records; JSONC reads
  then saves strict; big number survives round-trip unrounded.
- Files: `lib/formats/json/`.

**8.5 Editing with pre-save gate.**
- Acceptance: edit values/keys in tree and raw source; add/delete nodes; undo/redo, find
  & replace; a well-formedness check runs before saving and blocks an invalid save (or
  save-anyway-as-copy); save with chosen indentation and encoding/line endings.
- Test: unit — invalid edit blocked at save; valid edit round-trips with chosen indent.
- Files: `lib/formats/json/`.

**8.6 Insights, output, file-level ops.**
- Acceptance: key count, depth, array sizes, type breakdown; export JSON→CSV (flat
  arrays)/YAML/PDF/HTML; diff two JSON files; print; zip; copy full/minified/subtree;
  metadata (top-level type, item count); split/merge top-level arrays.
- Test: unit — diff reports added/removed/changed; split then merge reproduces the array.
- Files: `lib/formats/json/`.

---

## Phase 9 — XML

**Goal.** Views, tree navigation, entity-safe editing, and optional schema validation.

**Depends on.** Phase 3, Phase 5.

**Introduces (packages).** `xml`. Optional XSD via Android `javax.xml.validation` behind a
platform channel.

### Tasks

**9.1 Views: pretty / tree / raw.**
- Acceptance: syntax-highlighted pretty view, collapsible element tree, raw as-is; toggle
  between them.
- Test: widget — each view renders a sample; toggle preserves content.
- Files: `lib/formats/xml/`.

**9.2 Tree navigation.**
- Acceptance: expand/collapse one or all; tag name, attributes, text value; child counts
  and repeated elements; copy a node's path (`root/items/item[2]/name`); copy
  subtree/attribute/value.
- Test: widget/unit — path copy and child counts correct.
- Files: `lib/formats/xml/`.

**9.3 Search + optional XPath.**
- Acceptance: search by tag/attribute/text, jump between matches; filter tree; optional
  XPath; line numbers + tag/bracket matching in raw.
- Test: unit — tag/attr/text search and an XPath query return expected nodes.
- Files: `lib/formats/xml/`.

**9.4 Format handling + entities.**
- Acceptance: well-formedness check (error line if not); format/minify; handle the XML
  declaration/encoding; show namespaces; collapse comments and CDATA; resolve built-in
  and numeric entities for display and re-escape them correctly on save so text is never
  corrupted; (advanced) XSD validation via platform channel. DTD and XSLT are out of scope.
- Test: unit — entity round-trip preserves text; malformed XML reports the error line;
  failure-path tests for corrupt/truncated/empty.
- Files: `lib/formats/xml/`.

**9.5 Editing with pre-save gate.**
- Acceptance: edit element text/attributes/structure in tree and raw; add/delete/move
  elements and attributes; undo/redo, find & replace; well-formedness check blocks an
  invalid save (or save-as-copy); preserve XML declaration and encoding on save (or
  chosen encoding/line ending).
- Test: unit — invalid edit blocked at save; declaration/encoding preserved on round-trip.
- Files: `lib/formats/xml/`.

**9.6 Insights, output, file-level ops.**
- Acceptance: element count, depth, most-common tags, attribute list per element type;
  export XML→JSON/CSV (flatten a repeated element)/PDF/HTML; print; zip; copy
  full/minified/subtree; metadata (root element, encoding, element count); split by a
  repeated child / merge under a new wrapper root.
- Test: unit — split by element and merge under a wrapper reproduce the content.
- Files: `lib/formats/xml/`.

---

## Phase 10 — Large-file handling (cross-cutting)

**Goal.** Keep memory bounded up to ~50 MB and degrade gracefully above the limit, across
all formats and tabs.

**Depends on.** Phase 4 (start after the first format); applied to each of Phases 6–9 as
they land.

**Introduces (packages).** None new.

### Tasks

**10.1 Streaming parse + list virtualization.**
- Acceptance: large CSV/JSON/XML/TXT open smoothly by streaming and rendering only
  visible rows; memory stays bounded (target ~50 MB, arch §11).
- Test: performance/manual — a ~50 MB file scrolls smoothly; memory stays within budget.
- Files: per-format parsers + shared virtualization helpers.

**10.2 Degraded / paged view-only mode.**
- Acceptance: above the comfortable limit, the app offers a raw, paged, view-only mode and
  tells the user editing is disabled for that file (idea Risks); it never crashes.
- Test: manual/unit — an oversized file opens in degraded mode with the notice.
- Files: per-format viewers + shell.

**10.3 Tab memory release / rebuild.**
- Acceptance: background tabs can release heavy in-memory state and rebuild from the file
  when the user returns, keeping several large files in check.
- Test: state — a backgrounded tab drops its heavy state and restores on focus.
- Files: `lib/shell/tabs/` + per-format state.

---

## Phase 11 — Settings completion

**Goal.** One Settings screen (arch §8) exposing every preference the features added.

**Depends on.** The features each toggle controls (Phases 2–10, and 12 for the Sync
section). Finalized late so all toggles exist.

**Introduces (packages).** None new.

### Tasks

**11.1 Appearance section.** theme, font size/family, line spacing, default word-wrap.
- Acceptance/Test: changing a value updates the app and persists across restart.
- Files: `lib/shell/settings/`.

**11.2 Editor section.** encoding/line-ending default (preserve vs chosen),
confirm-before-overwrite, auto-save/draft interval, read-only default.
- Acceptance/Test: each toggle changes the matching editor behavior.
- Files: `lib/shell/settings/`.

**11.3 Files & Tabs section.** max open tabs (Auto — N / fixed), over-limit behavior,
restore-tabs-on-relaunch.
- Acceptance/Test: lowering the cap below open tabs closes extras by the over-limit rule.
- Files: `lib/shell/settings/`.

**11.4 Speech (TTS) section.** English on/off, Malayalam toggle with guided install.
- Acceptance/Test: toggling Malayalam runs the check/install/auto-disable flow.
- Files: `lib/shell/settings/`.

**11.5 Sync section.** which categories are syncable and any exposed tunables; no
security/identity state listed here.
- Acceptance/Test: only allow-listed, non-sensitive settings appear.
- Files: `lib/shell/settings/`.

**11.6 Security section.** optional app-lock, screenshot protection on the pairing-code
screen, other protective toggles.
- Acceptance/Test: enabling app-lock gates entry; screenshot protection flags the screen.
- Files: `lib/shell/settings/`.

**11.7 About section.** reads values from `app_config.json` (Phase 1.5), cross-checked
with `package_info_plus`.
- Acceptance/Test: About shows config values; editing the config changes the screen with
  no code change (arch §12 settings/config test).
- Files: `lib/shell/settings/`, `assets/config/app_config.json`.

---

## Phase 12 — P2P LAN sync (parallel track)

**Goal.** Offline, same-LAN, device-to-device sync with payload-layer crypto (arch §9).
**Read [security-rules.md](security-rules.md) before any task here.**

**Depends on.** Phase 1 (data layer, secure storage). Otherwise independent — can run in
parallel with Phases 4–9.

**Introduces (packages).** `qr_flutter` (QR render), `mobile_scanner` (QR scan), `encrypt`
(AES-GCM), `pointycastle` (PBKDF2). Android permissions: `INTERNET`,
`ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CAMERA` (local sockets only, no backend).

### Tasks

**12.1 Sync constants.**
- Acceptance: all tunables and wire literals centralized (alphabet, code length, PBKDF2
  iterations, salt/nonce sizes, handshake strings, caps, timeouts, QR URI scheme/host/
  version, payload caps, sync-mode keys) so host and client stay in lockstep.
- Test: referenced by the crypto/transport tests below.
- Files: `lib/sync/sync_constants.dart`.

**12.2 Crypto.**
- Acceptance: pairing code generate/normalize/format (~320 bits, no 0/O/1/I/L);
  `randomBytes` from `Random.secure()`; PBKDF2-HMAC-SHA256 key derivation; AES-256-GCM
  `encryptWire`/`decryptWire` (`base64(nonce(12) || ciphertext+tag)`, one line); strict QR
  URI build/parse that rejects foreign QRs. The pairing code never goes on the wire.
- Test: unit — wire crypto round-trips; a wrong key throws (GCM tag fails); QR parser
  rejects malformed/foreign URIs.
- Files: `lib/sync/sync_crypto.dart`.

**12.3 Bounded line reader.**
- Acceptance: buffers bytes, caps line length (separate handshake vs payload caps),
  exposes a `closed` future; never an unbounded `readLine` (guards slow-loris / giant
  line DoS).
- Test: unit — an over-long line is rejected at the cap; a drop resolves `closed`.
- Files: `lib/sync/bounded_line_reader.dart`.

**12.4 Transport (connect-then-choose).**
- Acceptance: `ServerSocket`/`Socket` host + client; client acknowledged immediately
  (both show "connected"); host holds open; sender pushes the payload on action; wrong
  code → host `DENIED` and keeps listening, or client reports "incorrect code"; single
  client at a time; connect + socket timeouts; long `payloadWaitTimeout` for the payload
  read; app-agnostic (moves opaque strings only).
- Test: unit/loopback — happy path connects and receives the pushed payload; wrong code is
  rejected and never connects; `sendToConnectedClient` with no client throws (arch §12).
- Files: `lib/sync/sync_transport.dart`.

**12.5 Payload build / validate / merge.**
- Acceptance: JSON shape with `syncMode` (full/incremental), `records`, optional `groups`,
  optional allow-listed non-sensitive `settings`; a category key is present only if it is
  part of this sync; `validateAndParse` treats every payload as hostile — enforces caps
  (max records, per-field length) and rejects malformed input before it touches the DB;
  merge is add-only, client-wins (full applies all incl. settings; incremental skips
  existing keys and applies settings fill-only); returns counts for the summary.
- Test: unit — validate rejects oversized/malformed and caps record counts; merge skips
  duplicates and applies settings fill-only (arch §12).
- Files: `lib/sync/payload.dart`.

**12.6 Secret lifecycle.**
- Acceptance: on the host, device-key secrets are re-sealed under the session key only
  transiently in memory while building the payload (never on disk, never logged); on the
  client, imported secrets are re-encrypted under the receiving device's own key before
  storage; payloads/secrets/keys/code are never logged.
- Test: unit — a secret round-trips device-key → session-key → device-key; nothing secret
  reaches logs.
- Files: `lib/sync/payload.dart`, `lib/sync/sync_provider.dart`.

**12.7 Sync provider (state orchestration).**
- Acceptance: Riverpod state that runs the transport, builds the payload from chosen
  categories, and applies imports.
- Test: state — a full loopback flow (connect → choose → push → import summary).
- Files: `lib/sync/sync_provider.dart`.

**12.8 Sync UI.**
- Acceptance: host two tabs (connection details with QR + IP/port/code as selectable text,
  live status chip, Stop; and choose-what-to-share with Full Sync + per-category
  checkboxes and the "won't override" note, actions disabled until connected); client
  scan/manual form → waiting screen → added/kept/applied summary; idle/background
  auto-lock suppressed while the sync screen is open; optional screenshot protection while
  the code/QR is shown.
- Test: widget — status chip updates on connect; actions gated until connected; summary
  renders counts.
- Files: `lib/sync/` UI + `lib/shell/settings/` sync section.

---

## Phase 13 — Security, accessibility, localization, polish

**Goal.** A dedicated hardening and finishing pass across the whole app.

**Depends on.** All feature phases (2–12).

**Introduces (packages).** None new (localization via Flutter's `intl`/gen-l10n).

### Tasks

**13.1 Security hardening pass.**
- Acceptance: audit against [security-rules.md](security-rules.md) — untrusted input
  validated everywhere, no secret logging (even debug), least-privilege permissions,
  scoped-storage only, atomic writes, `Random.secure()` for all security randomness,
  bounded reads/timeouts/caps on sync.
- Test: run `/security-review`; targeted tests for each rule; grep for accidental logging.
- Files: cross-cutting; concentrated in `lib/sync/`, `lib/core/storage/`,
  `lib/core/editor/`.

**13.2 App-lock + screenshot protection.**
- Acceptance: optional app-lock; `FLAG_SECURE`/screenshot protection on the pairing-code/
  QR screen.
- Test: manual/widget — lock gates entry; protected screen blocks screenshots.
- Files: `lib/shell/settings/`, `lib/sync/`.

**13.3 Accessibility.**
- Acceptance: system font scaling respected; screen-reader labels on key controls where
  practical.
- Test: manual with TalkBack; widget — semantics present on primary actions.
- Files: cross-cutting.

**13.4 Localization.**
- Acceptance: UI strings localizable (at least English), given the Malayalam content
  focus.
- Test: build with the localization delegate; no hardcoded user-facing strings in new UI.
- Files: `lib/l10n/` + screens.

**13.5 Error / empty-state polish.**
- Acceptance: every bad-file path shows a friendly, never-crashing message; empty states
  are friendly; snackbars are non-blocking.
- Test: run the parser failure-path suite; manual pass over each format's error screen.
- Files: cross-cutting.

---

## Phase 14 — Testing & release

**Goal.** Complete the test suite (arch §12), verify a real two-device sync, and prepare
the release.

**Depends on.** All phases.

**Introduces (packages).** None new.

### Tasks

**14.1 Complete the automated suite.**
- Acceptance: sync loopback (happy path, wrong code, send-with-no-client, validate caps,
  crypto round-trip + wrong key, add-only/fill-only merge); parser failure-path tests for
  all formats; editor atomic-save + encoding/line-ending + find & replace (regex + scope)
  + draft recovery + unsaved-changes; config load + syncable-settings allow-list.
- Acceptance: `flutter test` green; coverage on the core and sync modules.
- Files: `test/sync/`, `test/formats/`, `test/core/editor/`, settings/config tests.

**14.2 Manual two-device sync verification.**
- Acceptance: a real transfer between two devices on a LAN succeeds (arch §12 requires this
  before release).
- Test: documented manual run with the result recorded in the change log.
- Files: (manual) — record in `change_log/`.

**14.3 Release prep.**
- Acceptance: version/build set from `app_config.json`; permissions reviewed
  (least-privilege); release build signed and installable on minSdk 26; README/About
  accurate.
- Test: install the release build on a device and smoke-test each format.
- Files: `android/` release config, `assets/config/app_config.json`.

---

## 3. Summary — phase order and dependencies

| Phase | Name | Depends on | Can overlap with |
|---|---|---|---|
| 0 | Project scaffold | — | — |
| 1 | Data & platform foundation | 0 | — |
| 2 | App shell | 1 | 3 |
| 3 | Shared editor core + read services | 1 | 2 |
| 4 | TXT (first slice) | 2, 3 | — |
| 5 | Output & utility services | 3 | 4 |
| 6 | Markdown | 3, 5 | 7, 8, 9, 12 |
| 7 | CSV | 3, 5 | 6, 8, 9, 12 |
| 8 | JSON | 3, 5 | 6, 7, 9, 12 |
| 9 | XML | 3, 5 | 6, 7, 8, 12 |
| 10 | Large-file handling | 4 (then 6–9) | 6–9 |
| 11 | Settings completion | 2–10, 12 | — |
| 12 | P2P LAN sync | 1 | 4–9 |
| 13 | Security / a11y / l10n / polish | 2–12 | — |
| 14 | Testing & release | all | — |

**Minimum critical path:** `0 → 1 → 3 → 4 → 5 → (one of 6–9) → 10 → 11 → 13 → 14`, with
the **sync track `1 → 12`** running alongside the format work.
