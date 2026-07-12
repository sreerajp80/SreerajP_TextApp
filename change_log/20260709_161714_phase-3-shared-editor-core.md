# Change Log — Phase 3: Shared editor core + shared read services

**Date:** 2026-07-09 16:17 (local)
**Implements plan:** [plans/20260709_161714_phase-3-shared-editor-core.md](../plans/20260709_161714_phase-3-shared-editor-core.md)
**Design source:** [docs/architecture.md](../docs/architecture.md) §6, §4, §11.
Rules: [CLAUDE.md](../CLAUDE.md), [docs/security-rules.md](../docs/security-rules.md).

---

## Summary

Built the one shared editing engine and the read-side services every file format
will reuse (Phase 3, tasks 3.1–3.9). This is the highest-value shared code and is
almost all **pure Dart**, so it is unit-tested on the host with no device. The
on-screen `TextField` editor and save wiring are intentionally left for Phase 4
(TXT). Two small widgets ship now because they plug into the existing tab shell:
the unsaved-changes dialog and the read-only lock.

All work followed the approved plan. `flutter analyze` reports **no issues** and
`flutter test` is **green at 131 tests** (18 new test cases added across 8 files).

## What changed

### New — core editor (`lib/core/editor/`)
- `encoding.dart` — `TextCodecService`: detects UTF-8/UTF-8-BOM/UTF-16 LE+BE/
  ASCII/Latin-1/Windows-1252 (BOM sniff → strict UTF-8 validation → single-byte
  fallback, plus a BOM-less UTF-16 heuristic) and CRLF/CR/LF line endings;
  normalizes newlines to `\n` in memory and restores the original style on
  encode. Custom UTF-16 and Windows-1252 codecs — **no new encoding package**.
  Never throws on bad input.
- `undo_redo.dart` — `TextReplacement` command (stores only the changed slices)
  and `UndoRedoStack` with typing coalescing and `breakRun`.
- `editor_controller.dart` — pure-Dart `EditorController` (text + selection +
  undo/redo + dirty flag + read-only guard), no Flutter dependency.
- `find_replace.dart` — `FindReplace` with `$1`/`$$` capture references, scope
  ranges, match-count preview, and safe handling of an invalid regex.
- `draft_store.dart` — `DraftStore` (private draft files keyed to the content
  fingerprint, indexed in `drafts_index`) + `AutoSaver` (save-if-changed tick);
  `draftStoreProvider` uses `path_provider`'s support directory.
- `atomic_saver.dart` — `AtomicSaver` (encode → well-formedness gate → single
  verified write), `SaveTarget`/`SaveGate`/`AlwaysValidGate` abstractions, and a
  typed `SaveResult` (saved / savedAsCopy / blockedByGate / readOnlyNeedsCopy /
  failed).
- `saf_save_target.dart` — `SafSaveTarget`: temp-write-then-verify locally, then
  push through the SAF URI; "Save as a copy" via the new `createDocument`.
- `unsaved_changes.dart` — `UnsavedChangesAction` enum.

### New — search + metadata
- `lib/core/search/search_options.dart`, `lib/core/search/text_search.dart` —
  shared search with a `SearchOutcome` (matches or friendly error).
- `lib/core/metadata/file_metadata.dart` — `FileMetadata` + `MetadataService`
  (name/size/encoding/line-ending + per-format hook; modified date via native
  `modifiedTime`, nullable).

### New — shell wiring (`lib/shell/tabs/`)
- `unsaved_changes_dialog.dart` — `showUnsavedChangesDialog` (Save / Save a copy /
  Discard; hides Save for a read-only tab; dismiss = cancel).
- `read_only_lock_button.dart` — `ReadOnlyLockButton` + `ReadOnlyBanner`.

### Changed
- `lib/core/storage/saf_service.dart` — added `createDocument`, `isWritable`, and
  `modifiedTime` wrappers (typed errors, no raw platform exceptions).
- `android/.../SafChannel.kt` — native `createDocument` (ACTION_CREATE_DOCUMENT,
  writes the bytes + takes a persistable grant), `isWritable`, and `modifiedTime`;
  refactored `onActivityResult` to route pick vs create.
- `lib/shell/tabs/tabs_controller.dart` — `setReadOnly` / `toggleReadOnly`.
- `lib/shell/tabs/tabs_workspace.dart` — replaced the placeholder close prompt
  with the real unsaved-changes dialog; added a thin document toolbar hosting the
  read-only lock and the read-only banner.
- `pubspec.yaml` — added `path_provider: ^2.1.5`.
- `docs/implementation-progress.md` — Phase 3 rows → ✅, totals updated to 27/86.

### New — tests (18 cases)
- `test/core/editor/encoding_test.dart`, `undo_redo_test.dart`,
  `find_replace_test.dart`, `draft_store_test.dart`, `atomic_saver_test.dart`
- `test/core/search/text_search_test.dart`
- `test/core/metadata/file_metadata_test.dart`
- `test/shell/unsaved_changes_widget_test.dart`, `read_only_lock_widget_test.dart`

## Notable decisions (as approved in the plan)

1. Editor core is **pure Dart**; the Flutter `TextField` binding is deferred to
   Phase 4.
2. Encoding uses **custom, dependency-free** UTF-16 and Windows-1252 codecs.
3. Added **`path_provider`** (only new runtime package) for the draft store.
4. Added native SAF **`createDocument`** for Save-as-a-copy; its on-device
   behavior is an owed manual check.

## Security notes (security-rules)

- File bytes, decoded text, and draft content are **never logged**. Save errors
  are generic and user-safe (no path/content leaked).
- Encoding detection and all search/replace paths have no-throw failure paths.
- The atomic saver materializes and verifies the full bytes before touching the
  original, and the SAF target writes to a private temp first — a failed or
  blocked save never corrupts the original file.
- Drafts live only in app-private storage.

## Verification

- `flutter analyze` → **No issues found**.
- `flutter test` → **All tests passed (131)**.
- **Owed manual (on device):** Save-as-a-copy via `createDocument`, an overwrite
  save through a real SAF URI, and the metadata modified-date read. Not run as
  part of this change (no device/emulator in this environment).
