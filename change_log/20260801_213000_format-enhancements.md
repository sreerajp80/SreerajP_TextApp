# Change Log — Format Enhancements (roadmap §4.2, §4.3, §4.4)

**Implements:** [plans/20260801_211500_format-enhancements.md](../plans/20260801_211500_format-enhancements.md)

All ten "High-Impact Improvements" from
[docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md)
§4.2 (CSV), §4.3 (JSON & XML) and §4.4 (Markdown) are now built.

No new packages were added. `fl_chart`, `two_dimensional_scrollables`, `xml`
and `csv` were already dependencies, so the open-source-only rule
(CLAUDE.md §3.1) is unchanged.

---

## 1. CSV (§4.2)

### 1.1 Multi-column sorting
- `lib/formats/csv/csv_filter_sort.dart` — added `CsvSortSpec` (column +
  direction, with `encode`/`decode` for storage) and
  `CsvFilterSort.sortMulti(...)`, a **stable** multi-level comparator. The old
  single-column `sort` is now a one-level wrapper, so nothing else changed.
- `lib/formats/csv/csv_sort_sheet.dart` *(new)* — a sheet to build the
  hierarchy: add, remove and reorder levels, each with a column and a
  direction. Levels are edited in a working copy and only applied on "Apply
  sort", so a half-built hierarchy never reshuffles the grid.
- `csv_document_session.dart` — the session now holds a list of sort levels
  instead of one column. `sortColumn` / `sortDirection` still work (they read
  the first level), so the grid header and the saved reading position are
  unaffected. A header tap still cycles one column.
- `csv_grid.dart` — the header shows a level number when more than one level is
  active.
- **Old files keep working:** the hierarchy is stored under a new key, and the
  legacy single-column keys are still read as a fallback.

### 1.2 Calculated formula columns
- `lib/formats/csv/csv_formula.dart` *(new)* — a small recursive-descent
  evaluator: numbers, `+ - * /` with brackets, a column letter for this row
  (`B`), an absolute cell (`B2`), ranges (`A1:A10`, `A:A`), and `SUM`,
  `PRODUCT`, `AVG`/`AVERAGE`, `MIN`, `MAX`, `COUNT`. It never throws — a bad
  formula returns a friendly message (CLAUDE.md §3.4), and a formula that reads
  its own column is refused rather than looping.
- `lib/formats/csv/csv_formula_sheet.dart` *(new)* — set, change or clear a
  column's formula, with tappable column-letter chips, live validation, and a
  preview of the first rows.
- `csv_document_session.dart` — formulas are kept per column, recomputed into
  the table after every change, and remembered per file. **The values are
  materialised into the cells**, so save, export, share and insights need no
  special case and the file stays plain CSV. A calculated column is not
  hand-editable in the grid (a typed value would be overwritten) and carries a
  small formula icon in its header.

### 1.3 Conditional formatting
- `lib/formats/csv/csv_conditional_format.dart` *(new)* — pure rule model
  (`CsvFormatRule`, `CsvCondition`, `CsvHighlight`) and an evaluator prepared
  once per rule set. Duplicate detection is precomputed per column rather than
  re-scanned per cell, so a large grid keeps scrolling smoothly.
- `lib/formats/csv/csv_conditional_format_sheet.dart` *(new)* — list, add and
  remove rules; also maps each highlight onto theme-aware colours that stay
  readable in dark mode.
- `csv_grid.dart` — a matching cell takes its background from the first rule
  that matches, so the user's order is their priority.
- Rules are remembered per file.

### 1.4 Interactive charting
- `lib/formats/csv/csv_chart_data.dart` *(new)* — pure series building: one
  point per row for bar and line charts, totals per label for pie charts, with
  a cap on points, an "Other" slice for the tail, and negative values excluded
  from pies (they cannot be drawn as slices).
- `csv_chart.dart` — added `CsvChartView`, which draws bar, line and pie charts
  with touch tooltips and a pie legend. The existing small `CsvColumnChart` in
  the insights sheet is unchanged.
