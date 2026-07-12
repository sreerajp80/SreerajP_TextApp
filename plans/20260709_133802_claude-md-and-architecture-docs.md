# Plan: Create CLAUDE.md and architecture.md

**Status:** completed

## What is the issue / goal

The project `SreerajP_TextApp` currently has only `docs/TextData-Idea.md` (the product
idea) and a supplied P2P LAN sync implementation guide. There is no `CLAUDE.md` (project
rules for the AI assistant) and no `architecture.md` (technical design). The user wants
both files created so future work has clear rules and a clear architecture to follow.

Key inputs:
- `docs/TextData-Idea.md` — the full product idea (TXT/MD/CSV/JSON/XML reader-editor,
  shared capabilities, app shell, per-format features, risks, non-functional requirements).
- The supplied "Offline P2P LAN Sync for Flutter" guide (attached in the request).
- User's extra requirements:
  - Flutter 3.41.9, Dart 3.11.5.
  - Most modern UI.
  - Editor should support the maximum features required.
  - A Settings screen with settings grouped into sections; an About section that shows
    values read from a **config file**.
  - P2P sync must be implemented.
  - All modern security measures must be applied.
- Global rules from the user's private global `CLAUDE.md` (plan-before-change, log-after-change,
  approval gate, simple-English communication) must be embedded into the project `CLAUDE.md`.

## Files to be changed (created)

1. `CLAUDE.md` (project root) — **new**
   - The global workflow rules (plan before changing, approval gate, log after changing,
     `plans/` + `change_log/` naming) copied in so they always apply for this project.
   - The communication rule (always simple English).
   - Project overview: what the app is (Flutter Android text/data editor for
     TXT/MD/CSV/JSON/XML).
   - Tech stack: Flutter 3.41.9+, Dart 3.11.5+, minSdk 26.
   - Hard licensing constraint: **every library must be open source** (no Syncfusion or
     source-available/commercial SDKs).
   - Security rules (untrusted file input, scoped storage / SAF only, P2P pairing-code +
     AES-GCM rules, never log secrets/keys/pairing code, atomic saves).
   - Coding conventions and project layout pointer (points to `architecture.md`).
   - Testing expectations (loopback tests for sync, parser failure paths, atomic-save tests).
   - A short "where things live" map and a pointer to `architecture.md` for full detail.

2. `architecture.md` (project root) — **new**
   - High-level architecture: layered design (UI → State → Services/Core → Data/Storage).
   - Tech choices with open-source package suggestions per concern (editor, markdown render,
     CSV/JSON/XML parse, TTS, QR, crypto, state management) — all open source.
   - Proposed folder/module layout under `lib/`.
   - Shared editor core design (undo/redo, find & replace with regex/scope, unsaved-changes,
     draft/auto-save recovery, read-only lock, encoding/line-ending handling, atomic save).
   - App shell & navigation (Home/Recent, tabs with memory-aware cap, bookmarks, favorites,
     share-into-app, first-run onboarding).
   - Per-format module design (TXT, MD, CSV, JSON, XML) at an architectural level.
   - Settings screen design: grouped sections (Appearance, Editor, Files & Tabs, Speech,
     Sync, Security, About). About section reads app name/version/build/author/links from a
     **config file** (e.g. `assets/config/app_config.json` loaded via a `ConfigService`).
   - Modern UI approach: Material 3, dynamic color, adaptive layouts, light/dark/sepia.
   - **P2P LAN sync** design section, derived from the supplied guide: connect-then-choose
     flow, PBKDF2 + AES-256-GCM, out-of-band QR/typed pairing code, bounded reads, timeouts,
     payload validation, add-only client-wins merge, allow-list of syncable settings, secret
     lifecycle, hostile-peer hardening checklist. Module layout under `lib/sync/`.
   - Security architecture: modern measures — scoped storage / SAF, no broad permissions,
     treat files as untrusted, AES-256-GCM sealed sync, PBKDF2 key stretching, secure
     random, secure storage for device keys (`flutter_secure_storage`), no secret logging,
     atomic writes, optional app-lock / screenshot protection on sensitive screens.
   - Non-functional requirements: 50 MB streaming/virtualization target, offline-first,
     accessibility/localization, error handling (never crash).
   - Testing strategy overview.

## Plan for the work

1. Create `plans/` folder (this plan already lives here).
2. Write `CLAUDE.md` at the project root with global rules + project rules.
3. Write `architecture.md` at the project root with the full technical design.
4. After approval and implementation, write a change log under `change_log/`.

No application code is written in this task — only the two documentation files (plus this
plan and, later, the change log). All recommended libraries will be open source to honor
the licensing constraint.

## Open assumptions

- State management: recommend **Riverpod** (open source) as the default in the architecture,
  noting Provider/Bloc are acceptable alternatives. Will call it a recommendation, not a lock-in.
- Config file for the About section: `assets/config/app_config.json` loaded at startup.
- These are documentation files; no build tooling is created yet (no `pubspec.yaml`).
