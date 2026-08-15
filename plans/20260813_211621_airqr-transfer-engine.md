# Build the Optical Air-Gap Transfer Engine (AirQR) — Steps 1 and 2

**Status:** completed

Approved by the user on 2026-08-13, with the §3.3 recommendation chosen: encryption on by
default with a 6-character session code (12-character option available).

Change log: `change_log/20260813_215145_airqr-transfer-engine.md`.

One design change during implementation: the cyclic repetition in §3.1 had to **reshuffle the
frame order on every pass**. A fixed order (and two simpler shift variants) each starved
against a periodic frame dropper. See the change log §2 and the regression tests.

Implements Feature 7 from [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) §3,
scoped by `plans/20260813_080812_airqr-scope-clarification.md`.

This plan covers **Step 1 (snippet transfer)** and **Step 2 (single-document transfer)**.
Step 3 (settings & rules transfer) is deliberately left for a follow-up plan — see §8.

---

## 1. What the issue is

Feature 7 is documented but not built. There is no way to move a document or a snippet
between two devices when LAN traffic is prohibited. The existing P2P sync subsystem covers
the LAN case only, and it moves records (favorites, bookmarks, recents), not document text.

---

## 2. What already exists that we reuse

This feature needs **no new dependencies**. Everything is already in the project:

| Need | Already present | Where |
| --- | --- | --- |
| Render a QR | `qr_flutter: ^4.1.0` | `pubspec.yaml` line 64 |
| Scan a QR | `mobile_scanner: ^7.2.0` | `pubspec.yaml` line 65 |
| Camera permission | `android.permission.CAMERA` | `android/app/src/main/AndroidManifest.xml` |
| AES-256-GCM + PBKDF2 | `SyncCrypto.deriveKey` / `encryptWire` / `decryptWire` | `lib/sync/sync_crypto.dart` |
| Secure randomness | `SyncCrypto.randomBytes`, `generatePairingCode` | `lib/sync/sync_crypto.dart` |
| Compression | `gzip` from `dart:io` | Dart SDK |
| Checksum | `crypto: ^3.0.7` (SHA-256) | `pubspec.yaml` line 46 |
| Save received file | `SafService` + the SAF create-document flow | `lib/shell/create_document_action.dart` |

So `pubspec.yaml` is **not** modified by this plan.

---

## 3. Three engineering decisions that need a decision from you

### 3.1 Reed-Solomon is the wrong tool — use cyclic repetition instead

The roadmap says *"Reed-Solomon error correction to handle dropped frames"*. This conflates
two different layers:

- **A QR symbol already contains Reed-Solomon ECC.** That is exactly what error-correction
  level L/M/Q/H is. It repairs a *damaged* frame — glare, blur, a finger over a corner.
- **A dropped frame is an erasure, not damage.** Nothing inside a single QR can recover a
  frame the camera never saw. That needs cross-frame erasure coding — a fountain code
  (LT / Raptor) — which is a large, subtle piece of maths with no vetted open-source Dart
  implementation, so we would be writing and self-certifying GF(256) code.

**Recommendation: cyclic repetition.** The sender loops the frame sequence forever. The
receiver keeps a set of frames it already has and picks up stragglers on the next pass. It is
about 40 lines, has no new dependency, is trivially testable, and self-heals — the user just
keeps holding the camera up. A fountain code would cut the number of passes but is a poor
trade for v1.

We keep QR-level ECC at **level M** (recovers ~15% of a damaged symbol), which is the part of
"Reed-Solomon" that genuinely helps.

If you approve this, §7 also updates the roadmap wording so the doc stops promising
frame-level Reed-Solomon.

### 3.2 Compress before chunking

gzip the payload before splitting it into frames. Plain text, JSON, CSV, and Markdown
typically compress 3-5x, which multiplies effective throughput by the same factor. A 200 KB
Markdown note becomes roughly 50 KB, so the transfer drops from ~20 seconds to ~5. This is
the single biggest speed win available and costs one `dart:io` call each way.

### 3.3 Encryption: on by default, with a short code

