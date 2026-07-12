# Plan — Phase 3: Shared editor core + shared read services

**Status:** completed

Implements Phase 3 of [implementation-plan.md](../docs/implementation-plan.md) (tasks
3.1–3.9) and updates [implementation-progress.md](../docs/implementation-progress.md).
Design source: [architecture.md](../docs/architecture.md) §6, §4, §11. Rules:
[CLAUDE.md](../CLAUDE.md), [security-rules.md](../docs/security-rules.md),
[workflow-rules.md](../docs/workflow-rules.md).

---

## 1. What this phase is

Build the **one editing engine** every file format reuses, plus the read-side shared
services. This is pure, testable logic (arch §2 says the core is plain Dart so it can be
unit-tested with no device). The nine tasks:

- 3.1 Encoding detect / convert + line endings.
- 3.2 Editor controller + undo/redo.
- 3.3 Shared search (case / whole-word / regex).
- 3.4 Find & replace (capture-group refs + scope + count preview).
- 3.5 Draft / auto-save store (crash recovery).
- 3.6 Atomic save + well-formedness gate.
- 3.7 Unsaved-changes handling.
- 3.8 Read-only lock toggle.
- 3.9 Metadata service.

**Phase 3 builds the engine, not the on-screen editor.** The real `TextField`-backed
editor UI is Phase 4 (TXT, the first vertical slice). So the editor controller here is a
**pure-Dart text model** (text + selection + undo/redo), unit-tested on the host. A thin
Flutter binding to a `TextField` is deferred to Phase 4. Only two small widgets are built
now: the **unsaved-changes dialog** (3.7) and the **read-only lock** wiring (3.8), because
those plug straight into the existing tab shell.

## 2. What the gap is

- Phases 0–2 gave the data layer and the shell (tabs, theme, home). A tab currently shows
  `placeholder_document_view.dart` — there is no way to load a file's text, edit it,
  search it, save it, or recover a draft.
- `DocumentTab` already has `isDirty` and `isReadOnly` fields, but nothing sets `isDirty`
  and there is no lock toggle. `DraftsIndexRepository` exists but no draft store writes
  the draft file it points to. `SafService` has `readBytes` / `writeBytes` but no atomic
  save flow and no "create a new document" for Save-as-a-copy.

## 3. Design decisions (please confirm at approval)

1. **Editor core is pure Dart, not a Flutter `TextEditingController`.** `EditorController`
   holds `text` + `selection` + an undo/redo stack as plain Dart, so all of 3.2–3.4 is
   unit-testable with no widget. Phase 4 adds the thin `TextField` binding when the TXT
   editor lands. (Matches arch §2 "core is plain Dart, testable without a device".)

2. **Encoding: custom, dependency-free codecs (recommended).** Dart core covers
   `utf8` / `ascii` / `latin1`. I will add small, well-tested codecs for **UTF-16 (LE/BE,
   BOM-aware)** and **Windows-1252** (a 256-entry table; only 0x80–0x9F differ from
   Latin-1). Detection = BOM sniff → strict UTF-8 try → single-byte fallback
   (Windows-1252). This keeps the "open source only / minimal deps" rule and stays fully
   testable. *Alternative:* add the open-source `enough_convert` package for Windows code
   pages. **I recommend the custom route**; say the word if you'd rather add the package.

3. **Add `path_provider` (open source, BSD) for the draft store.** Drafts are files in the
   app-private directory (arch §6: the draft store writes the file, `drafts_index` points
   to it). The store takes an **injected base `Directory`** so tests use a temp dir; the
   real app-private dir comes from `path_provider`. This is the only new runtime package.

4. **Add a native SAF `createDocument` for Save-as-a-copy.** `SafService.writeBytes`
   already overwrites. Save-as-a-copy needs `ACTION_CREATE_DOCUMENT`. I will add a small
   Kotlin method + a Dart wrapper. The **pure atomic-save logic is tested with a fake
   target**; the native path (and Save-as-copy on a device) is an **owed manual check**,
   the same way Phases 1–2 recorded owed on-device checks.

5. **Atomicity model.** `AtomicSaver` encodes → runs the well-formedness gate → writes to
   a **private temp file** and verifies its length → then pushes the verified bytes to the
   SAF URI (overwrite) or to a freshly created document (copy). A failed encode or a failed
   gate never touches the original. True cross-process atomicity over SAF is a native
   limit; the temp-then-push step guarantees we never send half-encoded content, which is
   what the unit test asserts (interrupted save leaves the original intact).

