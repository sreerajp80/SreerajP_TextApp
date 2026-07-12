# Plan — Phase 14: Testing & release

**Status:** in_progress

Implements Phase 14 of [implementation-plan.md](../docs/implementation-plan.md)
(`14.1` complete the automated suite, `14.2` manual two-device sync verification,
`14.3` release prep). Tracks in [implementation-progress.md](../docs/implementation-progress.md).

---

## 1. What this phase is

Phase 14 is the final phase. It does **not** add features. It:

1. Finishes and audits the automated test suite (arch §12).
2. Verifies a real two-device LAN sync (the release gate).
3. Prepares the release build.

## 2. Current state (already found)

- `flutter test` is **green — 534 tests pass** today.
- Test folders already cover every area the plan's 14.1 acceptance names: sync
  (`test/sync/` — crypto round-trip + wrong key, transport happy/wrong-code/
  send-with-no-client, payload caps + merge), all five parsers with failure-path
  tests (`test/formats/**`), editor (atomic save, encoding/line-ending, find &
  replace, draft recovery, unsaved changes under `test/core/editor/` +
  `test/shell/`), and config + syncable-settings (`test/core/config/`,
  `test/sync/sync_share_prefs_test.dart`).
- Release signing is already wired (Phase 13.1): `android/app/build.gradle.kts`
  reads a gitignored `android/key.properties`, debug-fallback if absent;
  `key.properties.example` + `docs/release-signing.md` exist.
- One physical device is connected: **moto g54 5G, Android 15 (API 35)**.
- `pubspec.yaml` = `1.0.0+1`; `assets/config/app_config.json` = version `1.0.0`,
  build `1` — they match. Permissions in the manifest: INTERNET,
  ACCESS_NETWORK_STATE, ACCESS_WIFI_STATE, CAMERA, USE_BIOMETRIC.

So the bulk of 14.1 is already met. The remaining work is **audit, close any
real gaps, produce a coverage report, do the manual runs, and record results.**

## 3. The issue / what is missing

1. **14.1** — no explicit coverage report has been produced, and the acceptance
   list has never been checked item-by-item against the suite to confirm no gap.
2. **14.2** — the real two-device LAN transfer has never been run. It **needs a
   second device** and cannot be done from one phone. It is currently `⬜`.
3. **14.3** — no release build has been produced/installed/smoke-tested; the
   README and About accuracy have not been signed off; permissions have not been
   formally reviewed for least-privilege.
4. Loose end flagged in Phase 11.5 / 13: `syncableSettingKeys` are un-namespaced
   and do not match the app's namespaced keys, so settings-sync exports nothing.
   Phase 14 is the place to either fix or consciously accept this. **Proposed:
   document it as a known limit in the change log (no behavior change), because a
   fix touches sync payload semantics and is out of a "testing & release" phase.**

## 4. Plan of work

### 14.1 — Complete + audit the automated suite
- Run `flutter test --coverage` to generate `coverage/lcov.info`; summarize
  line coverage for `lib/core/` and `lib/sync/` (parse the lcov file with a small
  throwaway script — no new tooling needed).
- Walk the 14.1 acceptance checklist against the existing tests; for any genuine
  gap found, add a focused test in the right folder. (Expectation from the survey:
  few or none — this is mostly verification.)
- Record the coverage numbers and the checklist result in the change log.

### 14.2 — Manual two-device sync verification
- **Needs a second Android device on the same Wi-Fi/LAN.** With one device I
  cannot complete this gate.
- If a second device is available: install the app on both, run Send on one /
  Receive on the other (QR scan + manual code), confirm the added/kept/applied
  summary, and record the run (devices, categories, counts, result) in the
  change log. Mark 14.2 ✅.
- If not: build + install on the one device so it is ready, keep 14.2 as `⛔
  Blocked — needs a second device`, and note it as the one remaining release gate.

### 14.3 — Release prep
- Confirm version/build flow from `app_config.json` (already matches pubspec);
  no change unless a bump is requested.
- **Permissions review (least-privilege):** write a short table justifying each
  of the 5 manifest permissions; confirm no broad storage permission (CLAUDE.md
  §3.3). Remove any that are not needed (none expected).
- **Release build:** run `flutter build apk --release`.
  - If the user has created `android/key.properties` + keystore → real signed
    release. (The AI does **not** generate the keystore or passwords — Phase 13
    rule; the user runs `keytool` per `docs/release-signing.md`.)
  - If not → the build debug-signs via the existing fallback; usable for the
    on-device smoke test but **not** a distributable signed release. That will
    stay owed until the user provides the keystore.
- Install the release build on the moto g54 and **smoke-test each format** (open
  a TXT, MD, CSV, JSON, XML via SAF; view; a small edit + save; share/export
  once). Record the result.
- Verify README + About screen values are accurate (About already reads
  `app_config.json`; check the README exists and matches).

## 5. Files to change

- `docs/implementation-progress.md` — flip Phase 14 task statuses + summary table.
- `change_log/20260712_*_phase-14-testing-release.md` — new change log (results,
  coverage numbers, permissions table, manual-run records).
- `test/**` — only if the 14.1 audit finds a real gap (add focused tests). No
  wholesale test rewrite.
- `assets/config/app_config.json` / `pubspec.yaml` — only if a version bump is
  requested (default: no change).
- Possibly `README.md` — only if it is missing or inaccurate.

No product/source (`lib/`) behavior changes are planned; this is a
verification-and-release phase.

## 6. How we know it is done

- 14.1: `flutter test` green (already), coverage report captured, checklist
  signed off.
- 14.2: recorded two-device transfer succeeds (or explicitly blocked on a second
  device, clearly noted).
- 14.3: release build installs on minSdk 26 device and each format smoke-tests
  clean; permissions reviewed; About/README accurate.

## 7. Decisions (from the user)

1. **Second device for 14.2** — the user **has** a second Android device and is
   getting it ready. 14.2 will be run **live** once it is on the LAN. I must
   **wait** for the device before that step.
2. **Release keystore for 14.3** — **debug-signed smoke test this round.** No
   keystore yet, so the release build falls back to debug signing (already wired
   in `build.gradle.kts`). Good for install + smoke test + the two-device sync
   test. A distributable *signed* release stays owed until the user runs
   `keytool` per `docs/release-signing.md`.
3. **Version** — **bump to `1.1.0+2`.** Update `pubspec.yaml`
   (`version: 1.1.0+2`) and `assets/config/app_config.json`
   (`version: "1.1.0"`, `build: "2"`); confirm they cross-check.

## 8. Order of work (given the wait)

1. While waiting for the device: **14.1** (coverage report + checklist audit) and
   the non-device parts of **14.3** (version bump, permissions review, release
   build, README/About check).
2. Install the release build on both devices.
3. When the second device is ready: run **14.2** live, record the transfer.
4. Update progress + write the change log.
