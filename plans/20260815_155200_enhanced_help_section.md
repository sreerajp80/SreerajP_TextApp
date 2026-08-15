# Enhance Help Section with New Features

**Status:** Proposed

## 1. Overview
The TextData app has implemented multiple advanced features across recent phases:
- LAN Peer-to-Peer Sync & Live Document Diff / Delta Sync
- Optical AirQR Transfer (air-gapped visual QR transfer)
- Offline Privacy Shield & PII Scrubber
- Secure Document Vault & Encrypted Backup Archives (.txdata)
- SQL Query Engine for CSV, JSON, and XML
- Multi-Cursor & Column Selection
- Workspace Search & SQLite FTS5 Full-Text Indexing
- Tamper-Evident Audit Log (SHA-256 hash-chain integrity)
- Format-Specific Tools (JSON Tree/JSONPath/Schema, Markdown Table Builder/Front-Matter/Live Preview, CSV Grid/Formulas, XML XPath/XSD, TXT Tools)
- Text-to-Speech Read Aloud (English & Malayalam)

Currently, the Help section only shows 4 basic topics. This change enhances the Help section to provide 10 comprehensive, organized topics covering all app features, adds an in-screen search filter to quickly find topics, and adds complete English and Malayalam localizations.

---

## 2. Files to Change

| File | Action | Purpose |
|------|--------|---------|
| `lib/l10n/app_en.arb` | Modify | Add English strings for new help topics and help search UI |
| `lib/l10n/app_ml.arb` | Modify | Add Malayalam translations for new help topics and help search UI |
| `lib/shell/settings/sections/help_section.dart` | Modify | Update help topic data model, add in-page search filtering, enhance UI with rich detail view |
| `test/shell/settings/settings_screen_test.dart` | Modify | Add and update widget tests for HelpSection rendering, search filtering, and topic detail display |

---

## 3. Detailed Changes

### A. Localization (`lib/l10n/app_en.arb` & `lib/l10n/app_ml.arb`)
Add strings for:
1. `helpSearchFilterHint`: "Search help topics…" / "സഹായ വിഷയങ്ങൾ തിരയുക…"
2. `helpNoTopicsFound`: "No matching help topics found." / "പൊരുത്തപ്പെടുന്ന സഹായ വിഷയങ്ങളൊന്നും കണ്ടെത്തിയില്ല."
3. `helpP2pSyncTitle`, `helpP2pSyncSubtitle`, `helpP2pSyncBody` (LAN Sync & Live Diff)
4. `helpQrSharingTitle`, `helpQrSharingSubtitle`, `helpQrSharingBody` (AirQR)
5. `helpPrivacyShieldTitle`, `helpPrivacyShieldSubtitle`, `helpPrivacyShieldBody` (Privacy Shield & PII Scrubber)
6. `helpVaultBackupTitle`, `helpVaultBackupSubtitle`, `helpVaultBackupBody` (Document Vault & Encrypted Backups)
7. `helpSqlQueryTitle`, `helpSqlQuerySubtitle`, `helpSqlQueryBody` (SQL Query Engine)
8. `helpMultiCursorTitle`, `helpMultiCursorSubtitle`, `helpMultiCursorBody` (Multi-Cursor & Column Editing)
9. `helpSearchTitle`, `helpSearchSubtitle`, `helpSearchBody` (Search & Workspace Index)
10. `helpAuditLogTitle`, `helpAuditLogSubtitle`, `helpAuditLogBody` (Tamper-Evident Audit Log)
11. `helpFormatToolsTitle`, `helpFormatToolsSubtitle`, `helpFormatToolsBody` (Format-Specific Tools)
12. `helpSpeechTitle`, `helpSpeechSubtitle`, `helpSpeechBody` (Speech & Read Aloud)
*(Preserve `helpSplitArray*` and `helpBackup*` as well for full compatibility).*

### B. Help Section UI (`lib/shell/settings/sections/help_section.dart`)
1. Convert `HelpSection` to a `StatefulWidget` to support interactive search filtering.
2. Filter topics by matching search query against topic title, subtitle, and body text.
3. Show empty state banner if no topics match the search query.
4. Enhance `_HelpTopicDetail` with a Material 3 card banner (icon, title, subtitle) and structured, scrollable content.

### C. Testing & Verification
1. Run `flutter gen-l10n`.
2. Update tests in `test/shell/settings/settings_screen_test.dart`.
3. Run `dart format lib test`, `flutter analyze`, and `flutter test`.

---

## 4. Verification Plan
- Automated tests: `flutter test test/shell/settings/settings_screen_test.dart`
- Full test suite: `flutter test`
- Static analysis: `flutter analyze`
