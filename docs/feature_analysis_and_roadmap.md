# Feature Analysis, Novel Innovation & Product Roadmap — SreerajP TextApp (TextData)

A look at where the app stands against similar apps, and the ordered list of what to
build next. Read it when planning new work, not when checking how something works today.

> **Which document owns what.** This file is about *future* work and comparisons. What
> the app already does is listed in [features.md](features.md); the technical design is
> in [architecture.md](architecture.md); the phase-by-phase build record is in
> [implementation-plan.md](implementation-plan.md) and
> [implementation-progress.md](implementation-progress.md). If a fact here disagrees
> with one of those, the other document wins.

---

## 1. Executive Summary & App Identity Analysis

**TextData** (`SreerajP_TextApp`) is an offline-first, privacy-focused Android text and structured data editor built with Flutter (minSdk 26+). Unlike standard text viewers or cloud-dependent productivity apps, TextData focuses on zero-cloud operations, Storage Access Framework (SAF) scoped storage integrity, open-source compliance (banning commercial SDKs like Syncfusion), and serverless Peer-to-Peer (P2P) local Wi-Fi synchronization.

The application natively supports five core formats: **TXT, Markdown (MD), CSV, JSON, and XML**, along with line-delimited JSON (**JSONL / NDJSON**) as a specialized JSON viewer mode. YAML is supported at the content level via 1-tap conversion to/from JSON and through a dedicated form editor for Markdown YAML frontmatter.

### Core Architecture Highlights
- **Shared Multi-Format Editor Engine**: Provides unified undo/redo, regex search and replace with capture group substitution (`$1`), column/subtree scoped replacement, line-ending (CRLF/LF) and encoding (UTF-8, UTF-16, Windows code pages) preservation, and atomic safe saving (`AtomicSaver`).
- **Tabbed Multi-Document Interface**: Dynamically manages document tabs with RAM-aware automatic caps (`TabCapPolicy` based on `system_info2`).
- **P2P Local Sync Subsystem**: QR-code and PIN paired socket communication over LAN protected with AES-256-GCM encryption and PBKDF2-HMAC-SHA256 key derivation.
- **Large-File Virtualization Engine**: Streaming parsers and virtualized lists capable of rendering files up to 50 MB smoothly without out-of-memory crashes.

### Ecosystem Synergy & Reusable Core Technologies
TextData operates within a broader ecosystem of 18 offline-first Flutter/Kotlin Android applications (`L:\Android\MyFlutterApps\myapps.md`). This architecture leverages pre-built, battle-tested modules across the developer's application suite:
- **Optical Air-Gap QR Data Transfer (AirQR)** *(from `sreeraj_qr_reader` & `SreerajP_Authenticator`)*: Camera-based animated QR stream transport for snippets and single documents. **Built in this app as `lib/airqr/`** and reusable across the suite.
- **Tamper-Evident Audit Logging** *(from `SreerajPContactSphere`)*: Cryptographic SHA-256 hash-chain event logging with live verification and signed export capabilities. **Built in this app as `lib/core/audit/`**.
- **Ephemeral & Self-Destructing Workspace** *(from `SreerajPContactSphere`)*: Timed and trigger-based auto-scrubbing data storage. **Built in this app as `lib/core/ephemeral/`**.
- **Workspace Full-Text Search Indexing** *(from `SreerajP_Journal_Vault`)*: SQLite FTS5 indexers for multi-file workspace queries. **Built in this app as `SearchIndexService`**.
- **Embedded SQL-on-Data Engine** *(from `SreerajP_TextApp` & `SreerajPContactSphere`)*: In-memory SQLite evaluation over CSV grids and JSON arrays. **Built in this app as `lib/core/sql/`**.
- **PDF Rendering, Conversion & Digital Signatures** *(from `SreerajP_PDFApp`)*: High-performance pdfrx rendering, `PdfBox-Android` document manipulation, Bouncy Castle cryptographic signature verification, copy-on-write page operations, and image/text-to-PDF conversion.
- **iCalendar Recurrence Engine & Data Visualization** *(from `sreerajp_todo`)*: RFC 5545 RRULE recurrence engines, interactive `fl_chart` analytics (bar, line, pie), and passphrase-encrypted ZIP backup archives.
- **Canonical Link Builders & Encrypted Vault Portability** *(from `sreerajp_youtube_shortcut`)*: AES-256-GCM encrypted backup payload serialization, PBKDF2 key derivation, and offline QR payload generation/scanning.
- **Encrypted Local Storage & Biometric Gating** *(from `vault-files` & `SreerajP_Authenticator`)*: Hardware Keystore AES-256-GCM encryption (`flutter_secure_storage`), biometric app-lock (`local_auth`), and hidden vault structures.
- **PII Extraction & Testing Sandboxes** *(from `sms-sentry`)*: Heuristic regex classifiers and real-time rule test workbenches.
- **AST & Storage Access Framework Security** *(from `SreerajP_CodeApp`)*: SAF URI management, syntax trees, and atomic document persistence (`AtomicSaver`).
- **Complex Script Publishing & Multi-Script Mapping** *(from `LyricChord`, `SreerajP_PDFApp` & `SreerajPContactSphere`)*: Embedded SIL OFL fonts, Malayalam Unicode NFC normalization (`unorm_dart`), and multi-script T9 / search key generation.

