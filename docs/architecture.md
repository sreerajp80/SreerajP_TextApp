# Architecture — SreerajP_TextApp

Technical design for the Flutter Android app that opens, reads, edits, and saves **TXT,
Markdown, JSON, CSV, and XML** files, with **offline P2P LAN sync**. This document explains
how the app is structured, which open-source packages to use, and how the hard parts (editor
core, settings, sync, security) fit together.

Read [CLAUDE.md](../CLAUDE.md) first for the project rules. See
[TextData-Idea.md](TextData-Idea.md) for the full product idea.

**Rule reminder:** every library named here is **open source**. No commercial or
source-available SDKs (Syncfusion is banned).

---

## 1. Design goals

- **Modern, adaptive UI** (Material 3) that works on phones and tablets, portrait and
  landscape, in light / dark / sepia.
- **One shared core**, reused across all five file formats — search, TTS, share, export,
  print, metadata, editing/save-back, zip.
- **Bounded memory** even on large files (target: smooth up to ~50 MB) through streaming
  parsing and list virtualization.
- **Offline-first**; only optional online parts (remote images, remote links).
- **Security by default** — untrusted file input, scoped storage, and payload-layer crypto
  for P2P sync.
- **Never crash, never lose edits.**

---

## 2. Layered architecture

```
+------------------------------------------------------------------+
| UI layer (screens + widgets, Material 3)                          |
|   Home/Recent, Tabs, per-format viewers/editors, Settings, Sync   |
+------------------------------------------------------------------+
| State layer (Riverpod providers / notifiers)                      |
|   Holds per-tab state, orchestrates services, exposes view state  |
+------------------------------------------------------------------+
| Core + services (pure Dart, testable)                             |
|   Editor core, search, TTS, export, print, share, zip, config,    |
|   sync transport+crypto, format parsers                           |
+------------------------------------------------------------------+
| Data / platform layer                                             |
|   SAF file access, secure storage, prefs, drafts store, DB        |
+------------------------------------------------------------------+
```

Rule: **lower layers never depend on upper layers.** The core and services are plain Dart so
they can be unit-tested without a device. The transport+crypto sync service is fully
**app-agnostic** — it only moves opaque strings.

---

## 3. Recommended open-source packages

State management uses **Riverpod** as the default recommendation (Provider or Bloc are
acceptable alternatives). All packages below are open source; confirm the license before
adding any new one.

| Concern | Package (open source) |
|---|---|
| State management | `flutter_riverpod` |
| File pick / SAF | `file_picker`, plus a platform channel or `saf_util`-style helper for persistable URIs |
| Secure storage (device keys) | `flutter_secure_storage` |
| Preferences | `shared_preferences` |
| Local DB (recents, bookmarks, favorites, drafts index) | `sqflite` or `drift` |
| Markdown render | `flutter_markdown` (+ `markdown`); `flutter_math_fork` for LaTeX (planned) |
| Code / syntax highlight | `flutter_highlight` / `highlight` |
| CSV parse | `csv` |
| JSON | Dart core `dart:convert`; custom lenient reader for JSONC/JSON5, NDJSON handling |
| XML | `xml` |
| Text editing surface | Flutter's `TextField`/`EditableText` with a custom controller; consider `re_editor`/`code_text_field`-style open-source editors for line numbers + highlighting |
| Text-to-Speech | `flutter_tts` |
| QR render | `qr_flutter` |
| QR scan | `mobile_scanner` |
| Crypto (AES-GCM) | `encrypt` |
| Key derivation (PBKDF2) | `pointycastle` |
| Zip / compress | `archive` |
| Export to PDF | `pdf` + `printing` (printing also covers the Print feature) |
| DOCX / XLSX export | open-source generators only (e.g. build OOXML via `archive`); no Syncfusion |
| Share | `share_plus` |
| App info / version | `package_info_plus` (used with the config file for About) |
| Device memory (tab cap) | `system_info2` / platform channel for total RAM |

---

## 4. Project / module layout

