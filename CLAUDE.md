# CLAUDE.md — SreerajP_TextApp

This file is read by Claude Code at the start of every session in this repository.
Read it before making any change. See the docs table below for the full detail.

---

## 1. Project identity

| Field | Value |
|-------|-------|
| App name | SreerajP Text App (product name: **TextData**) |
| Type | Open, read, edit, and save TXT, Markdown, JSON, CSV, and XML files, with offline LAN peer-to-peer sync |
| Platform(s) | Android only (minSdk 26 / Android 8.0, targetSdk from the Flutter toolchain) |
| Package / org id | `in.sreerajp.TextAPP` (dev flavor adds `.debug`) |
| Flutter SDK | 3.44.8 or higher |
| Dart SDK | 3.12.2 or higher |
| State management | Riverpod (`flutter_riverpod`), single `ProviderScope` at the root |
| Navigation | Imperative `Navigator` + `MaterialPageRoute`. No router package. |
| Database | `sqflite` (recents, favorites, bookmarks, drafts index) + `shared_preferences` (settings) + `flutter_secure_storage` (secrets) |
| Orientation | Portrait and landscape; phones and tablets |
| Connectivity | Offline-first. `INTERNET` is held **only** for local TCP sockets used by LAN sync — there is no HTTP client and no backend. |
| UI | Material 3 |
| Localization | English + Malayalam, via Flutter `gen-l10n` (`lib/l10n`) |

---

## 2. Read these docs before working

| Document | Read when |
|----------|-----------|
| [docs/architecture.md](docs/architecture.md) | Changing structure, screens, state, services, models, repositories |
| [docs/security-rules.md](docs/security-rules.md) | Touching permissions, logging, storage, crypto, manifest, or opened-file input |
| [docs/security.md](docs/security.md) | The full security blueprint — threat model, crypto design, OWASP checklist, open risks |
| [docs/project_structure.md](docs/project_structure.md) | Finding where a file belongs |
| [docs/dependencies.md](docs/dependencies.md) | Adding, removing, or upgrading any package |
| [docs/release-signing.md](docs/release-signing.md) | Building a release, versioning, signing |
| [docs/workflow-rules.md](docs/workflow-rules.md) | Starting or finishing any change |
| [docs/textdata_idea.md](docs/textdata_idea.md) | Understanding the product idea and scope |
| [docs/GUIDELINES_MANIFEST.md](docs/GUIDELINES_MANIFEST.md) | The shared Flutter guidelines index (`docs/guidelines/` submodule) |

If a doc is copied into this project's own `docs/`, the local copy wins over the shared
master in `docs/guidelines/`.

---

## 3. Hard rules (must follow — these override convenience)

1. **Open source only.** Every library must be **open source**. Commercial or
   source-available SDKs are **not allowed**, even with a free community licence (for
   example, **Syncfusion is banned**). Check a package's licence before adding it.
2. **Offline-first.** The app must work fully offline. The only online parts are optional
   (loading remote images, opening remote links). P2P sync is **LAN-only**, never internet.
3. **Scoped storage only.** Open files through the **system file picker (Storage Access
   Framework)** and **"Open with" / share intents** only. **No** broad storage permission
   and **no** in-app file browser. Take persistable URI permissions for recent files.
4. **Never crash on bad input.** Corrupt, truncated, empty, or wrong-encoding files must
   show a clear, friendly message. Every parser needs a failure path.
5. **Atomic saves.** Always write to a temp file, then replace, so a failed save never
   corrupts the original file. Preserve the file's detected encoding and line endings by
   default; let the user choose otherwise.
6. **Never lose edits silently.** Unsaved-changes prompts, draft/auto-save recovery, and a
   read-only lock are part of the editor core — do not bypass them.

---

## 4. Architecture rules

- Layout: **feature-first** under `lib/` — `core/` (shared services), `formats/` (one folder
  per file type), `shell/` (app frame, home, tabs, settings), `sync/` (LAN P2P),
  `airqr/` (optical air-gap QR transfer), `l10n/`.
  Do not restructure without instruction.