A QR stream is displayed openly on a screen. Anyone in the room with a camera can record it.
For a feature whose stated purpose is *"high-security field environments"*, sending plaintext
would be wrong.

**Recommendation:** seal every frame's payload with AES-256-GCM, reusing `SyncCrypto`
unchanged. The sender shows a **6-character code** from the existing look-alike-free alphabet
(`SyncConstants.codeAlphabet`); the user reads it aloud or types it into the receiver. Key
derivation is the existing PBKDF2-HMAC-SHA256 at 200,000 iterations, with a random salt
carried in the manifest frame (a salt is not secret — same model as `lib/sync/`).

A 6-character code is ~30 bits. That is weak against an offline brute-force *if* an attacker
records the whole stream. It is strong against the realistic threat (a bystander glancing at
one frame). The user can switch to a 12-character code for a stronger guarantee, and the UI
will say plainly what the short code does and does not protect against.

**Alternative if you prefer simplicity:** no encryption, with a clear on-screen warning that
the stream is readable by anyone who can see the display. I do not recommend it.

---

## 4. Files to be created

New module `lib/airqr/`, mirroring the structure and conventions of `lib/sync/`.

| File | Purpose | Rough size |
| --- | --- | --- |
| `lib/airqr/airqr_constants.dart` | Every tunable and wire literal in one place: frame byte budget, frames per second, payload caps, scheme, protocol version, payload-kind keys. Mirrors `sync_constants.dart`. | ~120 |
| `lib/airqr/airqr_payload.dart` | The payload envelope — kind (`snippet` / `document`), suggested file name, MIME type, content, plus strict validation and user-safe rejection of a malformed envelope. | ~150 |
| `lib/airqr/airqr_codec.dart` | Pure codec. Encode: gzip → optional AES-GCM seal → split into chunks → build one manifest frame + N data frames, each with an index, a total, and a SHA-256 of the whole payload. Decode: parse a frame, reject foreign or version-mismatched frames with a user-safe message. **No Flutter import.** | ~220 |
| `lib/airqr/airqr_sender.dart` | Drives the frame cycle: current frame index, advance, loop. Holds no timer itself so it stays testable. | ~90 |
| `lib/airqr/airqr_receiver.dart` | Collects frames, ignores duplicates, tracks which indexes are still missing, reassembles when complete, verifies the SHA-256, and reports progress (`received / total`, elapsed, estimated remaining). | ~200 |
| `lib/airqr/airqr_provider.dart` | Riverpod controllers for send and receive, following `sync_provider.dart` (a `ChangeNotifier` behind a `Provider`, phase enum, user-safe `errorMessage`). Owns the frame `Timer`. | ~220 |
| `lib/airqr/ui/airqr_landing_screen.dart` | Send / Receive chooser, matching `sync_landing_screen.dart`. | ~70 |
| `lib/airqr/ui/airqr_send_screen.dart` | Shows the animated QR, the session code, a frames/second slider, a pass counter, and a "hold steady" hint. Keeps the screen awake while sending. | ~230 |
| `lib/airqr/ui/airqr_receive_screen.dart` | `MobileScanner` plus a live progress bar (frames captured of total, FPS, checksum state), then the save/apply step. | ~250 |
| `lib/airqr/ui/airqr_size_warning.dart` | The cap dialog: transfers silently under 256 KB, warns with an estimated time above 1 MB and offers LAN sync instead, refuses above 4 MB. | ~110 |

### Tests to be created (mirroring `test/sync/`)

| File | Covers |
| --- | --- |
| `test/airqr/airqr_codec_test.dart` | Round trip; gzip round trip; sealed round trip; wrong code fails the GCM tag; foreign frame rejected; version mismatch rejected; truncated / corrupt frame rejected without throwing to the UI. |
| `test/airqr/airqr_receiver_test.dart` | **Dropped-frame recovery via a second pass** (the core claim of §3.1); duplicate frames ignored; out-of-order arrival; checksum mismatch reported; frame count mismatch reported. |
| `test/airqr/airqr_payload_test.dart` | Envelope validation; oversize rejection at each cap; empty and malformed envelopes. |
| `test/airqr/no_secret_logging_test.dart` | Mirrors `test/sync/no_secret_logging_test.dart` — asserts the module never logs the session code, the derived key, the salt, or payload content. |

