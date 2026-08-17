# Project structure — SreerajP_TextApp

The file tree of this project and what each folder is responsible for. Read this when you
need to decide where a new file belongs. The full technical design is in
[architecture.md](architecture.md); the project rules are in [../CLAUDE.md](../CLAUDE.md)
and [../AGENTS.md](../AGENTS.md).

---

## 1. Root layout

```
SreerajP_TextApp/
├── CLAUDE.md                 # project rules for Claude Code (mandatory)
├── AGENTS.md                 # the same rules for other AI agents (mandatory)
├── README.md
├── analysis_options.yaml     # lint rules on top of flutter_lints
├── l10n.yaml                 # gen-l10n config (English + Malayalam)
├── pubspec.yaml / pubspec.lock
├── .github/workflows/        # CI: format, analyze, test
├── android/                  # Android host project, flavors, signing
├── assets/
│   ├── branding/             # app icon master art
│   └── config/               # app_config.json — About screen source of truth
├── fonts/                    # bundled open-source fonts + licences (see the note below)
├── third_party/              # vendored, patched packages (re_editor)
├── docs/                     # design docs (this folder)
│   └── guidelines/           # shared Flutter guidelines (git submodule — read only)
├── plans/                    # one plan per change
├── change_log/               # one log per implemented change
├── lib/                      # app source
└── test/                     # tests, mirroring lib/
```

> **One accepted deviation.** The shared engineering standard §3.3 puts fonts at
> `assets/fonts/`. This project keeps them at the root `fonts/` folder instead. Moving
> them would rewrite every font path in `pubspec.yaml` and the bundled licence files for
> no functional gain, so the deviation is deliberate. Everything else in the root layout
> follows the standard.

---

## 2. `lib/` — feature-first layout

```
lib/
├── main.dart                 # thin: bind, open settings store, runApp
├── app.dart                  # MaterialApp, theme, locale, onboarding, app-lock gate
├── core/                     # shared services used by every feature
├── formats/                  # one folder per supported file type
├── shell/                    # app frame: home, tabs, settings, onboarding
├── sync/                     # offline LAN peer-to-peer sync
├── airqr/                    # optical air-gap transfer (animated QR)
└── l10n/                     # .arb files + generated AppLocalizations
```

Dependency direction is one way:

```
shell / formats (widgets) → Riverpod providers → services & repositories in core/ → storage & models
```

Widgets must not know SQL, `SharedPreferences` keys, SAF URIs, or Android intents.
Services must not know `BuildContext`, routes, or user-facing strings.

---

## 3. `lib/core/` — shared services

| Folder | Responsibility |
| --- | --- |
| `audit/` | Tamper-evident workspace audit log (Feature 8) — SHA-256 chain hasher, SQLite repository, certificate export, status badge, full log screen |
| `config/` | **Fixed path.** `AppConfig` + `ConfigService` for the About screen. Never move or rename. |
| `editor/` | Editor core — atomic saver, draft store, encoding detection, editor settings, SAF save target, selection toolbar |
| `ephemeral/` | Self-destructing documents (Feature 9) — timing policy, the burn sequence, zero-fill wiping, countdown badge, the options sheet |
| `export/` | Export writers — TXT, MD, CSV, HTML, DOCX, XLSX, PDF |
| `fingerprint/` | Content fingerprinting used to detect outside changes |
| `index/` | Workspace-wide FTS5 search index: repository, service, startup backfill |
| `large_file/` | Guards and streaming helpers for very large files |
| `locale/` | Locale controller (English / Malayalam) |
| `logging/` | `AppLogger` — the one logging entry point. Console only, level set by flavor. See [architecture.md](architecture.md) §16. |
| `metadata/` | File metadata reading |
| `output/` | Shared providers for the export / share / print actions |
| `print/` | System print integration |
| `search/` | Shared search options and matching |
| `security/` | App lock, PIN, biometrics, recovery codes, screenshot protection |
| `share/` | Share-sheet integration |
| `sql/` | Read-only SQL over an open CSV / JSON array (Feature 4) — dataset model, statement guard, in-memory engine, query screen |
| `storage/` | SAF access, SQLite database, recents / favorites / bookmarks / drafts index, key-value store, secure store |
| `theme/` | Material 3 themes, theme controller and settings |
| `tts/` | Text-to-speech settings and engine install flow |
| `zip/` | ZIP packaging for multi-file export |

## 4. `lib/formats/` — one folder per file type

`csv/`, `json/`, `markdown/`, `txt/`, `xml/`.

