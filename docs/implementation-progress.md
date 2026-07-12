# Implementation Progress — SreerajP_TextApp

**Purpose.** A living record of how far the build has got. It mirrors the phases and tasks
in [implementation-plan.md](implementation-plan.md). Update it as work lands.

Related docs: [CLAUDE.md](../CLAUDE.md), [TextData-Idea.md](TextData-Idea.md),
[architecture.md](architecture.md), [security-rules.md](security-rules.md).

---

## Status legend

| Symbol | Meaning |
|---|---|
| ⬜ Not started | No work done yet. |
| 🟨 In progress | Work started, not finished. |
| ⛔ Blocked | Cannot proceed; see the note for the blocker. |
| ✅ Done | Finished, acceptance met, tests green. |

**Rule:** a task is only ✅ when its **acceptance** holds and its **test** (from the plan)
passes. Note the change-log file in the Notes column when a task is completed.

---

## How to update this file

1. When you start a task, set it to 🟨 and add a short note.
2. When it is finished and its test passes, set it to ✅ and add the change-log filename
   (e.g. `20260710_090000_txt-viewer.md`).
3. If a task is stuck, set it to ⛔ and write the blocker in the note.
4. Update the phase's **overall** status and the **summary table** at the top.
5. Keep this in step with the plan — if the plan changes, change the tables here too.

---

## Summary

| Phase | Name | Status | Done / Total |
|---|---|---|---|
| 0 | Project scaffold | ✅ Done | 4 / 4 |
| 1 | Data & platform foundation | ✅ Done | 6 / 6 |
| 2 | App shell | ✅ Done | 8 / 8 |
| 3 | Shared editor core + read services | ✅ Done | 9 / 9 |
| 4 | TXT (first slice) | ✅ Done | 5 / 5 |
| 5 | Output & utility services | ✅ Done | 5 / 5 |
| 6 | Markdown | ✅ Done | 5 / 5 |
| 7 | CSV | ✅ Done | 6 / 6 |
| 8 | JSON | ✅ Done | 6 / 6 |
| 9 | XML | ✅ Done | 6 / 6 |
| 10 | Large-file handling | ✅ Done | 3 / 3 |
| 11 | Settings completion | ✅ Done | 7 / 7 |
| 12 | P2P LAN sync | ✅ Done | 8 / 8 |
| 13 | Security / a11y / l10n / polish | ✅ Done | 5 / 5 |
| 14 | Testing & release | ⬜ Not started | 0 / 3 |
| | **Total** | **🟨 In progress** | **83 / 86** |

---

## Phase 0 — Project scaffold  ·  ✅ Done

Change log: `20260709_151918_phase-0-project-scaffold.md`.

| Task | Status | Notes |
|---|---|---|
| 0.1 Create Flutter project + pin tool versions | ✅ | Flutter 3.41.9 / Dart 3.11.5, minSdk 26. Blank-app emulator run still owed as a manual check. |
| 0.2 Lay out module folders | ✅ | arch §4 tree created with `.gitkeep` placeholders. |
| 0.3 Wire Riverpod + base Material 3 app | ✅ | `ProviderScope` + `MaterialApp(useMaterial3: true)` + placeholder home. |
| 0.4 Lint / format / test scaffolding | ✅ | `flutter_lints` active; `test/smoke_test.dart` passes. |

## Phase 1 — Data & platform foundation  ·  ✅ Done

Change log: `20260709_153441_phase-1-data-platform-foundation.md`.
Owed: one manual on-device SAF check (pick → restart → re-open; stale URI error).

| Task | Status | Notes |
|---|---|---|
| 1.1 SAF file access + persistable URIs | ✅ | Custom SAF platform channel (Kotlin) + typed `SafException`s. Dart error-path tests pass; native path owes the manual device check. |
| 1.2 Content fingerprint | ✅ | size + streamed SHA-256 value type; equality + `tryParse` tested. |
| 1.3 Preferences + secure storage | ✅ | `KeyValueStore` facade routes sensitive keys to `flutter_secure_storage`, rest to `shared_preferences`; tested. |
| 1.4 Local DB (recents/bookmarks/favorites/drafts) | ✅ | `sqflite` schema v1 + migration hook; four repositories; FFI in-memory CRUD tests pass. |
| 1.5 ConfigService + app_config.json | ✅ | Typed `AppConfig` + safe fallback + `package_info_plus` cross-check; degrade-on-error tested. |
| 1.6 Device-memory reader (tab cap) | ✅ | `system_info2` reader behind an interface + pure `autoTabCap`; tested with sample RAM values. |

