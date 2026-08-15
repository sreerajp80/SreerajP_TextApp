# Dependencies — SreerajP_TextApp

The packages this app is allowed to use, why each one is here, and the packages that must
never be added. Read this before adding, removing, or upgrading any package.

Read first: [../CLAUDE.md](../CLAUDE.md) §11 (dependency constraints) and
[security-rules.md](security-rules.md).

`pubspec.yaml` is the source of truth for version ranges, and `pubspec.lock` for the exact
resolved versions. This document explains the **why** and the **licence**, not the numbers.

---

## 1. The two hard rules

1. **Open source only.** Every package must be open source. Commercial or
   source-available SDKs are not allowed, even with a free community licence.
   **Syncfusion is banned.** Check the licence before adding anything.
2. **Offline-first.** The app must work fully offline. No package may be added for the
   purpose of talking to a network service.

---

## 2. Approved runtime packages

### 2.1 App framework and state

| Package | Licence | Why it is here |
| --- | --- | --- |
| `flutter`, `flutter_localizations` | BSD-3 | The SDK itself |
| `flutter_riverpod` | MIT | The one state-management approach for this app |
| `intl` | BSD-3 | Locale-aware formatting; version pinned by `flutter_localizations` |
| `cupertino_icons` | MIT | Icon set |

### 2.2 Storage and settings

| Package | Licence | Why it is here |
| --- | --- | --- |
| `sqflite` | BSD-2 | Recents, favorites, bookmarks, drafts index, and the in-memory SQL query engine (Feature 4) |
| `shared_preferences` | BSD-3 | App settings and small key-value state |
| `flutter_secure_storage` | BSD-3 | **Secrets only** — PIN hash, recovery codes, sync keys |
| `path_provider` | BSD-3 | App-private directories for temp and draft files |

### 2.3 Editor and text handling

| Package | Licence | Why it is here |
| --- | --- | --- |
| `re_editor` | MIT | The code/text editor surface. **Vendored** — see §5 |
| `markdown` | BSD-3 | Markdown parsing and rendering |
| `flutter_math_fork` | Apache-2.0 | Maths in Markdown |
| `csv` | MIT | CSV parsing and writing |
| `xml` | MIT | XML parsing and writing |
| `two_dimensional_scrollables` | BSD-3 | The CSV grid |
| `fl_chart` | MIT | CSV charts (the open-source replacement for banned commercial chart SDKs) |

### 2.4 Export, share, print

| Package | Licence | Why it is here |
| --- | --- | --- |
| `pdf` | Apache-2.0 | PDF export |
| `printing` | Apache-2.0 | System print |
| `archive` | MIT | ZIP packaging for multi-file export; DOCX and XLSX containers |
| `share_plus` | BSD-3 | System share sheet |
| `url_launcher` | BSD-3 | Opening links and `mailto:` from the About screen |

### 2.5 Security and sync

| Package | Licence | Why it is here |
| --- | --- | --- |
| `crypto` | BSD-3 | Hashing (file fingerprints, PIN hashing) |
| `encrypt` | BSD-3 | AES-256-GCM sealing of the LAN sync wire |
| `pointycastle` | Bouncy Castle (MIT-style) | PBKDF2-HMAC-SHA256 key derivation, aligned with `encrypt` |
| `local_auth` | BSD-3 | Optional biometric unlock; the PIN stays the fallback |
| `qr_flutter` | BSD-3 | Renders the pairing QR on the host |
| `mobile_scanner` | BSD-3 | Scans the pairing QR on the client |

### 2.6 Device and platform info

| Package | Licence | Why it is here |
| --- | --- | --- |
| `package_info_plus` | BSD-3 | Version/build check in `ConfigService.loadAndVerify()` |
| `system_info2` | BSD-3 | Device memory, used to size the large-file guard |
| `flutter_tts` | MIT | Text-to-speech reader |

---

## 3. Dev dependencies

| Package | Licence | Why it is here |
| --- | --- | --- |
| `flutter_test` | BSD-3 | Test framework |
| `flutter_lints` | BSD-3 | Lint baseline. **Pin the major version** so the lint set cannot shift under CI |
| `sqflite_common_ffi` | BSD-2 | Runs SQLite in plain unit tests, with no device. **Test only** — the SQL query engine uses plain `sqflite` on the device, so Feature 4 added no package. |

---

## 4. Blocked — never add, never accept

- **HTTP clients and networking helpers** as a *direct* dependency (`http`, `dio`,
  `connectivity_plus`, and similar). LAN sync uses raw `dart:io` TCP sockets only.
- **Cloud / BaaS SDKs** — Firebase, Supabase, AWS Amplify, and similar.
- **Analytics and crash reporting** — Sentry, Crashlytics, Mixpanel, and similar.
- **Ads** of any kind.
- **Commercial or source-available SDKs** — Syncfusion and similar, even with a free
  community licence.
- **Broad storage / file-browser packages** — the app uses the Storage Access Framework
  only, with no broad storage permission and no in-app file browser.

### 4.1 Known transitive `http`

`http` **is** in the dependency tree today. It arrives through `package_info_plus`,
`printing`, and `flutter_svg`/`vector_graphics` (pulled in by `printing`). These packages use
it on web and desktop code paths that this Android app does not run.

This is accepted, with two standing conditions:

- The app itself must never import or call `http`. Only `dart:io` sockets, and only on the
  LAN.
- On any dependency upgrade, re-check that no **new** direct or transitive network client
  appears, and that these four packages are still the only source of `http`.

---

## 5. Vendored package: `re_editor`

`re_editor` is vendored at `third_party/re_editor/` with a one-line patch that sets
`enableSuggestions: false`. Without it, the Android keyboard duplicates a line on the first
Enter after a document is opened (flutter/flutter#31512).

- The patch is documented in `third_party/re_editor/PATCH_NOTES.md`.
- The `dependency_overrides` entry in `pubspec.yaml` must stay.
- `third_party/**` is excluded from analysis in `analysis_options.yaml` — it is not our code.
- When upgrading `re_editor`, re-apply the patch and update the notes.

---

## 6. Fonts

Bundled fonts are in `fonts/`, with licences and sources recorded in `fonts/README.md` and
`fonts/licenses/`. All are OFL or OFL+GPL.

- English: Inter, Lora, JetBrains Mono
- Malayalam: Manjari, Rachana, Noto Sans Malayalam

---

## 7. Before adding any package — checklist

- [ ] Licence checked and it is genuinely open source (not source-available).
- [ ] Its own `pubspec.yaml` checked for network, cloud, analytics, or ad dependencies.
- [ ] It removes real complexity; the same thing cannot be done with the SDK alone.
- [ ] It is maintained, has clear ownership, and supports null safety.
- [ ] If it touches storage, files, camera, or crypto, its transitive tree was reviewed.
- [ ] If it uses build hooks (`hook/build.dart`, `hook/link.dart`), the native code was
      reviewed — that is the same supply-chain risk as a native plugin.
- [ ] `dart pub deps --style=compact` re-checked for a new network client (see §4.1).
- [ ] The reason for adding it is written in the plan and the change log.

---

## 8. Audit cadence

- `flutter pub outdated` — monthly and before each release. Review major upgrades one by one.
- `dart pub deps --style=tree` — at least quarterly, to spot unexpected additions.
- `flutter pub licenses` — before any release that adds a dependency; confirm every
  transitive licence is compatible.
- Keep the security-critical packages (`encrypt`, `pointycastle`, `crypto`,
  `flutter_secure_storage`) on deliberate, reviewed upgrades only.