Each folder follows the same shape:

| File pattern | Responsibility |
| --- | --- |
| `<type>_document_session.dart` | Owns parsing, editing state, and saving for the type |
| `<type>_document_view.dart` | The screen that renders the document |
| `<type>_parse.dart` / `<type>_parser.dart` | Parsing, with a failure path for bad input |
| `<type>_toolbar.dart` | The type's action bar |
| `<type>_find_panel.dart` | Find / replace for the type |
| `<type>_info_sheet.dart` | Document statistics sheet |
| `<type>_export_sheet.dart`, `<type>_save_options_sheet.dart` | Export and save dialogs |
| `<type>_split_merge*.dart` | Split and merge tools |
| `<type>_session_manager.dart` | Keeps open sessions per tab |

Type-specific extras live in the same folder — for example `csv_chart*.dart`,
`csv_formula.dart`, `json_path.dart`, `json_schema_validator.dart`, `md_front_matter.dart`,
`xml_tree_view.dart`.

## 5. `lib/shell/` — the app frame

| Folder / file | Responsibility |
| --- | --- |
| `app_shell.dart` | The top-level frame and navigation between home, tabs, settings |
| `home/` | Home and Recent files screen |
| `onboarding/` | First-run onboarding |
| `settings/` | Settings screen; `settings/sections/` holds one file per settings group, including the About section |
| `tabs/` | Multi-document tab workspace and its controller |
| `open_file_action.dart`, `create_document_action.dart` | Entry points for opening and creating documents |
| `shell_providers.dart` | Riverpod providers for the shell |

## 6. `lib/sync/` — LAN peer-to-peer sync

| File | Responsibility |
| --- | --- |
| `sync_transport.dart` | Local TCP socket transport (host and client) |
| `sync_crypto.dart` | AES-256-GCM sealing, PBKDF2 key derivation from the pairing code |
| `payload.dart` | Wire payload shape and size caps |
| `bounded_line_reader.dart` | Reads framed lines with a hard size limit |
| `sync_data_access.dart` | Reads and merges app data (add-only / fill-only) |
| `sync_constants.dart` | Ports, limits, protocol constants |
| `sync_provider.dart` | Riverpod state for a sync session |
| `sync_share_prefs.dart` | What the user chose to share |
| `ui/` | Host and client screens, QR pairing |

## 6A. `lib/airqr/` — optical air-gap transfer

Moves a document or a snippet between devices with only the screen and the camera, for places
where even LAN traffic is prohibited. Adds no dependency — it reuses `qr_flutter`,
`mobile_scanner`, and `SyncCrypto` from LAN sync.

| File | Responsibility |
| --- | --- |
| `airqr_constants.dart` | Frame budget, frames per second, size caps, protocol literals |
| `airqr_payload.dart` | The transfer envelope, hostile-input validation, name sanitising |
| `airqr_codec.dart` | Frame encode / decode, gzip, AES-256-GCM sealing, SHA-256 digest |
| `airqr_sender.dart` | The frame cycle, reshuffled each pass so dropped frames recover |
| `airqr_receiver.dart` | Frame collection, duplicate handling, reassembly, verification |
| `airqr_provider.dart` | Riverpod controllers for a send or receive session |
| `ui/` | Landing, send, and receive screens; the size gate; send / receive actions |

## 7. `lib/l10n/`

`app_en.arb` and `app_ml.arb` are the sources. `app_localizations*.dart` are **generated** by
`flutter gen-l10n` — never edit them by hand. Every user-facing string belongs in the `.arb`
files.

---

## 8. `test/` — mirrors `lib/`

```
test/
├── core/        # config, editor, export, storage, security, theme, tts, zip, …
├── formats/     # csv, json, markdown, txt, xml
├── shell/       # settings, tabs
├── sync/        # loopback transport, crypto, merge
├── airqr/       # frame codec, dropped-frame recovery, payload validation
├── security/    # security-rule regression tests
├── a11y/        # accessibility checks
├── l10n/        # localization coverage
├── support/     # shared test helpers and fakes
└── smoke_test.dart
```

A test file lives at the path that mirrors the file it covers. Add or update a test whenever
you add or change a service, repository, or parser.

---

## 9. Rules for adding a file

- New shared service → `lib/core/<concern>/`. Create a new concern folder only when the
  service does not fit an existing one.