6. **Metadata dates are nullable for now.** SAF today returns name / mime / size only.
   Created/modified dates need a native `DocumentFile.lastModified()` call; I will model
   them as nullable with a `TODO` and a native `statDocument` method added opportunistically
   with `createDocument`. Size + encoding + line-ending + name are the core fields and are
   fully tested.

## 4. Files to change / add

### New — encoding (3.1) · `lib/core/editor/`
- `encoding.dart` — `TextEncodingType` enum (utf8, utf8Bom, utf16le, utf16be, ascii,
  latin1, windows1252), `LineEndingStyle` enum (lf, crlf, cr), `DecodedText`
  (text + encoding + lineEnding), and `TextCodecService`:
  `detectAndDecode(bytes) -> DecodedText` (never throws — worst case a lossy but safe
  decode) and `encode(text, encoding, lineEnding) -> Uint8List`. Includes the compact
  UTF-16 and Windows-1252 codecs.

### New — undo/redo + editor controller (3.2) · `lib/core/editor/`
- `undo_redo.dart` — a **command stack**: `TextReplacement(offset, removed, inserted)`
  (stores only the changed slices, so large documents stay light) with `invert()`, and an
  `UndoRedoStack` that applies/inverts commands, supports `canUndo`/`canRedo`, and
  coalesces consecutive typing so undo steps are word-sized (responsiveness).
- `editor_controller.dart` — pure-Dart `EditorController`: current `text` + `selection`,
  `replace(range, text)` (records a command), `undo()` / `redo()`, dirty flag, and a
  change notifier hook. No Flutter dependency.

