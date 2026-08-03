# Feature Analysis, Novel Innovation & Product Roadmap — SreerajP TextApp (TextData)

## 1. Executive Summary & App Identity Analysis

**TextData** (`SreerajP_TextApp`) is an offline-first, privacy-focused Android text and structured data editor built with Flutter (minSdk 26+). Unlike standard text viewers or cloud-dependent productivity apps, TextData focuses on zero-cloud operations, Storage Access Framework (SAF) scoped storage integrity, open-source compliance (banning commercial SDKs like Syncfusion), and serverless Peer-to-Peer (P2P) local Wi-Fi synchronization.

The application natively supports five core formats: **TXT, Markdown (MD), CSV, JSON, and XML**.

### Core Architecture Highlights
- **Shared Multi-Format Editor Engine**: Provides unified undo/redo, regex search and replace with capture group substitution (`$1`), column/subtree scoped replacement, line-ending (CRLF/LF) and encoding (UTF-8, UTF-16, Windows code pages) preservation, and atomic safe saving.
- **Tabbed Multi-Document Interface**: Dynamically manages document tabs with memory-aware automatic caps based on device RAM (`system_info2`).
- **P2P Local Sync Subsystem**: QR-code paired socket communication over LAN protected with AES-256-GCM encryption and PBKDF2-HMAC-SHA256 key derivation.
- **Large-File Virtualization Engine**: Streaming parsers and virtualized lists capable of rendering files up to 50 MB smoothly without out-of-memory crashes.

---

## 2. Comprehensive Audit of Implemented Features

Below is a summary of the capabilities currently present in the codebase:

| Category | Current Implemented Features |
| :--- | :--- |
| **Shared Editor Core** | Undo/redo stack, Find & replace (case, whole word, regex + capture groups), Scoped replace (column / subtree), Read-only lock, Unsaved changes prompt, Draft/Auto-save crash recovery, Line numbers, Encoding & line-ending detection/override. |
| **TXT Format** | Line numbers gutter, jump to line, custom font size/spacing, light/dark/sepia themes, word/char/line stats, URL autolink, TTS read-aloud (English/Malayalam), simple file splitting & concatenation. |
| **Markdown (MD)** | Rendered view vs Raw source view, **Orientation-aware split-screen dual view with a draggable divider**, Table of Contents (TOC), GFM extensions (tables, task lists, strikethrough, autolinks), LaTeX Math rendering (`flutter_math_fork`), YAML frontmatter metadata inspector **plus a form editor that preserves unknown YAML**, formatting toolbar, **visual table builder dialog**, heading-based splitting. |
| **CSV Format** | Two-dimensional scrollable table grid vs raw text, Header row freeze, First column freeze, Column show/hide & column auto-fit, Header sort (asc/desc), **Multi-level sort hierarchy**, **Calculated formula columns** (SUM/PRODUCT/AVG/MIN/MAX/COUNT, cell refs, ranges), **Conditional formatting highlight rules**, Filter by keyword, Delimiter/encoding auto-detect, Column data type inference (number, date, text, bool, currency), Column statistics (sum, min, max, avg, unique count), **Full-screen interactive bar / line / pie charts**, Duplicate row detection/removal, CSV export options. |
| **JSON Format** | Pretty, Tree, Raw, Minified **and sortable Table** views, Node tree expand/collapse with value type badges, JSONPath query support **plus a visual query builder**, JSON Lines (NDJSON) viewer, JSONC/JSON5 lenient reading mode, Large-number precision protection (BigInt string preservation), JSON Schema validation **with 1-tap quick fixes**, Top-level array splitting/merging. |
| **XML Format** | Pretty, Tree, and Raw views, Collapsible XML hierarchy, Tag/attribute/text search, XPath query support **plus a visual XPath builder**, Entity resolving (`&amp;`, `&#160;`), Namespace visibility, well-formedness check **with 1-tap quick fixes** (XSD schema validation is UI-flagged "coming soon", not yet implemented), Repeated element splitting/merging. |
| **App Shell & Output** | Multi-document tab bar with RAM-based tab auto-cap, edge-swipe gesture to switch between open tabs (tab strip chips themselves use long-press for a menu, not swipe), Recent files list with persistable URI permissions, Favorites/pinned files, In-document fingerprint-based bookmarks, Share sheet integration, Output export (PDF, HTML, DOCX, XLSX, JSON, CSV, YAML), ZIP archive for sharing, Printing support. |
| **Sync & Security** | Serverless LAN P2P pairing via QR code, AES-256-GCM encrypted payload transfer, Selective metadata/favorites/bookmarks sync, App-lock (PIN + Biometric `local_auth` + recovery key), Pairing screen screenshot protection. |

