# Security — SreerajP_TextApp

The full security blueprint for this app: what we protect, what we protect it from, how the
crypto and storage work, and what is still open. Read this when you change anything
security-sensitive, or when you need the reasoning behind a rule.

Read first: [../CLAUDE.md](../CLAUDE.md) (or [../AGENTS.md](../AGENTS.md)) for the project
rules, and [security-rules.md](security-rules.md) for the short day-to-day rules list. This
file is the detail behind those rules. The shared template this was filled in from is
`guidelines/security.md`.

Related: [architecture.md](architecture.md) · [dependencies.md](dependencies.md) ·
[security-audit-phase13.md](security-audit-phase13.md)

---

## 1. Security scope

The app is an offline file editor with an optional LAN sync feature. It has **no backend, no
accounts, and no telemetry**. That removes most of the usual mobile attack surface and leaves
three real areas:

1. **Opened files** — arbitrary, untrusted input from the system file picker or a share
   intent.
2. **LAN sync** — a second device on the same network, which may be hostile.
3. **Local device data** — recents, favorites, bookmarks, drafts, settings, and the app-lock
   secrets, on a device that may be shared, lost, or stolen.

Profile: this app is in `Core Baseline` + `Production App Extension` + `Sensitive Data
Extension`, because it stores a PIN hash, recovery codes, and per-device sync keys.

---

## 2. Security objectives

- A malformed or hostile **file** can never crash the app, corrupt the user's original file,
  or cause code execution.
- A hostile **peer** on the LAN cannot read the user's data, inject data, or exhaust device
  memory.
- A person holding the **unlocked device** cannot read the PIN or recovery code out of
  storage.
- The app **never sends user data anywhere** without an explicit user action (share, export,
  print, or a sync the user started).

---

## 3. Threat model

### 3.1 In scope

| Threat | Where it is handled |
| --- | --- |
| Malformed / truncated / wrong-encoding file crashes the app | Every parser has a failure path; §7 |
| A file save is interrupted and destroys the original | Atomic temp-then-replace save; §7 |
| A hostile peer joins the sync session without the pairing code | AES-256-GCM tag failure aborts the handshake; §5 |
| A hostile peer sends a huge or malicious payload | Bounded reads, payload caps, schema checks before ingestion; §5.3 |
| A hostile peer overwrites the receiver's data | Add-only, client-wins merge; §5.4 |
| A network observer reads sync traffic | Every wire message sealed with AES-256-GCM; §5 |
| Someone reads the PIN or recovery code from storage | Only a salted PBKDF2 digest is stored; §4, §6 |
| Someone reads a shoulder-surfed pairing code or PIN | App-lock and screenshot protection on those screens |
| Timing side-channel on PIN check | Constant-time digest compare; §6.2 |

### 3.2 Out of scope

- A **rooted or compromised device**. If the OS is owned, app-level storage protection cannot
  hold.
- **Physical device forensics** against an unlocked, unencrypted device.
- **Denial of service on the LAN** — a peer flooding the network is a network problem, not an
  app problem. The app defends its own memory and sockets (§5.3), not the link.
- **Supply-chain compromise of Flutter or the Android platform itself.**
- Protecting the user's **files at rest on shared storage** — those live outside the app,
  under the Storage Access Framework, and keep whatever protection the OS gives them.

---

## 4. Sensitive data inventory

| Data | Where it lives | Protection |
| --- | --- | --- |
| App-lock PIN | `flutter_secure_storage`, key `app_lock_pin` | Stored only as `base64(salt):base64(PBKDF2 digest)` — never in the clear |
| Recovery code | `flutter_secure_storage`, key `app_lock_recovery` | Same salted-digest form as the PIN |
| Per-device sync key | `flutter_secure_storage`, key `device_key` | Never leaves the device; never synced |
| Pairing code | In memory only, for one session | Never written to disk, never logged, never put on the wire |
| Session AES key | In memory only, for one session | Derived per session; discarded when the session ends |
| Opened file contents | In memory; drafts in app-private storage | Treated as untrusted; never sent without user action |
| Drafts | App-private directory, `<encoded fingerprint>.draft` | Private app storage; removed on save or discard (§9) |
| Recents / favorites / bookmarks | SQLite in app-private storage | Private app storage; no secret material |
| Workspace search index | SQLite in app-private storage (`search_docs` + `search_fts`) | Holds up to 2 MB of each indexed file's text; never logged, never synced; can be turned off and cleared in Settings › Files & Tabs |
| Settings | `shared_preferences` | No secret material; see the sync allow-list in §5.4 |

