# Ephemeral / Self-Destructing Document Workspace (Feature 9)

**Status:** completed

Change log: `change_log/20260813_225906_ephemeral-document-workspace.md`

Implements roadmap **Feature 9** from `docs/feature_analysis_and_roadmap.md`
(Phase 18, Ecosystem Synergy — from `SreerajPContactSphere`).

---

## 1. What the feature is

A user can mark any open document tab as **ephemeral**. An ephemeral tab
self-destructs when either trigger fires:

1. **A timer runs out** — the user picks 15 minutes, 1 hour, 4 hours, 24 hours,
   or a custom number of minutes.
2. **One output action completes** — "burn after export": the first successful
   share, export-save, or print of that document burns the tab straight away.

When a tab burns, the app removes every trace it owns of that document and
closes the tab. A countdown badge on the tab chip shows the time left.

---

## 2. The issue / why this needs care

The app is privacy-first and offline-first, but right now **opening any file
leaves a trail** in app-private storage that survives closing the tab:

| Trace left behind | Where |
|---|---|
| Auto-save draft file (full document text) | `drafts/` in app support dir, via `DraftStore` |
| Draft pointer row | `drafts_index` table |
| Recents row (URI, name, size) | `RecentsRepository` |
| Favorite row, if pinned | `FavoritesRepository` |
| Bookmarks in the document | `BookmarksRepository` |
| **Full document text, indexed for search** | FTS5 table, via `SearchIndexService` |
| Reading position + per-file view settings | `SharedPreferences`, keys ending in the fingerprint |
| The open-tab set | `tabs.open_set` pref, restored on relaunch |

For a document a user wants gone, all of that has to go too. The FTS index is
the sharpest edge: it stores the **document text itself**.

### Two honest limits (stated up front, and written into the UI)

- **The user's own file is never deleted.** The app is scoped-storage only
  (`CLAUDE.md` §3 rule 3) and has no business deleting a document out of the
  user's storage. "Ephemeral" means *the app forgets it* — RAM plus every
  app-private trace above. The confirm sheet will say this in one plain line.
- **`0x00` overwrite is defence in depth, not a guarantee.** On a flash device
  with wear-levelling and a journaling filesystem, overwriting a file's bytes
  does not reliably erase the physical blocks. Android's per-app file-based
  encryption is the real protection. We still do the overwrite (it defeats
  ordinary undelete on the logical file, and it is what the
  `SreerajPContactSphere` module does), but the docs and code comments will not
  claim more than it delivers.
- **Dart strings cannot be zeroed.** `String` is immutable and GC-managed, so
  "memory scrubbing" in Dart means *dropping every reference so the GC can
  reclaim it*: dispose the session, clear the editor controller, clear the
  cached raw bytes. Where the content is held as a `Uint8List` (the raw file
  bytes in each session) we **can** and will zero-fill in place. The code
  comment will say exactly this so nobody later believes more is happening.

---

## 3. Design

### 3.1 Single source of truth

A new `EphemeralController` (Riverpod `Notifier`) holds a
`Map<String tabId, EphemeralMark>`. `DocumentTab` is **not** changed — no
duplicated state, and the tab model stays a plain persisted value object.
Everything that needs to know (tab strip, persistence, workspace) reads the
controller.

```dart
class EphemeralMark {
  final String tabId;
  final String fingerprint;
  final String displayName;
  final int? expiresAtMillis;   // null = no timer
  final bool burnAfterOutput;   // burn on first successful export/share/print
}
```

One `Timer.periodic(1 s)` runs only while at least one timed mark exists. Each
tick recomputes the remaining time (badge) and burns anything expired. Wall
clock is injected as `int Function() now` so tests drive it without waiting.

### 3.2 The burn sequence

`EphemeralWiper.burn(mark)` runs these, each independently guarded so one
failure never blocks the rest:

1. Zero-fill and delete the draft file for the fingerprint, then drop its
   `drafts_index` row.
2. `SearchIndexService.remove(fingerprint)` — the indexed text goes first among
   the database rows, because it holds the content.