---

## 3. World-First & Unprecedented Feature Proposals (Android Exclusives)

These proposed features do **not exist** in traditional Android text/code/data editors (such as QuickEdit, Markor, Jota, Acode, or Table Notes). They leverage Flutter's cross-format architecture and TextData's serverless local infrastructure.

### Feature 1: Visual Zero-Cloud Data Pipeline Engine (Offline ETL Flow)
- **Concept**: A visual block-based flow tool that lets users chain data operations across different file formats without writing scripts or uploading data to cloud services.
- **Why it's unique**: No Android file app allows transforming data across formats (e.g. CSV -> JSON -> Markdown -> PDF) with filtering, mapping, and key-extraction steps entirely offline on-device.
- **Key Use Cases**:
  - Extract specific keys from a 10MB JSON log file -> Filter records where `status_code == 500` -> Convert result to a CSV table -> Render as a PDF summary report.
  - Join a CSV user list with a JSON permissions export based on a common `user_id` key and generate a formatted Markdown documentation page.
- **Technical Realization**: Built as a visual step node graph in Flutter using pure functional Dart transformations (`Stream<List<Map<String, dynamic>>>`).

### Feature 2: Serverless P2P Live Document Diff & Delta Sync
- **Concept**: Real-time side-by-side document comparison and conflict resolution between two Android devices connected via TextData's local P2P socket network.
- **Why it's unique**: Existing P2P file share tools (like LocalSend or Syncthing) only transfer static files. TextData can establish a peer editing session where two users on the same Wi-Fi view visual line-by-line or cell-by-cell diffs of a CSV, JSON, or MD file and selectively merge edits without Git servers or cloud infrastructure.
- **Key Use Cases**:
  - Two field researchers offline in the field comparing and merging updated CSV survey data between their Android tablets.
  - Pair-reviewing JSON API responses or Markdown documentation over local Wi-Fi.

### Feature 3: Offline Privacy Shield & Intelligent PII Scrubbing Engine
- **Concept**: An on-device automated scanner that identifies sensitive Personally Identifiable Information (PII) and secret credentials before exporting or sharing files.
- **Why it's unique**: Android editors share raw data as-is, risking data leaks. TextData can inspect files locally for sensitive patterns and redact or anonymize them on-the-fly.
- **Capabilities**:
  - Automatically flags Emails, Phone Numbers, Credit Card Numbers, IP Addresses, JWT Tokens, AWS Access Keys, and Private RSA Keys across TXT, MD, CSV, JSON, and XML.
  - Offers 1-tap masking modes: **Redact** (`[REDACTED]`), **Hash** (Salted SHA-256 string substitution), or **Pseudo-Anonymize** (replaces names with `User_01`, `User_02` while retaining structural integrity).

### Feature 4: Embedded Local SQL Query Engine for CSV & JSON (SQL-on-Data)
- **Concept**: An in-memory SQL interface that allows executing standard SQL queries (`SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`, `JOIN`) directly against open CSV files or JSON arrays.
- **Why it's unique**: Current Android tools only offer basic string filtering. Integrating an offline SQL evaluation engine over tabular CSVs and JSON arrays brings desktop-grade analytical querying to mobile devices.
- **Technical Realization**: Utilizes `sqflite_common_ffi` or an in-memory SQLite virtual table mapping engine to query open document buffers in real time.

### Feature 5: Context-Aware Structured Voice Reader & Field Dictation Engine
- **Concept**: An enhanced Text-to-Speech (TTS) and Voice-to-Text engine tailored specifically for structured data formats rather than plain text blocks.
- **Why it's unique**: Standard Android TTS engines read CSV grids and JSON nodes as flat, unpunctuated text strings. TextData's structured voice reader converts layout structures into natural spoken sentences.
- **Capabilities**:
  - **Structured CSV Reading**: Speaks rows semantically: *"Row 14: Client Name: Acme Corp, Status: Pending, Total: $4,500"*.
  - **JSON Tree Verbalizer**: Explains tree hierarchies aloud: *"Object 'Settings' contains 4 keys: Theme (Dark), Font Size (14)..."*.
  - **Voice Dictation Cell Entry**: Allows field workers to fill CSV cells or append TXT lines hands-free using bilingual speech recognition (English and Malayalam).

