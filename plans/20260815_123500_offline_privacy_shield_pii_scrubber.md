# Offline Privacy Shield & Intelligent PII Scrubbing Engine

**Status:** completed

---

## 1. Overview & Goals

This plan implements **Feature 3: Offline Privacy Shield & Intelligent PII Scrubbing Engine** in TextData (`SreerajP_TextApp`), as specified in `docs/feature_analysis_and_roadmap.md`.

When users open, inspect, or export text documents, code logs, CSV spreadsheets, JSON payloads, or XML files, these files often contain sensitive personal information (PII) or secret credentials. Sharing or exporting these raw files risks unintended data leaks.

The **Offline Privacy Shield** provides an automated, on-device scanner and transformer that:
1. **Detects sensitive patterns offline:** Emails, Phone Numbers, Credit Card Numbers (with Luhn checksum validation), IP Addresses, JWT Tokens, AWS Access Keys (`AKIA...`), Private RSA/SSH Keys, and API Secrets across all 5 formats (TXT, Markdown, CSV, JSON, XML).
2. **Offers 3 masking modes:**
   - **Redact:** Replaces sensitive values with explicit tags (e.g. `[REDACTED: EMAIL]`, `[REDACTED: PHONE]`).
   - **Salted SHA-256 Hash:** Replaces values with deterministic truncated SHA-256 hashes (`[HASH:a3f1...e9]`), preserving relationship structures across repeated tokens without exposing original data.
   - **Pseudo-Anonymize:** Replaces entities with format-consistent dummy labels (e.g. `email_1@redacted.local`, `User_01`, `192.168.0.1`), maintaining visual layout and readability.
3. **User Control ("Scrub or Not Scrub"):** Scrubbing is completely interactive and optional. Users can view detected matches, toggle individual items or categories, choose masking modes, apply changes directly to the editor buffer (with undo support), share/export a scrubbed copy while preserving the original document, or choose to share as-is.

---

## 2. Architecture & Design

### 2.1 Pure Dart Core Privacy Engine (`lib/core/privacy/`)
- `lib/core/privacy/pii_type.dart`: Enum `PiiType` (`email`, `phone`, `creditCard`, `ipAddress`, `jwtToken`, `awsKey`, `privateKey`, `apiKeySecret`) with labels, icons, risk levels, and descriptions.
- `lib/core/privacy/pii_detection.dart`: Models `PiiMatch` (type, rawValue, start, end, line, column, isSelected) and `PiiScanResult` (matches, countsByType, scanDuration).
- `lib/core/privacy/pii_detector.dart`: Pure Dart scanner with regex matching, Luhn credit card validation, IP octet boundary checks, and multi-line private key boundaries.
- `lib/core/privacy/pii_mask_mode.dart`: Enum `PiiMaskMode` (`redact`, `hash`, `anonymize`).
- `lib/core/privacy/pii_scrubber.dart`: Pure Dart transformer that applies selected masking modes to text while maintaining consistent anonymized / hashed mappings for duplicate values.

### 2.2 Interactive Bottom Sheet UI (`lib/core/privacy/ui/privacy_shield_sheet.dart`)
- Accessible via:
  1. Format overflow menus (**"Privacy Shield & PII Scrubbing"**).
  2. Editor selection popup menu (**"Scan for PII / Secrets"**).
- Features:
  - **Category summary chips:** Filter and bulk toggle categories (e.g., Email, AWS Keys, Phone).
  - **Masking Mode Selector:** Segmented button (Redact / Hash / Anonymize).
  - **Match items list:** Item details with line numbers, category tags, preview, and selection checkboxes.
  - **Before / After live preview:** Shows how text looks before and after applying scrubbing.
  - **Action buttons:**
    - `Apply to Document`: Modifies the active editor text with undo support.
    - `Share Scrubbed Copy`: Shares masked copy via `ShareService` without modifying active document.
    - `Export Scrubbed File`: Saves masked copy to a new file via `SafService`.
    - `Share / Export As-Is`: Explicit option to proceed unscrubbed.

### 2.3 Integration Across Formats
- Add Privacy Shield menu option to:
  - `lib/formats/txt/txt_toolbar.dart`
  - `lib/formats/markdown/md_toolbar.dart`
  - `lib/formats/csv/csv_toolbar.dart`
  - `lib/formats/json/json_toolbar.dart`
  - `lib/formats/xml/xml_toolbar.dart`

### 2.4 Localization (`lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`)
- Full English and Malayalam translations for all privacy categories, modes, dialog titles, and actions.

---

## 3. Files to Create and Modify

### New Files:
1. `lib/core/privacy/pii_type.dart` — PII category enum and metadata.
2. `lib/core/privacy/pii_detection.dart` — PII match and scan result models.
3. `lib/core/privacy/pii_detector.dart` — Offline regex and heuristic detection engine.
4. `lib/core/privacy/pii_mask_mode.dart` — Masking mode enum.
5. `lib/core/privacy/pii_scrubber.dart` — Text transformation engine.
6. `lib/core/privacy/ui/privacy_shield_sheet.dart` — Interactive bottom sheet UI.
7. `test/core/privacy/pii_detector_test.dart` — Detector unit test suite.
8. `test/core/privacy/pii_scrubber_test.dart` — Scrubber unit test suite.
9. `test/core/privacy/privacy_shield_sheet_test.dart` — Widget test suite.

### Modified Files:
1. `lib/formats/txt/txt_toolbar.dart` — Add Privacy Shield menu action.
2. `lib/formats/markdown/md_toolbar.dart` — Add Privacy Shield menu action.
3. `lib/formats/csv/csv_toolbar.dart` — Add Privacy Shield menu action.
4. `lib/formats/json/json_toolbar.dart` — Add Privacy Shield menu action.
5. `lib/formats/xml/xml_toolbar.dart` — Add Privacy Shield menu action.
6. `lib/l10n/app_en.arb` — Add English strings.
7. `lib/l10n/app_ml.arb` — Add Malayalam strings.
8. `docs/feature_analysis_and_roadmap.md` — Mark Feature 3 as DELIVERED in roadmap and matrix.

---

## 4. Verification Plan

### Automated Tests:
- `flutter test test/core/privacy/pii_detector_test.dart`
- `flutter test test/core/privacy/pii_scrubber_test.dart`
- `flutter test test/core/privacy/privacy_shield_sheet_test.dart`
- `flutter test`
- `flutter analyze`
- `dart format lib test`
