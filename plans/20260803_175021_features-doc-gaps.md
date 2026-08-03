# Fill gaps in docs/features.md

**Status:** completed

## Files to change

- `docs/features.md`

## What the issue is

I compared `docs/features.md` against the actual app code (`lib/`) to check it lists every
feature. Most of the document is accurate and already covers recent additions (CSV charts,
conditional formatting, formulas, JSON/XML query builders, quick-fix engines, Markdown table
builder and front-matter form, external-change detection). But three real, user-facing
features in the code are missing from the document:

1. **Create New Document** (`lib/shell/create_document_action.dart`, wired from the Home
   screen). The user can create a new blank TXT, Markdown, CSV, JSON, or XML file through the
   system file picker (SAF), each with a sensible starter template (e.g. `{}` for JSON, a
   minimal `<root>` element for XML), and it opens straight into the editor. This is a
   fairly major feature (the app is not just "open existing files") and is not mentioned
   anywhere in the document.

2. **Tab over-limit behavior choice** (`lib/shell/tabs/over_limit_behavior.dart`, exposed in
   Settings → Files & Tabs). When the open-tab cap is reached, the user can choose whether the
   app silently closes the least-recently-used tab (never one with unsaved edits) or asks the
   user what to close. The document only mentions the RAM-aware tab cap itself, not this
   choice.

3. **Restore-on-relaunch setting** (also in Settings → Files & Tabs). Whether open tabs are
   restored the next time the app launches is a user-visible toggle, not just an automatic
   background behavior. The document's "session retention policy" line is too vague to cover
   this and the related background session eviction policy
   (`lib/shell/tabs/session_retention.dart`) that keeps memory in check for background tabs.

I also checked the "Open with… / share intents" hard rule in `CLAUDE.md` §3.3 against
`android/app/src/main/AndroidManifest.xml`: only `MAIN`/`LAUNCHER` is registered — there is no
`VIEW`/`SEND` intent-filter, so "Open with" is not actually implemented yet. `features.md`
correctly does not claim this feature, so no change is needed there, but I will flag this to
you as a separate note (not a doc fix) since it's a gap between the project rule and the
current app.

## The plan for the fix

Edit `docs/features.md` only, in three small places:

1. In **§2.7 (SAF & File System Integration)**, add a new bullet for "Create New Document"
   describing the 5 supported starter formats and that it goes straight into the editor.

2. In **§2.1 (Shared Multi-Format Editor Engine)** or **§2.14 (Performance)**, add a bullet
   for the tab over-limit behavior (ask vs. auto-close least-recently-used, never closing a
   dirty tab).

3. Reword the "session retention policy" bullet in **§2.12 (Comprehensive App Settings)** to
   explicitly mention: fixed vs. auto tab cap, over-limit behavior choice, and restore-tabs-on-
   relaunch toggle. Also add a short bullet in §2.14 for the background session eviction
   policy (releases heavy in-memory state for background tabs to save memory, never for the
   active or a dirty tab).

No other sections need changes — the App Overview description in §1 is already broad enough
("full-featured reader, editor, parser...") that it doesn't need new wording for these three
items; they fit under the existing "editor" and "multi-document" framing.

I will not touch code, only `docs/features.md`.
