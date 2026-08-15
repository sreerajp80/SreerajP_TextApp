# Change log — Android backup turned off

**Date:** 2026-08-13
**Plan:** `plans/20260813_201850_disable-android-backup.md`
**Result:** Done. Verified on the real `prodRelease` merged manifest.

Closes the first open risk recorded in `docs/security.md` §12.

---

## 1. What was wrong

The manifest never set `android:allowBackup`, so Android's default of `true` applied. Every
file in the app's private storage was eligible for **Android Auto Backup** (upload to the
user's Google Drive) and for **device-to-device transfer**.

The serious part was **drafts**. They live under `getApplicationSupportDirectory()/drafts/`
and hold a **plain copy of the text of a document the user was editing**, kept until that
document is saved or discarded. So a user who opened a sensitive file and abandoned it had
that content in a cloud backup — user content leaving the device with no user action and no
indication. That contradicts the app's offline-first promise in `CLAUDE.md` §1 and the
objective in `docs/security.md` §2.

The SQLite database and `shared_preferences` were also going. The
`flutter_secure_storage` entries were going too, but they are encrypted under an Android
Keystore key that never leaves the device, so a restored copy is unreadable elsewhere — those
were never the problem.

---

## 2. What changed

### Created

- **`android/app/src/main/res/xml/data_extraction_rules.xml`** (API 31+) — excludes every
  domain from **both** `cloud-backup` and `device-transfer`.
- **`android/app/src/main/res/xml/backup_rules.xml`** (API 30 and below) — the same answer in
  the older `full-backup-content` format.

The `res/xml/` folder did not exist and was created. Both files carry a comment explaining
the reasoning, so the next person does not have to guess.

### Changed

- **`android/app/src/main/AndroidManifest.xml`** — added to `<application>`:
  `android:allowBackup="false"`, `android:fullBackupContent="@xml/backup_rules"`,
  `android:dataExtractionRules="@xml/data_extraction_rules"`, with a comment above the tag.

All three are set rather than relying on how `allowBackup` and `dataExtractionRules` interact
on any particular Android version. `minSdk` is 26 and `targetSdk` is 36, so the app spans the
API 31 change in backup configuration; setting all three gives the same unambiguous answer at
every level.

- **`docs/security.md`** — new **§10.4 "Backup is off"** with the settings table, why it
  matters, and an honest split of what users do and do not lose. The item was removed from
  §12 "Open risks" (the remaining risks renumbered, with a "Closed:" line recording it). The
  OWASP **M8** row moved from *Open* to *OK*. §14 gained a checklist line telling a future
  reviewer to check the **merged** manifest, not just the app's own.
- **`docs/security-rules.md`** — one new day-to-day rule: app data must never be backed up
  off-device, and P2P sync is the migration path.

No Dart code changed. No dependency changed. No behaviour changed inside the running app.

---

## 3. A mistake caught during the work

The first version of the manifest edit put the explanatory comment **inside** the
`<application>` tag's attribute list. That is not valid XML and would have broken the Android
build. It was caught immediately, and the comment was moved above the tag.

Because of that, all three XML files were then checked for well-formedness with a parser
before going any further, and all three passed.

---

## 4. Why turning backup off costs users little here

Recorded in `docs/security.md` §10.4 so the decision is not re-litigated later:

1. **Documents are untouched.** They live in shared storage behind the Storage Access
   Framework, never inside app storage. Only the app's own pointers and settings were being
   backed up.
2. **A restored recents list would have been broken anyway.** Recents and bookmarks store SAF
   **persistable URI permissions**, which are tied to this device and install. Restored onto
   a new device, every entry would fail to open.
3. **The app already ships its own migration path.** LAN peer-to-peer sync exists to move
   favorites, bookmarks, and recents between devices under the user's control.

The real cost: settings (theme, fonts, editor defaults) no longer return automatically after
a reinstall or on a new device. Small and one-time.

---

## 5. Verification

Static analysis and tests do not exercise a manifest change, so the meaningful check was the
Android build and the **merged** manifest.

| Check | Result |
| --- | --- |
| XML well-formedness (manifest + both rule files) | All 3 parse |
| `flutter build apk --flavor dev --debug` | Built — proves the resources resolve and merge |
| `flutter build apk --flavor prod --release` | Built — 86.4 MB |
| **`prodRelease` merged manifest** | Carries all three attributes: `allowBackup="false"`, `dataExtractionRules`, `fullBackupContent` |
| `dart format --output=none --set-exit-if-changed lib test` | Clean |
| `flutter analyze --no-pub` | **No issues found** |
| `flutter test` | **All 836 tests passed** |
| `third_party/` modified | 0 files |

Note on the merged manifest: the other variants under
`build/app/intermediates/merged_manifest/` still show the attributes missing. Those are
**stale artifacts from July builds** — confirmed by their timestamps. Only the two variants
rebuilt here (`devDebug` and `prodRelease`) are current, and both are correct. `prodRelease`
is the one that ships.

The `flutter build apk --flavor dev --debug` run also printed a Kotlin incremental-compilation
cache stack trace. It is unrelated to this change and non-fatal — the build completed and
produced the APK.

---

## 6. Still needs a device (cannot be done here)

- `adb shell bmgr backupnow in.sreerajp.TextAPP` should report the package is not
  backup-enabled. Worth running once before the next release.

---

## 7. Left open

The other two hardening gaps in `docs/security.md` §12 are untouched and still recorded:

1. **R8 / ProGuard is not configured** for release builds. Low impact given AOT compilation.
2. **Drafts have no age-based purge.** Backup no longer carries a draft off the device, so
   this is now a local-only exposure — but it is the underlying cause that made §10.4
   necessary, and a purge would remove it at the source.