Nothing sensitive is stored in `shared_preferences` or SQLite. Secrets go only to
`SecureStore` (`lib/core/storage/secure_store.dart`), which is backed by
`flutter_secure_storage` and the Android Keystore.

---

## 5. LAN sync security design

Security lives at the **payload layer**, never the transport. The TCP socket itself is
assumed to be fully readable by an attacker.

### 5.1 Pairing

- A fresh pairing code is generated per session: **64 characters** drawn with
  `Random.secure()` from a **31-symbol** look-alike-free alphabet
  (`ABCDEFGHJKMNPQRSTUVWXYZ23456789` — no `0 O 1 I L`). That is about **317 bits** of
  entropy.
- Sampling is **rejection-sampled** so there is no modulo bias.
- The code moves **out of band only** — shown as a QR code or typed. It is **never put on the
  wire**.
- The random port in the range **45000–45999** is conflict avoidance, **not** a security
  boundary.

### 5.2 Key derivation and sealing

| Parameter | Value |
| --- | --- |
| KDF | PBKDF2-HMAC-SHA256 |
| Iterations | 200,000 |
| Salt | 16 random bytes, fresh per session (may be sent in the clear) |
| Key length | 32 bytes (AES-256) |
| Cipher | AES-256-GCM |
| Nonce | 12 bytes |

Every wire message is sealed. A wrong pairing code produces a wrong key, the GCM tag check
fails, and the handshake aborts — so a wrong code is rejected by the crypto itself, not by a
comparison the app has to remember to make.

### 5.3 Hardening against a hostile peer

| Control | Value |
| --- | --- |
| Handshake line cap | 8 KB |
| Payload line cap | 16 MB |
| Max records per category | 100,000 |
| Max field length | 64k characters |
| Max settings entries | 500 |
| Connect timeout | 10 seconds |
| Socket timeout | 30 seconds |
| Payload wait timeout | 10 minutes |
| Concurrent clients | One at a time |

Caps are enforced **before** ingestion, so an oversized payload is rejected without being
built in memory. The QR parser is strict about its scheme (`textdatasync://pair`) and
protocol version. The host keeps listening after a wrong code rather than dying, and stops
itself when idle.

### 5.4 Merge policy

- Merge is **add-only, client-wins**. The receiver's existing data is never overwritten on a
  conflict.
- Only an explicit **allow-list** of non-sensitive settings may sync
  (`SyncConstants.syncableSettingKeys`).
- Security and identity state is on an explicit **never-sync** list
  (`SyncConstants.neverSyncKeys`) — PINs, app-lock enablement, biometrics, and per-device
  keys never move between devices.

---

## 6. Authentication and access control

### 6.1 App lock

Optional PIN lock, with optional biometric unlock (`local_auth`). The **PIN is always the
fallback** — biometrics never replace it, so a biometric failure cannot lock the user out.
A recovery code (12 characters, about 59 bits) is issued for the case where the PIN is
forgotten.

### 6.2 How the PIN and recovery code are stored

Both are stored only as `base64(salt) : base64(PBKDF2-HMAC-SHA256 digest)` with a fresh
16-byte salt, using the same 200,000-iteration KDF as sync. Verification uses a
**constant-time compare**, so the check does not leak how many bytes matched. A stolen
secure-storage entry therefore does not reveal the secret.

Implementation: `lib/core/security/app_lock_hasher.dart`.

---

## 7. Handling opened files

Every opened file is untrusted input.

- Files are opened **only** through the Storage Access Framework or a share / "Open with"
  intent. There is no broad storage permission and no in-app file browser.
- Every parser (TXT, Markdown, JSON, CSV, XML) has a failure path that produces a friendly
  message instead of a crash. Failure-path tests are required for corrupt, truncated, empty,
  and wrong-encoding input.
- Very large files go through the large-file guard (`lib/core/large_file/`), which sizes its
  limit from the device's reported memory rather than assuming.
- Saves are **atomic**: write a temp file, then replace. A failed save never damages the
  original. The detected encoding and line endings are preserved by default.
- Remote content in a document (an image URL, a link) is never fetched silently — the user is
  warned first (`md_link_warning.dart`, `txt_link_warning_dialog.dart`).

---

## 8. Logging and telemetry policy

The app has **no analytics, no crash reporting, and no telemetry of any kind**. Nothing about
the user or their files leaves the device except through an action the user takes.

### Never log

File contents, sync payloads, secrets, keys, the pairing code, the PIN, or the recovery code
— **not even in debug builds**.

### Allowed

Non-identifying control-flow context: an operation name, an error type, a size or a count.
Error messages shown to the user must be safe — no secret material, no raw paths.

---

## 9. Data retention and purge