3. `RecentsRepository.remove(fingerprint)`.
4. `FavoritesRepository.remove(fingerprint)`.
5. `BookmarksRepository.clearForFile(fingerprint)`.
6. Remove every per-fingerprint preference key (the full list is enumerated in
   one constant, drawn from the sessions: `txt.pos.`, `md.pos.`, `md.preview.`,
   `json.pos.`, `xml.pos.`, `csv.pos.`, `csv.dir.`, `csv.sorts.`,
   `csv.formulas.`, `csv.rules.`).
7. Ask the owning format session to scrub in memory (`scrubInMemory()`:
   zero-fill `_rawBytes`, clear the code controller, drop `_savedText`), then
   release the session through the session managers.
8. `TabsController.burnTab(id)` — force-close, no unsaved-changes prompt.

Step 8 deliberately skips the unsaved-changes guard. That is not a hole in
`CLAUDE.md` §3.6: marking a tab ephemeral **is** the user's explicit decision to
discard it, and the confirm sheet says so before the mark is set.

### 3.3 Prevention, not only cleanup

Burning after the fact is the fallback. An ephemeral tab also stops making new
traces from the moment it is marked:

- `TabsPersistence.save()` filters ephemeral tab ids out, so an ephemeral tab is
  never written to `tabs.open_set` and never comes back on relaunch.
- Ephemeral tabs suppress FTS re-indexing on save (`onSaved` hook checks the
  controller) and are not recorded in recents on re-open.
- The auto-save draft still runs while the tab is open (edits must not be lost
  while the user is working — `CLAUDE.md` §3.6); the draft is wiped on burn.

### 3.4 Open-as-ephemeral

`OpenFileAction.openFile(..., ephemeral: EphemeralOption?)` gains an optional
parameter. When set, the recents write and the index write are **skipped
entirely** rather than cleaned up afterwards, and the mark is applied as soon as
the tab exists. The home screen's open button gets a long-press → "Open as
ephemeral".

### 3.5 Countdown badge

`EphemeralBadge` in the tab chip: a small timer icon plus `mm:ss` under an hour,
`h m` above it, turning to the theme error colour in the last 60 seconds. It
rebuilds off the controller's 1 s tick, so no extra timer per tab.

### 3.6 Burn-after-output hook

Each format's `*OutputActions` class gains an optional
`void Function()? onOutputCompleted`, fired after a **successful** share, zip
share, print, export-save, or export-share. Each format toolbar's `_output(ref)`
builder passes a closure calling
`EphemeralController.notifyOutputCompleted(tab.id)`, which burns the tab if its
mark has `burnAfterOutput`. A cancelled or failed action does not fire.

---

## 4. Explicitly out of scope (and why)

**Memory-only notes** (a document with no file behind it) are named in the
roadmap concept line. They are **not** in this change. Every layer below the tab
— `DocumentTab.uri`, `TabsPersistence`, all five `*_document_session.dart`
loaders, `AtomicSaver`, `SafSaveTarget`, the external-change watcher — assumes a
real SAF URI. Adding a fileless document is its own architectural change of
comparable size, and bolting it on here would make both harder to review. It is
proposed as a follow-up roadmap line. Everything else in the Feature 9
capability list (timer expiry, single-export destruction, zero-fill wiping,
countdown badges) is delivered by this change.

---

## 5. Files

### New — `lib/core/ephemeral/`

| File | What it holds |
|---|---|
| `secure_wipe.dart` | `SecureWipe.wipeFile(File)` — overwrite the file's length with `0x00`, flush, then delete. Pure `dart:io`, no Flutter. Also `SecureWipe.zeroBytes(Uint8List)`. |
| `ephemeral_models.dart` | `EphemeralMark`, `EphemeralDuration` enum (15 min / 1 h / 4 h / 24 h / custom), `EphemeralOption`. Immutable, `const` + `copyWith`. |
| `ephemeral_policy.dart` | Pure expiry maths: `remaining(now)`, `isExpired(now)`, `formatRemaining()` for the badge. No I/O, fully unit-tested. |
| `ephemeral_wiper.dart` | The burn sequence of §3.2 against injected repositories. No `BuildContext`, no strings. |
| `ephemeral_controller.dart` | `EphemeralController` `Notifier` + the 1 s ticker + `ephemeralControllerProvider`. |
| `ephemeral_badge.dart` | The countdown badge widget. |
| `ephemeral_sheet.dart` | The "Make this tab ephemeral" bottom sheet: duration choice, burn-after-export switch, and the plain-language warning that the user's own file is not deleted. |

