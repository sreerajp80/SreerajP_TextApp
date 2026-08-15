# Add help topics for QR sharing, backup, and search

**Status:** completed

---

## Issue

The Help section currently only has one topic ("Split array"). The user wants
three more help topics added:

1. **QR sharing** — explain how the AirQR optical air-gap transfer works
   (send, receive, encryption, speed expectations).
2. **Backup** — explain how to keep a copy of files via the "Export" and "Save a
   copy" features, since this scoped-storage-only app has no filesystem browser
   or dedicated backup screen.
3. **Search** — explain the two search layers: in-document find & replace, and
   workspace-wide search across indexed files.

---

## Plan

### 1. Add localization strings

#### `lib/l10n/app_en.arb`

Add six new keys right after the existing `helpSplitArrayBody` entry (lines 514–515):

| Key | Value |
|-----|-------|
| `helpQrSharingTitle` | `"QR sharing"` |
| `helpQrSharingBody` | A paragraph explaining: open a document → "Send by QR" or "Send selection by QR" from the menu → animated QR stream appears → point the other device's camera at it → the session code (shown separately) protects the data with AES-256-GCM → short notes take seconds, large files take minutes → for big files, use LAN sync instead → receive from the AirQR landing screen. |
| `helpBackupTitle` | `"Backup & export"` |
| `helpBackupBody` | A paragraph explaining: use "Export" from the document menu to convert to PDF, TXT, or other formats → use "Save a copy" to save the document to a new location → the original is untouched → for extra safety, export important files regularly and store copies somewhere safe (cloud folder, SD card, or another device via LAN sync or QR). |
| `helpSearchTitle` | `"Search"` |
| `helpSearchBody` | A paragraph explaining the two layers: (1) in-document find & replace (Ctrl+F icon in the editor toolbar — case, whole-word, regex, and $1 capture groups in replace), and (2) workspace-wide search (magnifying glass on the home screen — searches the local index of recent and favorite files, filter by format, everything stays on-device, turn the index on in Settings › Files & Tabs). |

Each key will also have its `@key` description entry.

#### `lib/l10n/app_ml.arb`

Add the same six keys (without `@` descriptions) with Malayalam translations,
right after the existing `helpSplitArrayBody` entry (line 252).

### 2. Update the HelpSection widget

#### `lib/shell/settings/sections/help_section.dart`

Refactor the widget to show all four help topics (the existing split-array plus
the three new ones) as a `Column` of cards. Each topic card follows the same
layout as the existing one: icon + title row, then body text. The icons will be:

| Topic | Icon |
|-------|------|
| Split array | `Icons.call_split` (existing) |
| QR sharing | `Icons.qr_code_2` |
| Backup & export | `Icons.save_outlined` |
| Search | `Icons.search` |

I will extract a small private `_HelpTopicCard` widget to avoid repeating the
card layout four times.

---

## Files to change

| File | Action |
|------|--------|
| `lib/l10n/app_en.arb` | Add 6 new key+description entries |
| `lib/l10n/app_ml.arb` | Add 6 new keys with Malayalam text |
| `lib/shell/settings/sections/help_section.dart` | Add 3 new topic cards, extract shared card widget |

---

## Verification

1. `flutter pub get`
2. `dart format lib test`
3. `flutter analyze` — must be zero issues
4. `flutter gen-l10n` — confirm new keys appear in generated files
5. `flutter run --flavor dev` — open Settings → Help and verify all four topics render correctly
