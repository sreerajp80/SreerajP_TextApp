# Features & Capabilities — TextData (`SreerajP_TextApp`)

A reader-facing catalogue of everything the app can do today. Read it when you need to
know whether a capability exists and what it covers.

> **Which document owns what.** This file describes *features*. It is not the source of
> truth for design or rules. The technical design lives in
> [architecture.md](architecture.md), the folder layout in
> [project_structure.md](project_structure.md), the security rules in
> [security-rules.md](security-rules.md), and the product idea in
> [textdata_idea.md](textdata_idea.md). Future work lives in
> [feature_analysis_and_roadmap.md](feature_analysis_and_roadmap.md). If a fact here
> disagrees with one of those, the other document wins.

---

## 1. App Overview & Core Description

**TextData** (`SreerajP_TextApp`) is an offline-first, zero-cloud, privacy-focused Android application built with Flutter (supporting Android 8.0+ / minSdk 26+ on phones and tablets in both portrait and landscape orientations). It is a full-featured reader, editor, parser, structure analyzer, chart generator, formula evaluator, query engine (JSONPath/XPath), schema validator with 1-tap quick fixes, structural diff tool, multi-format converter and exporter (PDF, HTML, DOCX, XLSX, ZIP, system print), bilingual (English/Malayalam) app with a matching text-to-speech reader, PIN/biometric app-lock, and a serverless peer-to-peer (P2P) sync engine for plain-text and structured-data files.

Unlike basic text viewers or cloud-dependent office suites, TextData operates **100% locally on-device** without requiring external cloud servers, user accounts, analytics tracking, or internet access. It seamlessly handles five primary file formats — **TXT, Markdown (MD), CSV, JSON, and XML** — plus line-delimited JSON (**JSONL / NDJSON**) as a specialized JSON viewer mode. YAML is supported at the content level, not as its own openable file type: JSON documents can be 1-tap converted to/from YAML syntax, and Markdown front matter (which is written in YAML) has its own inspector and form editor.

```
                  ┌────────────────────────────────────────────────────────┐
                  │                 TextData (SreerajP_TextApp)            │
                  │   Offline-First, Zero-Cloud Data & Reader Workspace    │
                  └───────────────────────────┬────────────────────────────┘
                                              │
         ┌───────────────────┬────────────────┼───────────────────┬───────────────────┐
         │                   │                │                   │                   │
  ┌──────────────┐   ┌──────────────┐  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │  Plain Text  │   │   Markdown   │  │   CSV Grid   │   │  JSON Tree   │   │   XML Tree   │
  │   (.txt)     │   │     (.md)    │  │   (.csv)     │   │   (.json)    │   │    (.xml)    │
  └──────┬───────┘   └──────┬───────┘  └──────┬───────┘   └──────┬───────┘   └──────┬───────┘
         │                  │                 │                   │                   │
         └──────────────────┴─────────────────┼───────────────────┴───────────────────┘
                                              │
         ┌───────────────────┬────────────────┼───────────────────┬───────────────────┐
         │                   │                │                   │                   │
  ┌──────────────┐   ┌──────────────┐  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │ SAF Storage  │   │ P2P LAN Sync │  │ App Lock &   │   │ Export & Zip │   │ Multi-Lang   │
  │ Architecture │   │ AES-256-GCM  │  │  Biometrics  │   │  PDF/Docx/.. │   │ English/Malay│
  └──────────────┘   └──────────────┘  └──────────────┘   └──────────────┘   └──────────────┘
```

### Core Philosophical & Technical Pillars
- **Zero-Cloud & Privacy First**: All file editing, parsing, formatting, conversions, statistics, chart rendering, and local sync occur strictly on-device. Network activity is limited exclusively to serverless local Wi-Fi (LAN) P2P transfers.
- **Storage Access Framework (SAF) Scoped Storage**: Interoperates with standard Android system file pickers (`Intent.ACTION_OPEN_DOCUMENT`, `Intent.ACTION_CREATE_DOCUMENT`) and URI permissions without requesting broad, invasive external storage permissions (`READ_EXTERNAL_STORAGE` / `MANAGE_EXTERNAL_STORAGE`).
- **Strict Open-Source Compliance**: Banned all proprietary or commercial SDKs (e.g. Syncfusion). All dependencies and fonts are strictly open-source (OFL, BSD-3, MIT, Apache 2.0).
- **Atomic Safe Saving**: File writes utilize temporary intermediate shadow files (`AtomicSaver`) to guarantee original files are never corrupted during unexpected power loss, write interruptions, or app crashes.
- **Multi-Document Tabbed Architecture**: Manages multiple open documents simultaneously in tabs with dynamic tab capacity (`TabCapPolicy`) based on available device RAM queried via `system_info2`.
- **Non-Crashing Parser Fallbacks & Degraded Gates**: Implements error-tolerant parser fallbacks (`JsonWellFormedGate`, `XmlWellFormedGate`), degraded raw view modes, and 1-tap schema quick-fix helpers for malformed or corrupted documents.
- **Serverless P2P LAN Sync**: Transfers documents, metadata, recents, and bookmarks directly between Android devices over local Wi-Fi with QR code scanning, a long random pairing code (typed by hand when the camera is not used), end-to-end AES-256-GCM encryption, and `FLAG_SECURE` window protection.
- **Hardware-Backed App Security**: Comprehensive PIN lock, recovery keys, native Android biometrics (`local_auth`), encrypted key storage (`flutter_secure_storage`), and screen recording / screenshot prevention (`WindowSecurity`).