| Data | When it goes |
| --- | --- |
| Draft | On a real save, or when the user chooses "discard" |
| Session pairing code and AES key | When the sync session ends (memory only) |
| Recents / favorites / bookmarks | When the user removes the entry |
| Workspace search index entry | When its recent is removed, when recents are cleared (favorites stay), or on "Clear search index" |
| App-lock secrets | When the user turns app lock off |
| Everything | On app uninstall — all of it is app-private storage |

There is **no age-based automatic purge of drafts**. A draft persists until its document is
saved or discarded. That is deliberate — the point of a draft is to survive a crash — but it
means an abandoned document keeps a copy of its content in app-private storage. See §12.

### 9.1 Self-destructing documents (`lib/core/ephemeral/`)

A user who does not want a document to leave anything behind can mark its tab to
self-destruct — on a timer, or after its first successful export, share, or print. The burn
clears every trace listed in the table above **for that one document**: the draft (zero-filled
first), its index row, the recents entry, the favourite, its bookmarks, its per-file
preference keys, and its text in the workspace search index. An ephemeral tab is also kept
out of the saved tab set, out of recents, and out of the search index while it is open, so
those traces are never created in the first place.

Three limits are stated here so nobody later reads more into the feature than it delivers:

1. **The user's own file is never deleted.** The app is scoped-storage only, so a burn clears
   what *the app* stores, not what the user stores.
2. **The `0x00` overwrite is defence in depth, not a guarantee.** It defeats an ordinary
   undelete of the logical file. On flash storage, wear-levelling and the filesystem journal
   may retain the old blocks where no app can reach them. Android's per-app file-based
   encryption remains the real protection for app-private data.
3. **Dart strings cannot be scrubbed.** `String` is immutable and garbage-collected, so
   clearing text means dropping every reference and waiting for the collector. Only
   `Uint8List` buffers are genuinely overwritten in place. `SafService.readBytes` therefore
   documents that the caller owns the buffer it returns.

This narrows §12's "an abandoned draft keeps a copy of its content" risk for documents the
user marks, but it does not remove that risk for ordinary documents.

---

## 10. Platform security controls (Android)

### 10.1 Permissions

Five permissions, each with a written reason in the manifest:

| Permission | Why |
| --- | --- |
| `INTERNET` | Local TCP sockets for LAN sync only. There is no HTTP client and no backend. |
| `ACCESS_NETWORK_STATE` | Check the device is on a network before offering sync |
| `ACCESS_WIFI_STATE` | Show the user which network they are pairing on |
| `CAMERA` | Scan the pairing QR code — nothing else |
| `USE_BIOMETRIC` | Optional biometric unlock for app lock |

No permission may be added without a written reason in the manifest and a line here.

> `INTERNET` looks alarming on an offline-first app. It is required by Android to open **any**
> socket, including a purely local one. The offline-first rule is enforced by the dependency
> block list in [dependencies.md](dependencies.md) §4, not by withholding this permission.

### 10.2 Screenshot protection

`ScreenshotProtector` (in `app.dart`) guards screens that can show secret material — the
pairing code / QR and the lock screen.

### 10.3 Binary protections

- **Dart obfuscation** is applied on release builds via `--obfuscate` with
  `--split-debug-info`, per the documented build commands in `CLAUDE.md` §5. Symbol files
  must be kept per version and never shipped.
- **R8 / ProGuard** is not explicitly configured. Dart code is AOT-compiled to native, so the
  Java/Kotlin surface is only the thin Flutter shim and there is little for R8 to protect.
  See §12.
- **Debuggable** is left to the Flutter toolchain's defaults: release builds are not
  debuggable.

### 10.4 Backup is off

App data must never leave the device without an explicit user action, so **Android backup is
disabled on every supported API level**:

| Setting | Covers | Value |
| --- | --- | --- |
| `android:allowBackup` | All API levels | `false` |
| `android:fullBackupContent` | API 30 and below | `@xml/backup_rules` — everything excluded |
| `android:dataExtractionRules` | API 31 and above | `@xml/data_extraction_rules` — both `cloud-backup` and `device-transfer` fully excluded |

All three are set to the same answer rather than relying on how `allowBackup` and
`dataExtractionRules` interact on a given Android version.

**Why this matters.** With the default (`allowBackup` unset means `true`), the drafts folder
under the app support directory was eligible for upload to the user's Google Drive. A draft
holds a **plain copy of the text of a document the user was editing** and is kept until that
document is saved or discarded (§9). That is user content leaving the device with no user
action and no indication — which contradicts §2.

**What users do not lose.** Their documents are untouched: those live in shared storage
behind the Storage Access Framework, never inside app storage. Recents and bookmarks hold SAF
persistable URI permissions, which are tied to this device and install, so a restored copy of
that table would have produced entries that all fail to open. The app's **LAN peer-to-peer
sync is the supported way to move favorites, bookmarks, and recents between devices**, under
the user's control.

