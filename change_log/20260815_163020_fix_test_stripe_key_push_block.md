# Change Log: Fix Stripe Test Key in PII Detector Unit Test

**Date:** 2026-08-15
**Plan Reference:** `plans/20260815_162830_fix_test_stripe_key_push_block.md`

## Summary of Changes
- Updated the dummy Stripe key in `test/core/privacy/pii_detector_test.dart` from `sk_live_1234567890abcdefghijklmnopqr` to `sk_test_1234567890abcdefghijklmnopqr`.
- This prevents GitHub Secret Scanning and Push Protection from flagging and blocking git pushes while still verifying `PiiDetector`'s API secret token scanning logic.

## Verification
- Ran `flutter test test/core/privacy/pii_detector_test.dart` — 14/14 tests passed.
- Ran `flutter analyze` — 0 issues found.