```
lib/
  main.dart
  app.dart                      # MaterialApp, theme, routing

  core/
    config/
      config_service.dart       # loads assets/config/app_config.json (About values)
      app_config.dart           # typed model of the config
    theme/                      # Material 3 themes: light / dark / sepia, dynamic color
    editor/                     # SHARED editor core (see section 6)
      editor_controller.dart
      undo_redo.dart
      find_replace.dart         # regex + scope-aware
      draft_store.dart          # crash/auto-save recovery
      atomic_saver.dart         # temp-write then replace
      encoding.dart             # detect + convert encodings, line endings
    search/                     # shared search (case, whole-word, regex)
    tts/                        # shared TTS module (English + Malayalam)
    export/                     # single conversion service (PDF/HTML/DOCX/…)
    print/                      # shared print service
    share/                      # share sheet wrapper
    zip/                        # compress-for-sharing
    metadata/                   # size, dates, encoding, per-format fields
    storage/
      saf_service.dart          # scoped-storage file access + persistable URIs
      recents_repository.dart
      bookmarks_repository.dart
      favorites_repository.dart
    fingerprint/                # content fingerprint (size + hash) for file identity

  formats/
    txt/                        # viewer + editor + metadata
    markdown/                   # rendered/raw toggle, TOC, toolbar
    csv/                        # table grid, parse, insights, editor
    json/                       # pretty/tree/raw/minified, validate, editor
    xml/                        # pretty/tree/raw, validate, editor

  shell/
    home/                       # Home / Recent Files screen + empty state
    onboarding/                 # first-run intro
    tabs/                       # multi-document tabs, memory-aware cap, swipe
    settings/                   # Settings screen (see section 8)

  sync/                         # P2P LAN sync (see section 9)
    sync_constants.dart
    sync_crypto.dart
    bounded_line_reader.dart
    sync_transport.dart
    sync_provider.dart
    payload.dart                # build + validate + merge

assets/
  config/app_config.json        # About section source of truth

test/
  sync/                         # loopback transport, wrong code, caps, merge
  formats/                      # parser failure-path tests
  core/editor/                  # atomic save, encoding, find & replace
```

---

## 5. Modern UI approach

- **Material 3 (Material You)**: dynamic color from the device wallpaper where available,
  with a safe fallback color scheme. `useMaterial3: true`.
- **Themes**: light / dark / sepia plus "follow system". Adjustable font size, font family,
  and line spacing, applied through a central `ThemeController`.
- **Adaptive layout**: `LayoutBuilder` / `NavigationRail` on wide screens (tablets, landscape),
  bottom navigation / compact layout on phones. Respect system font scaling and screen readers.
- **Tabs**: a tab strip with left/right swipe to move between open documents. On formats that
  scroll horizontally (wide CSV grid), bind the tab-switch gesture to an edge swipe or the tab
  strip so it does not fight content scrolling.
- **Motion and feedback**: subtle transitions, clear "connected / waiting" status chips on the
  sync screen, live match counts in find & replace, and non-blocking snackbars for results.
- **Empty and error states**: friendly empty state on Home ("Open a file"), and clear,
  never-crashing error screens for bad files.

---

## 6. Shared editor core

One editing engine reused by every format. Key parts:

- **Undo / redo** — command stack in `undo_redo.dart`.
- **Find & replace (power options)** — honors shared search options (case-sensitive,
  whole-word, **regex** with `$1` capture-group references in the replacement). **Scope
  control**: whole file, current selection, or a format-specific scope (a CSV column, a
  JSON/XML subtree). Shows a match-count preview before "Replace all". Bad regex → a friendly
  "invalid pattern" hint, never a crash.
- **Unsaved-changes handling** — leaving, closing a tab, switching away, or exiting with
  unsaved edits shows a **Save / Save as a copy / Discard** prompt. Edits are never lost.
- **Crash / draft recovery** — `draft_store.dart` periodically writes in-progress edits to a
  private auto-save store, keyed to the file's **content fingerprint**. On next open it offers
  to restore or discard the draft; the draft is cleared once a real save succeeds.
- **Read-only lock toggle** — a per-file lock that disables editing gestures and shows a clear
  "locked" state until the user explicitly unlocks.
- **Encoding & line endings** — `encoding.dart` detects UTF-8 / UTF-16 / ASCII / Windows code
  pages and CRLF vs LF on open, preserves them by default on save, and lets the user choose a
  different encoding or line-ending style. Applies to **all** formats.
- **Atomic save** — `atomic_saver.dart` writes to a temp file then replaces the target via the
  SAF URI, so a failed save never corrupts the original. Structured formats (JSON, XML) run a
  **well-formedness check before saving** and block a broken save (with "save anyway as a copy").
  Saving offers **Save** (overwrite) and **Save as a copy** (new file, original untouched). If
  only read access is available, only "Save as a copy" is offered.

