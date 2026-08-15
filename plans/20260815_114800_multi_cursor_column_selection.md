# Multi-Cursor & Column Block Selection (Shared Editor Core)

**Status:** completed

---

## 1. Overview & Goals

This plan implements **Multi-Cursor & Column Block Selection** for TextData's **Shared Editor Core** (roadmap item 4.1 in `docs/feature_analysis_and_roadmap.md`).

On mobile and touch devices, placing multiple individual finger touch cursors is cumbersome and imprecise. To solve this, desktop IDEs and professional editors use structured **column/block editing** and **multi-cursor bulk operations**.

This feature brings desktop-grade bulk editing capabilities to TextData across all formats (TXT, Markdown, CSV raw, JSON, XML):
1. **Multi-Line Prefix & Suffix & Wrap:** Rapidly add bullets (`- `), comments (`// `, `# `), quotes (`> `), tags (`<!-- -->`), commas (`,`), semicolons (`;`), or custom wrappers across selected lines.
2. **Column Block Selection (Vertical Slicing):** Select vertical character rectangles across lines by column indices `[startCol..endCol]` to Cut, Copy to clipboard, Delete, or Replace.
3. **Multi-Cursor Insert at Column:** Place virtual cursors at column `N` across a range of lines and insert text simultaneously (with optional line padding).
4. **Auto-Incrementing Sequence & Line Numbering:** Insert formatted numbered sequences (`1. `, `2. `, `[01]`, `[02]`, etc.) at line starts or designated columns.
5. **Multi-Line Trimming:** Bulk trim leading or trailing whitespace across selected lines.

---

## 2. Architecture & Design

### 2.1 Pure Dart Core Engine (`lib/core/editor/column_selection.dart`)
- Pure Dart utility class `ColumnSelectionEngine` with zero Flutter UI dependencies.
- Methods:
  - `applyPrefix(String text, {required int startLine, required int endLine, required String prefix})`
  - `applySuffix(String text, {required int startLine, required int endLine, required String suffix})`
  - `applyWrap(String text, {required int startLine, required int endLine, required String prefix, required String suffix})`
  - `applyInsertAtColumn(String text, {required int startLine, required int endLine, required int column, required String insertText, bool padShorterLines})`
  - `extractColumnBlock(String text, {required int startLine, required int endLine, required int startCol, required int endCol})`
  - `replaceColumnBlock(String text, {required int startLine, required int endLine, required int startCol, required int endCol, required String replacement, bool padShorterLines})`
  - `deleteColumnBlock(String text, {required int startLine, required int endLine, required int startCol, required int endCol})`
  - `applyNumbering(String text, {required int startLine, required int endLine, int startNumber, int step, String format, int padding, int column})`
  - `applyTrim(String text, {required int startLine, required int endLine, bool trimLeading, bool trimTrailing})`
- Returns a structured result with modified text and updated cursor/line bounds.

### 2.2 Interactive Bottom Sheet UI (`lib/core/editor/column_selection_sheet.dart`)
- Opened via:
  1. Editor selection popup menu (**"Column / Multi-Cursor"** action when text is selected).
  2. Format actions / overflow menu (**"Multi-Cursor & Column Edit"**).
- Features:
  - **Line Range Picker:** Start line to end line with increment/decrement steppers, "Current Selection" and "All Lines" presets.
  - **Four Mode Tabs / Segmented Buttons:**
    - `Prefix / Suffix / Wrap`: Quick chips for common syntax (`- `, `// `, `# `, `1. `, `> `, `<!-- -->`, `,`, `;`, quotes) + custom input.
    - `Column Block Slice`: Start column to end column inputs, with **Cut**, **Copy Block**, **Delete**, and **Replace** actions.
    - `Insert at Column`: Column offset input, insert text field, and "Pad shorter lines" toggle.
    - `Auto-Numbering`: Start number, step, format template, and padding digits.
  - **Live Preview Window:** Real-time before-and-after preview of the affected lines before applying.
  - **Apply Button:** Modifies the editor controller atomically and creates a single undo step.

### 2.3 Integration with Editor Surfaces & Selection Toolbar
- `lib/core/editor/editor_selection_toolbar.dart`: Add `onColumnEdit` callback to `createEditorSelectionToolbar`.
- Wire `onColumnEdit` and menu entries in:
  - `lib/formats/txt/txt_editor_surface.dart`
  - `lib/formats/markdown/md_editor_surface.dart`
  - `lib/formats/json/json_editor_surface.dart`
  - `lib/formats/xml/xml_editor_surface.dart`
  - `lib/formats/csv/csv_raw_view.dart`

### 2.4 Localization (`lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`)
- Full English and Malayalam translations for all labels, modes, quick chips, and action buttons.

---

## 3. Files to Create and Modify

### New Files:
1. `lib/core/editor/column_selection.dart` — Pure Dart multi-cursor and column block manipulation engine.
2. `lib/core/editor/column_selection_sheet.dart` — Mobile UI sheet with live preview and operation modes.
3. `test/core/editor/column_selection_test.dart` — Comprehensive unit test suite for the engine.
4. `test/core/editor/column_selection_sheet_test.dart` — Widget test suite for the UI sheet and editor integration.

### Modified Files:
1. `lib/core/editor/editor_selection_toolbar.dart` — Add `onColumnEdit` action to selection popup.
2. `lib/formats/txt/txt_editor_surface.dart` — Pass `onColumnEdit` handler.
3. `lib/formats/markdown/md_editor_surface.dart` — Pass `onColumnEdit` handler.
4. `lib/formats/json/json_editor_surface.dart` — Pass `onColumnEdit` handler.
5. `lib/formats/xml/xml_editor_surface.dart` — Pass `onColumnEdit` handler.
6. `lib/formats/csv/csv_raw_view.dart` — Pass `onColumnEdit` handler.
7. `lib/l10n/app_en.arb` — Add English localization strings.
8. `lib/l10n/app_ml.arb` — Add Malayalam localization strings.
9. `docs/feature_analysis_and_roadmap.md` — Update Section 4.1, Section 5, and Section 6 with delivery status.

---

## 4. Verification Plan

### Automated Tests:
- `flutter test test/core/editor/column_selection_test.dart`
- `flutter test test/core/editor/column_selection_sheet_test.dart`
- `flutter test`
- `flutter analyze`
- `dart format lib test`