## Phase 2 — App shell  ·  ✅ Done

Change log: `20260709_153825_phase-2-app-shell.md`.
Owed: one manual emulator pass (theme switch look, portrait/landscape layout,
onboarding first-run, swiping between tabs). Tabs show a placeholder document view
until the editor (Phase 3) / TXT viewer (Phase 4) land; the unsaved-edit flag exists
but is unset until Phase 3.

| Task | Status | Notes |
|---|---|---|
| 2.1 Theme system (light/dark/sepia/system) | ✅ | `ThemeController` + `AppThemes` (seed-based, dynamic-color TODO). Font scale / line spacing / family. Sync-hydrated. Widget + unit tests pass. |
| 2.2 Adaptive navigation | ✅ | `AppShell`: `NavigationRail` (wide) vs bottom `NavigationBar` (narrow) at 640px. Widget test asserts both. |
| 2.3 Home / Recent Files + empty state | ✅ | Recents list with stale/unavailable handling, remove/clear, empty state, "Open a file". Widget tests pass. |
| 2.4 First-run onboarding | ✅ | Skippable 3-page intro; `onboarding.complete` flag; shown once. Widget tests pass. |
| 2.5 Multi-document tabs | ✅ | `TabsController` + independent per-tab state, tab strip, close/others/all guards. State tests pass. |
| 2.6 Memory-aware tab cap + over-limit | ✅ | Cap from `autoTabCap` (Phase 1.6) or fixed; pure `pickLruClosable`; unsaved tab never auto-closed. Unit + state tests pass. |
| 2.7 Left/right swipe between tabs | ✅ | Edge-bound swipe zones so it does not fight content scroll. Widget tests pass (edge switches, centre does not). |
| 2.8 Restore tabs on relaunch (optional) | ✅ | JSON set in `KeyValueStore` behind a toggle; skips inaccessible URIs with a notice. State tests pass. |

## Phase 3 — Shared editor core + read services  ·  ✅ Done

Change log: `20260709_161714_phase-3-shared-editor-core.md`.
Owed: one manual on-device check of the new native SAF methods — Save-as-a-copy
via `createDocument` (ACTION_CREATE_DOCUMENT), an overwrite save through a real
SAF URI, and modified-date read for metadata. The engine is pure Dart and fully
host-tested; the on-screen `TextField` editor + save wiring land in Phase 4.

| Task | Status | Notes |
|---|---|---|
| 3.1 Encoding detect/convert + line endings | ✅ | `TextCodecService`: BOM sniff → UTF-8 validate → single-byte fallback; custom UTF-16 (LE/BE) + Windows-1252 codecs, no new package. CRLF/CR/LF detect + preserve. Round-trip + failure-path tests pass. |
| 3.2 Editor controller + undo/redo | ✅ | Pure-Dart `EditorController` + command-stack `UndoRedoStack` (stores only changed slices; coalesces typing). Undo/redo returns exact prior states; tested. |
| 3.3 Shared search (case/whole-word/regex) | ✅ | `TextSearch` returns a `SearchOutcome` (matches or friendly error); invalid regex never throws. Tested. |
| 3.4 Find & replace (power options + scope) | ✅ | `FindReplace`: `$1` capture refs, `$$`, scope range, match-count preview = actual. Tested. |
| 3.5 Draft / auto-save store (crash recovery) | ✅ | `DraftStore` (private files keyed to fingerprint + `drafts_index`) + `AutoSaver`; kill-mid-edit recovered, real save clears. Added `path_provider`. Tested (FFI DB + temp dir). |
| 3.6 Atomic save + well-formedness gate | ✅ | `AtomicSaver` (encode → gate → single verified write) + `SafSaveTarget` (temp-write-verify then push) + native `createDocument`. Interrupted-save/gate/read-only tested with a fake target; native path owed. |
| 3.7 Unsaved-changes handling | ✅ | `UnsavedChangesAction` + `showUnsavedChangesDialog` (Save / Save a copy / Discard; read-only hides Save). Wired into tab close. Widget tests pass. |
| 3.8 Read-only lock toggle | ✅ | `TabsController.setReadOnly`/`toggleReadOnly`; `ReadOnlyLockButton` + `ReadOnlyBanner`; `EditorController` rejects edits while locked. Unit + widget tests pass. |
| 3.9 Metadata service | ✅ | `FileMetadata` + `MetadataService` (name/size/encoding/line-ending + per-format hook; dates via native `modifiedTime`, nullable). Tested. |