### Changed

| File | Change |
|---|---|
| `lib/shell/tabs/tabs_controller.dart` | Add `burnTab(id)` (force-close, no prompt); filter ephemeral ids out of `_save()`. |
| `lib/shell/tabs/tabs_persistence.dart` | `save()` takes the ephemeral id set to exclude. |
| `lib/shell/tabs/tab_strip.dart` | Countdown badge on the chip; long-press menu gains "Make ephemeral…" / "Cancel ephemeral" / "Burn now". |
| `lib/shell/tabs/tabs_workspace.dart` | Never release an ephemeral session as a background LRU victim (its scrub must run through the wiper), and wire the burn confirmation. |
| `lib/shell/open_file_action.dart` | Optional `ephemeral` parameter; skip recents + index writes when set. |
| `lib/shell/home/*` (open button host) | Long-press → "Open as ephemeral". |
| `lib/formats/{txt,markdown,json,csv,xml}/*_document_session.dart` | Add `scrubInMemory()` — zero-fill `_rawBytes`, clear the code controller, drop the saved-text cache. 5 files, small additions. |
| `lib/formats/{txt,markdown,json,csv,xml}/*_session_manager.dart` | Skip the FTS `_reindex` hook for an ephemeral tab. 5 files, one guard each. |
| `lib/formats/{txt,markdown,json,csv,xml}/*_output_actions.dart` | Optional `onOutputCompleted` callback, fired on success. 5 files. |
| `lib/formats/{txt,markdown,json,csv,xml}/*_toolbar.dart` | Pass the callback in `_output(ref)`. 5 files, one line each. |
| `lib/shell/settings/sections/security_section.dart` | Default ephemeral duration + default burn-after-export, plus a "Burn all ephemeral tabs now" action. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | All new user-facing strings (roughly 22). No hard-coded UI text. |

### Tests — new, under `test/core/ephemeral/`

| File | Covers |
|---|---|
| `secure_wipe_test.dart` | File is zero-filled before deletion (read the bytes back from a copy taken mid-wipe), file is gone afterwards, missing file does not throw, read-only/locked file does not throw. |
| `ephemeral_policy_test.dart` | Remaining-time maths, expiry boundary, badge formatting under and over an hour, a custom duration, and a clock that jumps backwards. |
| `ephemeral_wiper_test.dart` | Every trace is removed with fakes for each repository; one failing repository does not stop the others; the user's SAF file is never touched. |
| `ephemeral_controller_test.dart` | Mark / cancel / expiry burn with an injected clock; burn-after-output fires once and only on success; a cancelled output does not burn. |
| `test/shell/tabs/tabs_persistence_test.dart` (extend) | An ephemeral tab is never written to `tabs.open_set`. |

---

## 6. Dependencies

**None added.** Everything uses `dart:io`, `dart:async`, Riverpod, and the
repositories already in the app. Nothing in `pubspec.yaml` changes.

---

## 7. Docs to update after implementation

- `docs/feature_analysis_and_roadmap.md` — mark Feature 9 delivered, with the
  scope note about memory-only notes remaining as a follow-up, and tick the
  Phase 18 line.
- `docs/features.md` — add the feature to the Sync & Security row.
- `docs/architecture.md` — add `lib/core/ephemeral/` and the burn sequence.
- `docs/project_structure.md` — add the new folder.
- `docs/security.md` / `docs/security-rules.md` — record the two honest limits
  from §2 so a later reader does not over-trust the wipe.

---

## 8. Verification

- `flutter analyze` — must stay at zero issues.
- `flutter test` — all existing tests plus the new ones green.
- `dart format lib test`.
- Manual check on device: mark a tab ephemeral with a 1-minute custom timer,
  confirm the badge counts down, confirm the tab closes on expiry, confirm the
  file no longer appears in recents or in the workspace search, and confirm the
  original file still opens fine from the picker.

---

## 9. Question for approval

Section 4 leaves **memory-only notes** out of this change. If you want them
included, say so and I will redraft with the fileless-document work added —
it roughly doubles the size, because the tab, persistence, and all five format
sessions each assume a SAF URI.

**Do you approve this plan?**
