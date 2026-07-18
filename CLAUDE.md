# CLAUDE.md — SreerajP_TextApp

This file gives rules for anyone (including the AI assistant) working on this project.
Read it before making any change. See [architecture.md](docs/architecture.md) for the full
technical design.

---

## 1. What this app is

An **Android app built in Flutter** to **open, read, edit, and update** plain-text and
structured-data files: **TXT, Markdown (MD), JSON, CSV, and XML**. It is a real editor, not
just a viewer — it changes file content and saves it back. See
[docs/TextData-Idea.md](docs/TextData-Idea.md) for the full product idea.

The app also supports **offline peer-to-peer (P2P) sync over the local network** to move
app data between two devices with no server and no internet.

---

## 2. Tech stack (fixed)

- **Flutter 3.41.9 or higher**
- **Dart 3.11.5 or higher**
- **minSdk 26 (Android 8.0)**; phones and tablets, portrait and landscape.
- **Material 3** modern UI (see [architecture.md](docs/architecture.md) for UI approach).

---

## 3. Hard rules for this project

These are **must-follow** rules. They override convenience.

1. **Open source only.** Every library used must be **open source**. Commercial or
   source-available SDKs are **not allowed**, even with a free community license (for
   example, **Syncfusion is banned**). Check a package's license before adding it.
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

## 4. Security rules

Security is not optional. The full security rules live in
[docs/security-rules.md](docs/security-rules.md).

**Read [docs/security-rules.md](docs/security-rules.md) before changing any
security-sensitive code** — P2P sync, crypto, storage, logging, secrets, or anything
that handles opened-file input.

---

## 5. Where things live

```
CLAUDE.md            # this file — project rules
docs/                # product idea and design notes
docs/architecture.md    # full technical design
docs/security-rules.md  # full security rules (read when touching security code)
docs/workflow-rules.md  # full plan/approval/change-log workflow rules
plans/               # one plan per change (see workflow rules below)
change_log/          # one log per implemented change
lib/                 # app source (see docs/architecture.md for the module map)
assets/config/       # app_config.json — source of the About screen values
test/                # unit tests (sync loopback, parsers, atomic save, merge)
```

---

## 6. Testing expectations

- **P2P sync** transport + crypto is testable over **loopback** with no devices: cover the
  happy path, wrong-code rejection, `send` with no client, payload caps, crypto round-trip,
  and add-only / fill-only merge. Verify a real two-device transfer manually before release.
- **Parsers** (CSV/JSON/XML/TXT) each need failure-path tests (corrupt, truncated, empty,
  wrong encoding).
- **Saves** must be tested for atomicity and encoding/line-ending preservation.

---

## 7. Workflow rules (mandatory — from global rules)

Every change must follow the plan-before-changing and log-after-changing process. The
full workflow rules live in [docs/workflow-rules.md](docs/workflow-rules.md).

**Read [docs/workflow-rules.md](docs/workflow-rules.md) before starting or finishing
any change to the project.** In short: write a plan to `plans/` and get explicit
approval before editing, then write a change log to `change_log/` after.

Follow the guidelines listed in [docs/GUIDELINES_MANIFEST.md](docs/GUIDELINES_MANIFEST.md).

---

## 8. Communication rules

- **Always use simple English.** Write all responses, plans, change logs, and explanations
  in plain, simple English. Prefer short sentences and common words. Avoid jargon unless it
  is necessary, and explain it when used.