## Phase 4 — TXT (first slice)  ·  ✅ Done

Change log: `20260710_071843_phase-4-txt.md`.
Added packages: `re_editor` (MIT, editor surface), `url_launcher` (BSD, links).
Owed: one manual on-device pass (open a real TXT via SAF; edit; overwrite-save;
save-as-copy; switch encoding; split; append; open a link via the warning).

| Task | Status | Notes |
|---|---|---|
| 4.1 TXT viewer | ✅ | `re_editor` viewer: line-number gutter, word-wrap toggle, jump-to-line, reading-position restore (by fingerprint), light/dark/sepia + font settings. Links via a "Links" sheet + warning dialog (inline tap not possible with re_editor's renderer). |
| 4.2 TXT editor via the core | ✅ | Edit with undo/redo + find & replace (re_editor); Save / Save as a copy via `AtomicSaver` + `SafSaveTarget`; encoding + line ending chooser. Round-trip tested. |
| 4.3 Stats + metadata | ✅ | Pure `TxtStats` (word/char/line) + file-info sheet (size, dates, encoding, line ending). Tested incl. empty/multi-line. |
| 4.4 Encoding switch UI + failure path | ✅ | Encoding sheet re-decodes original bytes; binary-content warning; read failure → friendly failed state, never a crash. Failure-path tested. |
| 4.5 Split / merge TXT | ✅ | Pure `TxtSplitMerge` (split by lines/size, concatenating merge); `merge(split(t))==t` tested. UI: split saves parts via create-document; merge appends a picked file. |

## Phase 5 — Output & utility services  ·  ✅ Done

Change log: `20260710_113500_phase-5-output-utility-services.md`.
Added packages: `share_plus` (BSD-3), `archive` (MIT), `pdf` (Apache-2.0),
`printing` (Apache-2.0), `flutter_tts` (MIT) — all open source (CLAUDE.md §3.1).
Owed: one manual on-device pass (real share sheet, print preview, open an exported
PDF/DOCX, hear English read-aloud). Known limit: exported PDF uses a built-in
Latin-1 font, so non-ASCII (e.g. Malayalam) text does not render in the PDF yet —
a bundled Unicode font is a later polish item.

| Task | Status | Notes |
|---|---|---|
| 5.1 Share service | ✅ | `ShareService` + injectable `ShareLauncher` (`SharePlusLauncher`); shares file bytes or text. Request-building unit-tested with a fake launcher. Wired into the TXT toolbar (Share). |
| 5.2 Zip / compress-for-sharing | ✅ | Pure `ZipService` (`archive`); `zip`/`unzip` round-trip tested + ZIP signature check. Wired into "Share as zip". |
| 5.3 Print service | ✅ | `PrintService` + injectable `PrintLauncher` (`PrintingLauncher`); prints the document's PDF rendering. Job-building tested with a fake launcher. Wired into TXT (Print). |
| 5.4 Export / convert service | ✅ | Single `ExportService` with a `FormatExporter` registry; `TxtExporter` → PDF/DOCX/HTML/Markdown/plain text; PDF via `pdf`, DOCX via hand-built OOXML on `archive` (no Syncfusion). TXT→PDF (`%PDF-`) and TXT→DOCX (valid zip, escaped text) tested; unknown/unsupported target throws `UnsupportedExportException`. Wired into TXT export sheet (share/save the result). |
| 5.5 TTS (English + Malayalam guided install) | ✅ | `TtsService` (ChangeNotifier) + injectable `TtsEngine` (`FlutterTtsEngine`); state machine returns ready / needs-install / unavailable, auto-disables a vanished voice. English read-aloud button in the TXT toolbar; never a dead button. Full Settings toggle + Malayalam install launcher deferred to Phase 11.4. State machine unit-tested. |

## Phase 6 — Markdown  ·  ✅ Done

Change log: `20260710_120344_phase-6-markdown.md`.
Added packages: `markdown` (BSD-3, parser only), `flutter_math_fork` (Apache-2.0,
LaTeX). Rendering is our **own** widget renderer over the parser's AST — no
discontinued `flutter_markdown` (user decision, CLAUDE.md §3.1).
Owed: one manual on-device pass (open a real `.md` via SAF; toggle rendered/raw;
edit with the formatting toolbar; live preview; TOC jump; front matter banner;
export HTML/PDF/DOCX; split by heading; append a file). Known limits: PDF/DOCX
export is from the source text (HTML is the fidelity path); rendered code blocks
are styled monospace (no syntax coloring yet).

| Task | Status | Notes |
|---|---|---|
| 6.1 Rendered / raw toggle + scroll | ✅ | `MdMode` rendered/raw/edit; `MdPreviewView` (own `MarkdownRenderer`) + `MdEditorSurface` (re_editor); scroll position remembered by fingerprint. |
| 6.2 GFM + optional extensions | ✅ | gitHubWeb via `markdown` parser: tables, task lists, strikethrough, autolinks; mermaid → plain code block; LaTeX via `flutter_math_fork`, bad math degrades to `$$…$$` source. Widget-tested. |
| 6.3 TOC + jump-to-heading + front matter | ✅ | `MdToc` (heading anchors) + TOC sheet + internal `#` link jump via GlobalKeys; tolerant `MdFrontMatter` (title/author/tags) shown in a banner. Unit-tested. |
| 6.4 Editor + formatting toolbar + live preview | ✅ | Raw-source editing (undo/redo, find & replace); `MdFormatToolbar` on pure `MdSourceEdits` transforms; split live preview. Each transform unit-tested. |
| 6.5 Export / metadata / split-merge / failure path | ✅ | `MarkdownExporter` (core/export) → HTML (rendered)/PDF/DOCX/MD/plain; `MdStats` metadata; `MdSplitMerge` by top heading; corrupt/empty → friendly state. Export + failure-path tested. |

## Phase 7 — CSV  ·  ✅ Done

Change log: `20260710_133428_phase-7-csv.md`.
Added packages: `csv` (BSD-3, parse/serialize), `two_dimensional_scrollables`
(BSD-3, frozen-row/column grid), `fl_chart` (MIT, insights chart) — all open
source (CLAUDE.md §3.1). Decisions: **XLSX only** for spreadsheet export (legacy
`.xls` dropped as out of scope); chart via `fl_chart`. Rendering uses the official
`TableView.builder` (pinned header/first column). Owed: one manual on-device pass
(open a real `.csv` via SAF; edit cells; add/delete/reorder rows+cols; dedup; sort/
filter/jump; toggle raw; insights+chart; export each target; split; merge; overwrite-
save; save-as-copy). Known limits: manual column-resize is auto-fit only (no drag);
table-mode find is a row filter (find & replace lives in raw mode); PDF export uses
the built-in Latin-1 font (non-ASCII not rendered) — same as earlier phases.

| Task | Status | Notes |
|---|---|---|
| 7.1 Parsing & format handling | ✅ | `CsvDialect.detect` (comma/semicolon/tab/pipe, quote-aware) + `CsvParse` (tolerant, pads ragged rows, never throws) on the `csv` package; encoding/line-ending via Phase 3 codec; first-row-as-header toggle; `inferColumnType` (number/date/text/boolean/currency). Unit + failure-path tested. |
| 7.2 Table view & navigation | ✅ | `CsvGrid` on `TableView.builder`: frozen header row + first column, hide/show columns, H+V scroll, auto-fit widths, header-tap sort, row filter/search, jump-to-row, row/col counts, alternating colors + grid lines. Pure `CsvFilterSort` unit-tested; widget test covers render/filter/sort. |
| 7.3 Raw view toggle | ✅ | `CsvRawView` (re_editor) ↔ grid toggle; leaving raw re-parses back into the table; round-trip preserves content. Session + widget tested. |
| 7.4 Light data insights (read-only) | ✅ | `CsvInsights` per-column count/empty/unique + numeric min/max/sum/average; `CsvColumnChart` (fl_chart) bar chart per chosen column. Unit-tested. |
| 7.5 In-grid editing | ✅ | Cell edit, add/delete/reorder rows + columns, header rename, raw-text edit; snapshot undo/redo (`CsvTableUndo`); dup detection/removal (whole row or key column); save preserves delimiter/quoting/encoding/line endings; Save / Save as a copy. Table + session round-trip tested. |
| 7.6 Output & file-level ops | ✅ | `CsvExporter` → PDF (bordered table)/JSON (header-keyed)/HTML (`<table>`)/XLSX (hand-built OOXML, no Syncfusion); export all/filtered/selected rows; print; copy; `CsvSplitMerge` split by rows/size (header repeated) + merge; file-info sheet. Exporter + split/merge unit-tested. |

## Phase 8 — JSON  ·  ✅ Done

Change log: `20260710_142828_phase-8-json.md`.
No new packages (Dart `dart:convert` + our own lenient reader; colour coding is
our own rich text; YAML export is a small hand emitter). `ExportTarget` gained
`csv` + `yaml`; JSON exporter lives in `lib/formats/json/` (it needs the parser)
and is registered in `output_providers`. Owed: one manual on-device pass (open a
real `.json` via SAF; toggle pretty/tree/raw/minified; expand/collapse; copy a
path; search + JSONPath; validate a broken file; read a JSONC file then "Make
strict" and save; edit a value in the tree; blocked invalid save; export
CSV/YAML/PDF/HTML; diff two files; split/merge). Known limits: JSON5 and JSON
Schema are pragmatic subsets; advanced structural tree moves (drag-reorder) are
later polish; large-file streaming is Phase 10.

| Task | Status | Notes |
|---|---|---|
| 8.1 Views: pretty / tree / raw / minified | ✅ | `JsonViewMode` pretty/tree/raw/minified/edit. `JsonPrettyView` (own colour-coded `SelectableText.rich`), `JsonTreeView`, `JsonEditorSurface` (re_editor), `JsonMinifiedView`. |
| 8.2 Tree navigation | ✅ | Expand/collapse one/all (state on session, survives tab switch); type badges + child counts; copy path (`data.users[3].name`) / value / subtree. `pathOf` + tests. |
| 8.3 Search + optional JSONPath | ✅ | Tree filter by key/value; subset JSONPath (`$`, `.key`, `[i]`, `[*]`, `..key`) via `evaluateJsonPath` in a sheet; re_editor find (line numbers + bracket match) in raw/edit. Unit-tested. |
| 8.4 Validation + variants + big numbers | ✅ | Strict validity + error line; subset JSON Schema validator; format/minify; NDJSON → record list; lenient JSONC/JSON5 read with a "Make strict" banner that saves strict; big/high-precision numbers kept as exact text. Unit-tested. |
| 8.5 Editing with pre-save gate | ✅ | Raw-source edit (undo/redo, find & replace) + tree edits (edit value/key, add, delete) as source-span changes; `JsonWellFormedGate` blocks an invalid overwrite, save-as-copy bypasses it; chosen indentation + encoding/line ending. Session + tree-edit tests. |
| 8.6 Insights, output, file-level ops | ✅ | `JsonStats` insights; export JSON→CSV(flat)/YAML/PDF/HTML/JSON; `JsonDiff` two files; print; zip; copy full/minified/subtree; metadata; split/merge top-level arrays. Exporter + diff + split/merge tests. |

## Phase 9 — XML  ·  ✅ Done

Change log: `20260710_161500_phase-9-xml.md`.
Added package: `xml` (MIT — parse/serialize/entities, plus its `xpath.dart` for XPath).
No new `ExportTarget` (XML→JSON/CSV/PDF/HTML/plain reuse existing targets). Owed: one
manual on-device pass (open a real `.xml` via SAF; toggle pretty/tree/raw; expand/collapse;
copy a path; XPath query; validate a broken file; edit text/attributes in the tree; blocked
invalid save; declaration/encoding preserved; export JSON/CSV/PDF/HTML; split/merge). Known
limits: XSD schema validation is deferred to a native platform-channel follow-up (plan
§3.6, DTD/XSLT out of scope); tree edits re-serialize the whole document (raw editor is the
precise path); large-file streaming is Phase 10.

| Task | Status | Notes |
|---|---|---|
| 9.1 Views: pretty / tree / raw | ✅ | `XmlViewMode` pretty/tree/raw/edit. `XmlPrettyView` (own colour-coded `SelectableText.rich` from the DOM), `XmlTreeView`, `XmlEditorSurface` (re_editor); scroll position by fingerprint. |
| 9.2 Tree navigation | ✅ | Expand/collapse one/all (state on session, survives tab switch); tag + attribute chips + text/child-count; copy path (`root/items/item[2]/name`) / value / subtree. `xmlPathOf` + tests. |
| 9.3 Search + optional XPath | ✅ | Tree filter by tag/attribute/text; XPath via `package:xml/xpath.dart` in a sheet (friendly on bad query); re_editor find (line numbers + bracket match) in raw/edit. Unit-tested. |
| 9.4 Format handling + entities | ✅ | Well-formedness + error line; format/minify (minify strips indent whitespace); declaration/encoding readout; namespace list; comments/CDATA as tree rows; entity round-trip preserves text. XSD deferred. Unit-tested. |
| 9.5 Editing with pre-save gate | ✅ | Raw-source edit (undo/redo, find & replace) + tree edits (text/attributes/rename/add/delete/move) via DOM-mutate-then-re-serialize; `XmlWellFormedGate` blocks an invalid overwrite, save-as-copy bypasses it; chosen indent + encoding/line ending; declaration preserved. Session + tree-edit tests. |
| 9.6 Insights, output, file-level ops | ✅ | `XmlStats` insights; export XML→JSON/CSV/PDF/HTML/plain (`XmlExporter`); print; zip; copy full/minified; metadata; `XmlSplitMerge` split by a repeated child / merge under a wrapper root. Exporter + convert + split/merge tests. |

## Phase 10 — Large-file handling  ·  ✅ Done

Change log: `20260710_172500_phase-10-large-file-handling.md`.
Approach: **Way 1** (pragmatic size-gate, no new Android code) — user decision.
Known limit: the raw bytes are still read whole once; true from-disk streaming
(native ranged read) is deferred as a later follow-up. On-screen rendering was
already virtualized (re_editor, CSV `TableView.builder`, lazy trees), so 10.1's
"render only visible rows" was already met; Phase 10 closes the memory /
heavy-parsing gap. Owed: one manual on-device pass with a real >50 MB file.

| Task | Status | Notes |
|---|---|---|
| 10.1 Streaming parse + list virtualization | ✅ | `LargeFilePolicy` (pure) classifies a file by its known size (normal/large/oversized, ~5 MB / ~50 MB thresholds) **before** opening; oversized files skip the heavy format session entirely. Rendering already virtualized. Unit-tested. |
| 10.2 Degraded / paged view-only mode | ✅ | Shared `DegradedDocumentView` (pure `PagedText` paginator + read-only `SelectableText`, page nav + jump, "editing off" banner, friendly failure state) wired at one chokepoint in `tabs_workspace` for any oversized file; toolbar drops to minimal. Never crashes. Unit + widget tested. |
| 10.3 Tab memory release / rebuild | ✅ | Pure `pickReleasableSessions` (keep-loaded budget of 3; releases clean, non-active, LRU sessions; never releases active or dirty tabs); each session manager exposes `liveIds`; workspace releases background heavy state and rebuilds from file on return. Unit-tested. |

## Phase 11 — Settings completion  ·  ✅ Done

Change log: `20260710_214329_phase-11-settings-completion.md`.
One Settings screen composed of seven section widgets under
`lib/shell/settings/sections/`. Owed: one manual on-device pass (change each
setting and confirm it sticks across restart; real Malayalam voice install;
open sync from Settings; tap the About links). Known scope notes: word-wrap
default applies to the TXT wrap toggle (MD/CSV/JSON/XML use a fixed wrap in
their editor surface); Security toggles persist now but their enforcement
(launch lock gate + `FLAG_SECURE`) lands in Phase 13.2; Phase 12's
`syncableSettingKeys` are un-namespaced and do not match the app's namespaced
keys, so settings-sync exports nothing yet — a small follow-up flagged for
Phase 13/14.

| Task | Status | Notes |
|---|---|---|
| 11.1 Appearance section | ✅ | Theme/font-size/line-spacing (from Phase 2) + new font-family picker + default word-wrap (`appearance.word_wrap`, wired into the TXT session's initial wrap). Widget-tested via the settings screen. |
| 11.2 Editor section | ✅ | New `EditorSettings` + controller: default encoding / line-ending (preserve vs chosen), confirm-before-overwrite, auto-save interval (0 = off), open-read-only-by-default. Threaded through all 5 session managers (auto-save + encoding/line-ending default) and `TabsController.openFile` (read-only default); `confirmOverwriteIfNeeded` gates every format's overwrite save. Unit + widget tested. |
| 11.3 Files & Tabs section | ✅ | New `TabsController` setters (`setCapModeAuto`/`setFixedCap`/`setRestoreOnRelaunch`) + getters; Auto shows "Auto — N" from device RAM; over-limit uses the existing setter. Unit-tested. |
| 11.4 Speech (TTS) section | ✅ | New `TtsSettings` (English/Malayalam) + `TtsInstaller` over a new Kotlin `app/tts_install` method channel (INSTALL_TTS_DATA / open TTS settings). Malayalam toggle runs the check → guided-install / auto-disable flow; never a dead button. Unit + widget tested. |
| 11.5 Sync section | ✅ | Binds to Phase 12. New `SyncSharePrefs` (default share categories, `sync.share.<category>`) read by the host share chooser; note that only non-sensitive settings sync; "Open sync" button. Unit-tested. |
| 11.6 Security section | ✅ | New `SecuritySettings` (app-lock + screenshot-protection toggles + prefs). Enforcement deferred to Phase 13.2 (captions say so). Unit-tested. |
| 11.7 About section (from config) | ✅ | Reads `appConfigProvider` (from `app_config.json`); shows name/description/version+build/author/email/license/links (tappable via `url_launcher`). Editing the config changes the screen with no code change — widget-tested. |

## Phase 12 — P2P LAN sync  ·  ✅ Done

Change log: `20260710_205500_phase-12-p2p-lan-sync.md`.
Added packages: `qr_flutter` (BSD-3), `mobile_scanner` (BSD-3), `encrypt` (BSD-3),
`pointycastle` (MIT) — all open source (CLAUDE.md §3.1). Android permissions added:
`INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CAMERA` (local sockets +
QR scan only). Synced categories: favorites, bookmarks, recents, plus an allow-list
of non-sensitive settings. Owed manual/device checks: QR **camera scan** on a
device, and a real **two-device LAN transfer** (the formal Phase 14.2 gate). Known
limits: no live secret-bearing category yet, so the `SecretResealer` machinery is
built + unit-tested but not wired to a live secret; screenshot protection /
app-lock-suppress on the sync screen is a hook only (full behavior is Phase 11.6 /
13.2).

| Task | Status | Notes |
|---|---|---|
| 12.1 Sync constants | ✅ | `SyncConstants`: alphabet (no 0/O/1/I/L), 64-char code (~317 bits), PBKDF2 iters, salt/nonce sizes, handshake words, bounded caps (handshake vs payload), payload caps, timeouts, QR scheme/host/version, category keys, settings allow-list, never-sync keys. |
| 12.2 Crypto | ✅ | `SyncCrypto`: `Random.secure()` bytes, code generate/normalize/format/validate, PBKDF2-HMAC-SHA256 (`pointycastle`), AES-256-GCM `encryptWire`/`decryptWire` (`base64(nonce\|\|ct+tag)`, `encrypt`), strict QR build/parse (rejects foreign/malformed). `SecretResealer` device↔session round-trip. Unit-tested (round-trip, wrong key throws, tamper, QR rejects, resealer). |
| 12.3 Bounded line reader | ✅ | `BoundedLineReader`: buffers bytes, caps line length, `closed` future, no unbounded readLine. Over-cap line rejected; drop resolves `closed`. Unit-tested. |
| 12.4 Transport (connect-then-choose) | ✅ | `SyncHost`/`SyncClient`: salt(clear)→HELLO→ACCEPT→hold-open→push; wrong code → `DENIED` + keep listening / "incorrect code"; single client; connect/socket/`payloadWaitTimeout`; app-agnostic (opaque strings). Loopback-tested: happy path, wrong code never connects, keep-listening, send-with-no-client throws. |
| 12.5 Payload build / validate / merge | ✅ | `SyncPayload.build`/`validateAndParse` (hostile input: app id/version/mode, caps, drop non-allow-listed settings, reject protected keys); pure `mergeRecords` (add-only, client-wins, natural keys) + `mergeSettings` (full=all, incremental=fill-only). Unit-tested. |
| 12.6 Secret lifecycle | ✅ | `SecretResealer` (device-key→session-key→device-key) unit-tested; device key provisioned once with `Random.secure()` in secure storage, never synced/logged. No live secret category yet (per plan). |
| 12.7 Sync provider (state) | ✅ | `SyncController` (ChangeNotifier) + `SyncDataAccess`/`RepositorySyncDataAccess` bridge to Phase 1 repos + settings. Full loopback flow (connect→push→import summary + real DB writes) tested; wrong-code path tested. |
| 12.8 Sync UI | ✅ | Landing (Send/Receive), host two-tab screen (QR via `qr_flutter` + IP/port/code selectable + status chip + Stop; Full Sync + per-category checkboxes + "won't override" note, gated until connected), client scan (`mobile_scanner`)/manual form → waiting → added/kept/applied summary. Entry point in Home app bar. Widget-tested (status chip, gating, summary counts). |

## Phase 13 — Security / a11y / l10n / polish  ·  ✅ Done

Plan: `plans/20260711_175430_phase-13-security-a11y-l10n-polish.md` (staged A–E).
Change log: `change_log/20260712_*_phase-13-security-a11y-l10n-polish.md`.
Owed manual/device checks: real screenshot block on the sync screen, app-lock
PIN/biometric/recovery on relaunch + resume, a signed release install, and a
TalkBack pass.

| Task | Status | Notes |
|---|---|---|
| 13.1 Security hardening pass | ✅ | Audit doc `docs/security-audit-phase13.md`; rule-guard tests `test/security/` (logging audit across all `lib/`, `Random.secure()` + entropy). **Plus keystore wiring**: `signingConfigs.release` reads gitignored `android/key.properties` (debug fallback if absent), `key.properties.example`, `docs/release-signing.md`. No keystore/password generated by the AI (user runs `keytool`). |
| 13.2 App-lock + screenshot protection | ✅ | PIN (salted PBKDF2 hash) + biometric (`local_auth`) + recovery code (shown once, unlock → force new PIN). `lib/core/security/` (hasher/repository/controller/gate/biometric/window + lock/set-pin/recovery screens); Kotlin `WindowSecurityChannel` (`FLAG_SECURE`), `USE_BIOMETRIC` perm; secrets on the never-sync list. Tests in `test/core/security/`. Owed: on-device screenshot-block + biometric check. |
| 13.3 Accessibility | ✅ | No hardcoded text-scale overrides (guarded by test); icon-only controls carry tooltips (spoken by TalkBack); `Semantics` labels added to the pairing QR image and camera scanner. `test/a11y/semantics_test.dart`. Owed: manual TalkBack pass. |
| 13.4 Localization | ✅ | **Full extraction complete.** `flutter_localizations` + `intl` + gen-l10n (`l10n.yaml`, `lib/l10n/app_en.arb`, delegates + `supportedLocales` in `app.dart`), shared `localizedApp` test helper. **Every** user-facing string migrated: app title, home, onboarding, app shell, security/lock/PIN/recovery, all settings sections, all sync screens, tabs/dialogs, and **all five formats** (TXT, Markdown, CSV, JSON, XML) — toolbars, sheets, tree views, find panels, save/export/split-merge, output actions, and failure/empty states. Reusable shared key families (`action*`/`save*`/`out*`/`find*`/`export*`/`split*`/`readAloud*`/`info*`/`sync*`/`tab*`/`draft`/`fail`). Widget tests updated with the delegates. `test/l10n/localization_test.dart`. Analyze clean, 531 tests pass. |
| 13.5 Error / empty-state polish | ✅ | Non-blocking snackbars app-wide via a global `SnackBarThemeData` (floating + close icon) in `AppThemes` — no per-call-site changes. Every format's bad-file path shows a consistent friendly, never-crashing failure view (error icon + title + message + Retry) and friendly empty states; all were localized and reviewed in 13.4, and the parser failure-path suites stay green. `test/shell/error_polish_test.dart`. (Deliberate scope note: kept the per-format failure/empty widgets rather than extracting shared ones — they are already consistent and localized, so a refactor would be churn with no behavior gain.) |

## Post-Phase 13 improvements

| Change | Status | Notes |
|---|---|---|
| Create new document | ✅ | Home now offers **New document** for TXT, Markdown, CSV, JSON, and XML. Creation uses the existing Android SAF create picker, then the shared fingerprint, Recents, tab-cap, and editor-open flow. JSON and XML start well formed; all starter content is UTF-8. Format definitions, success, cancellation, SAF failure, picker UI, and accessibility are tested. Owed: one manual Android pass creating each format with a real document provider. |

## Phase 14 — Testing & release  ·  ⬜ Not started

| Task | Status | Notes |
|---|---|---|
| 14.1 Complete the automated suite | ⬜ | |
| 14.2 Manual two-device sync verification | ⬜ | |
| 14.3 Release prep | ⬜ | |
