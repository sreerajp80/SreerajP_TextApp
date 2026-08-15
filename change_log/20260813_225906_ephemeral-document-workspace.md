# Change log — Ephemeral / Self-Destructing Document Workspace (Feature 9)

**Implements:** `plans/20260813_223410_ephemeral-document-workspace.md`
**Date:** 2026-08-13

---

## 1. What was built

Any open document tab can now be marked to self-destruct. It burns when either
trigger fires:

1. **A timer runs out** — 15 minutes, 1 hour, 4 hours, 24 hours, or a typed
   number of minutes.
2. **One output completes** — the first successful export, share, or print.

A countdown badge sits on the tab chip. A file can also be opened straight into a
self-destructing tab by long-pressing the "Open a file" button on Home, which
means the tab is marked before any trace of it is written.

## 2. What a burn removes

Opening a file used to leave seven traces that outlived the tab. A burn clears
all of them, for that one document:

| Trace | Store |
|-------|-------|
| The document's text, indexed for search | FTS5 table (`SearchIndexService`) — cleared **first** |
| Auto-save draft (the full text) | `drafts/` in app-private storage, zero-filled then deleted |
| Draft pointer row | `drafts_index` |
| Recents entry | `RecentsRepository` |
| Favourite | `FavoritesRepository` |
| In-document bookmarks | `BookmarksRepository` |
| Reading position and per-file view settings | `SharedPreferences` |

The search index goes first because it is the only store holding the document's
own content rather than a reference to it — so a burn interrupted part-way has
already dealt with the worst trace. Each step is guarded on its own and returns
the names of any that failed, so one unreachable store cannot leave the rest
behind, and the UI can say the burn was not complete.

Burning also force-closes the tab **without** the unsaved-changes prompt. That is
not a hole in `CLAUDE.md` §3.6: marking a tab ephemeral *is* the decision to
discard it, and the sheet says so before the mark is applied.

## 3. Prevention, not only cleanup

An ephemeral tab stops producing new traces the moment it is marked:

- `TabsPersistence.save` excludes it, so it is never written to `tabs.open_set`
  and cannot come back after a relaunch.
- `OpenFileAction` skips the recents write and the index write entirely when a
  file is opened as ephemeral.
- Every format session manager skips the search re-index on save.

## 4. Three limits, stated in code, UI and docs

These are written into the class comments, the sheet, the Settings screen, and
`docs/security-rules.md`, so nobody later reads more into the feature than it
delivers:

1. **The user's own file is never deleted.** The app is scoped-storage only
   (`CLAUDE.md` §3 rule 3). "Ephemeral" means the app forgets the document.
2. **A `0x00` overwrite is defence in depth, not a guarantee.** It defeats an
   ordinary undelete of the logical file; flash wear-levelling and the filesystem
   journal may keep the old blocks out of reach. Android's per-app file-based
   encryption is the real protection.
3. **A Dart `String` cannot be zeroed.** It is immutable and garbage-collected,
   so scrubbing text means dropping every reference. Only `Uint8List` buffers are
   genuinely overwritten in place.

## 5. A real bug found and fixed along the way

`scrubInMemory` zero-fills the raw byte buffer a session got from
`SafService.readBytes`. The TXT session test then failed, and the cause was worth
fixing rather than working around: **the session was zeroing a buffer it did not
own.** The real SAF read allocates a fresh buffer per call, but the test doubles
returned their own stored instance, so zeroing it corrupted the fake's "file" for
every later read.

The fix makes the ownership contract explicit instead of implicit:

- `SafService.readBytes` now documents that **the caller owns the returned
  buffer** and may modify it, and that any test double must copy for the same
  reason — a shared buffer would let one reader corrupt the next read.
- Every `SafService` test double now returns a copy: `FakeSafService` in
  `test/support/`, the five `RecordingSafService` doubles in the format session
  tests, and the CSV grid test double.

`test/core/constants/app_constants_test.dart` also caught the new settings keys
using an unregistered namespace, which is exactly what that guard is for; the
`ephemeral` namespace is now registered.

## 6. Files added

### `lib/core/ephemeral/`

| File | Holds |
|------|-------|
| `secure_wipe.dart` | Zero-fill-then-delete for a file; in-place zeroing of a `Uint8List`. Pure `dart:io`, no Flutter. |
| `ephemeral_models.dart` | `EphemeralDuration`, `EphemeralOption`, `EphemeralMark` |
| `ephemeral_policy.dart` | Pure timing rules — remaining, expiry, badge text. No I/O. |
| `ephemeral_wiper.dart` | The burn sequence, each step guarded |
| `ephemeral_controller.dart` | The marks, one shared 1-second ticker, the burn entry points |
| `ephemeral_settings.dart` | Sheet defaults (settings namespace `ephemeral`) |
| `ephemeral_badge.dart` | The countdown badge |
| `ephemeral_sheet.dart` | The self-destruct options sheet |

