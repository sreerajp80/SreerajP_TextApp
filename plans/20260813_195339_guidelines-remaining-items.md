# Guidelines conformance — the three remaining items

**Status:** completed

Approved and implemented as: Group A + Group B1 + Group C's justification note. B2 and the
real C split were not done, by decision.
Change log: `change_log/20260813_201433_guidelines-remaining-items.md`.

Note on B1: no constants were actually moved. The candidates already lived correctly beside
their own logic, so B1 shipped as the namespace registry plus a test that enforces it. The
reasoning is in the change log §2.

This plan covers the three items left open by
`plans/20260813_062612_guidelines-conformance.md` (change log:
`change_log/20260813_063929_guidelines-conformance.md`).

The three items are very different in risk, so each is its own group. **Approve them
separately.** My recommendation is on each group.

---

## Group A — `docs/security.md` blueprint

**Recommendation: do it.** Low risk, and the app clearly needs it.

### The issue

The shared manifest puts this app in the `Sensitive Data Extension` profile: it holds a PIN
hash, recovery codes, biometric state, and per-device sync keys, and it moves user data over
a LAN. That profile requires the filled-in `security.md` blueprint.

Today the project has `docs/security-rules.md` — a good, short rules list, but it is a
*rules* file, not the blueprint. The blueprint sections that have no home anywhere are:
threat model (in scope / out of scope), sensitive-data inventory, storage model (at rest /
in memory / in transit), binary protections (obfuscation, R8, debuggable flag), permission
justification table, OWASP Mobile Top 10 checklist, data retention and purge policy, and the
security review checklist.

### The fix

Create **`docs/security.md`**, filled in from the `docs/guidelines/security.md` template with
this app's real decisions. It becomes the full blueprint; `security-rules.md` stays as the
short day-to-day rules file and links to it.

No existing doc is rewritten or renamed. Two small edits:

- `docs/security-rules.md` — change its "full detail" pointer to the new `security.md`.
- `CLAUDE.md` and `AGENTS.md` — add `docs/security.md` to the §2 docs table.

Content comes only from what is already true in the code and manifest (the five permissions
and their reasons, AES-256-GCM + PBKDF2, `flutter_secure_storage` for secrets, the add-only
merge, the obfuscation flags already in the build commands). Where a decision has genuinely
not been made, the row says so plainly rather than inventing one.

### Files

- Create: `docs/security.md`
- Change: `docs/security-rules.md`, `CLAUDE.md`, `AGENTS.md`

---

## Group B — `lib/core/constants/app_constants.dart`

**Recommendation: do the light version (B1), not the full move (B2).**

### What I found

The guideline says technical constants belong in a plain Dart file "such as
`lib/core/constants/app_constants.dart`". I checked how this project actually stores them,
and the current state is already good:

- Preference keys live as `static const String` on the settings class that owns them, and
  they are namespaced: `editor.*`, `appearance.*`, `tts.*`, `security.*`, `tabs.*`,
  `onboarding.*`, `md.split.*`.
- `lib/sync/sync_constants.dart` already collects the sync protocol constants in one file.

Moving all of these into one file would pull each key away from the default value and
parsing code that uses it, and would touch security-sensitive files
(`app_lock_repository.dart`, `security_settings.dart`) for a purely cosmetic reason. That
trades a good pattern for a worse one to satisfy the letter of a "such as" suggestion.

The one real gap is that nothing stops two files picking the same key string.

### B1 — light version (recommended)

Create **`lib/core/constants/app_constants.dart`** as an `AppConstants` class (values only,
no logic) holding:

- the settings-key **namespace prefixes** as named constants, and a comment block listing
  every namespace currently in use, so a new key cannot silently collide;
- the genuinely cross-cutting technical constants that are currently plain literals at their
  use site (for example the large-file threshold and the draft auto-save interval), where
  moving them does not separate them from logic.

Per-feature keys stay where they are. A short note in `docs/project_structure.md` records the
rule: "a settings key lives on the class that owns it, under a registered namespace; the
namespaces live in `AppConstants`."

Risk: low. Additive, with a small number of call-site edits.

### B2 — full move (not recommended)

Move all ~25 settings keys and other technical constants into `AppConstants`, updating every
use site. Risk: medium, touches security-sensitive files, and no behaviour gain. Listed only
so the choice is explicit.

### Files (B1)

- Create: `lib/core/constants/app_constants.dart`
- Change: `docs/project_structure.md`, plus the few files whose literals move (expected 3–5)

---

## Group C — splitting the six files over 500 lines

**Recommendation: do NOT do this now.** I am listing it so the decision is recorded, not
because I think it should run.

### The issue

Engineering standard §16.2 says "around 500 lines: split or justify". Six files are over:

| File | Lines |
| --- | --- |
| `lib/formats/csv/csv_document_session.dart` | 956 |
| `lib/formats/json/json_document_session.dart` | 764 |
| `lib/formats/json/json_parser.dart` | 661 |
| `lib/formats/markdown/md_document_session.dart` | 631 |
| `lib/formats/xml/xml_document_session.dart` | 623 |
| `lib/formats/txt/txt_document_session.dart` | 510 |

### Why I recommend not splitting now

- These are the five document sessions plus one parser. Each is one document type's single
  job: parse, hold edit state, save. That is a real justification, not an excuse.
- Direct test coverage of the sessions is thin — 1 to 3 test files each. The suite passes,
  but most of the 831 tests exercise the sessions indirectly. A structural split of a
  `ChangeNotifier` this central is exactly the kind of change that thin direct coverage does
  not protect.
- §16.2 itself says these are "prompts to review, not automatic failures".

### What I propose instead

Record the justification, so the rule is answered rather than ignored: add a short
"Large files and why" section to `docs/project_structure.md` naming the six files and the
reason each is large, and noting that `csv_document_session.dart` (956 lines, the clear
outlier — it carries sort, filter, formulas, and conditional formatting on top of the base
session) is the one worth splitting first if it grows again.

If you would rather actually split, the safest order is: **first** add direct unit tests for
`CsvDocumentSession`'s sort / filter / formula / conditional-format behaviour, **then**
extract each of those four concerns into its own mixin or collaborator class, one at a time,
with the suite green between each. That is a separate plan and a much larger job — I would
not fold it into this one.

### Files

- Change: `docs/project_structure.md` (justification section only)

---

## Verification for whichever groups are approved

- `dart format --output=none --set-exit-if-changed lib test` passes.
- `flutter analyze --no-pub` reports 0 issues.
- `flutter test` passes (831 tests).
- `third_party/` untouched.
- New and changed docs follow `DOCS_FOLDER_GUIDELINE.md` §10, use relative links, and
  contain no absolute paths and no secrets.

---

## Summary of what I am asking

| Group | What | Recommendation |
| --- | --- | --- |
| A | Write `docs/security.md` blueprint | **Do it** |
| B1 | Light `AppConstants` — namespaces + cross-cutting values | **Do it** |
| B2 | Move every settings key into `AppConstants` | Do not |
| C | Split the six large files | Do not now; record the justification instead |

Default if you just say "approved": **A + B1 + C's justification note.**