**What users do lose.** Settings (theme, fonts, editor defaults) no longer come back
automatically after a reinstall or on a new device. That is a small one-time
reconfiguration, and the sync allow-list (§5.4) already carries the settings that matter.

---

## 11. OWASP Mobile Top 10

| # | Risk | Status |
| --- | --- | --- |
| M1 | Improper credential use | No accounts, no server credentials. App-lock PIN is salted-hashed. **OK** |
| M2 | Inadequate supply chain | Open-source only, block list enforced, vendored code documented. **OK** |
| M3 | Insecure authentication / authorization | Local-only auth; PIN with constant-time check; biometrics never replace the PIN. **OK** |
| M4 | Insufficient input/output validation | Every parser has a failure path; sync payloads are capped and schema-checked before ingestion. **OK** |
| M5 | Insecure communication | LAN only, AES-256-GCM on every message, code never on the wire. **OK** |
| M6 | Inadequate privacy controls | No telemetry, no analytics, no data leaves the device unbidden. **OK** |
| M7 | Insufficient binary protection | Dart obfuscation on release; R8 not configured. **Partial — see §12** |
| M8 | Security misconfiguration | Backup fully disabled on every API level (§10.4); permissions minimal and each justified. **OK** |
| M9 | Insecure data storage | Secrets only in `flutter_secure_storage`; nothing sensitive in prefs or SQLite. **OK** |
| M10 | Insufficient cryptography | PBKDF2-HMAC-SHA256 at 200k iterations, AES-256-GCM, `Random.secure()` throughout. **OK** |

---

## 12. Open risks

These are known and recorded rather than silently accepted. None is a live vulnerability;
each is a hardening gap.

1. **R8 / ProGuard is not configured** for release builds (§10.3). Low impact given AOT
   compilation, but it is an unmade decision rather than a considered one.
2. **Drafts have no age-based purge** (§9). An abandoned document keeps a plain copy of its
   content in app-private storage until it is saved or discarded. Backup no longer carries
   that copy off the device (§10.4), so this is now a local-only exposure — but it is still
   the reason §10.4 was needed, and a purge would remove the underlying cause.
3. **The workspace search index stores file text in plain form** in the app-private
   database (§13 of `docs/architecture.md`). It is local-only, is never logged or synced,
   and the user can turn it off or clear it — but, like drafts, it is a copy of document
   content that outlives the open document.
4. **No integration test for a real two-device sync.** The loopback tests cover transport,
   crypto, caps, and merge, but a genuine two-device transfer is still a manual pre-release
   check.

Closed: `android:allowBackup` was unset and defaulted to `true`. Fixed — see §10.4.

---

## 13. Security testing

Required coverage, all of which exists today:

- **Sync over loopback**, with no devices: happy path, wrong-code rejection, `send` with no
  client, payload caps, crypto round-trip, and add-only / fill-only merge.
- **Crypto**: `deriveKey` determinism, a wrong key failing the GCM tag, malformed wire input.
- **Parsers**: a failure-path test per format for corrupt, truncated, empty, and
  wrong-encoding input.
- **Saves**: atomicity, and encoding / line-ending preservation.
- **App lock**: hash / verify round-trip, and the constant-time compare.

Manual before each release: a real two-device sync (§12.4).

---

## 14. Security review checklist

Run this before any release, and after any change to sync, crypto, storage, or permissions.

- [ ] No new permission without a written reason in the manifest and in §10.1.
- [ ] Backup is still off: `android:allowBackup="false"`, and both `backup_rules.xml` and
      `data_extraction_rules.xml` still exclude every domain (§10.4). Check the **merged**
      manifest, not just the app's own — plugins contribute manifest entries too.
- [ ] No secret, key, payload, pairing code, or file content reachable by any log call.
- [ ] Secrets still go only to `SecureStore` — never `shared_preferences`, never SQLite.
- [ ] All security randomness still uses `Random.secure()`.
- [ ] Payload caps and timeouts (§5.3) are still enforced before ingestion.
- [ ] The sync allow-list and never-sync list are still correct after any new setting.
- [ ] Merge is still add-only; nothing overwrites receiver data on conflict.
- [ ] Every new or changed parser has a failure-path test.
- [ ] Saves still go through the atomic temp-then-replace path.
- [ ] Release build used `--obfuscate` with a per-version `--split-debug-info` folder, and
      the symbols were archived and not shipped.
- [ ] No new dependency pulls in a network client (see [dependencies.md](dependencies.md) §4.1).