### `test/core/ephemeral/`

`secure_wipe_test.dart`, `ephemeral_policy_test.dart`, `ephemeral_wiper_test.dart`,
`ephemeral_controller_test.dart` — 50 tests covering the zero-fill (reading the
bytes back to prove every one is `0x00`), the expiry boundary, a clock that jumps
backwards, a full end-to-end trace wipe against real in-memory repositories, one
unreachable store not stopping the others, burn-after-output firing only on
success, and a burn closing a tab that has unsaved edits.

## 7. Files changed

| File | Change |
|------|--------|
| `lib/core/editor/draft_store.dart` | New `wipe()` — zero-fills the draft and any `.tmp` sibling before deleting |
| `lib/core/storage/saf_service.dart` | Documents the buffer-ownership contract on `readBytes` |
| `lib/core/constants/app_constants.dart` | Registers the `ephemeral` settings namespace |
| `lib/shell/tabs/tabs_controller.dart` | `burnTab()`; excludes ephemeral ids from the saved set |
| `lib/shell/tabs/tabs_persistence.dart` | `save()` takes `excludeIds` |
| `lib/shell/tabs/tab_strip.dart` | Countdown badge; menu gains make / change / keep / burn now, with a confirmation |
| `lib/shell/tabs/tabs_workspace.dart` | Burns the traces of an ephemeral tab closed by any other route |
| `lib/shell/open_file_action.dart` | Optional `ephemeral` parameter; skips recents and index writes |
| `lib/shell/home/home_screen.dart` | Long-press the open button → "Open as self-destructing" |
| `lib/shell/settings/sections/security_section.dart` | Defaults group plus "burn all now" and the honest wipe note |
| `lib/formats/*/(txt,md,json,csv,xml)_document_session.dart` | `scrubInMemory()`, called from `dispose()` |
| `lib/formats/*/(…)_session_manager.dart` | Skips the search re-index for an ephemeral tab |
| `lib/formats/*/(…)_output_actions.dart` | Optional `onOutputCompleted`, fired only on success |
| `lib/formats/*/(…)_toolbar.dart` | Passes the callback through |
| `lib/l10n/app_en.arb`, `app_ml.arb` | 36 new strings, English and Malayalam |
| `test/support/test_support.dart`, 6 test doubles | `readBytes` returns a copy (see §5) |
| `test/shell/tabs_controller_test.dart` | New test: an ephemeral tab is never written to the saved set |

Note: every session scrubs on dispose, not only ephemeral ones. It costs almost
nothing and means any closed tab stops holding a document in RAM.

## 8. Deviation from the plan

The plan said ephemeral sessions would never be released as background LRU
victims. That was implemented as **no restriction at all**, deliberately:
releasing a background session disposes it, which now runs the memory scrub and
frees the document from RAM. Keeping an ephemeral document loaded longer than a
normal one would work against the feature. Dirty tabs are still never released,
so nothing is lost.

## 9. Docs updated

- `docs/feature_analysis_and_roadmap.md` — Feature 9 marked **DELIVERED** with
  the trace table and the honest limits; Phase 18 ticked; the audit table and the
  feature matrix updated; **memory-only notes split out as their own item**.
- `docs/features.md` — added under §2.9 Security & Privacy.
- `docs/architecture.md` — new §14 covering the module layout, the burn order,
  and what the feature does and does not promise.
- `docs/security.md` — new §9.1 under Data retention and purge.
- `docs/security-rules.md` — rules that must hold for any future change here,
  including keeping `EphemeralWiper.fingerprintKeyPrefixes` in step with the
  format sessions.
- `docs/project_structure.md` — `lib/core/ephemeral/` added.

## 10. Scope left out

**Memory-only notes** (a document tab with no file behind it) are named in the
roadmap concept line and were **not** built. `DocumentTab.uri`, tab persistence,
all five session loaders, `AtomicSaver`, `SafSaveTarget`, and the external-change
watcher all assume a real SAF URI, so a fileless document is a comparable-sized
architectural change of its own. This was raised before implementation and
approved. It now stands as its own roadmap line in Phase 18.

## 11. Verification

- `flutter analyze` — **zero issues**.
- `flutter test` — **986 tests pass** (50 of them new).
- `dart format lib test` — applied.
- **No new dependency**; `pubspec.yaml` is untouched.

### Still to check by hand on a device

The countdown badge, the burn on expiry while the app sits in the background, and
the burn-after-export path have not been exercised on real hardware. Worth
checking before release: mark a tab with a 1-minute custom timer, confirm the
badge counts down and the tab closes, confirm the file no longer appears in
recents or in workspace search, and confirm the original file still opens fine
from the picker.
