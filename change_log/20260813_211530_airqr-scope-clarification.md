# Feature 7 (AirQR) scope, payload caps, and non-goals written into the roadmap

Implements plan `plans/20260813_080812_airqr-scope-clarification.md`.

Documentation only. No app code, dependencies, strings, or tests were touched.

---

## Why

The roadmap described Feature 7 as moving *"files or data snippets"*, which never said what is
actually sent. Two problems followed from that:

1. **No size limit was written down.** QR streams move roughly 10-20 KB per second in real
   conditions, so the app's stated 50 MB file ceiling would take over an hour. Anyone reading
   the old text could reasonably have planned a general file-transfer channel.
2. **The app has no document library to transfer.** It is scoped-storage only, so recents and
   favorites are stored as **SAF URIs**, which are bound to the device that granted them. A
   "send my file list" transfer would have arrived on the other device as dead links — a bug
   that would only have surfaced during testing.

---

## What changed

All changes are in [docs/feature_analysis_and_roadmap.md](../docs/feature_analysis_and_roadmap.md).

### 1. §3 Feature 7 block — rewritten

Added four new subsections under the existing concept and inspiration lines:

- **What is transferred (build order)** — three modes, ordered by risk:
  1. Snippet transfer (selection, CSV column, JSON subtree, XML element).
  2. Single-document transfer, where the **receiver** saves through its own SAF picker so the
     sender's URI is never sent. Fingerprint-keyed bookmarks may travel with the document.
  3. Settings and rules transfer.
- **Explicit non-goals** — no bulk workspace transfer, and no transfer of the recents or
  favorites lists, with the SAF URI reason stated.
- **Payload limits** — the throughput derivation plus a table of realistic transfer times, and
  the enforced caps: 256 KB soft, 1 MB warning, 4 MB refusal.
- **Relationship to LAN P2P sync** — AirQR is the fallback for sites where LAN is banned, not a
  replacement for Phase 17's direct payload transfer.

The original concept line now says "small payloads" instead of "files or data snippets".

### 2. §5 prioritization matrix

The AirQR row now carries the scope and caps in its name, and its **User Impact dropped from
High to Medium**, matching the honest scope of snippets and single documents.

### 3. §6 Phase 18 roadmap

The single AirQR bullet became a parent bullet with three ordered sub-steps, plus a fourth line
recording what is excluded by design.

### 4. §1 Ecosystem Synergy summary

The one-line AirQR entry now says "small payloads (snippets and single documents, not bulk file
transfer)" so the executive summary does not oversell the feature.

---

## Status of the feature itself

Feature 7 remains **unimplemented** and stays in Phase 18. This change only fixes what the
document promises. No `mobile_scanner` or `qr_flutter` dependency was added.

---

## Verification

- Re-read the four edited sections; the three modes, the non-goals, and the caps agree with
  each other and with the matrix and roadmap entries.
- No absolute paths and no private information were introduced (workflow rule 3).
- `flutter analyze` and `flutter test` were not run, and were not needed — no Dart source,
  manifest, or dependency file was modified.
