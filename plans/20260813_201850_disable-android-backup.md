# Turn off Android backup so app data does not leave the device

**Status:** completed

Implemented as planned and verified on the real `prodRelease` merged manifest.
Change log: `change_log/20260813_204706_disable-android-backup.md`.
The `adb shell bmgr` confirmation still needs a device.

Closes open risk 1 in [docs/security.md](../docs/security.md) §12.

---

## 1. What the issue is

The manifest never sets `android:allowBackup`, so Android's default of **`true`** applies.
Every file in the app's private storage is therefore eligible for **Android Auto Backup**,
which uploads it to the user's Google Drive, and for **device-to-device transfer**.

That is the opposite of what this app promises. `CLAUDE.md` §1 states the app is
offline-first with no backend and no telemetry, and `docs/security.md` §2 states that the app
never sends user data anywhere without an explicit user action. A silent cloud upload of app
data contradicts both.

### What is actually being uploaded today

| Data | Real path | Contains |
| --- | --- | --- |
| **Drafts** | `getApplicationSupportDirectory()/drafts/*.draft` | **The real content of documents the user was editing.** This is the serious one. |
| SQLite database | the default `databases/` path | Recents, favorites, bookmarks, drafts index — file names and SAF URIs |
| `shared_preferences` | `shared_prefs/` | All app settings |
| `flutter_secure_storage` | `EncryptedSharedPreferences` | The PIN hash, recovery-code hash, and device sync key |

The secure-storage entries are encrypted under an Android Keystore key that never leaves the
device, so a restored copy on another device is unreadable. Those are **not** the problem.

The problem is the drafts. A draft holds a plain copy of a document's text, and it is kept
until the document is saved or discarded (`docs/security.md` §9). So a user who opens a
sensitive file and abandons it has that content sitting in a Google cloud backup, with no
indication that happened.

---

## 2. Why turning backup off is the right call here, not a loss

Normally disabling backup is a real cost to users. Here it mostly is not:

1. **The user's actual files are not affected at all.** Documents live in shared storage and
   are reached through the Storage Access Framework. They are never inside app storage. Only
   the app's own pointers and settings are.
2. **Restored recents would be broken anyway.** Recents and bookmarks store **SAF persistable
   URI permissions**. Those grants are tied to the device and app install. Restoring them onto
   a new device produces a list of entries that all fail to open. So the backup of the most
   substantial table is of little real value and is arguably worse than nothing.
3. **The app already has its own migration path.** LAN peer-to-peer sync exists precisely to
   move favorites, bookmarks, and recents between two devices, under the user's control, with
   the user's own pairing code. Turning off Google's silent copy does not strand anyone — it
   points them at the feature the app already ships.

The genuine cost: settings (theme, fonts, editor defaults) will not come back automatically
after a reinstall or a new device. That is a small, one-time reconfiguration, and the P2P
sync allow-list already covers the settings that matter.

---

## 3. The plan for the fix

Two mechanisms are involved, because Android changed the API at 31 and this app runs on
26 through 36 (`minSdk = 26`, `targetSdk = flutter.targetSdkVersion`, currently **36**):

- **API 30 and below** — `android:allowBackup` and `android:fullBackupContent`.
- **API 31 and above** — `android:dataExtractionRules`, which splits cloud backup from
  device-to-device transfer into two separate sections.

Rather than reason about exactly how `allowBackup` and `dataExtractionRules` interact on each
version, the change sets **all of them** to the same "nothing leaves the device" answer. That
is unambiguous on every supported API level.

### 3.1 Manifest

Add three attributes to the `<application>` tag in
`android/app/src/main/AndroidManifest.xml`, with a comment saying why:

```xml
<application
    android:label="SreerajP Text App"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:allowBackup="false"
    android:fullBackupContent="@xml/backup_rules"
    android:dataExtractionRules="@xml/data_extraction_rules">
```

### 3.2 New resource files

`android/app/src/main/res/xml/` does not exist yet and will be created.

**`res/xml/data_extraction_rules.xml`** (API 31+) — exclude everything from both channels:

```xml
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <exclude domain="root" />
        <exclude domain="file" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="external" />
    </cloud-backup>
    <device-transfer>
        <exclude domain="root" />
        <exclude domain="file" />
        <exclude domain="database" />
        <exclude domain="sharedpref" />
        <exclude domain="external" />
    </device-transfer>
</data-extraction-rules>
```

**`res/xml/backup_rules.xml`** (API 30 and below) — the same answer in the older format:

```xml
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <exclude domain="root" />
    <exclude domain="file" />
    <exclude domain="database" />
    <exclude domain="sharedpref" />
    <exclude domain="external" />
</full-backup-content>
```

### 3.3 Documentation

- `docs/security.md` — move this out of §12 "Open risks" and into §10 "Platform security
  controls" as a decided control, recording what was turned off and why. Renumber the
  remaining open risks (R8 and draft purge stay open).
- `docs/security.md` §14 — add a checklist line so a future change cannot silently re-enable
  backup.
- `docs/security-rules.md` — add one short rule: app data must never be backed up off-device;
  P2P sync is the migration path.

`CLAUDE.md` and `AGENTS.md` need no change — they already point at `docs/security.md`.

---

## 4. Files to be changed

Create:

- `android/app/src/main/res/xml/data_extraction_rules.xml`
- `android/app/src/main/res/xml/backup_rules.xml`

Change:

- `android/app/src/main/AndroidManifest.xml`
- `docs/security.md`
- `docs/security-rules.md`

No Dart code changes. No dependency changes. No behaviour change inside the running app.

---

## 5. How this gets verified

Static checks (these are the ones I can run here):

- `flutter analyze --no-pub` — 0 issues.
- `flutter test` — all 836 pass.
- `flutter build apk --flavor dev --debug` — proves the manifest and the two new XML
  resources actually compile and merge. **This is the real check for this change**, because a
  malformed backup rules file is a manifest-merge or resource error, not a Dart error.
- Inspect the merged manifest at
  `build/app/intermediates/merged_manifests/…/AndroidManifest.xml` and confirm
  `android:allowBackup="false"` survived the merge. Flutter and its plugins also contribute
  manifest entries, so confirming the merged output is worth doing rather than assuming.

Manual, on a device (cannot be done here — flag for you):

- `adb shell bmgr backupnow in.sreerajp.TextAPP` should report that the package is not
  backup-enabled.

---

## 6. Risk

**Low, and reversible.** It is a manifest attribute plus two static resource files. Nothing
in the app's own code path changes; nothing is read at runtime. If it were ever wrong, the
fix is to delete three lines.

The one thing to get right is that the resource files must be well-formed and in
`res/xml/`, or the Android build fails outright — which the `flutter build apk` step above
catches before anything ships.

---

## 7. What I am not doing

- **Not** selectively excluding only the drafts folder while keeping the rest backed up. It
  is more moving parts, it leaves the broken-SAF-URI restore problem in place, and it means
  every future file added to app storage has to be classified correctly or it leaks by
  default. Excluding everything fails safe.
- **Not** touching the other two open risks (R8 configuration, draft age-based purge). They
  are separate decisions and stay recorded in `docs/security.md`.
