# Change log — `docs/features.md` now lists only implemented features

**Implements:** `plans/20260817_192614_features-doc-implemented-only.md`

## Why

`docs/features.md` calls itself a catalogue of "everything the app can do today", but 19
of its claims described behaviour the code does not have. Each claim was checked against
`lib/` before it was changed.

## Files changed

- `docs/features.md` (documentation only — no code, no tests)

## What changed

### Speech / Text-to-Speech
- **§2.2** — replaced "play, pause, stop, speech rate, pitch" with the real control: a
  single play / stop toggle. Added a plain note that rate and pitch stay with the device's
  own TTS engine, and moved the voice on/off + install helper description to where it
  really lives (Settings › Speech). `TtsService` exposes only `speak` and `stop`.
- **§2.12** — rewrote the Speech Settings bullet: English on/off, Malayalam on/off, a
  Malayalam voice install check, and a shortcut to the system TTS settings. Removed the
  "voice engine selector", rate, and pitch, which do not exist in `TtsSettings`.

### Editor and appearance
- **§2.1** — dropped "customizable tab indentation (2, 4, or 8 spaces)" (no such setting).
  Said the line-numbers gutter is always shown, and that soft wrap is an app-wide switch in
  Settings › Appearance.
- **§2.12** — rewrote the Editor Settings bullet to the real fields: default encoding,
  default line ending, confirm before overwrite, open read-only by default, leave edit mode
  after save, auto-save interval. Removed the line-number toggle, the wrap toggle, and the
  tab width selector.
- **§2.12** — expanded the Appearance Settings bullet to include what was missing: app
  language, line spacing, a separate Malayalam font family, and the word wrap toggle.

### Plain text
- **§2.2** — statistics now read: word count, character count, character count **without
  line breaks**, and line count. Removed paragraph count and average word length, and
  corrected "with and without spaces".
- **§2.2** — split is by line count or maximum part size; removed "custom search
  delimiters". Merge is joined with newlines; removed "customizable line separators".

### Markdown
- **§2.3** — heading split is H1 only, not "H1 or H2". Added the real detail that headings
  inside fenced code blocks are skipped.

### CSV
- **§2.4** — column widths are auto-fit from the header plus a row sample; removed "manual
  column width adjustments".
- **§2.4** — insights now list what is actually computed (type, filled, empty, unique,
  numeric count, and min/max/sum/average for numeric columns). Removed Median.
- **§2.4** — split is by row count or maximum part size, with the header repeated on each
  part. Merge joins parts that already share the same columns, taking the header from the
  first part. Removed "header grouping" and "automatic column header matching".

### XML
- **§2.6** — renamed the heading from "Entity Resolution & Namespace Inspector" to
  "Namespace Inspector", and said plainly that entities are resolved by the parser at read
  time, with no separate entity browser.

### Files and metadata
- **§2.7** — the metadata inspector bullet now lists the fields the info sheets really
  show, and states that the SAF URI and MIME type are not among them.

### P2P LAN sync
- **§1 pillar** and **§2.8** — removed the "6-digit numeric PIN". The pairing code is 64
  characters over a 31-character confusion-free alphabet (about 317 bits); the manual
  fallback is typing or pasting that code.
- **§2.12** — rewrote the Sync Settings bullet to the real contents (default share
  categories, open sync, open AirQR) and explained that the TCP port is chosen by the host
  at run time. Removed device display name, port field, and pairing history management.

### Security and About
- **§2.9** — replaced "configurable auto-lock timeouts" with the truth: `AppLockGate` locks
  as soon as the app goes to the background, with no timeout to set.
- **§2.12** — rewrote the Security Settings bullet to include the screenshot-blocking
  toggle and the self-destructing document defaults, and removed the auto-lock timeout.
- **§2.12** — the About bullet now describes the `app_config.json` details it shows and
  states there is no per-dependency licence list screen.

## Verification

- `flutter analyze` — no issues found.
- `flutter test` — all 1176 tests passed.

Both were run to confirm nothing outside the doc moved; the change is documentation only.

## Known gap, deliberately left open

The doc still has no entry for several **implemented** areas: the encrypted Vault
(`lib/core/vault/`), backup bundles (`lib/core/backup/`), the audit log
(`lib/core/audit/`), PII / Privacy Shield detection and masking (`lib/core/privacy/`),
AirQR optical transfer (`lib/airqr/`), P2P direct file transfer and Live Diff
(`lib/sync/ui/`), and multi-cursor editing. Adding those is a separate job and was left
out on purpose — this change was about removing what is not built, not adding what is
missing.
