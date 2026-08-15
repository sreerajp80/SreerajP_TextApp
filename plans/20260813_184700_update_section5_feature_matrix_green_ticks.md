# Plan: Add status indicators and green ticks to Section 5 feature matrix

**Status:** completed

Change log: `change_log/20260813_184700_update_section5_feature_matrix_green_ticks.md`.

Plan file: `plans/20260813_184700_update_section5_feature_matrix_green_ticks.md`

Documentation-only change. No application code, dependencies, or tests affected.

---

## 1. Issue Description

In [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md), Section 5 ("Categorized Feature Matrix & Prioritization") lists 20 features and improvements in a table, but does not use green ticks (`✅`) or pending icons (`⬜`) in the `Feature Name` column for completed items, whereas Sections 3, 4, and 6 use `✅` and `⬜` icons for status visibility.

## 2. Proposed Changes

Update the table in Section 5 of [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) to add status prefixes (`✅` for completed/delivered features, `⬜` for planned/unbuilt features) to every item in the `Feature Name` column:

- `✅ **Embedded SQL Query Engine (CSV/JSON)**`
- `✅ **Optical Air-Gap Transfer (AirQR)**`
- `✅ **Ephemeral / Self-Destructing Workspace**`
- `✅ **Workspace-Wide SQLite FTS5 Indexer**`
- `✅ **Multi-Column CSV Sorting & Formulas**`
- `✅ **JSON Array-to-Table Grid View**`
- `✅ **Markdown Split-Screen Live Preview**`
- `✅ **Visual Markdown Table Builder GUI**`
- `⬜` for all 12 remaining planned/unbuilt items.

## 3. Files to be modified

- [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md)

## 4. Verification Plan

- Verify relative paths only and simple English.
- Verify status match between Section 5 and Sections 3, 4, and 6.

## 5. Change Log

To be written to `change_log/20260813_184700_update_section5_feature_matrix_green_ticks.md` after approval and completion.