---

## 2. Exhaustive Feature Directory

### 2.1 Shared Multi-Format Editor Engine & Common Services
- **Core Text Editor Surface**: Built on a customized, vendored `re_editor` engine (patched to set `enableSuggestions: false` preventing line duplication on keypresses; `flutter/flutter#31512`). Features responsive text entry and a line-numbers gutter (always shown). Soft line wrapping is an app-wide switch in Settings › Appearance.
- **Dynamic Zooming & Text Scaling**: Multi-touch pinch-to-zoom text scaling (`PinchToZoomArea`) and slider-based font size adjustment across all text editing surfaces.
- **Undo / Redo Stack**: Comprehensive edit history preservation (`UndoRedoStack`) maintained per tab session.
- **Advanced Find & Replace (`TextSearch` & `FindReplacePanel`)**:
  - Case-sensitive and whole-word toggle options.
  - Regular expression (regex) search with capture group substitution (e.g. `$1`, `$2`).
  - Scoped replacement: Replace within the full document, active selection, specific CSV column, or target JSON/XML tree node.
  - Real-time match counting and match highlight navigation.
- **Read-Only Lock Mode (`ReadOnlyLockButton`)**: Single-tap toggle to lock editor buffers against accidental keystrokes.
- **Binary Content Sniffing & Detection (`TxtContentSniff`)**: Inspects leading sample bytes to detect non-text binary files (NUL bytes, high control character ratio) and warns the user before displaying garbled text while preserving UTF-16 patterns.
- **Unsaved Changes Guard (`UnsavedChangesDialog`)**: Prompt dialog preventing loss of edits when switching tabs, closing tabs, or exiting the application.
- **Automatic Draft & Crash Recovery (`DraftStore`)**: Background persistence of un-saved edits per tab session, allowing complete workspace session recovery after app restarts or device crashes.
- **External File Change Detection (`ExternalChangeNotifier`)**: Auto-detects modified disk states for open files using SHA-256 content fingerprints (`ContentFingerprint`) and alerts the user via an actionable banner to reload or overwrite.
- **Universal Encoding Engine**:
  - Auto-detects and decodes UTF-8, UTF-8 with BOM, UTF-16LE, UTF-16BE, ASCII, ISO-8859-1 (Latin-1), and Windows-1252 — a file that fits none of these still decodes through the Windows-1252 fallback, so the app never fails to open a file for encoding reasons.
  - Manual encoding selector dialog (`TxtEncodingSheet`) for forcing one of these encodings instead of the detected one.
- **Line Ending Preservation**: Auto-detects and preserves original line endings (`LF` vs `CRLF`), with option to convert line ending styles on save.
- **Text-to-Speech (TTS) Read Aloud, All Formats**: The same "Read aloud" toggle (`TtsService`) is available on **TXT, Markdown, JSON, and XML** documents, not just plain text — each format reads its own text content aloud in English or Malayalam, with play/stop control, and hides itself automatically when no speech engine is available.
- **Two-Tier Save Workflow**: A plain **Save** silently overwrites the file, preserving its original encoding, line ending, and (for CSV) delimiter. **Save As…** opens a per-format options sheet to explicitly choose encoding, line ending, and other format-specific save settings, or save as a copy. Read-only files automatically fall back to "save as a copy".
- **Edge-Swipe Tab Switching**: Left/right swipe gestures on thin screen-edge zones move between open document tabs without needing to reach the tab strip.
- **Over-Limit Tab Behavior**: When the open-tab cap is reached and another file is opened, the user chooses whether the app silently closes the least-recently-used tab or asks what to close — a tab with unsaved edits is never auto-closed.

