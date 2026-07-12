# Change Log: Create CLAUDE.md and architecture.md

**Date:** 2026-07-09
**Implements plan:** [plans/20260709_133802_claude-md-and-architecture-docs.md](../plans/20260709_133802_claude-md-and-architecture-docs.md)

## What was changed

Two new documentation files were created at the project root. No application code was written.

### 1. `CLAUDE.md` (new)

Project rules for the app and the AI assistant:
- App overview (Flutter Android editor for TXT / MD / CSV / JSON / XML).
- Fixed tech stack: Flutter 3.41.9+, Dart 3.11.5+, minSdk 26, Material 3.
- Hard rules: open-source-only libraries (Syncfusion banned), offline-first, scoped
  storage (SAF) only, never crash on bad input, atomic saves, never lose edits.
- Security rules: untrusted file input, P2P payload-layer crypto (PBKDF2 + AES-256-GCM,
  out-of-band pairing code), hostile-peer hardening, add-only client-wins merge,
  secret lifecycle, no secret logging, `Random.secure()`.
- "Where things live" map and testing expectations.
- The **global workflow rules** embedded: plan-before-change with the approval gate,
  status lifecycle, and log-after-change.
- The communication rule (always simple English).

### 2. `architecture.md` (new)

Full technical design:
- Design goals and a four-layer architecture (UI → State → Core/Services → Data/Platform).
- Recommended open-source packages per concern (state, SAF, secure storage, markdown,
  CSV/JSON/XML, TTS, QR, crypto, zip, export, share).
- Proposed `lib/` module layout.
- Modern UI approach (Material 3, dynamic color, adaptive, light/dark/sepia, tabs + swipe).
- Shared editor core (undo/redo, regex + scope find & replace, unsaved-changes, draft
  recovery, read-only lock, encoding/line-endings, atomic save, large-file degrade).
- Per-format module design (TXT, MD, CSV, JSON, XML).
- Settings screen with grouped sections (Appearance, Editor, Files & Tabs, Speech, Sync,
  Security, About). The **About section reads from a config file**
  (`assets/config/app_config.json` via a `ConfigService`), with an example JSON.
- **P2P LAN sync** design derived from the supplied guide: core security idea, `lib/sync/`
  module layout, connect-then-choose handshake, payload/validation/merge, secret lifecycle,
  sync UI, and Android permissions.
- Security architecture (modern measures) and non-functional requirements.
- Testing strategy.

## Notes

- State management is recommended as **Riverpod** (Provider/Bloc noted as acceptable
  alternatives) — presented as a recommendation, not a lock-in.
- All packages named are open source, honoring the licensing constraint.
- No `pubspec.yaml` or build tooling was created in this task (docs only).
