# Fix Stripe Test Key in PII Detector Unit Test

**Status:** Proposed

## Problem
GitHub Secret Scanning and Push Protection blocks git push due to a dummy `sk_live_...` token in `test/core/privacy/pii_detector_test.dart` at line 150. GitHub flags any `sk_live_` prefix as an active live Stripe secret key.

## Proposed Changes
- In `test/core/privacy/pii_detector_test.dart`: Replace `sk_live_1234567890abcdefghijklmnopqr` with `sk_test_1234567890abcdefghijklmnopqr`.
- `PiiDetector` supports `(?:sk|pk)_(?:test|live)_`, so test coverage remains 100% valid while avoiding GitHub push protection blocks.

## Files to Modify
- `test/core/privacy/pii_detector_test.dart`

## Verification
- Run `flutter test test/core/privacy/pii_detector_test.dart`
- Ensure all tests pass with zero issues.
