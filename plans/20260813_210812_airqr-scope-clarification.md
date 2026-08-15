# Pin down the real scope of Feature 7 (Optical Air-Gap Transfer / AirQR)

**Status:** completed

Documentation-only change. No app code, no dependencies, no tests affected.

User approved the scope in conversation and asked for it to be implemented in the same turn.
Change log: `change_log/20260813_211530_airqr-scope-clarification.md`.

---

## 1. What the issue is

[docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) §3 Feature 7
describes the AirQR transfer engine as moving *"files or data snippets"* between two devices.
That phrase never says **what** is sent, and it leaves two real questions open:

### Question A — how much data can this actually move?

The doc gives no payload limit, and the app elsewhere claims 50 MB file support. A reader can
easily assume AirQR is a general file-transfer channel. It is not. Realistic throughput:

| Factor | Value |
| --- | --- |
| Dense QR frame (version 40, byte mode) | ~2.9 KB |
| Reed-Solomon chunk overhead + dropped frames | 30-40% loss |
| Reliable camera scan rate for an animated stream | ~8-12 frames per second |
| **Net usable throughput** | **~10-20 KB per second** |

So a 200 KB note takes about 15-20 seconds, a 2 MB CSV takes about 3 minutes, and a 50 MB
file takes over an hour. Bulk transfer is not viable. Without a written cap, this gets built
or estimated wrongly.

### Question B — "documents" is the wrong word for what this app holds

The doc's title says *"Document & Data Transfer"*, which implies the app has a document
library to send. It does not. `CLAUDE.md` §3 rule 3 makes the app **scoped-storage only** —
files are reached through the SAF picker and share intents, with no in-app file browser. The
app never owns the files it edits.

What the app actually stores is metadata, not documents:

| Store | Holds | Portable to another device? |
| --- | --- | --- |
| `RecentsRepository` | Recent file entries, as **SAF URIs** | **No** — a SAF URI plus its persisted permission grant is bound to the source device. |
| `FavoritesRepository` | Pinned file entries, also SAF URIs | **No** — same reason. |
| `BookmarksRepository` | In-document bookmarks keyed by content fingerprint | **Partly** — a fingerprint re-attaches if the receiving device opens the same content. |
| Drafts index + draft files | Crash-recovery copies of document text | Yes, but these are transient by design. |
| `shared_preferences` | Editor and app settings | Yes. |

That produces a concrete failure: a "send my recents and favorites" transfer would arrive on
the receiving device as a list of **dead links**. The receiving app cannot resolve another
device's SAF URIs. Anyone implementing Feature 7 from the current text could build exactly
that and only discover the problem at test time.

### Question C — overlap with LAN P2P sync is not stated

The app already has an encrypted LAN P2P subsystem, and Phase 17 line 210 plans
*"Direct Document File Payload Transfer"* over it. Feature 7 is not a replacement for that —
it is the fallback for sites where even LAN traffic is banned. The doc never says so, so the
two features read as competing.

---

## 2. The plan for the fix

Rewrite Feature 7 so it states its scope, its size cap, and its relationship to LAN sync.
Keep it a documentation change only — Feature 7 stays unimplemented and stays in Phase 18.

### 2.1 Define three transfer modes, in build order

1. **Snippet transfer** — the current selection, one CSV column, one JSON subtree, one XML
   element. Payloads of a few KB, near-instant. Lowest risk, ship first.
2. **Single-document transfer** — the active document's **content** is streamed; the
   receiving device saves it through **its own SAF picker**. This respects scoped storage,
   because the receiver chooses the destination and the sender's URI is never transmitted.
   Bookmarks for that document may ride along, since they are fingerprint-keyed and
   re-attach on the receiver.
3. **Settings and rules transfer** — editor settings, CSV conditional-format rules, saved
   JSONPath / XPath queries. Small, and free of the dead-URI problem.

### 2.2 State an explicit non-goal

No bulk "transfer everything" mode, and **no transfer of the recents or favorites lists**,
because SAF URIs do not resolve on the receiving device.

### 2.3 State a payload cap

Soft cap **256 KB** (transfers without comment). Hard warning above **1 MB**, showing the
estimated transfer time and offering LAN P2P sync instead. Refuse above **4 MB**.

### 2.4 State the LAN relationship

One line saying AirQR is the fallback when LAN is prohibited, and that Phase 17's direct
payload transfer over LAN remains the normal path for anything large.

---

## 3. Files to be changed

| File | Change |
| --- | --- |
| [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) | Rewrite the Feature 7 block (§3). Add transfer scope, non-goals, payload caps, and the LAN relationship. |
| [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) | §5 matrix row for AirQR — note the payload cap and drop "High" user impact to "Medium", since the honest scope is snippets and single documents, not bulk transfer. |
| [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) | §6 Phase 18 line — split the single AirQR bullet into the three modes so the build order is visible. |
| [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md) | §1 Ecosystem Synergy line 17 — add "small payloads" so the summary does not oversell it. |

No other file changes. No code, no `pubspec.yaml`, no `.arb` strings.

---

## 4. How this will be verified

- Re-read the edited sections and confirm the three modes, the non-goal, and the caps all
  appear and agree with each other.
- Confirm no absolute paths and no private information were introduced (workflow rule 3).
- No `flutter analyze` / `flutter test` run needed — no Dart source is touched.

---

## 5. Change log

To be written to `change_log/` on completion.