- `lib/core/config/` is a **fixed path**: it holds `AppConfig` + `ConfigService` for the
  About screen. Never move or rename it.
- Dependency direction: `shell`/`formats` widgets → Riverpod providers → services and
  repositories in `core/` → storage/models. Never the other way.
- Layer boundaries: widgets must not know SQL, `SharedPreferences` keys, SAF URIs, or
  Android intents. Services must not know `BuildContext`, routes, or user-facing strings.
- `main.dart` stays thin: bind, open the settings store, `runApp`. Heavy setup goes in a
  service.
- One document type = one `*_document_session.dart` in its `formats/<type>/` folder. That
  session owns parsing, editing state, and saving for the type.
- Models are immutable (`const` + `copyWith`). Never mutate in place.

---

## 5. Build & run commands

```bash
flutter pub get                        # install dependencies
flutter run --flavor dev               # daily development
flutter run --flavor prod              # production build with debug tooling
flutter analyze                        # static analysis (must be clean — zero issues)
flutter test                           # run all tests
dart format lib test                   # format before committing (not third_party/)

# Production release APK (split per ABI)
flutter build apk --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod-1.9.0/ --split-per-abi

# Production Play Store bundle
flutter build appbundle --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod-1.9.0/
```

This app defines flavors, so a bare `flutter run` fails — always pass `--flavor`.
Update the `--split-debug-info` version folder to match `pubspec.yaml` on each release.

---

## 6. Build flavors

| Flavor | App ID | Version name | Signing |
|--------|--------|--------------|---------|
| `dev` | `in.sreerajp.TextAPP.debug` | `<version>-debug` | Debug keystore (automatic) |
| `prod` | `in.sreerajp.TextAPP` | `<version>` | Release keystore via `android/key.properties` |

Flutter sets `FLUTTER_APP_FLAVOR` for you; read it with
`String.fromEnvironment('FLUTTER_APP_FLAVOR')`. Do not pass it explicitly.

---

## 7. Signing / keystore

- Keystore file: `android/textapp-keystore.jks`. Keep at least one offline backup — losing
  it means you can no longer publish updates under the same signature.
- Signing values live in `android/key.properties` (git-ignored — never commit).
  `android/key.properties.example` shows the shape.
- When `key.properties` is absent the release build falls back to debug signing so the
  project still builds without the secret.
- `.gitignore` must keep covering: `**/key.properties`, `*.jks`, `*.keystore`.
- Full steps: [docs/release-signing.md](docs/release-signing.md).

---

## 8. Security rules

Security is not optional. The full rules live in
[docs/security-rules.md](docs/security-rules.md). **Read that file before changing any
security-sensitive code** — P2P sync, crypto, storage, logging, secrets, or anything that
handles opened-file input.

The short version:

- Never log secrets, keys, PINs, pairing codes, recovery codes, or decrypted data — not
  even in debug builds.
- Secrets go in `flutter_secure_storage`, never in `shared_preferences` or SQLite.
- Request only the permissions the app needs. Do not add a permission without a written
  reason in the manifest.
- LAN sync is sealed with AES-256-GCM and a PBKDF2-derived key. Never weaken or bypass it.
- Treat every opened file as untrusted input.
- Use `AppLogger` (`lib/core/logging/`) for every diagnostic line. Never `print` or
  `debugPrint` in committed code. See [docs/architecture.md](docs/architecture.md) §16
  for the full list of what must never be logged.

---

## 9. Code style / naming

- Files `snake_case.dart`; classes `PascalCase`; variables and methods `camelCase`;
  Riverpod providers `camelCase` + `Provider` suffix.
- Use `package:sreerajp_textapp/...` imports, **not** relative imports.
- Prefer `const` constructors, `final` locals, and single quotes.
- Comments explain **why**, not what. TODOs need an owner or clear follow-up.
- Do not swallow exceptions. Show a user-safe message and keep the diagnostic context.
- Around 500 lines in a file: split it or justify the size in the change log.
- Run `dart format lib test` and keep `flutter analyze` at **zero** issues before every commit.
- All user-facing strings go through `AppLocalizations` (`lib/l10n/app_en.arb` and
  `app_ml.arb`). Do not hard-code UI text.

