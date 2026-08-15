# Mark Feature 7 (AirQR) as delivered in the roadmap

**Status:** completed

Change log: `change_log/20260813_221919_airqr-mark-delivered.md`.

Documentation-only change. No app code, no dependencies, no tests affected.

The user asked for the feature to be marked completed after being told that Step 3 was still
open, so Step 3 is treated as **moved out of Feature 7**, not silently dropped.

---

## 1. What the issue is

`lib/airqr/` is built, tested (57 tests), analysed clean, and wired into all five formats. But
[docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) still reads as
if none of it exists:

- §2 "Comprehensive Audit of Implemented Features" does not mention AirQR at all, even though
  that table is meant to list what is actually in the codebase.
- §3 Feature 7 is still written as a **proposal** ("Build this first", future tense).
- §5 the prioritisation matrix still lists it as an unbuilt proposal.
- §6 Phase 18 shows it as 🟡 part-done.

## 2. The Step 3 question

Feature 7 was scoped as three steps. Steps 1 and 2 are delivered; **Step 3 (settings & rules
transfer)** is not built.

Marking the feature "completed" while a listed step is missing would make the document lie.
The honest way to do what was asked is to **narrow Feature 7 to what it actually is** — an
optical transfer engine for documents and snippets — and move settings-and-rules transfer out
to its own future roadmap item. Feature 7 is then genuinely complete as scoped, and the
unbuilt work is still visible rather than erased.

## 3. The plan for the fix

| Section | Change |
| --- | --- |
| §2 audit table | Add an **Optical Air-Gap Transfer (AirQR)** row describing what actually shipped, so the "implemented features" table is true. |
| §3 Feature 7 heading | Mark **(DELIVERED)**. |
| §3 "What is transferred" | Rewrite in past tense: two delivered modes, with the class names that exist. Remove "Build this first". |
| §3 payload limits | Keep, but state these caps are **enforced** in `AirqrConstants`, not proposed. |
| §3 non-goals | Keep unchanged — they are still true and still worth stating. |
| §3 | Add a short **"What shipped"** block: module path, test count, the reshuffle design, and the outstanding manual two-device check. |
| §5 matrix | Mark the AirQR row *(delivered)*, matching how other delivered rows are marked. |
| §6 Phase 18 | Change 🟡 → ✅ for the AirQR line; keep Steps 1 and 2 ticked; **move Step 3 out** into its own separate ⬜ roadmap item so it is not lost. |
| §1 Ecosystem Synergy | Note the module is now built and reusable. |

## 4. Honesty constraints

- The **manual two-device verification is still outstanding** and must stay visible in the
  document. "Delivered" means the code is written, tested, and analysed clean — not that it
  has been proven against a real camera.
- Step 3 must remain on the roadmap as its own unbuilt item.

## 5. Files to be changed

Only [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md).

## 6. Verification

- Re-read every edited section and confirm nothing claims work that was not done.
- Relative repository paths only; no private information (workflow rule 3).
- No `flutter analyze` / `flutter test` run needed — no Dart source is touched.

## 7. Change log

To be written to `change_log/` on completion.
