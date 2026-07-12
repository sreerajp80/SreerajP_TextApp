# Change log: Phased implementation plan and progress-tracking docs

**Implements plan:** [plans/20260709_135151_phased-implementation-docs.md](../plans/20260709_135151_phased-implementation-docs.md)

## What was done

Created two new documents under `docs/` after critically analysing the three design docs
(`TextData-Idea.md`, `architecture.md`, `security-rules.md`). No app code was changed.

### New files

- `docs/implementation-plan.md` — a phased build plan at **deep / spec-like** detail
  (user-chosen). It has:
  - **15 phases (0–14)**, from project scaffold to testing & release.
  - A **dependency map** (ASCII diagram) showing the critical path and the parallel P2P
    sync track, with overlap notes.
  - For each phase: goal, **depends-on** phases, the open-source packages it introduces,
    and concrete **tasks**. Each task lists **acceptance criteria**, a **test note** (tied
    to architecture §12), and **target file paths** (from architecture §4).
  - A summary table of phase order, dependencies, and which phases can overlap, plus the
    minimum critical path.

- `docs/implementation-progress.md` — a living progress tracker that mirrors the plan:
  - A **status legend** (⬜ Not started / 🟨 In progress / ⛔ Blocked / ✅ Done).
  - A **"how to update"** note.
  - A **summary table** (86 tasks total, all Not started) and **one table per phase**
    with a Status and Notes column per task.

## How the phasing was decided

Driven by the docs: the layered architecture (lower layers first), the shared core built
once and reused by all formats, SAF + content fingerprint as a base for any file screen,
the editor core as a hard dependency for every editor, TXT as the simplest first vertical
slice, and P2P sync as an app-agnostic parallel track that only needs the data layer.
Security and testing are dedicated late passes across the whole app.

## Notes

- Both new docs cross-link back to `CLAUDE.md` and the three design docs.
- `CLAUDE.md` was **not** changed (not required by the plan).
- Plan status moved: draft → approval_pending → in_progress → completed.