---

## 2. Comprehensive Audit of Implemented Features

Below is a summary of the capabilities currently present in the codebase:

| Category | Current Implemented Features |
| :--- | :--- |
| **Shared Editor Core** | Undo/redo stack, Find & replace (case, whole word, regex + capture groups `$1`), Scoped replace (column / subtree), Read-only lock, Unsaved changes prompt, Draft/Auto-save crash recovery, Line numbers, Encoding & line-ending detection/override, Pinch-to-zoom text scaling, Binary content sniffing, Edge-swipe tab switching, RAM-based tab auto-cap (`system_info2`). |
| **TXT Format** | Line numbers gutter, jump to line, custom font size/spacing, light/dark/sepia themes, word/char/line stats, URL autolink & security warning, All-links sheet, TTS read-aloud (English/Malayalam), simple file splitting & concatenation. |
| **Markdown (MD)** | Rendered view vs Raw source view, **Orientation-aware split-screen dual view with a draggable divider (`MdLivePreview`)**, Table of Contents (TOC), GFM extensions (tables, task lists, strikethrough, autolinks), LaTeX Math rendering (`flutter_math_fork`), YAML frontmatter metadata inspector **plus a form editor that preserves unknown YAML (`MdFrontMatterForm`)**, formatting toolbar, **visual table builder dialog (`MdTableBuilderDialog`)**, GFM table 2D matrix editor, heading-based splitting. |
| **CSV Format** | Two-dimensional scrollable table grid (`two_dimensional_scrollables`) vs raw text, Header row freeze, First column freeze, Column show/hide & column auto-fit, Header sort (asc/desc), **Multi-level sort hierarchy (`CsvSortSheet`)**, **Calculated formula columns** (SUM/PRODUCT/AVG/MIN/MAX/COUNT, cell refs, ranges), **Conditional formatting highlight rules (`CsvConditionalFormatSheet`)**, Filter by keyword, Delimiter/encoding auto-detect, Column data type inference (number, date, text, bool, currency), Column statistics (sum, min, max, avg, unique count, missing count), **Full-screen interactive bar / line / pie charts (`fl_chart`)**, Duplicate row detection/removal, CSV export options, Grid-level undo/redo, **embedded read-only SQL query engine (`lib/core/sql/`)**. |
| **JSON Format** | Pretty, Tree (`JsonTreeView`), Raw, Minified **and sortable Table** views (`JsonTableView`), Node tree expand/collapse with value type badges, Tree node manipulation (edit/add/delete/duplicate), Structural JSON diff engine (`JsonDiff`), JSONPath query support **plus a visual query builder (`JsonQueryBuilderSheet`)**, JSON Lines (NDJSON) viewer, JSONC/JSON5 lenient reading mode, Large-number precision protection (BigInt string preservation), JSON Schema validation **with 1-tap quick fixes (`JsonQuickFix`)**, Bi-directional YAML conversion, Top-level array splitting/merging, **embedded read-only SQL query engine over an array of records**. |
| **XML Format** | Pretty, Tree (`XmlTreeView`), and Raw views, Collapsible XML hierarchy, Tag/attribute/text search, Element editing (tags, attributes, CDATA, comments), XPath query support **plus a visual XPath builder (`XmlQueryBuilderSheet`)**, Entity resolving (`&amp;`, `&#160;`), Namespace visibility, well-formedness check **with 1-tap quick fixes (`XmlQuickFix`)**, JSON conversion (`XmlConvert`), Repeated element splitting/merging. |
| **Workspace Search** | **Workspace-Wide SQLite FTS5 Full-Text Search Indexer (`SearchIndexService`)**: Background FTS5 virtual table indexing over recent and favorite TXT, MD, CSV, JSON, and XML files, with format filter chips, snippet highlighting, and 1-tap tab opening from Home. |
| **App Shell & Output** | Multi-document tab bar with RAM-based tab auto-cap (`TabCapPolicy`), edge-swipe gesture to switch open tabs, Recent files list (`RecentsRepository`) with persistable URI permissions, Favorites/pinned files (`FavoritesRepository`), In-document fingerprint-based bookmarks (`ContentFingerprint`), Create New Document action (pre-filled templates), Share sheet integration (`share_plus`), Output export (PDF, HTML, DOCX, XLSX, JSON, CSV, YAML), ZIP archive compression (`ZipService`), System Printing (`printing`). |
| **Sync & Security** | Serverless LAN P2P pairing via QR code & PIN, AES-256-GCM encrypted payload transfer (`encrypt` + `pointycastle`), Selective metadata/favorites/bookmarks/recents sync (`ShareChooser`), App-lock (PIN + Biometric `local_auth` + recovery key), Hardware-backed key storage (`flutter_secure_storage`), Pairing screen screenshot protection (`FLAG_SECURE` / `WindowSecurity`), **Self-destructing document tabs (`lib/core/ephemeral/`)** with a countdown badge, burn-after-export, and a full trace wipe across drafts, recents, favourites, bookmarks, per-file settings and the FTS5 search index, **Tamper-evident workspace audit log (`lib/core/audit/`)** with SHA-256 chain verification, live status badge, and signed JSON certificate export, **Zero-knowledge encrypted backup archive (`lib/core/backup/`, `.txdata`)** with PBKDF2-HMAC-SHA256 (200,000 iterations), AES-256-GCM encryption, inner ZIP packaging, and selective restore. |
| **Optical Air-Gap Transfer (AirQR)** | Networkless device-to-device transfer over screen and camera only (`lib/airqr/`), animated QR frame stream (`qr_flutter`) with reshuffled cyclic repetition for dropped-frame recovery, camera capture (`mobile_scanner`) with live frames/FPS/missing-frame readout, gzip compression, AES-256-GCM sealing with a PBKDF2-derived key from an out-of-band session code, end-to-end SHA-256 verification, enforced 256 KB / 1 MB / 4 MB size gate, whole-document send from all five format menus, text-selection send from the editor popup, and receive-side save through the user's own SAF picker. |

