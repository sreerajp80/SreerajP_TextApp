# Plan — Format Enhancements (roadmap §4.2, §4.3, §4.4)

**Status:** completed

Implements all ten "High-Impact Improvements" listed in
[docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md)
under §4.2 (CSV), §4.3 (JSON & XML) and §4.4 (Markdown).

---

## 1. What the issue is

The roadmap lists ten improvements to formats the app already supports. None of
them are built yet:

**§4.2 CSV**
1. Multi-column sorting — today only one column can be sorted at a time.
2. Calculated formula columns — no spreadsheet-style formulas at all.
3. Conditional formatting rules — every cell looks the same.
4. Interactive data charting — there is only one small read-only bar chart
   inside the insights sheet.

**§4.3 JSON & XML**
1. JSON array-to-table grid view — a uniform array of objects can only be read
   as a tree or as text.
2. Query builder — JSONPath and XPath must be typed by hand.
3. Schema auto-fix — a broken file reports an error but offers no fix.

**§4.4 Markdown**
1. Split-screen live dual view — a split exists, but only inside edit mode, it
   is chosen by screen *width* (not orientation), and the two panes cannot be
   resized.
2. Visual table builder — the table button inserts a fixed skeleton the user
   must align by hand.
3. YAML front-matter form editor — front matter is shown read-only in a banner.

## 2. Design decisions (made up front)

These choices shape the code, so they are stated here rather than discovered
half-way through.

- **No new packages.** `fl_chart`, `two_dimensional_scrollables`, `xml` and
  `csv` are already dependencies. Nothing commercial is added
  (CLAUDE.md §3.1).
- **Pure logic first.** Every feature gets a plain-Dart file with no Flutter
  import, so it can be host-tested, and a thin widget on top. This matches how
  the format modules are already built.
- **Never crash on bad input** (CLAUDE.md §3.4). Formula evaluation, quick
  fixes, table parsing and query building all return a friendly error value
  instead of throwing.
- **Calculated columns are materialised.** A formula column writes its computed
  text into the real table cells and is recomputed whenever the table changes.
  The file stays plain CSV, so save, export, insights and share need no special
  case. The formula itself is remembered per file, and the column is not
  hand-editable while a formula is set.
- **Front-matter edits are line-preserving.** The form rewrites only the lines
  the user actually changed and keeps every other original line untouched, so a
  YAML feature the small parser does not understand is never silently dropped.
- **New strings go in both ARB files** (`app_en.arb` and `app_ml.arb`), then
  `flutter gen-l10n` regenerates the committed `app_localizations*.dart`.

## 3. Files to be changed

### 3.1 CSV — §4.2

| File | New? | What happens |
| :--- | :--- | :--- |
| `lib/formats/csv/csv_filter_sort.dart` | change | Add `CsvSortSpec` (column + direction) and `CsvFilterSort.sortMulti(...)` — a stable multi-level comparator. Keep the existing single-column `sort` as a thin wrapper. |
| `lib/formats/csv/csv_sort_sheet.dart` | **new** | Sheet to build the sort hierarchy: ordered list of levels, each a column + asc/desc, with add / remove / reorder. |
| `lib/formats/csv/csv_formula.dart` | **new** | Pure formula evaluator: `=SUM(A1:A10)`, `PRODUCT`, `AVG`/`AVERAGE`, `MIN`, `MAX`, `COUNT`, cell refs (`A1`, or bare `B` = this row), ranges, numbers and `+ - * / ( )`. Returns a value or a friendly error; guards against self-reference. |
| `lib/formats/csv/csv_formula_sheet.dart` | **new** | Add / edit / clear a column formula, with a live preview of the first rows. |
| `lib/formats/csv/csv_conditional_format.dart` | **new** | Pure rule model (`CsvFormatRule`, `CsvCondition`: less than, greater than, equals, not equals, contains, is empty, is duplicate; `CsvHighlight`: red / yellow / green / blue) and an evaluator that answers "which highlight, if any, for this cell". |
| `lib/formats/csv/csv_conditional_format_sheet.dart` | **new** | Add / remove / list highlight rules. |
| `lib/formats/csv/csv_chart_data.dart` | **new** | Pure series builder: given the table, a value column and an optional label column, produce bar / line / pie series (with "top N + other" grouping for pie). |
| `lib/formats/csv/csv_chart.dart` | change | Add `CsvChartType { bar, line, pie }` and an interactive `CsvChartView` (touch tooltips) drawn with `fl_chart`. Keep the existing small `CsvColumnChart` used by the insights sheet. |
| `lib/formats/csv/csv_chart_screen.dart` | **new** | Full-screen chart page: chart-type selector, value-column and label-column pickers, the interactive chart. |
| `lib/formats/csv/csv_insights_sheet.dart` | change | Add an "Open full chart" button that pushes `CsvChartScreen`. |
| `lib/formats/csv/csv_grid.dart` | change | Header cell shows the sort level number when more than one level is active; data cells take their background from the conditional-format rules; a formula column's cells are not editable and carry a small formula icon. |
| `lib/formats/csv/csv_document_session.dart` | change | Hold the sort spec list, the per-column formulas and the format rules; recompute formula columns after every table change; persist all three per file through `KeyValueStore`; keep reading the old single-column sort keys so existing files still restore. |
| `lib/formats/csv/csv_toolbar.dart` | change | New sort-levels action; conditional-formatting and chart entries in the overflow menu. |
| `lib/formats/csv/csv_columns_sheet.dart` | change | Per-column "Set formula…" entry point. |

