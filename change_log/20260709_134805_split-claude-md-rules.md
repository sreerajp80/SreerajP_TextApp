# Change log: Split security and workflow rules out of CLAUDE.md

Implements plan: [../plans/20260709_134541_split-claude-md-rules.md](../plans/20260709_134541_split-claude-md-rules.md)

## What changed

Moved two large, situation-specific sections out of `CLAUDE.md` so they no longer load
into context every session. They are now read on demand.

- **New file `docs/security-rules.md`** — holds the full Security rules (was Section 4
  of `CLAUDE.md`). Links back to `CLAUDE.md` and `architecture.md`.
- **New file `docs/workflow-rules.md`** — holds the full Workflow rules: plan before
  changing, approval gate, and log after changing (was Section 7 of `CLAUDE.md`).
- **`CLAUDE.md` Section 4** — replaced the full security text with a short pointer that
  tells the reader to open `docs/security-rules.md` before changing security-sensitive
  code.
- **`CLAUDE.md` Section 7** — replaced the full workflow text with a short pointer to
  `docs/workflow-rules.md`, keeping a one-line summary of the process.
- **`CLAUDE.md` Section 5 ("Where things live")** — added entries for the two new files.

All new `.md` files live under `docs/`; only `CLAUDE.md` stays at the project root, per
the user's instruction.

## Why

`CLAUDE.md` is always loaded. Plain linked files are not auto-loaded, so linking these
two sections (with a normal markdown link, not an `@import`) keeps them out of the
always-on context and reads them only when a relevant task needs them.

## Not changed

Sections 1, 2, 3, 6, and 8 of `CLAUDE.md` are unchanged. The rule text itself was moved
verbatim, not edited.