---

## 3. World-First & Unprecedented Feature Proposals (Android Exclusives & Ecosystem Synergy)

These proposed features leverage Flutter's cross-format architecture, TextData's serverless local infrastructure, and reusable modules from the developer's 18-app Flutter suite.

Entries marked ✅ **DELIVERED** are built and in the codebase.

### Feature 1: Visual Zero-Cloud Data Pipeline Engine (Offline ETL Flow)
- **Concept**: A visual block-based flow tool that lets users chain data operations across different file formats without writing scripts or uploading data to cloud services.
- **Why it's unique**: No Android file app allows transforming data across formats (e.g. CSV -> JSON -> Markdown -> PDF) with filtering, mapping, and key-extraction steps entirely offline on-device.
- **Key Use Cases**:
  - Extract specific keys from a 10MB JSON log file -> Filter records where `status_code == 500` -> Convert result to a CSV table -> Render as a PDF summary report.
  - Join a CSV user list with a JSON permissions export based on a common `user_id` key and generate a formatted Markdown documentation page.
- **Technical Realization**: Built as a visual step node graph in Flutter using pure functional Dart transformations (`Stream<List<Map<String, dynamic>>>`).

### ✅ Feature 2: Serverless P2P Live Document Diff & Delta Sync — **DELIVERED**
- **Concept**: Real-time side-by-side document comparison and conflict resolution between two Android devices connected via TextData's local P2P socket network.
- **Why it's unique**: Existing P2P file share tools (like LocalSend or Syncthing) only transfer static files. TextData can establish a peer editing session where two users on the same Wi-Fi view visual line-by-line or cell-by-cell diffs of a CSV, JSON, or MD file and selectively merge edits without Git servers or cloud infrastructure.
- **Status**: Built as `lib/sync/diff/` and `lib/sync/ui/live_diff_screen.dart`, covered by comprehensive test suites in `test/sync/diff/`, `flutter analyze` clean. Pure Dart Myers/LCS diff algorithm, 2D tabular CSV comparison, word-level inline highlights, real-time live delta sync over encrypted LAN sockets, and 1-tap resolution actions (`Mine`, `Peer`, `Both`, `Auto-Merge`).
- **Key Use Cases**:
  - Two field researchers offline in the field comparing and merging updated CSV survey data between their Android tablets.
  - Pair-reviewing JSON API responses or Markdown documentation over local Wi-Fi.