### 3.2 JSON & XML — §4.3

| File | New? | What happens |
| :--- | :--- | :--- |
| `lib/formats/json/json_table.dart` | **new** | Pure `JsonTable.fromNode(array)`: detects a tabular array (objects with overlapping keys, or scalars), builds the column union in document order, renders each cell to display text, and sorts by a column (numeric when the column is all numbers). |
| `lib/formats/json/json_table_view.dart` | **new** | Read-only grid built on `TableView.builder` (same engine as the CSV grid), header tap sorts, frozen header row. |
| `lib/formats/json/json_document_session.dart` | change | Add `JsonViewMode.table`, the selected array path, `tableFor(...)`, and sort state for the table view. |
| `lib/formats/json/json_document_view.dart` | change | Route the new mode to `JsonTableView`. |
| `lib/formats/json/json_tree_view.dart` | change | "View as table" action on an array node that holds objects. |
| `lib/formats/json/json_toolbar.dart` | change | Table mode entry (disabled when the document has no tabular array); query-builder entry. |
| `lib/formats/json/json_query_builder.dart` | **new** | Pure step model (root / key / index / all children / any-depth key) → a JSONPath string the existing `evaluateJsonPath` understands, plus next-step suggestions read from the real document. |
| `lib/formats/json/json_query_builder_sheet.dart` | **new** | Visual builder: tap to add a step from real keys, see the generated query and the live match count, then run or copy it. |
| `lib/formats/json/json_quick_fix.dart` | **new** | Pure quick fixes for common JSON errors: quote unquoted keys, single → double quotes, drop trailing commas, strip `//` and `/* */` comments, `True`/`False`/`None` → `true`/`false`/`null`. Each fix is offered only when it actually changes the text. |
| `lib/formats/json/json_tools_sheets.dart` | change | A "Quick fixes" section in the validate sheet, shown when the document is not strict JSON; each fix is one tap, then the sheet re-validates. |
| `lib/formats/xml/xml_query_builder.dart` | **new** | The XPath twin: element name / index / attribute / any-depth steps → an XPath string, with suggestions from real child element names. |
| `lib/formats/xml/xml_query_builder_sheet.dart` | **new** | The same visual builder for XPath. |
| `lib/formats/xml/xml_quick_fix.dart` | **new** | Pure quick fixes for XML: close tags left open at the end, escape a bare `&`, wrap several top-level elements in a single root, remove junk before the `<?xml …?>` declaration. |
| `lib/formats/xml/xml_tools_sheets.dart` | change | Same "Quick fixes" section in the XML validate sheet. |
| `lib/formats/xml/xml_toolbar.dart` | change | Query-builder entry. |

### 3.3 Markdown — §4.4

