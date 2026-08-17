# Change log: Add Flutter Guidelines submodule

**Plan:** `plans/20260716_073000_add-guidelines-submodule.md`
**Date:** 2026-07-16

## What changed

- Added the Git submodule `https://github.com/sreerajp80/Flutter_Guidelines` at `docs/guidelines/`.
- Updated [CLAUDE.md](../CLAUDE.md) under the workflow rules section to refer developers to the guidelines manifest.

## Why

To keep application development practices consistent across multiple apps by pulling in the shared Flutter guidelines repository and linking it in the central project documentation.

## Result

- Submodule is cloned and configured.
- Guidelines documents are available at `docs/guidelines/`.
- [CLAUDE.md](../CLAUDE.md) links to [docs/GUIDELINES_MANIFEST.md](../docs/GUIDELINES_MANIFEST.md).