**Large files:** above the comfortable limit, editing degrades to a paged / view-only mode and
the app tells the user editing is disabled for that file. Streaming parse + list virtualization
keep memory bounded (target ~50 MB).

---

## 7. Per-format modules (architectural view)

Each format module plugs its viewer/editor into the shared core and declares which shared
capabilities (export targets, print output, metadata fields) it supports.

- **TXT** — word-wrap toggle, line-number gutter, jump-to-line, URL detection, optional
  syntax highlight, split/merge, stats (word/char/line). Full text editing via the core.
- **Markdown** — rendered vs raw toggle (`flutter_markdown`), auto TOC from headings,
  GFM (tables, task lists, strikethrough, autolinks), optional footnotes/emoji, LaTeX via
  `flutter_math_fork` (planned; Mermaid out of scope → shown as a plain code block). Editor
  has a **formatting toolbar** and a live preview toggle.
- **CSV** — table view (freeze header + first column, hide/show columns, resize, sort, filter,
  jump-to-row) vs raw view; delimiter/encoding detection; type inference (number, date, text,
  boolean, currency); read-only per-column insights; in-grid editing, add/delete/reorder rows
  and columns, duplicate-row detection/removal; export selected/filtered rows.
- **JSON** — pretty / tree / raw / minified views; tree navigation (paths, child counts, copy
  subtree); search + optional JSONPath; validation + optional JSON Schema; NDJSON as a record
  list; **lenient** JSONC/JSON5 read (saves strict JSON); exact-text handling for
  large/high-precision numbers; split/merge top-level arrays.
- **XML** — pretty / tree / raw views; tree navigation; search + optional XPath; well-formedness
  check; namespaces, comments, CDATA, entity resolve/re-escape; optional XSD validation via
  Android `javax.xml.validation` behind a platform channel (DTD and XSLT out of scope);
  split/merge.

---

## 8. Settings screen

A single Settings screen with preferences **grouped into sections**. Each section is a card /
list group in the Material 3 style. Settings persist via `shared_preferences` (non-sensitive)
and `flutter_secure_storage` (sensitive).

Sections:

1. **Appearance** — theme (light / dark / sepia / follow system), font size, font family,
   line spacing, default word-wrap.
2. **Editor** — default encoding / line-ending behavior on save (preserve vs a chosen
   default), confirm-before-overwrite on Save, auto-save/draft interval, read-only default.
3. **Files & Tabs** — **maximum open tabs** (default **Auto**, computed from device RAM, shown
   as e.g. "Auto — 5 tabs"; can be switched to a fixed number), over-limit behavior
   (close least-recently-used vs ask), restore-tabs-on-relaunch on/off.
4. **Speech (TTS)** — English on/off, **Malayalam TTS** toggle with the guided install /
   auto-disable behavior (checks `ml-IN` voice, guides install via `INSTALL_TTS_DATA` or system
   TTS settings / Play Store, never shows a dead button).
5. **Sync** — P2P defaults (see section 9): which categories are syncable, and any tunables you
   choose to expose. Security/identity state is never listed here.
6. **Security** — optional app-lock, screenshot protection on the pairing-code screen, and other
   protective toggles.
7. **About** — **reads its values from a config file**, not from hardcoded strings.

### 8.1 About section + config file

`assets/config/app_config.json` is the single source of truth for the About screen. A
`ConfigService` loads it at startup (via `rootBundle`) into a typed `AppConfig` model. The
About section shows fields such as app name, description, version/build (cross-checked with
`package_info_plus`), and flexible text entries from `details`. An `Email` detail keeps
special `mailto:` tap behavior. The screen ends with a centered country footer. Example:

```json
{
  "appName": "Text & Data App",
  "description": "Open, read, edit, and save TXT, MD, CSV, JSON, and XML files.",
  "version": "1.0.0",
  "build": "1",
  "details": {
    "Author": "Sreeraj P",
    "Email": "sreerajp@zohomail.in",
    "License": "All libraries used are open source."
  }
}
```

Changing the About content is then a config edit, not a code change.

---

## 9. P2P LAN sync

Offline, peer-to-peer, same-LAN device-to-device sync — **no server, no account, no
internet**. One device **hosts** (sends), the other **joins** (receives). Pairing is
out-of-band (QR or a short typed code). Every wire message is sealed with authenticated
encryption, so the local network is never trusted.

