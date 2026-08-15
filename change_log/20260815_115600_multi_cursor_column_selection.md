# Multi-Cursor & Column Block Selection (Shared Editor Core)

**Plan reference:** [plans/20260815_114800_multi_cursor_column_selection.md](plans/20260815_114800_multi_cursor_column_selection.md)

---

## 1. Summary of Changes

Implemented **Multi-Cursor & Column Block Selection** across TextData's Shared Editor Core. This feature brings desktop-grade bulk text manipulation and multi-line editing tools to mobile and tablet devices across all file formats (TXT, Markdown, CSV, JSON, XML).

### 1. Pure Dart Engine (`lib/core/editor/column_selection.dart`)
- Created `ColumnSelectionEngine` with zero UI dependencies:
  - `applyPrefix(...)`: Prepend text across line ranges (e.g. `- `, `// `, `# `, `> `).
  - `applySuffix(...)`: Append text across line ranges (e.g. `,`, `;`).
  - `applyWrap(...)`: Wrap line ranges with prefix and suffix.
  - `applyInsertAtColumn(...)`: Multi-cursor insert text at column `N` with optional line padding.
  - `extractColumnBlock(...)`: Extract vertical rectangular slices of text.
  - `replaceColumnBlock(...)` and `deleteColumnBlock(...)`: Replace or delete vertical slices of characters across lines.
  - `applyNumbering(...)`: Auto-incrementing line numbering sequences (`1. `, `[01]`, etc.) with customizable start numbers, steps, format templates, and zero-padding.
  - `applyTrim(...)`: Bulk trim leading and trailing whitespace.

### 2. Interactive UI Bottom Sheet (`lib/core/editor/column_selection_sheet.dart`)
- Created `ColumnSelectionSheet` featuring:
  - Line range controls with increment/decrement steppers and preset chips ("Selection", "All lines").
  - 4 operation mode tabs with quick-insert syntax chips.
  - Live diff preview window in monospace formatting.
  - Direct Cut, Copy Block to Clipboard, Delete, and Apply actions.
  - Single-step atomic commit with full undo/redo history.

### 3. Editor Context Menu & Toolbar Integration
- Added **"Column / Multi-Cursor"** action in `lib/core/editor/editor_selection_toolbar.dart` for the touch selection popup menu across all format editor surfaces.
- Integrated overflow menu actions in:
  - `lib/formats/txt/txt_toolbar.dart`
  - `lib/formats/markdown/md_toolbar.dart`
  - `lib/formats/json/json_toolbar.dart`
  - `lib/formats/xml/xml_toolbar.dart`

### 4. Localization
- Added comprehensive English and Malayalam localization strings in `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb`.

### 5. Automated Testing
- Created unit tests in `test/core/editor/column_selection_test.dart` covering prefix, suffix, wrap, column insertion, block slicing, auto-numbering, trimming, and boundary clamping.
- Created widget tests in `test/core/editor/column_selection_sheet_test.dart` verifying mode switching, chip inputs, live preview, and text transformations.

---

## 2. Verification

- Ran full test suite (`flutter test`): **1,103 passing tests**.
- Ran static analysis (`flutter analyze`): **0 issues found**.
- Formatted repository with `dart format lib test`.