---

### 2.2 Plain Text (`.txt`) Format Features
- **Customizable Typography & Reading Themes**: Support for light, dark, and sepia reader palettes with custom sans-serif, serif, and monospace font selections.
- **Jump to Line**: Quick navigation dialog to jump directly to specified line numbers.
- **Link Auto-Detection & Security Warning (`TxtLinkWarningDialog`)**: Automatically detects web URLs (`http://`, `https://`) and prompts a security confirmation dialog before launching external browsers.
- **All-Links Sheet (`TxtLinksSheet`)**: A dedicated bottom sheet lists every link found in the document (since the underlying text engine cannot make inline text tappable), letting the user open, copy, or cancel any of them through the same security warning dialog.
- **Text-to-Speech (TTS) Read Aloud (`TtsService`)**:
  - Integrated speech synthesis engine supporting English (`en`) and Malayalam (`ml`) voice output.
  - A single play / stop toggle. There is no pause, and no in-app speech rate or pitch control — those stay with the device's own TTS engine settings.
  - The two voices are turned on and off in Settings › Speech, which also checks whether the Malayalam voice is installed and offers a guided install (`TtsInstaller`) or a shortcut to the system TTS settings when no engine is available.
  - (See §2.1 — the same Read Aloud control is also available for Markdown, JSON, and XML documents.)
- **File Tools (Splitting & Merging)**:
  - **Split File**: Split large TXT files into chunks by line count or by maximum part size (KB/MB).
  - **Merge Files**: Concatenate multiple TXT files into a unified document, joined with newlines.
- **Text Statistics**: Real-time display of word count, character count, character count without line breaks, and line count.

---

### 2.3 Markdown (`.md`) Format Features
- **Multi-View Rendering Modes**:
  - **Raw Source Editor**: Syntax-focused source editing with toolbar formatting shortcuts.
  - **Rendered Preview**: Formatted HTML-rendered Markdown view adhering to GitHub Flavored Markdown (GFM) specs.
  - **Orientation-Aware Split View (`MdLivePreview`)**: Side-by-side (landscape) or stacked (portrait) live editor and preview with a draggable divider.
- **Rich GFM Markdown Renderer (`MdRenderer`)**:
  - Full GFM support: Headers, bulleted/numbered lists, task lists with interactive checkboxes, strikethrough, blockquotes, styled code blocks.
  - **LaTeX Math Formula Rendering (`flutter_math_fork`)**: Native inline `$...$` and block `$$...$$` mathematical expression rendering.
  - Embedded image preview: Renders local and remote image links with fallback image icons.
  - Clickable URL link protection dialog (`MdLinkWarning`).
- **Formatting Toolbar**: Quick-insertion buttons for Headings (H1–H6), Bold, Italic, Strikethrough, Inline Code, Code Block, Blockquote, Unordered List, Ordered List, Task List, Table, Link, Image, and Horizontal Rule.
- **Visual Table Builder Dialog (`MdTableBuilderDialog`)**: Interactive grid dialog to specify row/column dimensions, column alignment (Left, Center, Right), and sample headers to auto-generate markdown table markup.
- **GFM Table Visual Matrix Editor (`MdTableSource`)**: Edit existing Markdown tables in a visual 2D matrix editor without manipulating raw pipe (`|`) syntax.
- **Table of Contents (TOC) Drawer (`MdTocSheet`)**: Automatically parses document headers to build a clickable outline drawer for rapid navigation.
- **YAML Frontmatter Inspector & Form (`MdFrontMatterForm`)**:
  - Parses and displays document frontmatter header metadata.
  - Interactive form editor for modifying standard fields (Title, Tags, Date, Author) while safely preserving un-recognized custom YAML key-value pairs.
- **Heading-Based File Splitting (`MdSplitMerge`)**: Split Markdown documents into separate files at each top-level H1 (`#`) heading. Headings inside fenced code blocks are ignored, so a `#` in a shell snippet does not split the file.

---

### 2.4 Comma-Separated Values (`.csv`) Format Features
- **Multi-View Modes**:
  - **2D Scrollable Grid View (`CsvGrid`)**: Spreadsheet-style interactive table built on `two_dimensional_scrollables` with bidirectional scrolling.
  - **Raw Text View**: Direct text buffer view with CSV dialect configuration.