### 9.1 Core security idea

The transport is plaintext TCP; **security lives at the payload layer**:

1. The host generates a **fresh, high-entropy pairing code per session** (~320 bits, from a
   human-transcribable alphabet with no 0/O/1/I/L).
2. The code moves **out-of-band** — shown on the host as a QR and as text, scanned or typed on
   the client. **It never travels over the network.**
3. Both sides derive an AES key from the code with **PBKDF2-HMAC-SHA256** (per-session random
   salt sent in the clear — a salt is not secret).
4. Every message is sealed with **AES-256-GCM**. Authentication is a side effect of
   decryption: a wrong code → wrong key → GCM tag fails → handshake aborts.

The random TCP port is conflict-avoidance and mild defense-in-depth only — **not** a security
boundary. **Never put the pairing code (or anything that reveals it) on the wire.** The salt,
ciphertext, and nonce are fine to send.

### 9.2 Module layout (`lib/sync/`)

- `sync_constants.dart` — every tunable and wire literal (pairing alphabet, code length,
  PBKDF2 iterations, salt/nonce sizes, handshake message strings, caps, timeouts, QR URI
  scheme/host/version, payload validation caps, sync-mode keys). Keeping these central keeps
  host and client in lockstep and makes the caps auditable.
- `sync_crypto.dart` — pairing code generate/normalize/format, `randomBytes` (from
  `Random.secure()`), PBKDF2 key derivation, AES-GCM `encryptWire` / `decryptWire`
  (wire = `base64(nonce(12) || ciphertext+tag)`, one line), and strict QR URI build/parse
  (scheme/host/version/port/code checks; reject foreign QRs).
- `bounded_line_reader.dart` — memory-safe line reader. Buffers bytes, caps line length
  (separate caps for handshake vs payload), and exposes a `closed` future so the host notices
  drops. **Never use an unbounded `readLine`** (guards against slow-loris and giant-line DoS).
- `sync_transport.dart` — `ServerSocket`/`Socket` host + client with the **connect-then-choose**
  flow (below). App-agnostic: moves opaque strings only.
- `sync_provider.dart` — Riverpod state that orchestrates the transport, builds the payload
  from chosen categories, and applies imports.
- `payload.dart` — build, `validateAndParse`, and merge.

### 9.3 Connect-then-choose flow

The client connects and is acknowledged **immediately** (both sides show "connected"), then
the **sender picks what to share** and the payload is pushed on that action. The host **holds
the connection open** after auth. Handshake (each line newline-terminated; everything after
the salt is AES-GCM sealed):

```
Host   -> Client   base64(salt)          (clear; salt is not secret)
Client -> Host     encrypt(HELLO_SYNC)    (proves it has the code)
Host   -> Client   encrypt(ACCEPT_SYNC)   (immediately, on successful auth)
        ...host holds open; sender picks data...
Host   -> Client   encrypt(payloadJson)   (pushed on the sender's action)
```

A wrong code makes the host's decrypt of HELLO throw → host replies `DENIED` and keeps
listening; or the client's decrypt of ACCEPT throws → client reports "incorrect code". The
client's payload read uses a **long `payloadWaitTimeout`** (minutes) distinct from the short
per-line `socketTimeout`.

### 9.4 Payload, validation, and merge

- **Shape**: JSON like the backup/export shape plus a `syncMode` marker (`full` or
  `incremental`), `records`, optional `groups`, and an optional **allow-list** of
  non-sensitive `settings`. Include a category key only if it is part of this sync so the
  receiver can tell "0 sent" from "not included".
- **Validate before ingestion**: treat every payload as hostile — parse, enforce caps (max
  records, per-field length), reject malformed input **before** it touches the DB.
- **Merge = add-only, client-wins**: the receiver keeps its own data.
  - **Full sync** (fresh device): apply everything, including settings.
  - **Incremental sync**: add-only — skip records whose natural key already exists; apply
    settings **fill-only** (only if the receiver has not set that key). Return counts for the
    summary UI.
- **Syncable settings are an explicit allow-list** (theme, timeouts, display prefs). **Never**
  sync app-lock enablement, PINs, biometric/phone-lock unlock, recovery keys, per-device
  tokens, or counters.

### 9.5 Secret lifecycle (sensitive data)

If records hold secrets encrypted with a **device-specific key**:

