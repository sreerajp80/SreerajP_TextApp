# Change Log: Offline Privacy Shield & Intelligent PII Scrubbing Engine

- **Date:** 2026-08-15
- **Plan Reference:** plans/20260815_123500_offline_privacy_shield_pii_scrubber.md
- **Feature Roadmap Reference:** Feature 3 in docs/feature_analysis_and_roadmap.md

---

## Summary of Changes

Implemented **Feature 3: Offline Privacy Shield & Intelligent PII Scrubbing Engine** across the shared core and all 5 supported document formats (TXT, Markdown, CSV, JSON, XML).

### 1. Pure Dart Offline Privacy Engine (`lib/core/privacy/`)
- `lib/core/privacy/pii_type.dart`: Enum defining categories of sensitive data (`email`, `phone`, `creditCard`, `ipAddress`, `jwtToken`, `awsKey`, `privateKey`, `apiKeySecret`) with risk levels, labels, and icons.
- `lib/core/privacy/pii_detection.dart`: Models `PiiMatch` and `PiiScanResult` capturing detected token positions, line/column coordinates, values, and selection states.
- `lib/core/privacy/pii_detector.dart`: Pure Dart offline scanner featuring regex and heuristic classifiers, Luhn checksum validation for credit cards to eliminate false positives, valid IP octet checks, and multi-line private key detection.
- `lib/core/privacy/pii_mask_mode.dart`: Enum defining 3 masking modes: `redact`, `hash`, `anonymize`.
- `lib/core/privacy/pii_scrubber.dart`: Transformation engine applying Redact (`[REDACTED: TYPE]`), Salted SHA-256 Hash (`[HASH:xxxx]` with relationship preservation across identical tokens), and Pseudo-Anonymize (`user_01@anonymized.local`, `10.0.0.1`, `User_01`) transformations.

### 2. Interactive UI (`lib/core/privacy/ui/`)
- `lib/core/privacy/ui/privacy_shield_sheet.dart`: Mobile-friendly bottom sheet providing:
  - Header with detection count badges or safe clean status.
  - 1-tap mode selector between Redact, Salted Hash, and Pseudo-Anonymize.
  - Category filter chips and "Select All" toggle.
  - Detected items list with individual selection checkboxes, line/column tags, and live before/after token previews.
  - Monospace full text preview tab.
  - Action buttons to **Apply to Document** in-place (with undo support), **Share Scrubbed** copy (without modifying original), **Export Scrubbed** file via SAF, or dismiss/proceed as-is.

### 3. Format Toolbar Integrations
Added **"Privacy Shield & Scrubbing"** overflow menu actions to:
- `lib/formats/txt/txt_toolbar.dart`
- `lib/formats/markdown/md_toolbar.dart`
- `lib/formats/csv/csv_toolbar.dart`
- `lib/formats/json/json_toolbar.dart`
- `lib/formats/xml/xml_toolbar.dart`

### 4. Localization
- `lib/l10n/app_en.arb`: Added English strings for all Privacy Shield features.
- `lib/l10n/app_ml.arb`: Added Malayalam strings for all Privacy Shield features.

### 5. Automated Tests & Documentation
- `test/core/privacy/pii_detector_test.dart`: 13 test cases covering all PII categories, Luhn checksum verification, IP validation, secrets, and edge cases.
- `test/core/privacy/pii_scrubber_test.dart`: 5 test cases covering Redact, Hash, Anonymize, and partial selection.
- `test/core/privacy/privacy_shield_sheet_test.dart`: Widget test cases testing UI rendering, clean state, in-place application, and sharing.
- `docs/feature_analysis_and_roadmap.md`: Updated Section 3, Section 5 matrix, and Section 6 Phase 16 marking Feature 3 as DELIVERED.

---

## Verification
- `flutter test test/core/privacy/`: 22 tests passing.
- `flutter test`: 1,125 tests passing (zero regressions).
- `flutter analyze`: Clean (zero issues).
- `dart format lib test`: Fully formatted.