### New — search (3.3) · `lib/core/search/`
- `search_options.dart` — `SearchOptions(caseSensitive, wholeWord, regex)`.
- `text_search.dart` — `SearchOutcome` (either `List<SearchMatch{start,end}>` or a
  friendly `errorMessage`); `find(text, query, options)` builds the `RegExp` (escapes a
  literal query, adds `\b…\b` for whole-word, sets the case flag) and **catches an invalid
  regex**, returning the error outcome instead of throwing (arch §6 "invalid pattern hint,
  never a crash").

### New — find & replace (3.4) · `lib/core/editor/`
- `find_replace.dart` — over `text_search`: `matchCount(...)` for the preview,
  `replaceOne(...)` / `replaceAll(...)` honoring `$1` capture-group refs (via
  `replaceAllMapped` for regex, literal otherwise) and a **scope** (`TextRange?` = whole
  file / selection; format-specific scopes — CSV column, JSON/XML subtree — reduce to a
  range the format module supplies later). Returns `{newText, replacedCount}`.

### New — draft / auto-save (3.5) · `lib/core/editor/`
- `draft_store.dart` — `DraftStore(baseDir, DraftsIndexRepository)`:
  `save(fingerprint, content)` (write draft file + upsert index),
  `load(fingerprint) -> String?`, `discard(fingerprint)` (delete file + index row),
  `hasDraft(fingerprint)`. Plus a small, testable `AutoSaver` (interval + "get current
  content" callback + injected clock) that periodically calls `save`; the draft is cleared
  by `AtomicSaver` after a real save.

### New — atomic save (3.6) · `lib/core/editor/`
- `atomic_saver.dart` — `SaveTarget` abstraction (`canOverwrite`, `writeOverwrite(bytes)`,
  `writeCopy(name, bytes)`), a `SaveGate` (pluggable `String -> GateResult`, default
  "always ok"; JSON/XML register a real one later), and `AtomicSaver.save(...)` /
  `saveAsCopy(...)`: encode via `TextCodecService`, run the gate, temp-write-verify, then
  push. Read-only target (`canOverwrite == false`) offers **copy only**. Returns a typed
  `SaveResult` (saved / blockedByGate / readOnlyNeedsCopy).
- `saf_save_target.dart` — the real `SaveTarget` backed by `SafService`
  (`writeBytes` for overwrite, new `createDocument` for copy).

### New — unsaved changes (3.7) · `lib/shell/tabs/` (+ core enum)
- `lib/core/editor/unsaved_changes.dart` — `UnsavedChangesAction` enum (save, saveAsCopy,
  discard, cancel).
- `lib/shell/tabs/unsaved_changes_dialog.dart` — the Material 3 dialog returning that enum;
  wired into tab close / switch-away / app-exit. `TabsController` close guards already
  block a silent close; this adds the actual prompt and routes Save / Save-as-copy /
  Discard.

### New — read-only lock (3.8)
- `TabsController.setReadOnly(id, bool)` (in `tabs_controller.dart`) + a lock
  toggle/indicator surfaced in the tab area; a locked editor rejects edits until unlocked.

### New — metadata (3.9) · `lib/core/metadata/`
- `file_metadata.dart` — `FileMetadata(name, size, createdAt?, modifiedAt?, encoding,
  lineEnding, Map<String,String> formatFields)` and `MetadataService.build(...)` from a
  `SafFile` + `DecodedText` + an optional per-format field hook.

### Changed
- `lib/core/storage/saf_service.dart` — add `createDocument(...)` (and opportunistic
  `statDocument(...)` for dates) with typed errors, mirroring the existing wrappers.
- `android/app/src/main/kotlin/.../MainActivity.kt` (or the SAF handler) — Kotlin
  `createDocument` via `ACTION_CREATE_DOCUMENT`, taking a persistable permission on the new
  URI (owed on-device check).
- `lib/shell/tabs/tabs_controller.dart` — `setReadOnly`, and hooks so the editor sets
  `isDirty`.
- `pubspec.yaml` — add `path_provider` (and, only if you pick the alternative in decision
  2, `enough_convert`).
- `docs/implementation-progress.md` — flip Phase 3 rows to ✅ and update the summary table.

### New — tests (mirror arch §12; each task's "Test")
- `test/core/editor/encoding_test.dart` — round-trip each encoding + line-ending style;
  wrong-encoding bytes decode safely, never throw (3.1).
- `test/core/editor/undo_redo_test.dart` — an edit sequence + undo/redo returns exact prior
  states; coalescing groups typing (3.2).
- `test/core/search/text_search_test.dart` — case / whole-word / regex return correct match
  sets; invalid regex → error outcome, no throw (3.3).
- `test/core/editor/find_replace_test.dart` — regex replace with `$1`; scope limits the
  replace; preview count equals actual (3.4).
- `test/core/editor/draft_store_test.dart` — simulate a kill mid-edit (write draft, no
  save); next open surfaces it; a real save clears it (3.5).
- `test/core/editor/atomic_saver_test.dart` — interrupted write leaves the original intact;
  read-only target offers copy only; gate blocks invalid content (3.6).
- `test/shell/unsaved_changes_widget_test.dart` — each exit path (close tab / switch away)
  shows the prompt; discard vs cancel behave (3.7).
- `test/shell/read_only_lock_widget_test.dart` — locked editor rejects edits; unlock
  restores them (3.8).
- `test/core/metadata/file_metadata_test.dart` — metadata for a sample file matches
  expected values (3.9).
- Test helpers: a `FakeSaveTarget` (records writes, can throw mid-write, toggle
  `canOverwrite`) and a temp-dir `DraftStore`.

## 5. Test / verify plan

- `flutter analyze` → zero issues.
- `flutter test` → all new + existing tests green.
- Manual (owed, recorded in the change log, not blocking): on a device — Save-as-a-copy via
  the new `createDocument`, and an overwrite save through a real SAF URI. No emulator run is
  part of this change.

## 6. Risks / notes

- **Biggest phase so far (9 tasks).** I will land it in one approved pass but in a sensible
  order: encoding → undo/redo → search → find&replace → draft → atomic save → metadata
  (all pure + tested), then the two widgets (unsaved dialog, read-only) + the native SAF
  method. If you'd prefer I split approval (e.g. cores first, widgets/native second), tell
  me and I'll re-scope.
- **Native SAF `createDocument` + metadata dates** are the only non-host-testable bits;
  their on-device behavior is an owed manual check, consistent with Phases 1–2.
- **Security (security-rules):** file bytes and text are **never logged**; encoding
  detection and all parsers have a no-throw failure path; atomic temp-then-push protects
  the original; drafts live only in app-private storage. No secrets are involved in this
  phase.

## 7. Out of scope (later phases)

- The on-screen `TextField` editor and TXT viewer/stats (Phase 4); format-specific scopes
  and pre-save gates for JSON/XML (Phases 8–9); large-file streaming / paged view-only mode
  and tab memory release (Phase 10); share / print / export / TTS (Phase 5); the full
  Settings sections for editor defaults (Phase 11).