- New behaviour for one file type → that type's folder under `lib/formats/`.
- New screen in the app frame → `lib/shell/`.
- Never add a broad `utils/` folder. Name the concern instead.
- Never create business logic in the Android host project unless a platform limit forces it.
- Around 500 lines: split the file or justify the size in the change log. The files that are
  already over that line, and why, are in §11.

---

## 10. Where constants go

Most technical constants live **next to the code that uses them**, not in one shared file.
Splitting a value from its default and its parsing makes both harder to change safely.

| Kind of constant | Where it lives |
| --- | --- |
| A persisted settings key | A `static const String ...Key` on the class that owns the setting |
| Sync protocol values (caps, timeouts, ports, categories) | `lib/sync/sync_constants.dart` |
| AirQR frame budget, frame rate, and transfer size caps | `lib/airqr/airqr_constants.dart` |
| A size or threshold that belongs to a policy | With that policy, e.g. `LargeFilePolicy.largeThresholdBytes` |
| The registry of settings-key namespaces | `lib/core/constants/app_constants.dart` |

### The settings-key rule

A persisted settings key is written as `<namespace>.<name>` in `lower_snake_case`, and its
Dart constant name ends in `Key`. Before adding one:

1. Use a namespace already registered in `SettingsNamespaces` (`lib/core/constants/app_constants.dart`),
   or add the new namespace there first.
2. Declare the key on the class that owns the setting — **not** in `app_constants.dart`.

`app_constants.dart` holds the namespace registry only. It exists because no single feature
owns the problem it solves: two features could otherwise pick the same key string and
silently overwrite each other. `test/core/constants/app_constants_test.dart` scans `lib/` and
fails the build if a key uses an unregistered namespace, if the same key is declared in two
files, or if a secret key name collides with a settings key.

Secrets themselves never go in settings. They go to `SecureStore`
(`lib/core/storage/secure_store.dart`), backed by the Android Keystore.

---

## 11. Large files and why

The engineering standard asks for a split or a justification at around 500 lines. Fifteen
files are over it. Each is justified below rather than split, because each one does a single
job and most are central enough that restructuring them carries real regression risk.

| File | Lines | Why it is this size |
| --- | --- | --- |
| `lib/formats/csv/csv_document_session.dart` | 1012 | The CSV session, plus sort hierarchy, filtering, calculated-column formulas, and conditional formatting. The clear outlier. |
| `lib/core/editor/column_selection_sheet.dart` | 936 | One sheet holding every column-block operation: prefix/suffix, insert-at-column, numbering, replace, and their preset chips. |
| `lib/formats/json/json_document_session.dart` | 817 | The JSON session, plus tree edits, query state, and schema-validation state |
| `lib/sync/ui/sync_client_screen.dart` | 695 | The receive screen: connect form, QR scan, received-file view, and received-diff view in one flow |
| `lib/formats/markdown/md_document_session.dart` | 684 | The Markdown session, plus split-view state, front matter, and the table of contents |
| `lib/formats/xml/xml_document_session.dart` | 676 | The XML session, plus tree edits, XPath query state, and quick fixes |
| `lib/formats/json/json_parser.dart` | 661 | A hand-written parser that reports precise positions for errors and quick fixes |
| `lib/shell/tabs/tabs_workspace.dart` | 617 | The tab frame: tab bar, format dispatch, lifecycle, and the unsaved-changes gate |
| `lib/formats/csv/csv_toolbar.dart` | 586 | The CSV toolbar and its full overflow menu |
| `lib/formats/txt/txt_document_session.dart` | 578 | The TXT session, plus encoding handling and link extraction |
| `lib/formats/json/json_toolbar.dart` | 567 | The JSON toolbar and its full overflow menu |
| `lib/core/privacy/ui/privacy_shield_sheet.dart` | 566 | The privacy shield sheet: detector results, per-type toggles, and the three transform modes |
| `lib/core/sql/sql_query_screen.dart` | 561 | The SQL screen: editor, schema panel, results grid, and the limit notices |
| `lib/formats/markdown/md_renderer.dart` | 538 | The Markdown render tree, covering every supported block and inline node |
| `lib/sync/sync_provider.dart` | 531 | The sync state machine: pairing, transport wiring, merge, and import summary |

**If one of these grows again, `csv_document_session.dart` is the one to split first.** The
safe order is: add direct unit tests for its sort, filter, formula, and conditional-format
behaviour, then extract those four concerns one at a time — each as its own mixin or
collaborator class — keeping the suite green between each step. Direct session test coverage
is currently thin (most of the suite exercises the sessions indirectly), so the tests come
first, not the refactor.