---

## 10. Testing rules

- `test/` mirrors `lib/` (e.g. `test/core/storage/`, `test/formats/csv/`).
- **P2P sync** transport + crypto is testable over **loopback** with no devices: cover the
  happy path, wrong-code rejection, `send` with no client, payload caps, crypto round-trip,
  and add-only / fill-only merge. Verify a real two-device transfer manually before release.
- **Parsers** (CSV/JSON/XML/TXT/MD) each need failure-path tests (corrupt, truncated, empty,
  wrong encoding).
- **Saves** must be tested for atomicity and encoding/line-ending preservation.
- Add or update a test whenever you add or change a service, repository, or parser.

---

## 11. Dependency constraints

- **Blocked** (never add, never accept as a transitive dep): HTTP clients, cloud/BaaS SDKs,
  analytics, crash reporting, ads, and any commercial or source-available SDK (Syncfusion
  and similar).
- Before adding any package: check its licence, check its `pubspec.yaml` for networking
  dependencies, and state why it is needed.
- `re_editor` is vendored under `third_party/` with a one-line patch — see
  `third_party/re_editor/PATCH_NOTES.md`. Do not drop the `dependency_overrides` entry.
- Full list and reasoning: [docs/dependencies.md](docs/dependencies.md).

---

## 12. Where things live

```
CLAUDE.md            # this file — project rules for Claude Code
AGENTS.md            # the same rules for other AI agents / LLMs
docs/                # design docs (see the table in §2)
docs/guidelines/     # shared Flutter guidelines (git submodule — never edit from here)
plans/               # one plan per change (see workflow rules)
change_log/          # one log per implemented change
lib/                 # app source (see docs/project_structure.md)
assets/config/       # app_config.json — source of the About screen values
third_party/         # vendored, patched packages
test/                # tests, mirroring lib/
```

---

## 13. Workflow rules (mandatory — from global rules)

Every change follows plan-before-changing and log-after-changing:

1. **Plan before changing.** Write a full plan to `plans/` named
   `yyyymmdd_hhMMss_<short-slug>.md` with a `**Status:**` line, the files to change, the
   issue, and the fix. Then **STOP and get explicit approval** before editing, creating, or
   deleting any project file (other than the plan). A question or an ambiguous reply is not
   approval.
2. **Log after changing.** After implementing, write a change log to `change_log/` named
   `yyyymmdd_hhMMss_<short-slug>.md` describing what changed and referencing its plan.
3. **Relative paths & privacy only.** All `plans/` and `change_log/` files MUST use relative
   repository paths only (never absolute system paths like `C:\...`, `l:\...`, or
   `file:///...`). They MUST NOT contain any sensitive or private information that cannot be
   shared publicly on the internet (secrets, API keys, tokens, passwords, keystore
   passphrases, local absolute paths, internal IPs, credentials, or PII).

Full detail: [docs/workflow-rules.md](docs/workflow-rules.md).
Also follow the shared guidelines listed in
[docs/GUIDELINES_MANIFEST.md](docs/GUIDELINES_MANIFEST.md).

---

## 14. Communication rules

- **Always use simple English.** Write all responses, plans, change logs, and explanations
  in plain, simple English. Prefer short sentences and common words. Avoid jargon unless it
  is necessary, and explain it when used.

---

## 15. What Claude must always / never do

**Always:** read this file first; name the target layer before adding a class; keep
`main.dart` thin; put user-facing text in the `.arb` files; give every parser a failure
path; run `dart format lib test`, `flutter analyze`, and `flutter test` after a change; keep
`AGENTS.md` in step with this file.

**Never:** put business logic in a widget; touch SQLite or `SharedPreferences` from a
widget; edit generated files (`lib/l10n/app_localizations*.dart`); edit anything inside
`docs/guidelines/` (it is a submodule); add a blocked dependency; log secrets; commit
`key.properties` or a keystore; write to a file without the atomic temp-then-replace path.
