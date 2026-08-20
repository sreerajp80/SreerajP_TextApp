# Plan: Appearance, Features, and Help Cards in Settings

**Status:** Proposed

## Overview
Based on the analysis of `L:\Android\SreerajPContactSphere`, we will elevate `SreerajP_TextApp`'s Settings screen and its sub-pages to match ContactSphere's design, depth, and aesthetics. Specifically:
1. **Appearance Hub & Sub-screens:** Re-architect Appearance in settings into modular, visual sections with live font sample preview cards (English + Malayalam), Theme Mode selector (Light / Dark / Sepia / System) with explanatory cards, text scale & line spacing sliders, and reading/display comfort settings.
2. **Features Card & Features Screen:** Create a comprehensive `FeaturesScreen` in `lib/shell/settings/features_screen.dart` with gradient header, grouped categories, styled icon badges, detailed descriptions, and highlight chip tags for all TextData capabilities (Editor, Formats, SQL/Data querying, LAN Sync, AirQR, Vault & Security, TTS, Export/Print).
3. **Help Center Hub & Guides:** Redesign the Help section into a rich Help Center with a gradient header banner, categorized guide topics (Editor & Formats, Data & SQL Tools, Privacy & Security, LAN Sync & AirQR, Troubleshooting & FAQs), search filtering, and structured detail pages.
4. **Settings Screen Card Styling:** Align `SettingsScreen` card aesthetics with ContactSphere (tinted icon badges, bold titles, clear subtitles, chevron navigation, refined spacing).

---

## Files to Create / Modify

### 1. New Screens & Widgets
- `lib/shell/settings/features_screen.dart` [NEW]: Full visual features catalog screen for TextData.
- `lib/shell/settings/appearance_screen.dart` [NEW]: Modular appearance hub or enhanced appearance options with live typography cards and theme mode cards.
- `lib/shell/settings/help_hub_screen.dart` (or updated `lib/shell/settings/sections/help_section.dart`) [MODIFY/NEW]: Categorized help center with gradient header, categorized topics, and search.

### 2. Modifications to Existing Settings
- `lib/shell/settings/settings_screen.dart` [MODIFY]: Add Features card, update card styling with tinted icon containers, rounded geometry, and routes to Appearance, Features, and Help.
- `lib/shell/settings/sections/appearance_section.dart` [MODIFY]: Upgrade with live typography cards (previewing English and Malayalam fonts) and theme cards.
- `lib/l10n/app_en.arb` & `lib/l10n/app_ml.arb` [MODIFY]: Add localization keys for Features, new Help categories, and Appearance sub-headings.

---

## Proposed Changes Detail

### 1. Settings Screen Cards & Layout
- Update `_SettingsCard` in `lib/shell/settings/settings_screen.dart` to use:
  - 48x48 icon badge with `accent.withValues(alpha: 0.14)` background and rounded corners (14-16px).
  - Title in `16px, FontWeight.w700`.
  - Subtitle in `13px, onSurfaceVariant`.
  - 12px vertical spacing between cards.
  - Add **Features** card between Appearance and Security/Help.

### 2. Features Screen (`lib/shell/settings/features_screen.dart`)
- Create data models `_FeatureCategory` and `_AppFeature`.
- Categories to include:
  1. **Multi-Format Document Engine** (TXT, Markdown, CSV, JSON, XML, Multi-tab workspace, Scoped Storage).
  2. **Smart Code & Text Editor** (Multi-cursor editing, Find & Replace with regex & column/subtree scope, line numbers, code folding, draft recovery, read-only safety lock).
  3. **Data Analysis & SQL Querying** (In-memory SQLite SQL engine on CSV/JSON, JMESPath/JSONPath, XPath queries, array splitting, interactive table grid).
  4. **P2P LAN Sync & AirQR Optical Transfer** (Zero-cloud LAN peer-to-peer sync with AES-256-GCM encryption, Animated AirQR optical data beam for air-gapped devices with error correction).
  5. **Privacy, Security & Vault** (Biometric & App PIN lock, Screenshot Guard, Tamper-proof Security Audit Log, Encrypted `.txbak` vault backups).
  6. **Voice & Text-to-Speech (TTS)** (Bilingual English & Malayalam read-aloud, speed/pitch sliders, background audio).
  7. **Export, Conversion & Printing** (Export to PDF, HTML, Markdown, CSV, JSON, XML, Zip bundling for sharing, Direct printing).
  8. **Personalization & Accessibility** (Light, Dark, and Sepia reading themes, Custom English & Malayalam typography, Adjustable text scale & line height).
- Styled with header banner card, gradient star badge, uppercase category headings, and highlight chips.

### 3. Appearance Section / Hub (`lib/shell/settings/sections/appearance_section.dart`)
- **Theme Mode card & selector**: Light, Dark, Sepia, System with descriptive card explaining Sepia (warm reading tone) and System modes.
- **Typography & Font Tiles**: Visual selection cards for English fonts (`Inter`, `Lora`, `JetBrains Mono`, `Default`) with sample text, and Malayalam fonts (`Manjari`, `Rachana`, `Noto Sans Malayalam`, `Default`) with live Malayalam samples (`മലയാളം സുന്ദരമാണ്`).
- **Text Size & Line Spacing**: Sliders with live preview labels.
- **Word Wrap & Reading options**: Switch tiles with clear explanations.

### 4. Help Center (`lib/shell/settings/sections/help_section.dart`)
- Add gradient header card with `Icons.help_center_rounded`.
- Organize help topics into structured categories:
  - **Editing & Documents**: Multi-cursor editing, Find & Replace with Regex, Format tools & Markdown preview, Split array transformations.
  - **Data Querying & Analysis**: SQLite SQL queries on CSV/JSON, JMESPath/JSONPath and XPath, Tabular CSV viewer.
  - **Privacy & Security**: App Lock & Biometrics, Screenshot Guard, Security Audit Log, Encrypted Vault backups.
  - **Sync & AirQR Transfer**: Local Wi-Fi P2P Device Sync, Optical AirQR Air-Gap transfer.
  - **Voice & Accessibility**: Bilingual Text-to-Speech, Themes and Sepia mode.
- Retain real-time keyword search bar across all categories.
- Polished topic detail view with header card, bullet points, and clear explanations.

---

## Verification Plan
1. Run `flutter analyze` to ensure zero static analysis warnings or errors.
2. Run `flutter test` to ensure all unit and widget tests pass.
3. Run `dart format lib test` to maintain clean formatting.
4. Verify navigation and UI layout on both Light and Dark themes.
