# Change Log: Move architecture.md into the docs folder

Implements plan `plans/20260709_134901_move-architecture-to-docs.md`.

## What changed

1. **Moved `architecture.md` → `docs/architecture.md`** so it sits with the other
   design documents (`TextData-Idea.md`, `security-rules.md`, `workflow-rules.md`).
   Updated its own two internal links because it moved one folder deeper:
   - `[CLAUDE.md](CLAUDE.md)` → `[CLAUDE.md](../CLAUDE.md)`
   - `[docs/TextData-Idea.md](docs/TextData-Idea.md)` → `[TextData-Idea.md](TextData-Idea.md)`

2. **`CLAUDE.md`** — updated all four references to the new path:
   - Line 4 link → `docs/architecture.md`
   - Line 26 link → `docs/architecture.md`
   - "Where things live" map: `architecture.md` line replaced with `docs/architecture.md`
   - `lib/` module-map pointer → `docs/architecture.md`

3. **`docs/security-rules.md`** — line 6 link updated from `../architecture.md` to
   `architecture.md` (now in the same folder).

## Not changed

- `plans/` and `change_log/` files that mention `architecture.md` are historical
  records and were left as-is.

## Verification

- Searched the repo for `architecture.md`. All live references (CLAUDE.md,
  docs/security-rules.md) point to the correct new location. Only historical
  plan/change_log entries still show the old name, as intended.
