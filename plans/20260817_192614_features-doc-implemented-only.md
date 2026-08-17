# Make `docs/features.md` list only implemented features

**Status:** completed

## Files to change

- `docs/features.md` (the only file)

## The issue

`docs/features.md` says it is "a reader-facing catalogue of everything the app can do
today". I checked every claim in it against the code in `lib/`. Most claims are correct,
but **18 claims describe things the app does not do**. A reader (or a future agent) would
trust them and be wrong.

Below is each wrong claim, with the code that proves it.

### A. Speech / Text-to-Speech

1. **§2.2** — "Controls for play, **pause**, stop, **speech rate**, **pitch**, and voice
   language selection."
   `lib/core/tts/tts_service.dart` only exposes `speak` and `stop`. There is no pause, no
   rate, and no pitch anywhere. (§2.1 already says the honest version: "play/stop control".)
2. **§2.12** — "Speech Settings: **TTS voice engine selector**, voice language, **speech
   rate**, **pitch**, system TTS installer prompt."
   `lib/core/tts/tts_settings.dart` holds exactly two fields: `englishEnabled` and
   `malayalamEnabled`. `lib/shell/settings/sections/speech_section.dart` shows those two
   switches, a Malayalam voice check, an install button, and a link to the system TTS
   settings. No engine picker, no rate, no pitch.

### B. Editor and appearance settings

3. **§2.1** — "customizable tab indentation (2, 4, or 8 spaces)".
   No tab-width setting exists. `lib/core/editor/editor_settings.dart` has no such field.
4. **§2.12** — "Editor Settings: **line numbers gutter toggle**, **soft line wrapping**,
   **tab width selector**, auto-save interval".
   `editor_settings.dart` really holds: default line ending, default encoding, confirm
   overwrite, auto-save seconds, open read-only by default, exit edit mode after save.
   Line numbers are always drawn (no toggle). Word wrap is an *Appearance* setting, not an
   Editor one.
5. **§2.12** — "Appearance Settings: theme mode, typography family picker, text scale slider".
   Incomplete. `lib/core/theme/theme_settings.dart` also has line spacing, a separate
   Malayalam font family, and the word-wrap toggle, and the section also holds the language
   picker.

### C. Plain text (TXT)

6. **§2.2** — "Text Statistics: ... **paragraph count**, and **average word length**."
   `lib/formats/txt/txt_stats.dart` computes words, characters, characters without line
   breaks, and lines. Nothing else. `txt_info_sheet.dart` shows only those four.
7. **§2.2** — "character count (**with and without spaces**)".
   The second figure is characters **without line breaks**, not without spaces.
8. **§2.2** — "Split File ... by line count, maximum file size, or **custom search
   delimiters**."
   `lib/formats/txt/txt_split_merge.dart` has `splitByLines` and `splitBySize` only.
9. **§2.2** — "Merge Files: ... with **customizable line separators**."
   The same file's `merge` is `parts.join('\n')` — the separator is fixed.

### D. Markdown

10. **§2.3** — "Heading-Based File Splitting ... based on **H1 (`#`) or H2 (`##`)** header
    sections."
    `lib/formats/markdown/md_split_merge.dart` has only `splitByTopHeading`, and its
    `_isTopHeading` matches `^#\s+\S` — H1 only.

### E. CSV

11. **§2.4** — "Auto-fit column width calculation and **manual column width adjustments**."
    `lib/formats/csv/csv_grid.dart` auto-fits (`_columnWidths`). There is no resize handle
    or width override anywhere in `lib/formats/csv/`.
12. **§2.4** — "Column Insights ... **Median**".
    `lib/formats/csv/csv_insights.dart` computes count, empty count, unique count, numeric
    count, min, max, sum, average. No median.
13. **§2.4** — "Split CSV by row count or **header grouping**; merge multiple CSV files with
    **automatic column header matching**."
    `lib/formats/csv/csv_split_merge.dart` splits by row count or by **file size**. `merge`
    concatenates parts and takes the header from the **first** part — it does not match or
    align headers.

### F. XML

14. **§2.6** — heading "**Entity Resolution & Namespace Inspector**".
    The namespace inspector is real (`xml_document_session.dart` `namespaces`, shown in
    `xml_info_sheet.dart`). Entity resolution is just what the `xml` package does when
    parsing — there is no entity inspector or entity UI. The heading promises a tool that
    does not exist.

### G. Files and metadata

15. **§2.7** — "File Metadata Inspector: Displays **file path**, **URI**, size, line count,
    character count, **MIME type**, encoding, and line ending style."
    `lib/core/metadata/` builds name, size, created, modified, encoding, line ending, plus
    per-format fields. The info sheets (e.g. `txt_info_sheet.dart`) show words, characters,
    characters without line breaks, lines, encoding, line ending, size, modified. No path,
    no URI, no MIME type.

### H. P2P LAN sync

