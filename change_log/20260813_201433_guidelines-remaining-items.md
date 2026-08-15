# Change log — The three remaining guidelines items

**Date:** 2026-08-13
**Plan:** `plans/20260813_195339_guidelines-remaining-items.md`
**Result:** Group A and Group B1 implemented. Group C answered with a written justification
instead of a refactor, as approved.

This finishes the guidelines conformance work started in
`change_log/20260813_193929_guidelines-conformance.md`.

---

## 1. Group A — `docs/security.md` security blueprint

### Created

**`docs/security.md`** — the filled-in blueprint required by the `Sensitive Data Extension`
profile. Fourteen sections: security scope, objectives, threat model (in scope / out of
scope), sensitive-data inventory, the LAN sync design, authentication, opened-file handling,
logging policy, retention and purge, Android platform controls, the OWASP Mobile Top 10
table, open risks, security testing, and a pre-release review checklist.

Everything in it was read out of the code and manifest rather than assumed. The concrete
values recorded include:

- Pairing code: 64 characters from a 31-symbol look-alike-free alphabet, rejection-sampled
  with `Random.secure()` — about **317 bits**.
- KDF: PBKDF2-HMAC-SHA256, **200,000 iterations**, 16-byte per-session salt, 32-byte key.
- Cipher: AES-256-GCM with a 12-byte nonce.
- Hostile-peer caps: 8 KB handshake line, 16 MB payload line, 100,000 records per category,
  64k character fields, 500 settings entries, 10s connect / 30s socket / 10min payload
  timeouts, one client at a time.
- App-lock PIN and recovery code stored only as `base64(salt):base64(PBKDF2 digest)`, checked
  with a constant-time compare. Recovery code is 12 characters, about 59 bits.
- The five Android permissions, each with its reason.

### Three real gaps found while writing it

These are recorded in `docs/security.md` §12 as open risks. **None is a live vulnerability**,
and none was fixed here — each needs its own plan.

1. **`android:allowBackup` is not set**, so Android's default of `true` applies. Recents,
   favorites, bookmarks, and settings can be included in a device backup. The
   `flutter_secure_storage` entries are encrypted under a Keystore key that does not leave the
   device, so backed-up secrets are not usable elsewhere. This is the one worth fixing first.
2. **R8 / ProGuard is not configured** for release builds. Low impact — Dart is AOT-compiled
   to native, so the Java surface is only the Flutter shim — but it is an unmade decision.
3. **Drafts have no age-based purge.** A draft is removed on save or discard only, so an
   abandoned document keeps a plain copy of its content in app-private storage.

### Changed

- `docs/security-rules.md` — its "full detail" pointer now goes to the new `security.md`
  rather than a section of `architecture.md`. The rules themselves are untouched.
- `CLAUDE.md` and `AGENTS.md` — `docs/security.md` added to the §2 docs table.

---

## 2. Group B1 — the constants registry

### What changed from the plan

The plan expected to move a few cross-cutting literals into `AppConstants`. On inspection
there were none worth moving: the two candidates I had in mind —
`LargeFilePolicy.largeThresholdBytes` and `EditorSettings.autoSaveChoices` — already sit with
the policy and the settings class that use them. Moving either would have separated a value
from its own logic, which is the exact problem the plan set out to avoid.

A scan also confirmed there are **no inline key literals anywhere**: all 27 persisted settings
keys are already named `static const String ...Key` constants on their owning class.

So B1 was implemented as the part that was a real gap: the namespace registry. Nothing was
moved.

### Created

**`lib/core/constants/app_constants.dart`** — values only, no logic, no imports:

- `SettingsNamespaces` — the seven namespaces in use (`appearance`, `editor`, `md.split`,
  `onboarding`, `security`, `tabs`, `tts`) plus an `all` set.
- `SecureStoreKeys.all` — the three secure-storage key strings, listed so the full set of
  persisted key strings is visible in one place. These stay declared on their owning classes;
  this is a registry, not a redefinition.
- A file-level comment stating the rule that most constants live next to their code, and why.

**`test/core/constants/app_constants_test.dart`** — five tests that make the registry
enforce something rather than just describe it. They scan the real `lib/` source, so a key
added in the future is covered automatically:

1. The scan finds the keys known to exist (guards the regex, so the others cannot pass
   vacuously).
2. Every settings key uses a registered namespace.
3. No settings key is declared in two different files.
4. No secure-store key collides with a settings key.
5. Every registered namespace is actually in use.

The first run of test 2 immediately caught two false positives —
`AppDatabase.defaultFileName = 'text_data.db'` and the registry's own `'md.split'` constant —
which showed the pattern was too loose. It now requires the Dart identifier to end in `Key`,
which is the project's actual convention for a persisted key.

### Changed

`docs/project_structure.md` — new **§10 "Where constants go"**: a table of what lives where,
and the settings-key rule (namespace registered first, key declared on the owning class,
enforced by the test).

---

## 3. Group C — large files answered, not split

No code was refactored, as approved.

`docs/project_structure.md` gained **§11 "Large files and why"** — a table naming all six
files over 500 lines with the reason each is that size, which answers the engineering
standard's "split or justify" rather than ignoring it.

It also records the safe path if a split is ever wanted:
`csv_document_session.dart` (956 lines) is the outlier and goes first, but **only after**
direct unit tests exist for its sort, filter, formula, and conditional-format behaviour —
then extract those four concerns one at a time. Direct session coverage is currently thin,
which is why the tests must come before the refactor.

---

## 4. Verification

| Check | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed lib test` | Clean — 375 files, 0 changed |
| `flutter analyze --no-pub` | **No issues found** |
| `flutter test` | **All 836 tests passed** (831 before + 5 new) |
| `third_party/` modified | 0 files |

---

## 5. Left open

- The three security gaps in `docs/security.md` §12 — `allowBackup`, R8, and draft purge.
  Recorded, not fixed. `allowBackup` is the one I would plan next.
- No integration test for a real two-device sync; it stays a manual pre-release check.
- Splitting the six large files, if it is ever wanted, on the terms in
  `docs/project_structure.md` §11.