- **Grid Navigation & Frozen Panes**:
  - Freeze Header Row & Freeze First Column options for smooth scrolling through large tables.
  - Auto-fit column widths, sized from the header plus a sample of the rows. Widths are not hand-adjustable.
  - Column Visibility Drawer (`CsvColumnsSheet`): Toggle individual column visibility.
  - Inline Cell Editor (`CsvCellEditor`) with keyboard navigation.
  - **Grid-Level Undo/Redo**: The 2D grid keeps its own bounded snapshot undo/redo stack (separate from the raw-text editor's history), so cell, row, and column edits made in grid view can be undone independently.
- **Sorting & Multi-Level Sort Hierarchy (`CsvSortSheet`)**:
  - Single-tap header sorting (ascending / descending).
  - Multi-level sort criteria builder (e.g. Primary sort by `Department` asc, Secondary sort by `Salary` desc).
- **Data Filtering & Type Inference**:
  - Keyword search filter across selected or all table columns.
  - Automatic column data type inference (Text, Number, Currency, Date, Boolean).
- **Spreadsheet Formula Calculation Engine (`CsvFormula` & `CsvFormulaSheet`)**:
  - Supports functions: `SUM`, `AVERAGE`, `MIN`, `MAX`, `COUNT`, `PRODUCT`, and basic arithmetic (`+`, `-`, `*`, `/`).
  - Cell references (e.g., `A1`, `B2`) and range references (e.g., `A1:A10`, `B:B`).
  - Dynamically calculates values in custom formula columns while storing results in standard plain-text CSV format.
- **Conditional Formatting Highlight Rules (`CsvConditionalFormatSheet`)**:
  - Add highlight rules for columns or entire grid: Less than, Greater than, Equals, Not Equals, Contains, Is Empty, or Duplicate values.
  - 4 theme-aware color highlight palettes (Red, Green, Yellow, Blue).
- **Interactive Data Charting (`CsvChartScreen`)**:
  - Full-screen visual charting powered by `fl_chart`.
  - Chart types: **Bar Chart**, **Line Chart**, and **Pie Chart**.
  - Customizable value columns, category label columns, touch tooltips, and filter-aware rendering (charts active filtered row sets).
- **Column Insights & Statistics (`CsvInsightsSheet`)**:
  - Computes column-level metrics: inferred column type, filled cell count, empty cell count, unique value count, numeric cell count, and — for numeric columns — Minimum, Maximum, Sum, and Average. (No median.)
- **Data Cleaning & Exporting**:
  - 1-tap Duplicate Row Detection and Removal.
  - Dialect auto-detection and manual overrides (Delimiter: `,`, `\t`, `;`, `|`; Quote char: `"`, `'`).
  - Custom column selection export sheet (`CsvExportSheet`).
- **Split & Merge Tools**: Split a CSV by row count or by maximum part size, with the header row repeated on every part so each part is a valid CSV on its own. Merge joins parts that already share the same columns — the header comes from the first part and the rest of the rows follow in order; it does not re-match or re-order mismatched columns.
- **Embedded SQL Query Engine (`lib/core/sql/`)**: Runs real, read-only SQL — `SELECT`, `WHERE`, `GROUP BY`, aggregates, `ORDER BY`, `JOIN` — against the open document, entirely offline. Opened from the overflow menu.
  - **How it works**: the document is copied into a throwaway in-memory SQLite database. It uses the `sqflite` package the app already had, so the feature added no new dependency. The app's own database is never touched.
  - **Typed columns**: an all-numeric column (including `1,234` and `$1,299.00`) loads as a number, so `WHERE amount > 100` compares numerically. Blank cells load as `NULL`, never `0`, so `AVG` and `COUNT` stay honest. A blank or repeated header is repaired and the schema panel says what was renamed.
  - **Joins across tabs**: any other open CSV or JSON tab can be added as a second table, which is what makes `JOIN` useful.
  - **Read-only by design**: only one statement starting with `SELECT` or `WITH` is allowed; writes, `PRAGMA`, the file functions, and `ATTACH` are refused, so a query can never reach another database or change a file. A blocked word inside a string literal (`WHERE note = 'delete me'`) still runs.
  - **Starter queries** are written with the loaded tables' real names, and tapping a column chip inserts it into the SQL box.
  - **Results**: shown in a scrollable grid, copyable as CSV, and savable as a new CSV file through the system picker.
  - **Stated limits**: 200,000 rows loaded per table, 5,000 result rows shown, no mid-query cancel (SQLite cannot be interrupted part-way), and the tables are a snapshot — a "Reload data" action re-copies after an edit.


---

### 2.5 JavaScript Object Notation (`.json`) Format Features
- **Multi-View Modes**:
  - **Tree View (`JsonTreeView`)**: Collapsible interactive tree hierarchy with color-coded type badges (`String`, `Number`, `Boolean`, `Null`, `Object`, `Array`), child count badges, and expand/collapse controls.
  - **Table View (`JsonTableView`)**: Read-only grid view for arrays of uniform JSON objects with sortable columns.
  - **Pretty Formatted View**: Formatted, indented JSON code view.
  - **Raw / Minified Editor**: Direct text editing buffer mode.
  - **JSON Lines (NDJSON / `.jsonl`) Viewer**: Specialized streaming line-by-line viewer for JSON log files.
- **Tree Node Manipulation (`JsonTreeEdits`)**: Edit keys and values, modify data types, insert new child nodes, delete nodes, and duplicate subtrees directly from the UI.
- **Structural JSON Diff Engine (`JsonDiff`)**:
  - Performs structural comparison between two JSON documents.
  - Identifies added, removed, and modified property paths (`JsonDiffResult`).
- **JSONPath Querying & Visual Builder (`JsonQueryBuilderSheet`)**:
  - Full JSONPath query evaluation engine (e.g., `$.items[*].id`).
  - Visual builder sheet allowing users to tap keys and array indices to construct JSONPath queries with live result counts.
- **Lenient JSONC / JSON5 Reading Mode**: Opens files that use practical JSONC/JSON5 extensions — `//` and `/* */` comments, trailing commas, and single-quoted strings — without requiring a fix first, so lightly non-standard JSON (e.g. hand-written config files) still opens and displays correctly.
- **JSON Schema Validation & 1-Tap Quick Fixes (`JsonQuickFix`)**:
  - Validates structures against a practical **subset** of JSON Schema (`type`, `required`, `properties`, `items`, `enum`, `minimum`/`maximum`, `minLength`/`maxLength`, `additionalProperties`); unknown keywords are ignored rather than failing, so a richer schema still validates what it can. Advanced keywords (`$ref`, `allOf`/`anyOf`, `pattern`, `format`, …) are out of scope.
  - **1-Tap Quick Fix Engine**: Automatically repairs common malformed JSON errors:
    - Quotes unquoted object keys.
    - Converts single quotes (`'`) to standard double quotes (`"`).
    - Removes trailing commas in arrays and objects.
    - Strips JavaScript comments (`//`, `/* */`).
    - Translates Python/YAML literals (`True`/`False`/`None` -> `true`/`false`/`null`).
- **Large Integer Precision Protection**: Preserves 64-bit integer numbers (e.g. Twitter/Discord IDs) as exact strings to prevent JavaScript/Dart double-precision truncation.
- **Bi-directional YAML Conversion (`JsonYaml`)**: 1-tap conversion between JSON and YAML syntax.
- **Array Split & Merge**: Split top-level JSON arrays into individual file chunks; merge separate JSON files into a master array.
- **Embedded SQL Query Engine**: An array of records can be queried with read-only SQL from the overflow menu — the same engine the CSV format uses (see §2.4). The array the table view is pointed at is the one that becomes the SQL table, so drilling into a nested array first also narrows the query. A nested object keeps its short display text (`{ 3 }`), so a query can select it but not look inside it.

---

### 2.6 Extensible Markup Language (`.xml`) Format Features
- **Multi-View Modes**:
  - **Tree View (`XmlTreeView`)**: Collapsible tree structure showing tags, attributes, text nodes, CDATA, and comment nodes.
  - **Pretty Formatted View**: Syntax-highlighted indented XML code.
  - **Raw Text View**: Direct text buffer editing mode.
- **Element Editing (`XmlTreeEdits`)**: Add/edit/delete XML tags, attribute key-value pairs, text content, and CDATA blocks.
- **XPath Querying & Visual Builder (`XmlQueryBuilderSheet`)**:
  - Evaluates XPath expressions across XML documents.
  - Visual XPath builder sheet allowing users to select elements and attributes to construct queries with live match highlights.
- **Well-Formedness Check & 1-Tap Quick Fixes (`XmlQuickFix`)**:
  - Checks the document is well-formed XML (the parser is deliberately forgiving of a bare `&` and text before the `<?xml?>` declaration, so those two fixes only appear when the file genuinely fails to parse).
  - **1-Tap Quick Fix Engine**: Repair common XML syntax defects:
    - Auto-closes unclosed tags.
    - Escapes unescaped bare ampersands (`&` -> `&amp;`).
    - Wraps multi-root XML structures in a synthetic `<root>` tag.
    - Strips invalid characters appearing before the `<?xml>` declaration.
  - Full **XSD schema validation** is shown in the UI as "coming soon" — it is not implemented yet, only well-formedness checking and the quick fixes above.
- **Namespace Inspector**: The document info sheet lists every distinct namespace URI declared in the file. Standard XML entities (`&lt;`, `&gt;`, `&amp;`, `&quot;`, `&apos;`, and numeric entities) are resolved by the parser when the file is read — there is no separate entity browser.
- **JSON Format Conversion (`XmlConvert`)**: 1-tap conversion of XML structures into equivalent JSON models.
- **Repeated Tag Splitting & Merging**: Split XML documents by repeated element tags; concatenate XML fragments under a shared root tag.

---

### 2.7 Storage Access Framework (SAF) & File System Integration
- **Scoped Storage Architecture**: Operates via Android Storage Access Framework (SAF) picker intents (`Intent.ACTION_OPEN_DOCUMENT`, `Intent.ACTION_CREATE_DOCUMENT`).
- **Persistable URI Permissions**: Requests long-term persistable URI permissions via `takePersistableUriPermission` to re-open recent files without repeated file picker prompts.
- **Duplicate-Tab Prevention**: Re-opening a file that is already open focuses its existing tab instead of adding a second one — matched first by SAF URI (so it still works after the file was edited and saved), then by content fingerprint plus display name, so two different files that happen to share identical bytes still get separate tabs.
- **Create New Document (`CreateDocumentAction`)**: Creates a brand-new blank file — TXT, Markdown, CSV, JSON, or XML — through the system file picker (SAF `ACTION_CREATE_DOCUMENT`), each pre-filled with a safe starter template (e.g. `{}` for JSON, a minimal `<root></root>` element for XML), then opens it straight into the editor.
- **Recent Files Repository (`RecentsRepository`)**: Tracks recently opened documents with file metadata, last opened timestamp, format type, and quick launch tiles on the Home screen.
- **Favorites & Pinned Files (`FavoritesRepository`)**: Pin frequently accessed files to the home dashboard.
- **In-Document Bookmarks & Fingerprinting (`ContentFingerprint`)**: Add persistent bookmarks to specific lines/locations within documents. Bookmarks track content alterations and line shifts using SHA-256 content hashes.
- **Workspace-Wide Full-Text Search (`SearchIndexService`)**: An offline SQLite FTS5 index over recent and favorite files. Files are indexed when opened and re-indexed after each successful save; a search screen on Home looks inside every indexed TXT, Markdown, CSV, JSON, and XML file at once, with format filter chips, highlighted snippets, and one tap to open the file as a tab. Oversized (≥ 50 MB) and binary files are skipped, each file is capped at 2 MB of stored text, and Settings › Files & Tabs can turn the index off, rebuild it, or clear it. Everything stays in the app's private database on the device.
- **File Metadata Inspector (`FileMetadata`)**: A per-document info sheet showing file name, size, last-modified time, detected encoding, and line ending style, plus counts for the format (for example words, characters, characters without line breaks, and lines for TXT; root element, element count, depth, common tags, and namespaces for XML). The raw SAF URI and MIME type are not shown.

---

### 2.8 Serverless Peer-to-Peer (P2P) Local LAN Sync Subsystem
- **Zero-Cloud Local Wi-Fi Sync**: Directly transfers document files, metadata, recents, and bookmarks between two Android devices over a local Wi-Fi / LAN connection.
- **QR Code Pairing**:
  - Host device renders a pairing QR code (`qr_flutter`).
  - Client device scans QR code using camera (`mobile_scanner`).
  - Manual fallback: the client can type or paste the pairing code instead of scanning. The code is 64 characters drawn from a 31-character confusion-free alphabet (no `I`, `O`, `0`, or `1`) — roughly 317 bits of entropy, because it is the only thing standing between a peer and the session key. It is not a short numeric PIN.
  - **Screenshot & Capture Protection (`WindowSecurity`)**: Activates Android `FLAG_SECURE` on the host pairing screen to block screen recording or screenshots of pairing keys.
- **End-to-End Encryption**: Encrypts all TCP socket communications using AES-256-GCM (`encrypt`) with keys derived via PBKDF2-HMAC-SHA256 (16-byte per-session random salt, 200,000 iterations via `pointycastle`).
- **Selective Data Sync & Merge**: Choose specific documents or sync all app metadata using conflict-free add-only/fill-only merging strategies.
- **Share Chooser (`ShareChooser`)**: A one-tap **Full Sync** action for pairing a fresh device, plus a selective panel with per-category checkboxes (recents, favorites, bookmarks, settings) that pre-checks sensible defaults; every action stays disabled until a peer is actually connected.
- **Live Connection Status Chip (`SyncStatusChip`)**: Shows the host's current pairing state at a glance — Waiting, Connected, Wrong Code, Error, or Stopped — with a matching icon and color.

---

### 2.9 Security, Privacy & App-Lock Protection
- **App Lock Passcode & Biometrics**:
  - Master PIN protection screen (`LockScreen`).
  - **Fingerprint & Face Unlock Integration (`BiometricService`)**: Native Android biometric authentication powered by `local_auth`.
  - Master Recovery Key System (`RecoveryCodeScreen`) to reset access if PIN is forgotten.
  - Auto-lock when the app goes to the background (`AppLockGate`), so returning to it needs an unlock. There is no grace period or timeout to configure — it locks straight away.
- **Hardware-Backed Key Storage (`SecureStore`)**: Encrypts security credentials, PIN hashes, and pairing keys using Android Keystore via `flutter_secure_storage`.
- **Window Security (`FLAG_SECURE`)**: Blocks task switcher previews and screenshot capture on sensitive app screens.
- **Self-Destructing Documents (`lib/core/ephemeral/`)**: Any open tab can be marked to self-destruct, either on a timer (15 minutes, 1 hour, 4 hours, 24 hours, or a typed number of minutes) or after its first successful export, share, or print. A countdown badge on the tab chip shows the time left. A file can also be opened straight into a self-destructing tab by long-pressing the "Open a file" button on Home.
  - **What a burn removes**: the auto-save draft (zero-filled before deletion), its `drafts_index` row, the recents entry, the favourite, the file's bookmarks, its reading position and per-file view settings, and — the most important one — the document's own text in the workspace FTS5 search index. The tab closes without the unsaved-changes prompt, because marking a tab ephemeral *is* the instruction to discard it, and the sheet says so before the mark is applied.
  - **What a burn does not do**: it never deletes the user's file. The app is scoped-storage only, so "ephemeral" means the app forgets the document, not that the document is destroyed. The sheet states this in plain words.
  - **Prevention, not just cleanup**: an ephemeral tab is never written to the saved tab set (so it cannot return after a relaunch), is never added to recents, and never feeds the search index on save.
  - **Honest limits**: a `0x00` overwrite defeats an ordinary undelete of the logical file, but flash wear-levelling means it is not a guarantee that the physical blocks are gone — Android's per-app file encryption is the real protection. A Dart `String` cannot be zeroed at all (it is immutable and garbage-collected), so text scrubbing means dropping every reference; only the raw byte buffers are genuinely overwritten. The Settings screen says as much.

---

### 2.10 Output, Export, Sharing & System Printing
- **Multi-Format Document Export (`ExportService`)**:
  - **PDF Export (`PdfWriter`)**: Render documents to formatted PDF documents with customizable page layout, margins, and typography via `pdf` and `printing`.
  - **HTML Export (`HtmlWriter`)**: Export styled HTML documents.
  - **Microsoft Word (`.docx`) Export (`DocxWriter`)**: Generate clean DOCX documents.
  - **Microsoft Excel (`.xlsx`) Export (`XlsxWriter`)**: Export CSV grids and JSON arrays to formatted XLSX spreadsheets.
  - Additional export formats: Plain TXT, Markdown, CSV, JSON, and YAML.
- **ZIP Archive Compression (`ZipService`)**: Package single or multiple files into standard ZIP archives for bulk sharing.
- **Android System Printing (`PrintService`)**: Send text, previewed Markdown, or formatted tabular grids directly to connected wireless or system printers.
- **Android System Share Sheet (`ShareService` / `share_plus`)**: Share document files or highlighted text selections directly to external apps.

---

### 2.11 Personalization, Themes & Multi-Language Localization
- **Material 3 Design System**: Clean, modern interface supporting dynamic palette matching, fluid animations, and responsive phone/tablet layouts.
- **Theme Modes (`AppThemes`)**: System Default, Light Theme, Dark Theme, and Sepia Reading Palette.
- **Bundled Open-Source Typography**:
  - **English / Latin**: Inter (Sans-Serif), Lora (Serif), JetBrains Mono (Monospace).
  - **Malayalam**: Manjari, Rachana, Noto Sans Malayalam.
- **Multi-Language Support (`lib/l10n`)**:
  - Fully localized in **English (`en`)** and **Malayalam (`ml`)** via Flutter `gen-l10n` (`AppLocalizations`).
  - In-app language switcher (`LocaleController`).

---

### 2.12 Comprehensive App Settings
- **Appearance Settings (`AppearanceSection`)**: Theme mode (System / Light / Dark / Sepia), app language, font size, Latin font family, a separate Malayalam font family, line spacing, and the app-wide soft word wrap toggle.
- **Editor Settings (`EditorSection`)**: Default encoding for new saves (or preserve the file's own), default line ending (or preserve), confirm-before-overwrite toggle, open files read-only by default, leave edit mode after a save, and the auto-save interval (including "off").
- **Files & Tabs Settings (`FilesTabsSection`)**: Auto (RAM-aware) or fixed open-tab cap, over-limit behavior choice (auto-close least-recently-used vs. ask), restore-open-tabs-on-relaunch toggle, and the workspace search index controls (on/off, indexed file count, rebuild, clear).
- **Speech Settings (`SpeechSection`)**: English voice on/off, Malayalam voice on/off, a check of whether the Malayalam voice is installed with a guided install, and a shortcut to the system TTS settings when no engine is present. Rate and pitch are not configurable in-app.
- **Sync Settings (`SyncSection`)**: The default categories to share (recents, favourites, bookmarks), a shortcut to the sync screen, and a shortcut to AirQR. The TCP port is picked by the host at run time and advertised in the pairing payload, so there is nothing to configure.
- **Security Settings (`SecuritySection`)**: App Lock PIN set / change / turn off, biometric unlock toggle, screenshot and recents-preview blocking toggle, recovery code generation, and the self-destructing document defaults (default duration, burn-after-export, burn all open ephemeral tabs).
- **About Section (`AboutSection`)**: Application name and description, version and build number, and the developer details from `assets/config/app_config.json` (author, email, a one-line licence note, tools used). There is no per-dependency licence list screen.
- **Help & Documentation Section (`HelpSection`)**: Integrated FAQ, supported formats guide, user manual.

---

### 2.13 Onboarding & First-Run Guide
- **Interactive Onboarding Flow (`OnboardingScreen`)**: Step-by-step introduction for first-time users explaining SAF file access, P2P LAN sync, security options, and multi-format capabilities.

---

### 2.14 Performance & Large-File Virtualization Engine
- **Memory-Aware Tab Management (`TabCapPolicy`)**: Automatically determines maximum allowed open document tabs based on total device RAM queried via `system_info2`.
- **Paged & Streaming Text Rendering (`PagedText` & `LargeFilePolicy`)**: Virtualizes files up to 50 MB, streaming chunked buffers into memory to prevent Out-Of-Memory (OOM) crashes on resource-constrained devices.
- **Background Session Eviction (`session_retention`)**: Keeps a small budget of tabs' heavy in-memory state (decoded text, parsed model, undo history) loaded at once and releases the rest in the background to save memory; the active tab and any tab with unsaved edits are never released, and a released tab is rebuilt from the file when the user returns to it.

---

## 3. Technical Specifications & Dependencies Summary

| Specifications / Layer | Details |
| :--- | :--- |
| **Product Version** | TextData v1.9.0+21 |
| **Framework & Engine** | Flutter 3.44.8+ / Dart 3.12.2+ |
| **Target OS & Requirements** | Android 8.0+ (minSdk 26+), Phones & Tablets, Portrait & Landscape |
| **Storage Architecture** | Storage Access Framework (SAF), SQLite (`sqflite`), Secure Storage (`flutter_secure_storage`) |
| **State Management** | Flutter Riverpod 3.3.2+ |
| **P2P LAN Sync Stack** | Raw TCP Sockets, `qr_flutter` 4.1.0, `mobile_scanner` 7.2.0, `encrypt` 5.0.3 (AES-256-GCM), `pointycastle` 3.9.1 (PBKDF2-HMAC-SHA256) |
| **UI & Layout Components** | Material 3, `re_editor` 0.10.0 (patched), `two_dimensional_scrollables` 0.5.3, `fl_chart` 1.2.0, `flutter_math_fork` 0.7.4 |
| **Document Export Engine** | `pdf` 3.11.1, `printing` 5.13.4, `archive` 4.0.2 (ZIP), `share_plus` 13.2.0 |
| **Biometrics & Security** | `local_auth` 2.3.0, `WindowSecurity` (`FLAG_SECURE`) |
| **Speech Subsystem** | `flutter_tts` 4.2.0 (English & Malayalam) |
| **Localization (l10n)** | Native Flutter `gen-l10n` (`app_en.arb`, `app_ml.arb`) |
| **Open-Source Fonts** | Inter, Lora, JetBrains Mono, Manjari, Rachana, Noto Sans Malayalam |
