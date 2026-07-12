# Plan: Create phased implementation plan and progress-tracking docs

**Status:** completed

## What the issue is

The project has three design docs — [TextData-Idea.md](../docs/TextData-Idea.md)
(product idea), [architecture.md](../docs/architecture.md) (technical design), and
[security-rules.md](../docs/security-rules.md) (security rules). They describe **what**
to build and **how** it is structured, but there is **no build order**. Nothing says
which parts come first, what each part depends on, or how to track progress.

The user asked for two new documents:

1. A **phased implementation plan** that breaks the whole app into ordered phases and
   marks how each phase depends on the others.
2. A **progress-tracking document** to record how far each phase and task has been
   built.

This plan file is only about creating those two documents. It does **not** write any
app code.

## Critical analysis (what drives the phasing)

Reading the three docs together, these facts shape the build order:

- **Layered architecture** (architecture.md §2): lower layers never depend on upper
  layers. So the data/platform layer and shared core must exist before UI and formats.
- **One shared core** (idea "Shared Capabilities", architecture §6): search, TTS,
  editor, export, print, share, zip, metadata are built once. Formats depend on them,
  so the shared core comes before per-format work.
- **SAF-only file access and content fingerprint** (idea NFRs, architecture §4/§11):
  every screen that opens or remembers a file needs these first.
- **Editor core** (architecture §6) is the heart of "never lose edits" and is reused by
  all five formats — it is a hard dependency for every editor.
- **Tabs need device RAM** for the auto cap (idea "Tab limit"); tabs hold documents in
  memory, so large-file streaming/virtualization is a cross-cutting concern.
- **P2P sync** (architecture §9) is app-agnostic and moves opaque strings. It depends on
  the data layer (to build/apply payloads) and secure storage/crypto, but is otherwise
  independent of the format work — so it can run as a parallel track.
- **Security rules** apply across everything but concentrate in sync, storage, secrets,
  and file input — those get a dedicated hardening pass.
- **TXT is the simplest format** and exercises the whole vertical slice (open → view →
  edit → save), so it is the first format and proves the shared core.

## The plan for the fix

Create two new Markdown files under `docs/`:

### 1. `docs/implementation-plan.md`

A phased build plan at **deep / spec-like** detail (user choice): each phase lists its
goal, its main **tasks** broken down concretely, and its **depends-on** phases. For each
task the doc records **acceptance criteria**, **test notes** (tying to architecture §12),
and the **target file paths** (from architecture §4). Each phase also names the
open-source packages it introduces. Proposed phase list:

- **Phase 0 — Project scaffold**: Flutter project, folder layout (architecture §4),
  Riverpod, Material 3 base, lint/test setup. *Depends on: none.*
- **Phase 1 — Data & platform foundation**: SAF file access + persistable URIs, content
  fingerprint, prefs, secure storage, local DB (recents/bookmarks/favorites/drafts
  index), ConfigService + `app_config.json`. *Depends on: 0.*
- **Phase 2 — App shell**: themes (light/dark/sepia), adaptive navigation, Home/Recent
  screen, onboarding/empty state, tab system with memory-aware cap and swipe.
  *Depends on: 1.*
- **Phase 3 — Shared editor core + shared read services**: encoding detect/convert,
  editor controller, undo/redo, find & replace (regex + scope), draft store, atomic
  saver, read-only lock, unsaved-changes flow, shared search, metadata. *Depends on: 1
  (uses SAF, fingerprint, DB); integrates into shell from 2.*
- **Phase 4 — TXT format (first vertical slice)**: viewer (word-wrap, gutter,
  jump-to-line, URL detection), editor via core, stats, encoding switch, split/merge.
  *Depends on: 2, 3.*
- **Phase 5 — Output & utility services**: share, zip, print, export/convert
  (PDF/HTML/DOCX/…), TTS (English + Malayalam guided install). *Depends on: 3; wired
  into TXT and later formats.*
- **Phase 6 — Markdown**: rendered/raw toggle, TOC, GFM, LaTeX (planned), formatting
  toolbar. *Depends on: 3, 5.*
- **Phase 7 — CSV**: table grid (freeze, hide/show, sort, filter), parsing/type
  inference, insights, in-grid editing, duplicate removal, export rows. *Depends on:
  3, 5.*
- **Phase 8 — JSON**: pretty/tree/raw/minified, tree nav, validate (+ optional schema),
  NDJSON, lenient JSONC/JSON5 read, big-number handling, editor. *Depends on: 3, 5.*
- **Phase 9 — XML**: pretty/tree/raw, tree nav, well-formedness, entities/namespaces/
  CDATA, optional XSD via platform channel, editor. *Depends on: 3, 5.*
- **Phase 10 — Large-file handling (cross-cutting)**: streaming parse, list
  virtualization, degraded/paged view-only mode, tab memory release. *Depends on:
  4/6/7/8/9 (applied to each format); can start after 4.*
- **Phase 11 — Settings completion**: all sections (Appearance, Editor, Files & Tabs,
  Speech, Sync, Security, About). *Depends on: the features each toggle controls;
  finalized late.*
- **Phase 12 — P2P LAN sync (parallel track)**: constants, crypto, bounded reader,
  transport (connect-then-choose), provider, payload build/validate/merge, sync UI.
  *Depends on: 1 (data layer, secure storage); can run in parallel with 4–9.*
- **Phase 13 — Security, accessibility, localization, polish**: security hardening pass
  against `security-rules.md`, app-lock/screenshot protection, a11y, localization,
  error/empty states. *Depends on: all feature phases.*
- **Phase 14 — Testing & release**: full test suite per architecture §12 (sync loopback,
  parser failure paths, editor atomic save/encoding, config/allow-list), manual
  two-device sync check, release prep. *Depends on: all.*

The doc will also include a **dependency diagram** (ASCII) showing the critical path
(0 → 1 → 2/3 → 4 → 5 → formats) and the parallel sync track (1 → 12), plus a short note
on which phases can overlap.

### 2. `docs/implementation-progress.md`

A living progress tracker. It will contain:

- A **status legend** (Not started / In progress / Blocked / Done).
- One **table per phase** listing each task, its status, and a notes column, with a
  per-phase overall status and a top-level summary line.
- A short "how to update this file" note so progress is recorded as work lands (and
  cross-links to the change logs).

### Cross-links

Both new files will link back to the three design docs and to `CLAUDE.md`. I will also
add a one-line pointer to each in the "Where things live" list is **not** required, but
I will mention them in the docs' own intro. (No change to `CLAUDE.md` unless you ask.)

## Files to be changed

- `l:\Android\SreerajP_TextApp\docs\implementation-plan.md` — new file (phased plan +
  dependency diagram).
- `l:\Android\SreerajP_TextApp\docs\implementation-progress.md` — new file (progress
  tracker).

## After implementing

Write a change log to `change_log/` referencing this plan.
