# SreerajP Text App

An **Android app built in Flutter** to **open, read, edit, and save** plain-text and
structured-data files: **TXT, Markdown (MD), CSV, JSON, and XML**. It is a real editor,
not just a viewer — it changes file content and writes it back safely.

The app also supports **offline peer-to-peer (P2P) sync over the local network** to move
app data (favorites, bookmarks, recents, and a few non-sensitive settings) between two
devices with **no server and no internet**.

## Highlights

- **Five formats, one editor core** — shared editing engine with undo/redo, find &
  replace (case / whole-word / regex + capture groups), encoding + line-ending detection,
  draft/auto-save crash recovery, unsaved-changes prompts, and a read-only lock.
- **Format views** — TXT viewer with line gutter and jump-to-line; rendered/raw Markdown
  with a formatting toolbar; a real CSV table grid with sort/filter/insights; JSON
  pretty/tree/raw/minified with validation and JSONPath; XML pretty/tree/raw with XPath.
- **Output** — share, zip, print, and export (PDF / HTML / DOCX / XLSX / JSON / CSV / YAML
  as each format supports), plus text-to-speech read-aloud.
- **Offline-first & private** — no broad storage permission; files are opened only through
  the system file picker (Storage Access Framework) and "Open with" / share intents, with
  persistable URI permissions for recents. Atomic saves never corrupt the original.
- **P2P LAN sync** — QR-paired, AES-256-GCM payload crypto, LAN sockets only, never the
  internet.
- **Security** — optional app-lock (PIN + biometric + recovery code) and screenshot
  protection on the pairing screen.

## Tech stack

- **Flutter 3.41.9+ / Dart 3.11.5+**, **Material 3**.
- **minSdk 26 (Android 8.0)**, phones and tablets, portrait and landscape.
- **Open source only** — every library used is open source (Syncfusion and other
  commercial/source-available SDKs are not used).

## Permissions (least-privilege)

| Permission | Why it is needed |
|---|---|
| `INTERNET` | Opens **local TCP sockets only** for LAN sync. There is no HTTP client and no backend. |
| `ACCESS_NETWORK_STATE` | Check LAN/Wi-Fi connectivity for sync. |
| `ACCESS_WIFI_STATE` | Read the device's LAN IP to show the pairing details. |
| `CAMERA` | Scan the pairing **QR code** only. |
| `USE_BIOMETRIC` | Optional biometric unlock for the app-lock. |

No broad storage permission is requested; file access is scoped-storage only.

## Build & run

```bash
flutter pub get
flutter run                 # debug on a connected device
flutter test                # full unit/widget suite
flutter build apk --release # release build (see signing below)
```

### Release signing

The release build reads a **gitignored** `android/key.properties` (never committed). If it
is absent, the build falls back to debug signing so the project still builds — that is fine
for testing but is **not** a distributable release. To produce a real signed release, copy
`android/key.properties.example` to `android/key.properties`, generate a keystore with
`keytool`, and fill in the values. See [docs/release-signing.md](docs/release-signing.md).

## Project docs

- [CLAUDE.md](CLAUDE.md) — project rules.
- [docs/TextData-Idea.md](docs/TextData-Idea.md) — the product idea.
- [docs/architecture.md](docs/architecture.md) — technical design.
- [docs/security-rules.md](docs/security-rules.md) — security rules.
- [docs/implementation-plan.md](docs/implementation-plan.md) /
  [docs/implementation-progress.md](docs/implementation-progress.md) — build order and status.

## License

All libraries used are open source. See the About screen in the app (sourced from
`assets/config/app_config.json`) for version and contact details.