### ✅ Feature 3: Offline Privacy Shield & Intelligent PII Scrubbing Engine — **DELIVERED**
- **Concept**: An on-device automated scanner that identifies sensitive Personally Identifiable Information (PII) and secret credentials before exporting or sharing files.
- **Why it's unique**: Android editors share raw data as-is, risking data leaks. TextData can inspect files locally for sensitive patterns and redact or anonymize them on-the-fly.
- **Status**: Built as `lib/core/privacy/`, covered by unit and widget tests in `test/core/privacy/`, `flutter analyze` clean. Features automatic detection of Emails, Phone Numbers, Credit Cards (with Luhn validation), IP Addresses, JWTs, AWS keys, Private Keys, and API secrets with 1-tap **Redact**, **Salted Hash**, and **Pseudo-Anonymize** masking modes.
- **Capabilities**:
  - Automatically flags Emails, Phone Numbers, Credit Card Numbers, IP Addresses, JWT Tokens, AWS Access Keys, and Private RSA Keys across TXT, MD, CSV, JSON, and XML.
  - Offers 1-tap masking modes: **Redact** (`[REDACTED]`), **Hash** (Salted SHA-256 string substitution), or **Pseudo-Anonymize** (replaces names with `user_01@anonymized.local`, `User_01` while retaining structural integrity).
  - Gives users full control to selectively scrub, apply in-place to the editor, or share/export a scrubbed copy while preserving the original.

### ✅ Feature 4: Embedded Local SQL Query Engine for CSV & JSON (SQL-on-Data) — **DELIVERED**
- **Concept**: An in-memory SQL interface that allows executing standard SQL queries (`SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`, `JOIN`) directly against open CSV files or JSON arrays.
- **Why it's unique**: Current Android tools only offer basic string filtering. Integrating an offline SQL evaluation engine over tabular CSVs and JSON arrays brings desktop-grade analytical querying to mobile devices.
- **Status**: Built as `lib/core/sql/`, with format adapters in `formats/csv/csv_sql_source.dart` and `formats/json/json_sql_source.dart`. Covered by tests in `test/core/sql/`, `flutter analyze` clean. Reached from the overflow menu of both CSV and JSON formats.

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

### ✅ Feature 7: Optical Air-Gap Document & Data Transfer Engine (AirQR) *(Ecosystem Synergy)* — **DELIVERED**
- **Concept**: Networkless transfer of snippets and single documents using animated QR code streams rendered on screen and scanned by another device's camera, without Wi-Fi, local sockets, or Bluetooth permissions.
- **Inspiration & Proven Module**: Derived directly from `sreeraj_qr_reader` (AirQR) and `SreerajP_Authenticator` (Optical Air-Gap Sync).
- **Status**: Built as `lib/airqr/`, covered by 57 tests in `test/airqr/`, `flutter analyze` clean. Enforces 256 KB soft cap, 1 MB warning, and 4 MB hard cap.