1. **Host**: decrypt with the device key and re-seal under the **session key** only
   *transiently* in memory while building the payload — never on disk, never logged.
2. **Client**: the import funnel re-encrypts received secrets under the **receiving device's
   own key** before storage.

So a secret is device-key-encrypted at rest on both ends and only session-key-encrypted on the
wire. **Never log** payloads, secrets, keys, or the pairing code.

### 9.6 Sync UI

- **Host — two tabs**: (1) connection details — the QR plus IP/port/code as selectable text
  with a copy button, a live status chip ("Waiting for a device…" → "Device connected ✓"), and
  a Stop button; (2) choose what to share — a **Full Sync** action for a fresh device and a
  **selective** section with per-category checkboxes and the note *"This won't override anything
  already on the other device; on a conflict the other device keeps its data."* Actions are
  disabled until a device is connected.
- **Client**: a scan-QR button (`mobile_scanner`) and a manual IP/port/code form → a waiting
  screen ("Connected — waiting for the sender to choose…") → a summary (added / kept / applied).
- **Suppress idle/background auto-lock while the sync screen is open** (scoped to that screen)
  so a waiting host or an in-flight transfer is not torn down. Consider screenshot protection
  while the code/QR is on screen.

### 9.7 Android permissions for sync

```
INTERNET, ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE   (local TCP sockets only, no HTTP/backend)
CAMERA                                               (QR scan)
```

`INTERNET` here only opens **local** sockets — there is no HTTP client or backend.

---

## 10. Security architecture (modern measures)

- **Untrusted input everywhere** — every opened file and every received payload is validated
  before use; parsers have failure paths; the app never crashes on bad data.
- **Scoped storage / SAF only** — no broad storage permission, no in-app browser; persistable
  URI permissions for recents; handle denied or stale URIs gracefully.
- **Least privilege permissions** — only what each feature needs (camera for QR, local network
  for sync). No location, no contacts, no background storage.
- **P2P transport zero-trust** — AES-256-GCM sealing, PBKDF2 key stretching, out-of-band
  pairing code, `Random.secure()` for all security randomness, bounded reads, timeouts, and
  payload caps (section 9).
- **Secure storage** — device-specific keys and any secrets at rest use
  `flutter_secure_storage` (Android Keystore-backed); non-sensitive prefs use
  `shared_preferences`.
- **Atomic writes** — temp-write-then-replace so a failed or interrupted save never corrupts
  the original.
- **No secret logging** — file contents, payloads, keys, and the pairing code are never logged,
  even in debug builds. Error messages are user-safe.
- **Screen protection** — optional app-lock and screenshot/`FLAG_SECURE` protection on the
  pairing-code/QR screen.
- **Offline by design** — no telemetry, no background sync, no data leaves the device without an
  explicit user action (share/export/sync).

---

## 11. Non-functional requirements

- **Large files** — smooth up to ~50 MB via streaming parse + list virtualization; above the
  limit, a clear warning and a degraded (raw, paged, view-only) mode instead of crashing.
- **File identity** — reading positions, bookmarks, and app-side state are keyed to a
  **content fingerprint** (size + hash), with the persisted URI as a fast path, so they survive
  move / rename / re-pick. A modified file is treated as a new document.
- **Offline** — full offline operation; only remote images/links are optional online parts.
- **Error handling** — corrupt / truncated / empty / wrong-encoding files show friendly
  messages; saves are atomic.
- **Performance & memory** — fast open, smooth scroll, bounded memory; prefer lazy loading.
- **Accessibility & localization** — support system font scaling and screen readers where
  practical; localizable UI (at least English, given the Malayalam content focus).

---

## 12. Testing strategy

- **Sync (loopback, no devices)** — happy path (connect → receive pushed payload), wrong code
  rejected and never connects, `sendToConnectedClient` with no client throws, `validateAndParse`
  rejects oversized/malformed payloads and caps record counts, wire crypto round-trips and a
  wrong key throws, merge is add-only (skips duplicates) and settings apply fill-only. Verify a
  real two-device transfer manually before release.
- **Parsers** — CSV / JSON / XML / TXT failure-path tests (corrupt, truncated, empty, wrong
  encoding).
- **Editor core** — atomic-save behavior, encoding/line-ending preservation, find & replace
  (regex + scope), draft recovery, unsaved-changes flow.
- **Settings / config** — About values load from `app_config.json`; syncable-settings
  allow-list is enforced.