---

## 5. Files to be modified

| File | Change |
| --- | --- |
| `lib/shell/settings/sections/sync_section.dart` | Add an "Air-gap transfer (QR)" entry next to the existing LAN sync entry, opening `AirqrLandingScreen`. |
| `lib/core/editor/editor_selection_toolbar.dart` | Add a "Send by QR" action for the current selection (Step 1, snippet transfer). |
| `lib/shell/tabs/tab_strip.dart` *(or the document overflow menu it feeds)* | Add "Send this document by QR" (Step 2). Exact host confirmed during implementation — it goes wherever the existing per-document Share action lives. |
| `lib/l10n/app_en.arb` | ~45 new strings (screen titles, progress, warnings, errors, the security note about the short code). |
| `lib/l10n/app_ml.arb` | The same keys in Malayalam. |
| `docs/architecture.md` | New section documenting the AirQR module, its frame format, and its trust model. |
| `docs/security-rules.md` | Short subsection: the shoulder-surfing threat, why the code is out of band, and the rule that frame content is never logged. |
| `docs/project_structure.md` | Add `lib/airqr/` to the layout. |
| `docs/feature_analysis_and_roadmap.md` | §3 Feature 7 — replace the frame-level Reed-Solomon claim per §3.1; tick Steps 1 and 2 in Phase 18. |

**Not modified:** `pubspec.yaml` (no new dependency), `AndroidManifest.xml` (CAMERA already
granted), any format parser, any storage repository.

---

## 6. Frame format

Each frame is one QR carrying a compact URI, kept short so the symbol stays low-density and
scans reliably on a cheap camera:

```
textdataqr://f?v=1&i=<index>&n=<total>&d=<base64url chunk>
```

The manifest frame is index `0`:

```
textdataqr://m?v=1&n=<total>&k=<kind>&s=<base64url salt>&h=<sha256 of payload>&z=1&e=1
```

`z=1` marks gzip, `e=1` marks encrypted. Both are read by the receiver rather than assumed,
so an unencrypted or uncompressed stream still decodes.

Defaults: **~1.1 KB of payload per frame** (QR version ~23 at ECC level M) at **5 frames per
second**. These are conservative on purpose — dense version-40 frames at 15 fps fail on many
phone cameras. Both are exposed as a slider so a user with two good devices can push higher.

---

## 7. Order of work

1. `airqr_constants.dart`, `airqr_payload.dart`, `airqr_codec.dart` + their tests. Pure Dart,
   no UI, fully testable.
2. `airqr_receiver.dart`, `airqr_sender.dart` + tests, including the dropped-frame pass.
3. `airqr_provider.dart`.
4. The three UI screens and the size-warning dialog.
5. Entry points: settings section, selection toolbar, document menu.
6. `.arb` strings (English, then Malayalam).
7. Docs.
8. `dart format lib test`, `flutter analyze` to zero, `flutter test`.

---

## 8. Explicitly out of scope

- **Step 3, settings & rules transfer** — separate follow-up plan.
- **Bulk workspace transfer, and transfer of the recents / favorites lists.** Ruled out in
  the scope plan: those are SAF URIs and do not resolve on the receiving device.
- **A fountain code.** See §3.1. Revisit only if repetition proves too slow in real use.
- **Two-way / acknowledged transfer.** The camera link is one-way by nature. The receiver
  cannot ask for a specific missing frame, which is exactly why the sender loops.

---

## 9. Verification

- `flutter analyze` at zero issues; `dart format lib test` clean; `flutter test` green.
- Codec and receiver behaviour, including dropped frames, are covered by unit tests with no
  device needed.
- **A real two-device transfer must be checked by hand before release** — same rule the
  project already applies to LAN sync (`CLAUDE.md` §10). Unit tests cannot prove that a real
  camera reads the chosen frame density at the chosen frame rate.

---

## 10. Change log

To be written to `change_log/` on completion.