### ✅ Feature 8: Tamper-Evident Workspace Audit Log *(Ecosystem Synergy)* — **DELIVERED**
- **Concept**: Cryptographically chained hash log (`SHA-256` chain) capturing every document edit, file export, P2P sync, and security event within TextData.
- **Inspiration & Proven Module**: Derived directly from `SreerajPContactSphere` (Tamper-Evident Audit Log).
- **Status**: Built as `lib/core/audit/`, covered by 17 unit tests in `test/core/audit/`, `flutter analyze` clean. Features automatic before/after SHA-256 content state hashing, live UI badge with verification banner, and one-tap export of HMAC-signed audit certificates.
- **Capabilities**:
  - Automatically records before/after state hashes of modified files.
  - Live UI badge showing "Tamper-Proof Chain Verified" or pinpointing the exact corrupted entry if an external process modifies the log.
  - One-tap export of signed audit certificates.

### ✅ Feature 9: Ephemeral / Self-Destructing Document Workspace *(Ecosystem Synergy)* — **DELIVERED**
- **Concept**: Temporary document tabs that automatically scrub from RAM and local disk after a user-configured expiration timer (15 minutes, 1 hour, 4 hours, 24 hours, or a typed number of minutes) or upon a single export action.
- **Inspiration & Proven Module**: Derived directly from `SreerajPContactSphere` (Ephemeral Contacts Engine).
- **Status**: Built as `lib/core/ephemeral/`, covered by tests in `test/core/ephemeral/`, `flutter analyze` clean. Performs full trace wipes across auto-save drafts, drafts index, recents, favorites, bookmarks, per-file preferences, and the FTS5 search index.

### Feature 10: Interactive Rule & Data Transformation Testing Sandbox *(Ecosystem Synergy)*
- **Concept**: An interactive workbench page allowing users to test JSONPath, XPath, SQL queries, or PII scrubbing regex rules against mock text inputs before executing them on open production documents.
- **Inspiration & Proven Module**: Derived directly from `sms-sentry` (Testing Sandbox Page).
- **Capabilities**:
  - Typed input area with 1-tap preset scenarios (e.g., Log Scrubbing, Bank JSON Extract, CSV Filter).
  - Real-time visual breakdown of matched tokens, extracted fields, and performance metrics.

### ✅ Feature 11: Workspace-Wide SQLite FTS5 Full-Text Search Indexer *(Ecosystem Synergy)* — **DELIVERED**
- **Concept**: Offline background SQLite FTS5 indexer that indexes recent and favorite documents across the workspace, enabling instant full-text search across all open or recent CSV, JSON, XML, Markdown, and TXT files.
- **Inspiration & Proven Module**: Derived directly from `SreerajP_Journal_Vault` (FTS5 Search Engine).
- **Status**: Built as `SearchIndexService` in `lib/core/storage/search_index_service.dart`. Provides full-text indexing, format filter chips, snippet highlighting, and 1-tap tab opening on Home.

### ✅ Feature 12: Zero-Knowledge Encrypted Backup Archive (`.txdata`) *(Ecosystem Synergy)* — **DELIVERED**
- **Concept**: Support exporting selected files, recents, favorites, bookmarks, and settings into a single password-encrypted AES-256 backup bundle.
- **Inspiration & Proven Module**: Derived directly from `sreerajp_youtube_shortcut`, `sreerajp_todo`, and `SreerajPContactSphere`.
- **Status**: Built as `lib/core/backup/`, covered by unit and integration tests in `test/core/backup/`, `flutter analyze` clean. Features PBKDF2-HMAC-SHA256 key derivation with 200,000 iterations and 16-byte random salt, AES-256-GCM encryption with password verification upon import, inner ZIP payload packaging with manifest, selective restore dialogs, and zero-knowledge security isolation.
- **Capabilities**:
  - PBKDF2-HMAC-SHA256 key derivation with 200,000 iterations and 16-byte random salt.
  - AES-256-GCM encryption over exported archives with password verification upon import.
  - Inner ZIP packaging of manifest, recents, favorites, bookmarks, settings, and attached document files.
  - Safe import preview and selective restore with merge / replace modes.

