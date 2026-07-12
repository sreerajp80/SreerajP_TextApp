# Text & Data App

# What is this app
This is an Android app built in Flutter to **open, read, edit, and update** plain-text and
structured-data files: **TXT, Markdown (MD), JSON, CSV, and XML**. Unlike a plain viewer,
this app can change file content and save it back. It is one of five separate apps split
out from the original single "File Reader" idea (the others cover PDF, code files, HTML,
and EPUB).

# Development Tools versions
Flutter 3.41.9 or higher
Dart 3.11.5 or higher

# Licensing constraint
Every library used by this app must be **open source**. Commercial or source-available SDKs
are not allowed, even when they have a free community license (for example Syncfusion).

# Shared Capabilities (build once, reuse everywhere)
These features repeat across the file types this app handles. Build them **one time** as
shared modules and reuse them, not re-implement per format.

- **Search** — find text, highlight matches, and jump between matches. Works over rendered
  content or raw source depending on the file type. Includes **advanced options**:
  **case-sensitive** on/off, **whole-word** on/off, and **regular-expression (regex)** search.
  Bad regex patterns are caught and shown as a friendly "invalid pattern" hint instead of
  failing.
- **Text-to-Speech (TTS)** — read content aloud in **English and Malayalam**. Malayalam TTS
  is controlled by a **toggle in the app's Settings** and depends on a Malayalam voice being
  installed on the device. If no voice is present, the app guides the user to install one;
  if the toggle is on but the voice goes missing, the app turns the toggle off and tells the
  user why. Reader screens ask this shared module for the current state, so they never show
  a dead or broken button. (See [Risks & Hard Features](#risks--hard-features).)
- **Share** — send the file, or exported output, to other apps via the Android share sheet.
- **Export / Convert** — a single conversion service with common targets (PDF, HTML, DOCX,
  plain text, images, and format-specific ones like JSON/CSV/XLSX). Each file type declares
  which targets it supports.
- **Metadata** — file size, created / modified date, and encoding, plus type-specific fields
  (row/column count for CSV, root element for XML, top-level type for JSON, etc.).
- **Themes & reading comfort** — light / dark / sepia themes, plus adjustable font size,
  font family (where relevant), and line spacing.
- **Reading position** — remember the last-read scroll position per file. Positions are
  keyed to the file's content fingerprint (see
  [Non-Functional Requirements](#non-functional-requirements)).
- **Copy** — select and copy text, a cell/row, a subtree, or the whole content.
- **Print** — a shared print service; **every format** can print, each using its natural
  output (TXT/MD raw or rendered text, CSV the table, JSON/XML the formatted view). Per-format
  sections may name what they print, but the print capability itself lives here.
- **Compress (zip) for sharing** — a shared action to zip the current file (or exported
  output) before sharing. Available for **all formats** (TXT, MD, CSV, JSON, XML), not just
  some.
- **Editing & save-back (shared editor core)** — a common editing engine used by every
  format: modify content, **undo / redo**, **find & replace**, and **save** the changes back
  to the picked file through its Storage Access Framework URI. Saving offers **"Save"**
  (overwrite the original) and **"Save as a copy"** (write a new file, original untouched).
  Structured formats (JSON, XML) run a **well-formedness check before saving** and block a
  save that would produce a broken file (with an option to save anyway as a copy). Edits are
  written atomically (write to a temp file, then replace) so a failed save never corrupts the
  original. The editor core also provides:
  - **Find & replace (power options).** Replace one or all matches, honoring the shared search
    options (case-sensitive, whole-word, and **regex** — with capture-group references like
    `$1` in the replacement). **Scope control** limits a replace to a chosen range: the whole
    file, the current selection, or a format-specific scope — for example **replace all within
    one column** in CSV, or within a chosen subtree in JSON / XML. A preview of the match count
    is shown before "Replace all".
  - **Unsaved-changes handling.** If the user tries to leave, close the tab, switch away, or
    exit the app with unsaved edits, the app shows a **"You have unsaved changes"** prompt with
    **Save**, **Save as a copy**, and **Discard** options — edits are never lost silently.
  - **Crash / draft recovery.** In-progress edits are periodically written to a private
    **draft/auto-save** store (separate from the real file). If the app is killed mid-edit, on
    the next open of that file it offers to **restore the unsaved draft** or discard it. Drafts
    are keyed to the file's content fingerprint and cleared once a real save succeeds.
  - **Read-only lock toggle.** A per-file **read-only lock** the user can turn on to guard
    against accidental edits when they only want to read. While locked, editing gestures are
    disabled and the editor shows a clear "locked" state; the user unlocks explicitly to edit.
  - **Encoding & line-ending on save (all formats).** Saving preserves the file's detected
    **encoding and line endings** by default, and lets the user **choose** a different encoding
    (UTF-8, UTF-16, ASCII, Windows code pages) or line-ending style (CRLF / LF). This applies
    to **every** format — TXT, MD, CSV, JSON, and XML — so structured formats keep this on top
    of their own save options (indentation for JSON, preserving the XML declaration, etc.).

# App Shell & Navigation
These are **app-wide** features, not tied to one file format. Build them once in the app shell
and reuse them for every format.

- **Home / Recent Files screen** — the first screen the app opens on. It lists recently opened
  files (name, type icon, path, last-opened time) built from the **persistable URIs** the app
  keeps (see [Non-Functional Requirements](#non-functional-requirements)). From here the user
  can re-open a file in one tap, open a new file through the system picker, remove an item from
  the list, or clear the whole list. Stale or no-longer-accessible entries are shown as
  unavailable with an option to remove them.
- **First-run onboarding & empty state** — on first launch, show a short, skippable intro
  (what the app does, how to open a file, the tab and gesture basics). When there are no recent
  files, the Recent Files screen shows a friendly **empty state** with a clear "Open a file"
  button instead of a blank screen.
- **Open files in tabs (multiple documents)** — the app can hold several files open at the
  same time, each in its own **tab**. A tab strip shows the open files; tapping a tab switches
  to it. Each tab keeps its **own state** — view mode, scroll / reading position, search, and
  any unsaved edits — independent of the others.
  - **Tab limit (auto by default, user can override).** There is a **maximum number of tabs
    open at a time**. By default this is set to **Auto**, where the app picks a sensible cap
    based on the **device's memory (RAM)** — a low-memory phone gets a smaller cap, a
    high-memory device a larger one. The user can override Auto in Settings and set a fixed
    number instead. This keeps memory in check, especially with large files (see
    [Risks & Hard Features](#risks--hard-features)).
  - **When the limit is reached.** Opening one more file past the limit either closes the
    **least-recently-used** tab automatically or asks the user which tab to close (this is a
    Settings option). A tab with **unsaved edits** is never closed silently — the app prompts
    to save, save as a copy, or discard first.
  - **Left / right swipe to move between tabs.** A horizontal **swipe gesture** moves to the
    previous / next open tab (swipe right → previous, swipe left → next), wrapping or stopping
    at the ends. The tab strip and swipe stay in sync. On formats that use horizontal scrolling
    themselves (for example a wide CSV grid), the tab-switch gesture is bound so it does not
    fight the content — e.g. an edge swipe or a swipe on the tab strip — so scrolling a wide
    table never accidentally changes tabs.
  - **Close a tab.** Close the current tab (with the unsaved-changes prompt when needed);
    optionally "close others" / "close all".
  - **Restore tabs on relaunch (optional).** Remember which files were open and re-open those
    tabs on the next launch, each back at its saved reading position, subject to the URIs still
    being accessible.
- **In-document bookmarks** — inside a single file the user can mark several positions (a line,
  a scroll point, a table row, or a tree node) and jump back to any of them from a bookmarks
  list. This is separate from **Reading position**, which only remembers the single last-read
  spot. Bookmarks are keyed to the file's content fingerprint, so they survive move / rename /
  re-pick, and a bookmark that no longer maps to the (changed) content is shown as stale.
- **Favorites / pinned files** — the user can mark files as favorites (pin them) so they stay
  at the top of the Recent Files screen and are not pushed out as new files are opened.
- **Receiving files shared into the app** — besides the system picker and **"Open with"**, the
  app also accepts files sent to it from other apps through the Android share sheet
  (`ACTION_SEND` for one file and `ACTION_SEND_MULTIPLE` for several). Shared files open in
  tabs like any other file, honoring the tab limit.
- **Settings screen** — a single place for app preferences, including: default **theme**
  (light / dark / sepia, and "follow system"); default **font size, font family, and line
  spacing**; default **word-wrap** state; default **encoding / line-ending** behavior on save
  (preserve vs a chosen default); **confirm before overwrite** on Save; the **maximum open
  tabs** setting and the over-limit behavior; **restore tabs on relaunch** on/off; and the
  **Malayalam TTS** toggle already described (see [Risks & Hard Features](#risks--hard-features)).
  - **Maximum open tabs.** Controls how many tabs can be open at once. The default is
    **Auto**, which the app computes from the **device's total memory (RAM)** so weaker phones
    get a lower cap and stronger devices a higher one; the shown value makes clear it was
    auto-chosen (e.g. "Auto — 5 tabs"). The user can switch off Auto and pick a fixed number.
    Lowering the limit below the number of currently open tabs closes extra tabs using the
    same over-limit rule (least-recently-used first, with the unsaved-changes prompt when
    needed).

# Features

## TXT
Open txt files. Render the text with word wrap on/off. Scroll, and jump to a line number.
Adjustable font size, font family, and line spacing. Dark / sepia / light reading themes.
Remember last scroll position (reading position). Show line numbers in a gutter. Search —
find and highlight a word/phrase, jump between matches. Select and copy text. Text-to-speech
— read the file aloud (English and Malayalam). Word / character / line count stats. Detect
and make URLs clickable. Detect and switch character encoding (UTF-8, UTF-16, ASCII, and
Windows code pages — note: "ANSI" is not a single encoding but a family of Windows code
pages, e.g. Windows-1252). Handle different line endings (Windows CRLF vs Unix LF). Optional
syntax highlighting if the content looks like code/config. Print the file. Share to other
apps. Export / convert — e.g. TXT → PDF, TXT → Markdown, or TXT → DOCX (Word). Copy the whole content to
clipboard. View metadata — file size, created/modified date, encoding. Split a large file
(by line count or size), or merge several TXT files (simple concatenation in a chosen order).
Compress (zip) for sharing.
- **Editing** — full text editing with undo/redo and find & replace; save back to the file
  or save as a copy. Choose the encoding and line-ending style to write with.

## Markdown (MD)
Rendered view — show formatted output: headings, bold/italic, lists, tables, blockquotes,
code blocks. Raw/source view — show the plain Markdown text as-is. Toggle between the two.
Scroll the rendered document. Table of contents — auto-generated from the headings, tap to
jump. Jump to a heading / anchor (internal #links). Adjustable font size, spacing, and
reading width. Dark / sepia / light themes. Remember last-read position. Syntax-highlighted
code blocks. Clickable links (open in browser or in-app). Images — load local or remote
images. Tables rendered as real tables. Task lists (`- [ ]` / `- [x]`) shown as checkboxes.
**GitHub-Flavored Markdown (GFM) extensions in scope:** tables, task lists, **strikethrough**
(`~~text~~`), and **autolinks** (bare URLs become clickable without `<>` or `[]`). Optional
extensions: footnotes and emoji. Math (LaTeX) is a planned extension — it renders
natively in Flutter with an open-source package (e.g. `flutter_math_fork`), so no WebView or
JavaScript is needed. Mermaid diagrams are out of scope and will not be implemented; a
` ```mermaid ` block simply shows as a plain code block (see
[Risks & Hard Features](#risks--hard-features)). Search — in rendered text or raw source.
Select and copy text (rendered or raw). Text-to-speech on the rendered content. Word /
heading count stats. Export / convert — MD → HTML, MD → PDF, MD → DOCX (Word). Print the
rendered document. Share the file or exported output. Compress (zip) for sharing. Copy as
rendered HTML or plain text. View metadata — file size, modified date. Read front-matter (YAML
block at the top) and show title/author/tags. Split (by top-level heading) / merge
(concatenation in a chosen order) Markdown files.
- **Editing** — edit the raw Markdown source with undo/redo and find & replace, with a
  live/preview toggle to the rendered view; save back to the file or save as a copy. A
  **formatting toolbar** speeds up common Markdown: bold, italic, strikethrough, headings,
  bullet / numbered / task lists, links, inline code and code blocks, blockquotes, and tables —
  each button wraps the selection or inserts the right syntax at the cursor.

## CSV
1. **Two viewing modes** — Table view (parse rows/columns, show a real grid with headers)
   and Raw text view (plain comma-separated text as-is). Toggle between the two.
2. **Table viewing & navigation** — freeze the header row while scrolling; **freeze the first
   column** (the key column) so it stays visible while scrolling wide tables; **hide / show
   columns** (pick which columns are visible without deleting them); horizontal + vertical
   scroll for wide/long files; resize / auto-fit column widths; sort by clicking a column
   header (ascending/descending); filter / search rows by keyword; jump to a specific row
   number; show row and column counts; alternating row colors / grid lines.
3. **Parsing & format handling** — detect the delimiter (comma, semicolon, tab (TSV), or
   pipe); handle quoted fields containing commas or line breaks; detect encoding (UTF-8 and
   Windows code pages — "ANSI" is a family of code pages, not one encoding) and line
   endings; treat the first row as header (toggle on/off); infer column data types (number,
   date, text, and also **boolean** (true/false, yes/no) and **currency** (amounts with a
   currency symbol)) for alignment/sorting.
4. **Light data insights (read-only)** — per-column quick stats (count, min, max, sum,
   average for numeric columns); count of unique / empty values; (advanced) render a simple
   chart from a chosen column.
5. **Output & sharing** — export / convert (CSV → PDF table, CSV → JSON, CSV → HTML table,
   CSV → XLSX (and the older XLS)); **export selected rows only** (export just the rows the user has selected or
   the current filtered set, instead of the whole file); print the table; share the file; copy
   a cell, row, or the whole table.
6. **File-level operations** — view metadata (size, modified date, row/column count,
   delimiter, encoding); split a large CSV (by row count or size; the header row is repeated
   in each part) or merge several (same columns, concatenated in a chosen order); compress
   for sharing.
- **Editing** — edit cells directly in the table grid; add / delete / reorder rows and
  columns; edit the header; edit the raw text in raw mode. **Duplicate-row detection &
  removal** — flag duplicate rows (whole row, or based on a chosen key column) and remove them
  on request. Undo/redo and find & replace. On save, write back using the file's detected
  delimiter, quoting, encoding, and line endings (or a chosen set); save back to the file or
  save as a copy.

## JSON
1. **Viewing modes** — Pretty / formatted (indented, color-coded), Tree view
   (collapsible/expandable nodes), Raw view (original text as-is), Minified view (single
   line). Toggle between them.
2. **Tree navigation** — expand / collapse individual nodes or all at once; show keys with
   value types (string, number, bool, null, object, array); show array indexes and child
   counts (e.g. `[ ] 250 items`); copy a node's path (e.g. `data.users[3].name`); copy a
   subtree or a single value.
3. **Reading & search** — search by key or value, jump between matches; filter the tree to
   matching nodes; JSONPath / query support to pull specific values (advanced); line numbers
   and bracket matching in raw/pretty view.
4. **Validation, formatting & format variants** — validate (check if well-formed, show the
   error line if not); **JSON Schema validation** (optional: check the document against a
   user-supplied schema and list the errors); format / beautify or minify; detect encoding.
   - **JSON Lines / NDJSON** — recognize newline-delimited JSON (one JSON value per line, common
     in logs/exports) and show it as a **list of records**, each viewable as its own tree.
   - **JSONC / JSON5 (comments & trailing commas)** — supported in a **lenient read mode only**:
     the parser can tolerate `//` and `/* */` comments and trailing commas so such files open
     instead of failing. Saving writes **standard, strict JSON** (comments are not preserved),
     and this is made clear to the user.
   - **Large-number / precision handling** — integers or decimals beyond the safe numeric range
     are kept as their **exact original text** (not silently rounded), so big IDs and
     high-precision values survive viewing and saving.
5. **Light insights** — total key count, depth, array sizes; data-type breakdown of values.
6. **Output & sharing** — export / convert (JSON → CSV for flat arrays, JSON → YAML,
   JSON → PDF/HTML); **compare / diff two JSON files** (show added / removed / changed keys and
   values); print the formatted output; share the file; **compress (zip) for sharing**; copy
   full / minified / a subtree.
7. **File-level operations** — view metadata (size, modified date, top-level type
   (object vs array), item count); **split / merge** — split a large top-level **array** into
   parts (by item count) and merge several JSON files whose top level is an array by
   concatenating their items into one array (in a chosen order).
- **Editing** — edit values and keys in the tree view, and edit the raw source in raw mode;
  add / delete nodes; undo/redo and find & replace. A **well-formedness check runs before
  saving** and blocks an invalid save (or lets the user save it anyway as a copy). Save back
  to the file with a chosen indentation (pretty or minified) and chosen encoding / line endings
  (see the shared editor core), or save as a copy.

## XML
1. **Viewing modes** — Pretty / formatted (indented, syntax-highlighted tags/attributes/
   values), Tree view (collapsible element hierarchy), Raw view (original text as-is).
   Toggle between them.
2. **Tree navigation** — expand / collapse elements (one or all); show each element's tag
   name, attributes, and text value; show child counts and repeated elements; copy a node's
   path (e.g. `root/items/item[2]/name`); copy a subtree, an attribute, or a value.
3. **Reading & search** — search by tag name, attribute, or text; jump between matches;
   filter the tree to matching nodes; XPath query to pull specific nodes (advanced); line
   numbers and tag/bracket matching in raw view.
4. **Validation & format handling** — well-formedness check (show the error line if not);
   format / beautify or minify; handle the XML declaration / encoding
   (`<?xml version encoding?>`); show namespaces (`xmlns`) clearly; ignore/collapse comments
   (`<!-- -->`) and CDATA sections; **handle entities** — resolve the built-in entities
   (`&amp;` `&lt;` `&gt;` `&quot;` `&apos;`) and numeric character references (e.g. `&#160;`)
   for display, and re-escape them correctly on save so text is never corrupted; (advanced)
   validate against an XSD schema — via Android's built-in `javax.xml.validation` behind a
   platform channel. DTD validation is **out of scope** (no good open-source path on Android).
5. **Light insights** — element count, tree depth, most-common tags; attribute list per
   element type.
6. **Output & sharing** — export / convert (XML → JSON, XML → CSV (flatten a chosen repeated
   element into rows/columns), XML → PDF/HTML). XSLT transforms are **out of scope** — there is
   no maintained Dart XSLT engine, and native platform-channel code is not worth it for this
   niche feature. Print the formatted output; share the file; **compress (zip) for sharing**;
   copy full / minified / a subtree.
7. **File-level operations** — view metadata (size, modified date, root element name,
   encoding, element count); **split / merge** — split by a chosen repeated child element into
   separate documents, and merge several XML files by placing their contents under a new
   wrapper root (in a chosen order).
- **Editing** — edit element text, attributes, and structure in the tree view, and edit the
  raw source in raw mode; add / delete / move elements and attributes; undo/redo and find &
  replace. A **well-formedness check runs before saving** and blocks an invalid save (or
  lets the user save it anyway as a copy). Preserve the XML declaration and encoding on save
  (or choose a different encoding / line ending — see the shared editor core); save back to
  the file or save as a copy.

# Risks & Hard Features

- **Very large files** (large CSV / JSON / TXT / logs) — a naive "read it all into memory"
  parser will run out of memory and crash. Needs streaming parsing and list virtualization
  (render only visible rows). This affects CSV, JSON, XML, and TXT. **Editing large files**
  is harder still: full in-place editing of a very large file may not fit in memory, so for
  files above the comfortable limit the app offers a degraded, view-only or paged mode and
  tells the user editing is disabled for that file.
- **Many open tabs vs memory** — every open tab holds a document in memory, so several large
  files open at once multiply memory use and can crash the app. This is why the number of open
  tabs is **capped**. By default the cap is **auto-set from the device's total memory (RAM)**
  so low-memory phones get a smaller limit; the user can override this with a fixed number in
  Settings. Opening past the cap closes (or asks to close) another tab, and background tabs can
  release heavy in-memory state and rebuild it from the file when the user returns to them.
- **Malayalam text-to-speech** — depends on the device having a Malayalam TTS voice
  installed. Many Android devices do not ship one, so the feature may be unavailable through
  no fault of the app. The decided behavior:
  - **Settings toggle.** Malayalam TTS is an on/off option in Settings.
  - **Check when enabling.** When the user turns the toggle on, the app checks whether a
    Malayalam voice (`ml-IN`) is available.
  - **Guide the user to install the voice.** If none is found, show a simple message with an
    **Install voice** button: if the engine supports Malayalam but the data is not
    downloaded (`LANG_MISSING_DATA`), open the engine's voice-download screen via the
    `INSTALL_TTS_DATA` intent; if the engine cannot do Malayalam at all
    (`LANG_NOT_SUPPORTED`), open system TTS settings — or the Play Store page for Google TTS
    (`com.google.android.tts`) if it is not installed, since it supports `ml-IN` for free.
    Re-check when the user returns.
  - **Auto-disable with a notification.** If the toggle is on but no Malayalam voice is later
    found, the app turns the toggle off and tells the user why, with the same install help
    path.
  - **Never a silent failure.** Reader screens ask the shared TTS module whether Malayalam
    speech is available and render the ready / needs-install / unavailable state; they never
    show a dead button.
- **Encoding and line endings** — files can arrive in UTF-8, UTF-16, ASCII, or Windows code
  pages, with CRLF or LF endings. The app must detect these on open and preserve (or let the
  user choose) them on save, so editing does not silently change a file's encoding or line
  endings.
- **Markdown Mermaid diagrams and LaTeX math** —
  - **Mermaid — will not be implemented.** There is no native Flutter renderer; the only
    path is `mermaid.js` inside a WebView, and this app has no WebView. A ` ```mermaid `
    block shows as a plain code block, so nothing breaks.
  - **LaTeX math — planned.** Rendered natively with an open-source package (e.g.
    `flutter_math_fork`) — no WebView, no JavaScript. It supports a common subset of LaTeX,
    not full TeX; unsupported math degrades to showing the `$$...$$` source text.
- **XSD schema validation (XML)** — done via Android's built-in `javax.xml.validation`
  behind a platform channel; DTD validation and XSLT are out of scope.

# Non-Functional Requirements

- **Large files** — target: files open smoothly up to about **50 MB** via streaming and
  virtualization. Above the limit, show a clear warning and a degraded mode (e.g. a raw
  paged, view-only mode) instead of crashing.
- **Storage & permissions** — modern Android uses **scoped storage**. Files are opened
  through the **system file picker (Storage Access Framework)** and **"Open with" intents
  only** — no broad storage permission and no in-app file browser. Take persistable URI
  permissions for recent files. Handle denied access or a stale persisted URI. **Editing**
  requires write access to the picked URI; if only read access is available, offer
  "Save as a copy" instead of failing.
- **File identity** — reading positions and app-side state are keyed to a **content
  fingerprint** (file size + hash), with the persisted URI as a fast path, so they survive
  move, rename, and re-pick. A modified file is treated as a new document.
- **Minimum Android version** — **minSdk 26 (Android 8.0)**. Phones and tablets, portrait
  and landscape.
- **Offline** — the app works fully **offline**. The only online parts are optional (loading
  remote images, opening remote links).
- **Error handling** — corrupt, truncated, empty, or wrong-encoding files must show a clear,
  friendly message and **never crash**. Every parser needs a failure path. Saves are atomic
  so a failure never corrupts the original file.
- **Performance & memory** — fast file open, smooth scrolling, bounded memory even on large
  files. Prefer lazy loading over loading everything at once.
- **Privacy & security** — treat opened files as untrusted input. Do not send file contents
  anywhere without the user's explicit action (share/export).
- **Accessibility & localization** — support system font scaling and screen readers where
  practical; the UI itself should be localizable (at least English, given the Malayalam
  content focus).