- `lib/formats/csv/csv_chart_screen.dart` *(new)* — the full-screen page: chart
  type, value column, optional label column, and a switch to chart only the
  rows the current filter shows.
- Reached from the CSV overflow menu and from "Open full chart" in the insights
  sheet.

---

## 2. JSON & XML (§4.3)

### 2.1 JSON array-to-table grid
- `lib/formats/json/json_table.dart` *(new)* — turns an array into a grid:
  columns are the union of the elements' keys in first-seen order, so a record
  missing a field leaves a blank cell instead of shifting the row. An array of
  plain values becomes a single `value` column. Nested values show their size
  (`{ 3 }`, `[ 2 ]`) rather than being flattened. Includes column sorting and a
  CSV export helper.
- `lib/formats/json/json_table_view.dart` *(new)* — a read-only grid on the
  same engine as the CSV grid; header tap sorts, cell tap copies.
- `json_document_session.dart` — new `JsonViewMode.table`, the selected array's
  path, and the table sort state. When the picked array disappears after an
  edit, the view falls back to the document's first usable array instead of
  showing an error.
- Reached from a new toolbar button (greyed out when the file has no usable
  array) and from "View as table" on an array node in the tree.

### 2.2 Visual query builders
- `lib/formats/json/json_query_builder.dart` *(new)* and
  `lib/formats/xml/xml_query_builder.dart` *(new)* — pure step models that
  produce a **JSONPath** / **XPath** string, plus next-step suggestions read
  from the open document (real keys, real element names, real attributes, real
  positions — capped so a huge array stays usable).
- `json_query_builder_sheet.dart` and `xml_query_builder_sheet.dart` *(new)* —
  the builders themselves: tap to add a step, see the query and its live match
  count, step back or start over, then copy or "Use this query".
- The built query is handed to the existing JSONPath / XPath sheets, which now
  take an `initialQuery` and run it straight away. **Running a query stays in
  one place**; the builder only writes it.
- Note: the roadmap named JMESPath. The stated goal is that users need not type
  raw syntax, and the app already evaluates JSONPath and XPath — so the builder
  targets those rather than adding a third query language.

### 2.3 Schema quick fixes
- `lib/formats/json/json_quick_fix.dart` *(new)* — quote bare keys, single →
  double quotes, drop trailing commas, strip `//` and `/* */` comments, and
  swap `True`/`False`/`None` for `true`/`false`/`null`. The scanners skip over
  string contents, so a comma, slash or keyword **inside a string** is never
  touched.
- `lib/formats/xml/xml_quick_fix.dart` *(new)* — close tags left open, escape a
  bare `&`, wrap several top-level elements in one root, and remove junk before
  the first tag. Each is offered only when it changes the text **and** leaves
  the document parseable.
- Both appear as a "Quick fixes" section in the existing validate sheets, shown
  only while the document is invalid, plus a "Fix everything" button that is
  offered only when applying everything really produces a valid file. A fix is
  a normal edit: undoable, and still has to be saved.
- **Worth knowing:** the app's XML parser is forgiving — it accepts a bare `&`
  and text before the declaration. Those two fixes therefore stay hidden until
  the file genuinely fails to parse, so the app never nags about a file it
  already reads happily.

---

## 3. Markdown (§4.4)

### 3.1 Split-screen dual view
- `md_live_preview.dart` — rewritten. The layout now follows the device
  **orientation** (landscape → side by side, portrait → stacked) instead of raw
  screen width, so a phone held sideways splits properly. A draggable divider
  sets how much each pane gets, clamped so neither can disappear.
- The split now works in **raw mode** too, not just edit mode, so a read-only
  file can be read as source and rendered output at once.
- `md_document_session.dart` — added `splitRatio` and `setSplitRatio`; the
  split's on/off state and ratio are remembered app-wide (it is a reading
  preference, not a property of one file).
- `md_toolbar.dart` — the split toggle is shown wherever the source is.