| File | New? | What happens |
| :--- | :--- | :--- |
| `lib/formats/markdown/md_live_preview.dart` | change | Rewrite: choose side-by-side vs top/bottom from **orientation** (landscape → side by side, portrait → stacked), add a draggable divider that sets the split ratio, and support a read-only source pane so the split also works outside edit mode. |
| `lib/formats/markdown/md_document_session.dart` | change | Add `splitRatio` + `setSplitRatio`, persist split on/off and ratio, and allow the split in `MdMode.raw`. |
| `lib/formats/markdown/md_document_view.dart` | change | Raw mode routes through the split view; front-matter banner becomes tappable to open the form. |
| `lib/formats/markdown/md_toolbar.dart` | change | Show the split toggle in raw mode too; add a "Front matter" overflow entry. |
| `lib/formats/markdown/md_table_source.dart` | **new** | Pure GFM table model: `MdTableData.parse(block)`, `toMarkdown()` (padded, aligned, pipes escaped), and `findTableAt(text, offset)` returning the span of the table under the cursor. |
| `lib/formats/markdown/md_table_builder_dialog.dart` | **new** | Grid of text fields, add / remove row and column, per-column alignment, live Markdown preview; returns the finished table text. |
| `lib/formats/markdown/md_format_toolbar.dart` | change | The table button opens the builder, pre-filled with the table under the cursor when there is one, and replaces that span. |
| `lib/formats/markdown/md_front_matter.dart` | change | Keep the original key spelling, the field order and each field's raw source line; add `render(...)` and `replaceIn(source, block)` so an edit rewrites only changed lines. |
| `lib/formats/markdown/md_front_matter_form.dart` | **new** | Form sheet generated from the front-matter fields: Title / Author as text, Date with a date picker, Tags as chips, everything else as plain text, plus "Add field". Writes back through the session. |

### 3.4 Shared

| File | What happens |
| :--- | :--- |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | All new user-facing strings (roughly 90 keys). |
| `lib/l10n/app_localizations*.dart` | Regenerated by `flutter gen-l10n`. |
| `docs/feature_analysis_and_roadmap.md` | Mark §4.2, §4.3 and §4.4 items as implemented, refresh the §2 audit table, and mark the matching Phase 15 bullets done. |

### 3.5 Tests

New: `test/formats/csv/csv_formula_test.dart`,
`csv_conditional_format_test.dart`, `csv_chart_data_test.dart`;
`test/formats/json/json_table_test.dart`, `json_query_builder_test.dart`,
`json_quick_fix_test.dart`; `test/formats/xml/xml_query_builder_test.dart`,
`xml_quick_fix_test.dart`; `test/formats/markdown/md_table_source_test.dart`,
`md_live_preview_widget_test.dart`, `md_front_matter_form_widget_test.dart`.

Extended: `test/formats/csv/csv_filter_sort_test.dart` (multi-level sorting),
`test/formats/csv/csv_document_session_test.dart` (formula recompute,
rule persistence), `test/formats/markdown/md_front_matter_test.dart`
(render / replace round-trip).

Each parser-like addition gets failure-path tests — bad formula, unparseable
table block, malformed query, broken XML — as CLAUDE.md §6 requires.

## 4. Order of work

1. CSV pure logic + tests (sort, formula, conditional format, chart data).
2. CSV UI (sheets, grid, chart screen, toolbar, session wiring).
3. JSON/XML pure logic + tests (table, query builders, quick fixes).
4. JSON/XML UI (table view, builder sheets, validate-sheet fixes).
5. Markdown pure logic + tests (table source, front matter).
6. Markdown UI (split view, table builder, front-matter form).
7. Strings, `flutter gen-l10n`, `flutter analyze`, `flutter test`.
8. Update the roadmap document, then write the change log.

## 5. Risks and how they are handled

- **Scope.** Ten features in one change is large. The order above keeps each
  format independently working, so an interruption never leaves a half-built
  format.
- **Formula loops.** A formula that refers to its own column is rejected with a
  clear message instead of recursing.
- **Front-matter data loss.** Handled by the line-preserving rewrite described
  in §2 — this is the main correctness risk in the Markdown work.
- **Grid performance.** Conditional-format duplicate detection is computed once
  per rule set, not per cell, so large files keep scrolling smoothly.
- **Existing files.** Old CSV sort persistence keys are still read, so a file
  opened after the update restores its sort as before.

## 6. Out of scope

- Full spreadsheet semantics (cross-file refs, IF/VLOOKUP, circular-reference
  resolution).
- Real JMESPath. The builder generates JSONPath / XPath, which the app's
  existing evaluators already run; adding a third query language is not needed
  to remove hand-typing, which is what §4.3.2 asks for.
- Editing inside the JSON table grid — it is a read-only view of the array.
- Full YAML in front matter (nested maps, anchors) stays unparsed and
  untouched.