### Feature 6: Offline Data Health & Structural Anomaly Auditor
- **Concept**: An automated diagnostic inspector that evaluates open data files for structural integrity, type inconsistencies, and data quality flaws.
- **Why it's unique**: Format validators only check syntax errors (e.g. invalid JSON syntax). The Data Health Auditor inspects data quality inside valid files.
- **Audit Checks**:
  - **CSV**: Flags ragged rows (inconsistent column counts), mixed data types in a single column (e.g., text found in an integer column), duplicate primary key values, and statistical numeric outliers.
  - **JSON/XML**: Identifies deep nesting warnings (>10 levels), orphan elements, unreferenced IDs, and missing mandatory properties against detected patterns.

---

## 4. High-Impact Improvements to Existing Features

### 4.1 Shared Editor Core
1. **Multi-Cursor & Column Block Selection**: Allow placing multiple edit cursors or selecting vertical character blocks across lines for rapid bulk editing.
2. **Minimap Scrollbar Overlay**: Provide a miniature visual preview strip along the scrollbar indicating document structure, search match locations, and modified lines.
3. **Built-in Regex Preset Library**: Supplement the search bar with a drop-down list of ready-to-use regex patterns (e.g., Extract Email Addresses, Match IPv4 Addresses, Find Duplicate Lines, Match HTML Tags).
4. **Visual Side-by-Side File Diff Tool**: Allow users to select two open tabs or compare an edited tab against its saved disk state with color-coded line diff highlighting (green additions, red deletions).

### 4.2 CSV Format Enhancements
1. ✅ **Multi-Column Sorting** *(implemented)*: Support multi-level sorting hierarchies (e.g. Sort by `Department` Ascending, then by `Salary` Descending). Built as a sort-levels sheet on the CSV toolbar; the hierarchy is remembered per file.
2. ✅ **Calculated Formula Columns** *(implemented)*: Basic spreadsheet formula evaluation (`=SUM(A1:A10)`, `=PRODUCT(B, C)`, `AVG`, `MIN`, `MAX`, `COUNT`, cell refs and arithmetic). Values are written into the column and refreshed on every edit, so the saved file stays plain CSV.
3. ✅ **Conditional Formatting Rules** *(implemented)*: Highlight rules per column or across the table (less than, greater than, equal, not equal, contains, is empty, repeats), in four theme-aware colours.
4. ✅ **Interactive Data Charting** *(implemented)*: A full-screen chart page with bar, line and pie charts over any numeric column, with touch tooltips, an optional label column, and an option to chart only the rows the current filter shows.

### 4.3 JSON & XML Format Enhancements
1. ✅ **JSON Array-to-Table Grid View** *(implemented)*: A read-only grid view for any array of uniform objects (or plain values), with header-tap sorting. Reached from the toolbar or from "View as table" on an array node in the tree.
2. ✅ **JMESPath / Advanced Query Builder** *(implemented)*: Visual builders for both JSONPath and XPath. The user taps keys, positions and attributes read from the open document; the generated query and its live match count stay on screen, then run through the app's existing evaluators.
3. ✅ **Schema Auto-Fix & Formatting Suggestions** *(implemented)*: 1-tap repairs in the validate sheets — JSON: quote bare keys, single→double quotes, drop trailing commas, strip comments, `True`/`False`/`None` → `true`/`false`/`null`; XML: close open tags, escape bare `&`, wrap several roots, remove junk before the first tag. Each fix is offered only when it actually changes the file and leaves it no worse.

### 4.4 Markdown Format Enhancements
1. ✅ **Split-Screen Live Dual View** *(implemented)*: Source and rendered preview together, side by side in landscape and stacked in portrait, with a draggable divider. Works in raw mode as well as edit mode, so a read-only file can still be read both ways.
2. ✅ **Visual Markdown Table Builder** *(implemented)*: A grid dialog with per-column alignment, add/remove row and column, and a live preview of the generated Markdown. The table button opens the table under the cursor for editing, or inserts a new one.
3. ✅ **YAML Frontmatter Form Editor** *(implemented)*: A form built from the file's own front-matter fields, with a date picker for `date` and chips for `tags`. Only the lines of fields the user actually changed are rewritten, so YAML the app's small parser does not understand survives an edit untouched.

### 4.5 App Shell & P2P Sync Enhancements
1. **P2P Direct Document File Payload Transfer**: Expand P2P LAN sync from syncing app metadata (recents/bookmarks) to streaming full document files directly between devices over local sockets.
2. **Per-Document Biometric Vault**: Allow users to lock individual sensitive files (e.g. confidential CSV or JSON config) with biometric authentication, even if the main app-lock is disabled.
3. **Zero-Knowledge Encrypted Export Archive (`.txdata`)**: Support exporting selected files into a single password-encrypted AES-256 backup bundle.