### 3.2 Visual table builder
- `lib/formats/markdown/md_table_source.dart` *(new)* — a GFM pipe-table model:
  `parse`, `toMarkdown` (columns padded so the source lines up), per-column
  alignment, and `findTableAt` to locate the table under the cursor. A `|`
  inside a cell is escaped and a newline becomes `<br>`, so a value can never
  break the table it sits in. Ragged rows are padded or trimmed rather than
  refused.
- `lib/formats/markdown/md_table_builder_dialog.dart` *(new)* — the grid
  dialog: a field per cell, add/remove rows and columns, an alignment picker
  per column, and a live preview of the Markdown.
- `md_format_toolbar.dart` — the table button now opens the builder. If the
  cursor is inside a table, that table is loaded and the result replaces it;
  otherwise a new table is inserted as its own block.

### 3.3 YAML front-matter form editor
- `md_front_matter.dart` — the parser now also records each field's **original
  key spelling**, its order, and the source lines it occupies
  (`MdFrontMatterField`), plus the raw block lines. Added `applyEdits`,
  `renderBlock` and the supporting rendering helpers.
- **The important part:** `applyEdits` rewrites only the lines of fields whose
  value the user actually changed. Every other line keeps its exact original
  text, so a comment, a nested map, or any other YAML this small parser does
  not understand survives an edit untouched. This was the main correctness risk
  called out in the plan, and it is covered by tests.
- `lib/formats/markdown/md_front_matter_form.dart` *(new)* — a form built from
  the file's own fields, with a date picker for `date`, chips for `tags`, plain
  text for everything else, and an "Add field" action. A file with no front
  matter is offered the common fields to fill in.
- Reached by tapping the front-matter banner (which now shows an edit icon) or
  from the Markdown overflow menu. A read-only tab gets a view-only form.

---

## 4. Shared

- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — about 90 new strings, added
  to **both** locales; `lib/l10n/app_localizations*.dart` regenerated with
  `flutter gen-l10n`.
- `docs/feature_analysis_and_roadmap.md` — §4.2, §4.3 and §4.4 items marked
  implemented with a note on what was built; the §2 audit table refreshed; the
  Phase 15 bullets ticked off (the file diff tool and the regex preset library
  are still outstanding and are marked as such).

---

## 5. Tests

**New:** `csv_formula_test.dart`, `csv_conditional_format_test.dart`,
`csv_chart_data_test.dart`, `json_table_test.dart`,
`json_query_builder_test.dart`, `json_quick_fix_test.dart`,
`xml_query_builder_test.dart`, `xml_quick_fix_test.dart`,
`md_table_source_test.dart`, `md_live_preview_widget_test.dart`,
`md_table_builder_widget_test.dart`, `md_front_matter_form_widget_test.dart`.

**Extended:** `csv_filter_sort_test.dart` (multi-level sorting and storage),
`csv_document_session_test.dart` (formula recompute, what a save writes, rule
and sort persistence, column deletion cleanup), `md_front_matter_test.dart`
(parsed field detail, `applyEdits`, `renderBlock`).

Every parser-like addition has failure-path tests as CLAUDE.md §6 requires:
bad and self-referencing formulas, unparseable table blocks, queries that match
nothing, unterminated strings and comments, stray and unfinished XML tags, and
out-of-range cell access.

**Result:** `flutter analyze` — no issues. `flutter test` — all 831 tests pass.

---

## 6. Not done / follow-ups

Deliberately out of scope, as stated in the plan:

- Full spreadsheet semantics (cross-file references, `IF`, `VLOOKUP`, circular
  reference resolution).
- Real JMESPath — see §2.2 above for why.
- Editing inside the JSON table grid; it is a read-only view of the array.
- Full YAML in front matter (nested maps, anchors) stays unparsed — but it is
  now explicitly preserved through an edit rather than dropped.

Still open in Phase 15, untouched by this change: the **Visual Side-by-Side
File Diff Tool** and the **Built-in Regex Preset Library**.

A real two-device / on-device pass has not been run — this change was verified
by the analyzer and the automated test suite only.
