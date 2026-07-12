# Plan: Split security and workflow rules out of CLAUDE.md

**Status:** completed

## What the issue is

`CLAUDE.md` is loaded into context on every session. Two large sections are only
needed in specific situations:

- **Section 4 — Security rules**: only needed when touching P2P sync, crypto,
  storage, logging, or other security-sensitive code.
- **Section 7 — Workflow rules**: the plan/approval/change-log process, needed when
  starting or finishing a change.

Keeping the full text of both in `CLAUDE.md` makes the always-on context bigger than
it needs to be.

## The plan for the fix

1. Create two new files under `docs/` (all `.md` files live in `docs/`, except
   `CLAUDE.md` which stays at the project root):
   - `docs/security-rules.md` — holds the full text now in Section 4.
   - `docs/workflow-rules.md` — holds the full text now in Section 7
     (plan-before-changing and log-after-changing).
2. In `CLAUDE.md`, replace the body of each of those two sections with a **short
   pointer** that tells the reader to open the matching file when doing that kind of
   work. Use a normal markdown link (not an `@import`), so the file is read on demand
   and does **not** auto-load into context every session.
3. Keep the section headings and numbering in `CLAUDE.md` so the structure stays the
   same. Sections 1, 2, 3, 5, 6, 8 stay unchanged.
4. Update the "Where things live" section (Section 5) to list the two new files.

### How "load only when needed" works

Claude Code always loads `CLAUDE.md`. It does **not** auto-load plain files that are
only linked. So a linked file is read only when the assistant chooses to open it for
a relevant task. The pointer text will make that trigger clear (for example: "Read
`security-rules.md` before changing any security-sensitive code").

## Files to be changed

- `l:\Android\SreerajP_TextApp\CLAUDE.md` — trim Sections 4 and 7 to pointers; update Section 5.
- `l:\Android\SreerajP_TextApp\docs\security-rules.md` — new file (moved Section 4 content).
- `l:\Android\SreerajP_TextApp\docs\workflow-rules.md` — new file (moved Section 7 content).

## After implementing

Write a change log to `change_log/` referencing this plan.
