# Fill gaps in docs/features.md

Implements: `plans/20260803_175021_features-doc-gaps.md`

## What changed

Compared `docs/features.md` against the actual app code and added three missing,
user-facing features that were not written down anywhere in the document:

1. **Create New Document** — added a bullet in §2.7 (SAF & File System Integration)
   describing the "new blank file" flow for TXT, Markdown, CSV, JSON, and XML
   (`lib/shell/create_document_action.dart`), each with a safe starter template, created
   through the system file picker and opened straight into the editor.

2. **Over-limit tab behavior** — added a bullet in §2.1 (Shared Multi-Format Editor Engine)
   for the choice between auto-closing the least-recently-used tab or asking the user, when
   the open-tab cap is reached (`lib/shell/tabs/over_limit_behavior.dart`), and reworded the
   Files & Tabs settings line in §2.12 to name this choice plus the restore-on-relaunch
   toggle explicitly (previously only a vague "session retention policy" phrase).

3. **Background session eviction** — added a bullet in §2.14 (Performance & Large-File
   Virtualization) describing the memory policy that releases heavy in-memory state for
   background tabs while protecting the active tab and any tab with unsaved edits
   (`lib/shell/tabs/session_retention.dart`).

No code was changed — this was a documentation-only pass.

## Note (not part of this change)

While checking the document, I also compared `CLAUDE.md` §3.3's "Open with… / share
intents" hard rule against `android/app/src/main/AndroidManifest.xml`. Only
`MAIN`/`LAUNCHER` is registered there — there is no `VIEW`/`SEND` intent-filter, so
"Open with" from other apps is not implemented yet. `docs/features.md` does not claim this
feature, so no doc change was needed, but this is a gap between the stated project rule and
the current app worth tracking separately.