### 4.6 Large File Handling Enhancements
1. **Chunked Windowed Editing for 100MB+ Files**: Extend the current 50MB view-only mode by introducing a chunked windowed editor that loads 5,000-line editable slices into memory on demand.
2. **Persistent Indexing Cache**: Save file offsets and byte position indexes locally for large files to enable instant re-opening without re-scanning the entire document.

---

## 5. Categorized Feature Matrix & Prioritization

The following matrix categorizes all proposed new features and improvements based on user impact, feasibility in Flutter/Android, and target complexity:

| Feature Name | Category | User Impact | Feasibility | Technical Requirements / Dependencies | Complexity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Visual Data Pipeline Engine (ETL Flow)** | World-First Feature | Very High | High | Custom Dart functional stream pipeline, UI Flow canvas | High |
| **Serverless P2P Live Document Diff & Sync** | World-First Feature | High | High | TextData socket transport, `diff_match_patch` | High |
| **Offline Privacy Shield (PII Scrubbing)** | World-First Feature | Very High | Very High | Regular expressions, Salted SHA-256 crypto | Medium |
| **Embedded SQL Query Engine (CSV/JSON)** | World-First Feature | High | High | `sqflite_common_ffi` in-memory SQLite bindings | Medium |
| **Structured Voice Reader & Field Dictation** | World-First Feature | High | High | `flutter_tts`, Speech-to-Text platform channels | Medium |
| **Offline Data Health & Quality Auditor** | World-First Feature | Medium | Very High | Data type analysis engines, statistical utilities | Low |
| **Visual Side-by-Side File Diff Tool** | Improvement | High | High | Custom diff widget, `diff_match_patch` | Medium |
| **Multi-Column CSV Sorting & Formulas** | Improvement | High | High | Custom sort comparator, basic math expression parser | Medium |
| **JSON Array-to-Table Grid View** | Improvement | High | Very High | Two-dimensional scrollables, dynamic map parsing | Low |
| **Markdown Split-Screen Live Preview** | Improvement | High | Very High | Flutter `Row`/`Column` layout, stream debouncer | Low |
| **Visual Markdown Table Builder GUI** | Improvement | Medium | Very High | Dialog stateful widget grid | Low |
| **P2P Direct File Payload Transfer** | Improvement | Very High | High | Binary stream chunking over TextData P2P socket | Medium |
| **Per-Document Biometric Vault** | Improvement | High | Very High | `flutter_secure_storage`, `local_auth` | Low |
| **Chunked Windowed Editor (100MB+ Files)** | Improvement | High | Medium | SAF random access stream, custom buffer manager | High |

---

## 6. Strategic Implementation Roadmap

### Phase 15: Editor Polish & Format Upgrades
- ⬜ Implement **Visual Side-by-Side File Diff Tool** for comparing document versions.
- ✅ Implement **Markdown Split-Screen Live Dual View** and **Visual Table Builder GUI**.
- ✅ Implement **JSON Array-to-Table Grid View** transformation.
- ⬜ Introduce **Built-in Regex Preset Library** to the search bar.
- ✅ Add **Multi-Column CSV Sorting** and **Interactive Data Charts** (`fl_chart`).
- ✅ *(also delivered)* **Calculated CSV formula columns**, **CSV conditional formatting**,
  **JSONPath / XPath visual query builders**, **JSON & XML schema quick fixes**, and the
  **YAML front-matter form editor** — everything in §4.2, §4.3 and §4.4.

### Phase 16: Advanced Analytics, Data Health & Security
- Implement **Offline Privacy Shield & PII Scrubbing Engine** (email, phone, keys masking).
- Implement **Offline Data Health & Structural Anomaly Auditor**.
- Integrate **Embedded SQL Query Engine** (`sqflite_common_ffi`) for CSV & JSON files.
- Add **Per-Document Biometric Vault** and **Encrypted `.txdata` Backup Archives**.
- Implement **Context-Aware Structured Voice Reader**.

### Phase 17: Next-Gen P2P Sync & Data Pipeline Engine
- Upgrade P2P LAN Subsystem to support **Direct Document File Payload Transfer**.
- Implement **Serverless P2P Live Document Diff & Delta Sync** between paired devices.
- Build the **Visual Zero-Cloud Data Pipeline Engine (ETL Flow Builder)**.
- Implement **Chunked Windowed Editing Engine** for files exceeding 100 MB.

---
*Document created for TextData (`SreerajP_TextApp`) project planning and documentation.*