16. **§1 pillar** and **§2.8** — "**6-digit numeric PIN** pairing" / "Fallback **6-digit
    numeric** pairing PIN for manual entry."
    `lib/sync/sync_constants.dart` sets `codeLength = 64` over a 31-character alphabet
    (≈317 bits). The manual fallback in `lib/sync/ui/sync_client_screen.dart` is a plain
    text field for that long code. There is no 6-digit PIN.
17. **§2.12** — "Sync Settings: P2P toggle, **device display name**, **network port**,
    **pairing history management**."
    `lib/shell/settings/sections/sync_section.dart` shows default share categories, an
    "Open sync" button, and an AirQR button. The port is ephemeral and chosen by the host
    (`sync_constants.dart` comment: "The host binds an ephemeral port and advertises it").
    No display name, no port field, no pairing history.

### I. Security and About

18. **§2.9** and **§2.12** — "**Configurable auto-lock timeouts** upon app backgrounding".
    `lib/core/security/app_lock_gate.dart` re-locks when the app goes to the background.
    There is no timeout value or picker in `lib/core/security/` or in
    `security_section.dart`. The section does have a screenshot-block toggle and the
    ephemeral-document settings, which §2.12 does not mention.
19. **§2.12** — "About & License Section: version, build number, developer details,
    **open-source dependency licenses**."
    `about_section.dart` shows app name, description, version + build, and the `details`
    map from `assets/config/app_config.json` (Author, Email, a one-line License note, AI
    used, IDE used). There is no license list screen (`showLicensePage` is not used).

### Correct claims (checked, keeping as-is)

Encodings list, line-ending preservation, edge-swipe tabs, regex capture groups, undo/redo,
draft store, external change detection, duplicate-tab prevention, FTS5 workspace search,
CSV formula functions (`SUM`/`AVERAGE`/`AVG`/`MIN`/`MAX`/`COUNT`/`PRODUCT`), conditional
format conditions and the four colours, chart types (bar/line/pie), the SQL engine section,
JSON quick fixes, JSON lenient JSONC/JSON5 mode, big-number precision, JSON/YAML
conversion, JSON table sorting, XML quick fixes, the XSD "coming soon" note, sepia theme,
the font list, AES-256-GCM + PBKDF2 200,000 iterations + 16-byte salt, share-chooser
categories, ephemeral documents, paged text, session retention, version 1.9.0+21, and the
dependency table.

## The plan for the fix

Edit `docs/features.md` only. For each of the 19 points above, either **delete** the
unimplemented part or **replace** it with what the code actually does. Specifically:

1. §1 pillar list — change "6-digit numeric PIN pairing" to the real long pairing code.
2. §2.1 — drop the tab-indentation claim; say line numbers are always shown and word wrap
   is a setting in Appearance.
3. §2.2 — TTS: play/stop plus the English/Malayalam voice toggles and the installer prompt;
   remove pause, rate, pitch. Statistics: words, characters, characters without line
   breaks, lines. Split: by line count or by size. Merge: joined with newlines.
4. §2.3 — heading split is H1 only.
5. §2.4 — remove "manual column width adjustments"; remove "Median"; correct the split
   modes to row count / file size and describe merge as "parts that share the same
   columns, header taken from the first part".
6. §2.6 — rename the heading to "Namespace Inspector" and say entities are resolved by the
   parser, with no separate entity tool.
7. §2.7 — list the metadata fields that are really shown.
8. §2.8 — replace the 6-digit PIN line with the real code + manual-entry fallback.
9. §2.9 — replace "configurable auto-lock timeouts" with "locks when the app goes to the
   background".
10. §2.12 — rewrite the Appearance, Editor, Speech, Sync, Security, and About bullets to
    match the real sections listed above.

No code changes, no test changes. `docs/features.md` is documentation only, so
`flutter analyze` and `flutter test` are unaffected, but I will still run them to confirm
nothing else moved.

## Not in this plan (please tell me if you want it)

The doc calls itself a catalogue of "everything the app can do today", but several
**implemented** areas have no entry at all:

- Encrypted Vault (`lib/core/vault/`)
- Backup bundles (`lib/core/backup/` + Settings › Backup)
- Audit log (`lib/core/audit/` + Settings › Audit)
- PII / Privacy Shield detection and masking (`lib/core/privacy/`)
- AirQR optical air-gap transfer (`lib/airqr/`)
- P2P direct file transfer and Live Diff (`lib/sync/ui/p2p_file_transfer_tab.dart`,
  `live_diff_screen.dart`)
- Multi-cursor editing (mentioned in the in-app Help section)

Adding these is a bigger job than trimming, and the request was to make the doc cover only
implemented features. Say the word and I will add them in a follow-up plan.

## Change log

After approval and implementation, a log goes to
`change_log/<timestamp>_features-doc-implemented-only.md` referencing this plan.
