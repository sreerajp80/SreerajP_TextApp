# Feature 7 (AirQR) marked as delivered in the roadmap

Implements plan `plans/20260813_215210_airqr-mark-delivered.md`.

Documentation only. One file changed:
[docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md). No app code,
no dependencies, no tests touched.

---

## Why

`lib/airqr/` was built and tested in `change_log/20260813_215145_airqr-transfer-engine.md`,
but the roadmap still described Feature 7 as an unbuilt proposal — future tense, "build this
first", and absent from the table of implemented features.

## The one judgement call

Feature 7 was originally scoped as three steps, and **Step 3 (settings & rules transfer) is
not built**. Marking the feature complete with a listed step missing would have made the
document untrue.

So Feature 7 was **narrowed to what it actually is** — an optical transfer engine for
documents and snippets — and settings-and-rules transfer was **split out into its own Phase 18
roadmap item**. Feature 7 is now genuinely complete as scoped, and the unbuilt work stays
visible instead of being erased.

## What changed

| Section | Change |
| --- | --- |
| §1 Ecosystem Synergy | The AirQR line now says the module is built in this app as `lib/airqr/` and is reusable across the suite. |
| §2 Audit of Implemented Features | **New row** for Optical Air-Gap Transfer (AirQR), describing what actually shipped. This table is meant to list what is in the codebase, and AirQR was missing from it. |
| §3 heading note | States that entries marked **DELIVERED** are no longer proposals, so a built feature sitting in a "Proposals" section is not confusing. |
| §3 Feature 7 title | Marked ✅ **DELIVERED**. The ✅ matches the convention already used for completed items in §4.2-§4.4 and the Phase 15 list, so a reader scanning the document sees the same signal everywhere. |
| §3 Feature 7 status line | Module path, 57 tests, analyze clean, and the fact that no new dependency was added. |
| §3 "What is transferred" | Rewritten in past tense; the two delivered modes, with the third step explicitly noted as moved out. |
| §3 payload limits | Now says the caps are **enforced in code** (`AirqrConstants` / `AirqrSizeWarning`), not merely proposed. |
| §3 capabilities | Marked as delivered, plus the frame-rate and density sliders that were built. |
| §3 **new** "Security model as built" | The out-of-band session code, PBKDF2 + AES-GCM, why the file name sits inside the sealed envelope, and an honest note on what ~30 bits of code entropy does and does not protect. |
| §3 **new** "Still to verify" | The outstanding manual two-device check, and the screen-timeout limitation. |
| §5 matrix | AirQR row marked *(delivered)*; dependency column corrected to say no new dependency was needed. |
| §6 Phase 18 | AirQR line 🟡 → ✅ with its delivered sub-points; Step 3 split out as its own ⬜ item; wakelock added as its own ⬜ item. |

## What was deliberately kept

- The **non-goals** section is unchanged. Ruling out bulk workspace transfer and
  recents/favorites transfer is still true and still worth stating, because the SAF-URI reason
  is not obvious.
- The **Reed-Solomon correction** section is unchanged. It records why the shipped design
  differs from the original promise.
- The **outstanding two-device verification** is stated in two places (§3 and §6). "Delivered"
  here means written, tested, and analysed clean — **not** proven against a real camera. That
  distinction is deliberate and should not be edited away until the manual check is done.

## Verification

- Every edited section re-read; nothing claims work that was not done.
- Relative repository paths only, no private information (workflow rule 3).
- `flutter analyze` and `flutter test` not run, and not needed — no Dart source was modified.
