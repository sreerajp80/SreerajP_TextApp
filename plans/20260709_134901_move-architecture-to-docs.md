# Plan: Move architecture.md into the docs folder

**Status:** completed

## The issue

`architecture.md` sits at the project root, but the other design documents
(`TextData-Idea.md`, `security-rules.md`, `workflow-rules.md`) all live in `docs/`.
The user wants `architecture.md` moved into `docs/` too, and `CLAUDE.md` updated to
point at the new location.

Moving the file changes the relative paths in the links, so links inside the file and
links pointing to it must be fixed, or they will break.

## Files to change

1. **`architecture.md` → `docs/architecture.md`** (move the file)
   - Its own internal links must change because it moves one folder deeper:
     - `[CLAUDE.md](CLAUDE.md)` → `[CLAUDE.md](../CLAUDE.md)`
     - `[docs/TextData-Idea.md](docs/TextData-Idea.md)` → `[TextData-Idea.md](TextData-Idea.md)`

2. **`CLAUDE.md`** — update every link that points to `architecture.md`:
   - Line 4: `[architecture.md](architecture.md)` → `[architecture.md](docs/architecture.md)`
   - Line 26: `[architecture.md](architecture.md)` → `[architecture.md](docs/architecture.md)`
   - Line 67 (the "where things live" map): `architecture.md` → `docs/architecture.md`
   - Line 73: `see architecture.md` → `see docs/architecture.md`

3. **`docs/security-rules.md`** — line 6 link is now in the same folder:
   - `[../architecture.md](../architecture.md)` → `[architecture.md](architecture.md)`

## Not changed

- `plans/` and `change_log/` files that mention `architecture.md` are historical
  records of past work. They are left as-is.

## Plan for the fix

1. Create `docs/architecture.md` with the current content, with its two internal
   links updated as above.
2. Delete the old root `architecture.md`.
3. Update the four link spots in `CLAUDE.md`.
4. Update the one link in `docs/security-rules.md`.
5. Write a change log to `change_log/`.