---

## 4. High-Impact Improvements to Existing Features

### 4.1 Shared Editor Core
1. ✅ **Multi-Cursor & Column Block Selection** *(implemented)*: Allow placing multiple edit cursors or selecting vertical character blocks across lines for rapid bulk editing (`ColumnSelectionEngine`, `ColumnSelectionSheet`).
2. **Minimap Scrollbar Overlay**: Provide a miniature visual preview strip along the scrollbar indicating document structure, search match locations, and modified lines.
3. **Built-in Regex Preset Library**: Supplement the search bar with a drop-down list of ready-to-use regex patterns (e.g., Extract Email Addresses, Match IPv4 Addresses, Find Duplicate Lines, Match HTML Tags).
4. **Visual Side-by-Side File Diff Tool**: Allow users to select two open tabs or compare an edited tab against its saved disk state with color-coded line diff highlighting (green additions, red deletions) using `diff_match_patch`.

### 4.2 CSV Format Enhancements
1. ✅ **Multi-Column Sorting** *(implemented)*: Support multi-level sorting hierarchies (`CsvSortSheet`).
2. ✅ **Calculated Formula Columns** *(implemented)*: Basic spreadsheet formula evaluation (`SUM`, `PRODUCT`, `AVG`, `MIN`, `MAX`, `COUNT`, cell refs and arithmetic).
3. ✅ **Conditional Formatting Rules** *(implemented)*: Highlight rules per column or across the table (`CsvConditionalFormatSheet`).
4. ✅ **Interactive Data Charting** *(implemented)*: A full-screen chart page with bar, line and pie charts over any numeric column (`fl_chart`).

### 4.3 JSON & XML Format Enhancements
1. ✅ **JSON Array-to-Table Grid View** *(implemented)*: A read-only grid view for any array of uniform objects (`JsonTableView`).
2. ✅ **JMESPath / Advanced Query Builder** *(implemented)*: Visual builders for both JSONPath and XPath (`JsonQueryBuilderSheet`, `XmlQueryBuilderSheet`).
3. ✅ **Schema Auto-Fix & Formatting Suggestions** *(implemented)*: 1-tap repairs in validate sheets (`JsonQuickFix`, `XmlQuickFix`).

### 4.4 Markdown Format Enhancements
1. ✅ **Split-Screen Live Dual View** *(implemented)*: Source and rendered preview together, side by side in landscape and stacked in portrait (`MdLivePreview`).
2. ✅ **Visual Markdown Table Builder** *(implemented)*: A grid dialog with per-column alignment (`MdTableBuilderDialog`).
3. ✅ **YAML Frontmatter Form Editor** *(implemented)*: A form built from the file's own front-matter fields (`MdFrontMatterForm`).

### 4.5 App Shell, Security & P2P Enhancements
1. ✅ **P2P Direct Document File Payload Transfer** *(implemented)*: Expand P2P LAN sync from syncing app metadata (recents/bookmarks) to streaming full document files directly between devices over local sockets (`lib/sync/`).
2. ✅ **Per-Document Biometric Vault (`.txvault`)** *(implemented)*: Allow users to lock individual sensitive files with biometric authentication (`local_auth`) and hardware-backed AES-256-GCM encryption (`lib/core/vault/`).
3. ✅ **Zero-Knowledge Encrypted Backup Archive (`.txdata`)** *(implemented)*: Export and restore selected files, recents, favorites, bookmarks, and settings into a password-encrypted AES-256 backup bundle (`lib/core/backup/`).

### 4.6 Large File Handling Enhancements
1. **Chunked Windowed Editing for 100MB+ Files**: Extend current 50MB view-only mode by introducing a chunked windowed editor that loads 5,000-line editable slices into memory on demand.
2. **Persistent Indexing Cache**: Save file offsets and byte position indexes locally for large files to enable instant re-opening.

---

## 5. Categorized Feature Matrix & Prioritization

The following matrix categorizes all proposed new features and improvements based on user impact, feasibility in Flutter/Android, target complexity, and ecosystem component reuse:

| Feature Name | Category | User Impact | Feasibility | Technical Requirements / Ecosystem Dependencies | Complexity |
| :--- | :--- | :--- | :--- | :--- | :--- |
| ⬜ **Visual Data Pipeline Engine (ETL Flow)** | World-First Feature | Very High | High | Custom Dart functional stream pipeline, UI Flow canvas | High |
| ⬜ **Serverless P2P Live Document Diff & Sync** | World-First Feature | High | High | TextData socket transport, `diff_match_patch` | High |
| ✅ **Offline Privacy Shield (PII Scrubbing)** | World-First Feature | Very High | Very High | Regular expressions, Salted SHA-256 crypto *(from `sms-sentry`)* *(delivered)* | Medium |
| ✅ **Embedded SQL Query Engine (CSV/JSON)** | World-First Feature | High | High | In-memory SQLite through `sqflite` — **no new dependency** *(delivered)* | Medium |
| ⬜ **Structured Voice Reader & Field Dictation** | World-First Feature | High | High | `flutter_tts`, Speech-to-Text platform channels | Medium |
| ⬜ **Offline Data Health & Quality Auditor** | World-First Feature | Medium | Very High | Data type analysis engines, statistical utilities | Low |
| ✅ **Optical Air-Gap Transfer (AirQR)** | Ecosystem Synergy | Medium | High | `mobile_scanner`, `qr_flutter`, `SyncCrypto` — **no new dependency** *(delivered)* | Medium |
| ✅ **Tamper-Evident Workspace Audit Log** | Ecosystem Synergy | Medium | Very High | `crypto` SHA-256 hash-chain logger *(from `SreerajPContactSphere`)* *(delivered)* | Low |
| ✅ **Ephemeral / Self-Destructing Workspace** | Ecosystem Synergy | Medium | Very High | In-memory timer, zero-fill wiping *(from `SreerajPContactSphere`)* *(delivered)* | Low |
| ⬜ **Interactive Transformation Sandbox** | Ecosystem Synergy | Medium | Very High | Test workbench UI, query evaluator bindings *(from `sms-sentry`)* | Low |
| ✅ **Workspace-Wide SQLite FTS5 Indexer** | Ecosystem Synergy | High | High | `sqflite` FTS5 virtual tables *(from `SreerajP_Journal_Vault`)* *(delivered)* | Medium |
| ✅ **Multi-Cursor & Column Block Selection** | Improvement | High | Very High | `ColumnSelectionEngine`, `ColumnSelectionSheet` *(delivered)* | Low |
| ⬜ **Visual Side-by-Side File Diff Tool** | Improvement | High | High | Custom diff widget, `diff_match_patch` | Medium |
| ✅ **Multi-Column CSV Sorting & Formulas** | Improvement | High | High | Custom sort comparator, math parser *(delivered)* | Medium |
| ✅ **JSON Array-to-Table Grid View** | Improvement | High | Very High | Two-dimensional scrollables, dynamic map parsing *(delivered)* | Low |
| ✅ **Markdown Split-Screen Live Preview** | Improvement | High | Very High | Flutter `Row`/`Column` layout, stream debouncer *(delivered)* | Low |
| ✅ **Visual Markdown Table Builder GUI** | Improvement | Medium | Very High | Dialog stateful widget grid *(delivered)* | Low |
| ✅ **P2P Direct File Payload Transfer** | Improvement | Very High | High | Binary stream chunking over TextData P2P socket *(delivered)* | Medium |
| ✅ **Per-Document Biometric Vault** | Improvement | High | Very High | `flutter_secure_storage`, `local_auth` *(delivered)* | Low |
| ✅ **Zero-Knowledge Encrypted Backup Archive** | Ecosystem Synergy | High | High | PBKDF2 + AES-256-GCM ZIP export *(from `sreerajp_youtube_shortcut`)* *(delivered)* | Medium |
| ⬜ **Chunked Windowed Editor (100MB+ Files)** | Improvement | High | Medium | SAF random access stream, custom buffer manager | High |

---

## 6. Strategic Implementation Roadmap

