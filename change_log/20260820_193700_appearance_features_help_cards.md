# Change Log: Appearance, Features, and Help Cards

**Plan Reference:** `plans/20260820_192800_appearance_features_help_cards.md`

## Summary of Changes

Analyzed `SreerajPContactSphere` and introduced feature and aesthetic parity in `SreerajP_TextApp` across **Appearance**, **Features**, and **Help** in the Settings screen:

1. **Features Screen & Card (`lib/shell/settings/features_screen.dart`):**
   - Added a dedicated **Features** card to the main Settings menu.
   - Built a comprehensive `FeaturesScreen` with a top gradient header card, star badge icon, and 8 organized categories:
     - Multi-Format Document Engine (TXT, Markdown, CSV, JSON, XML, Multi-Tab workspace, SAF Scoped Storage)
     - Smart Code & Text Editor (Multi-cursor editing, regex replace & scope, line numbering, draft auto-save recovery, read-only lock)
     - Data Analysis & SQL Querying (In-memory SQLite SQL engine on CSV/JSON, interactive table grid, JMESPath/JSONPath, XPath, array split)
     - P2P LAN Sync & Optical AirQR (Zero-cloud Wi-Fi P2P sync with AES-256-GCM, animated optical AirQR beam, live document diff & delta merge)
     - Privacy, Security & Vault (Biometric & App PIN lock, Screenshot Guard, SHA-256 audit logs, `.txbak` encrypted vault backups)
     - Voice & Text-to-Speech (Bilingual English & Malayalam TTS, pitch & speed controls)
     - Export, Conversion & Printing (Multi-format conversion, direct printing, zip sharing)
     - Personalization & Accessibility (Light, Dark, and Sepia themes, custom English & Malayalam typography, scale & line spacing)
   - Styled every feature tile with tinted 42x42 icon containers, bold titles, descriptive summaries, and tag chips.

2. **Upgraded Appearance Section (`lib/shell/settings/sections/appearance_section.dart`):**
   - Replaced flat dropdowns with visual font cards for English fonts (`Inter`, `Lora`, `JetBrains Mono`, `Default`) and Malayalam fonts (`Manjari`, `Rachana`, `Noto Sans Malayalam`, `Default`), rendering live sample previews.
   - Added Theme Mode selector (Light, Dark, Sepia, System) with an informational card explaining Sepia reading mode and System mode.
   - Preserved interactive sliders for font scale (50% to 300%) and line spacing (1.0 to 2.0) with live percentage/ratio badges, and word-wrap toggle.

3. **Upgraded Help Center (`lib/shell/settings/sections/help_section.dart`):**
   - Added a gradient header card with help center branding and description.
   - Grouped all help topics into structured categories: Editing & Documents, Data Querying & Analysis, Privacy & Security, Sync & AirQR Transfer, Voice & Accessibility.
   - Maintained real-time keyword search filtering across all topics with clear empty search feedback.
   - Retained and polished detail pages with styled header badges and readable line height.

4. **Settings Screen Aesthetics (`lib/shell/settings/settings_screen.dart`):**
   - Updated `_SettingsCard` to match ContactSphere card design: 48x48 icon container with primary tint (`accent.withValues(alpha: 0.14)`), `BorderRadius.circular(15)`, 16px bold title, 13px muted subtitle, trailing chevron, and 12px vertical spacing.

5. **Localization & Testing:**
   - Added English (`lib/l10n/app_en.arb`) and Malayalam (`lib/l10n/app_ml.arb`) translation strings for the new Features screen, Appearance cards, and Help categories.
   - Added widget test suite in `test/shell/settings/features_screen_test.dart` and updated `test/shell/settings/settings_screen_test.dart`.

## Verification
- `flutter gen-l10n` ran successfully.
- `dart format lib test` passed with clean formatting across all 510 files.
- `flutter analyze` completed with 0 issues.
- `flutter test` passed all 1,177 unit and widget tests.