### Phase 15: Editor Polish, Advanced Formatting & Analytics (DELIVERED)
- ✅ Implement **Markdown Split-Screen Live Dual View** (`MdLivePreview`) and **Visual Table Builder GUI** (`MdTableBuilderDialog`).
- ✅ Implement **JSON Array-to-Table Grid View** transformation (`JsonTableView`).
- ✅ Add **Multi-Column CSV Sorting** (`CsvSortSheet`) and **Interactive Data Charts** (`fl_chart`).
- ✅ Implement **Calculated CSV Formula Columns**, **CSV Conditional Formatting Rules**, **JSONPath / XPath Visual Query Builders**, **JSON & XML Schema Quick Fixes**, and **YAML Frontmatter Form Editor** (`MdFrontMatterForm`).

### Phase 16: Advanced Analytics, Data Health & Security
- ✅ Implement **Offline Privacy Shield & PII Scrubbing Engine** (email, phone, cards, IP, keys, token redaction, salted SHA-256 hashing, anonymizing) — **DELIVERED** as `lib/core/privacy/`.
- ⬜ Implement **Offline Data Health & Structural Anomaly Auditor** (ragged rows, mixed data types, outlier detection).
- ✅ Integrate **Embedded SQL Query Engine** for executing read-only SQL directly against open CSV and JSON buffers — **DELIVERED** as `lib/core/sql/`.
- ✅ Add **Per-Document Biometric Vault** (`lib/core/vault/`) — **DELIVERED**.
- ✅ Add **Zero-Knowledge Encrypted `.txdata` Backup Archives** (`lib/core/backup/`) — **DELIVERED**.
- ✅ Add **Multi-Cursor & Column Block Selection** (`lib/core/editor/column_selection.dart`, `lib/core/editor/column_selection_sheet.dart`) — **DELIVERED**.
- ⬜ Implement **Context-Aware Structured Voice Reader & Field Dictation Engine**.
- ✅ Build **Visual Side-by-Side File Diff Tool** (`lib/sync/diff/`, `LiveDiffScreen`) for document comparisons — **DELIVERED**.
- ⬜ Introduce **Built-in Regex Preset Library** to the search bar.

### Phase 17: Next-Gen P2P Sync & Data Pipeline Engine
- ✅ Upgrade P2P LAN Subsystem to support **Direct Document File Payload Transfer** between connected devices (`lib/sync/`) — **DELIVERED**.
- ✅ Implement **Serverless P2P Live Document Diff & Delta Sync** over encrypted LAN sockets (`lib/sync/diff/`) — **DELIVERED**.
- ⬜ Build the **Visual Zero-Cloud Data Pipeline Engine (ETL Flow Builder)** for node-based data transformations.
- ⬜ Implement **Chunked Windowed Editing Engine** for files exceeding 100 MB and **Persistent Indexing Cache**.

### Phase 18: Ecosystem Synergy, Air-Gap Transfers & Audit Security
- ✅ **Implement Optical Air-Gap Transfer Engine (AirQR)** using animated QR code streams *(from `sreeraj_qr_reader`)* — **DELIVERED** as `lib/airqr/`.
- ⬜ Add **AirQR settings & rules transfer**: editor settings, CSV conditional-format rules, and saved JSONPath / XPath queries over the optical channel.
- ⬜ Add a **wakelock on the AirQR sending screen** so a long transfer is not cut short by the screen timeout.
- ✅ **Implement Tamper-Evident Workspace Audit Log** with SHA-256 hash-chain verification *(from `SreerajPContactSphere`)* — **DELIVERED** as `lib/core/audit/`.
- ✅ **Add Ephemeral / Self-Destructing Document Workspace** with secure zero-fill wiping *(from `SreerajPContactSphere`)* — **DELIVERED** as `lib/core/ephemeral/`.
- ✅ **Integrate Workspace-Wide SQLite FTS5 Full-Text Search Indexer** across recents and favorites *(from `SreerajP_Journal_Vault`)* — **DELIVERED** as `SearchIndexService`.
- ⬜ Add **memory-only notes** (a document tab with no file behind it).
- ⬜ Integrate **Interactive Rule & Transformation Testing Sandbox** workbench *(from `sms-sentry`)*.

---
*Document updated for TextData (`SreerajP_TextApp`) project planning and ecosystem integration.*
