// Phase 18 — Optical air-gap transfer (AirQR): every tunable and wire literal.
//
// Keeping these in one place keeps the sender and the receiver in lockstep (they
// must agree on the frame shape, the caps, and the crypto sizes) and makes the
// limits auditable at a glance. This mirrors `lib/sync/sync_constants.dart`.
//
// Nothing here is secret. The session code is generated at runtime with
// Random.secure() and is never stored here, never put in a frame, and never
// logged.
library;

import 'package:text_data/sync/sync_constants.dart';

/// All fixed values the AirQR engine shares between sender and receiver.
class AirqrConstants {
  AirqrConstants._();

  // --- Protocol -------------------------------------------------------------

  /// URI scheme for every frame. A foreign QR with a different scheme is
  /// rejected by the parser before anything else is read.
  static const String scheme = 'textdataqr';

  /// Host segment of a manifest frame (`textdataqr://m?...`). The manifest
  /// describes the transfer: how many frames, what kind, the salt, the digest.
  static const String hostManifest = 'm';

  /// Host segment of a data frame (`textdataqr://f?...`).
  static const String hostFrame = 'f';

  /// Frame format version. Bump when the frame shape changes in a way an older
  /// receiver cannot read.
  static const int protocolVersion = 1;

  // --- Frame query keys -----------------------------------------------------
  // Single letters on purpose: every byte spent on a key is a byte not spent on
  // payload, and the frame budget is small.

  static const String keyVersion = 'v';
  static const String keyIndex = 'i';
  static const String keyTotal = 'n';
  static const String keyData = 'd';
  static const String keyKind = 'k';
  static const String keySalt = 's';
  static const String keyDigest = 'h';
  static const String keyGzip = 'z';
  static const String keyEncrypted = 'e';
  // The file name and MIME type deliberately have NO manifest key. They live
  // inside the sealed envelope, so a bystander who scans the very first frame
  // learns the transfer's size but not what the file is called.

  // --- Frame budget ---------------------------------------------------------

  /// Payload bytes carried by one data frame, before base64url expansion.
  ///
  /// Deliberately conservative. A version-40 QR can hold ~2.9 KB, but a symbol
  /// that dense needs a good camera, good light, and a steady hand. ~1.1 KB
  /// lands around QR version 23 at error-correction level M, which scans
  /// reliably on cheap hardware — and a frame that never scans is infinitely
  /// slower than a smaller one that does.
  static const int frameChunkBytes = 1100;

  /// Smallest and largest chunk size the user may choose with the density
  /// slider.
  static const int minChunkBytes = 400;
  static const int maxChunkBytes = 2200;

  /// Default frames per second for the animation.
  ///
  /// Cameras need time to focus and expose. Past ~10 fps most phones start
  /// missing more frames than the extra rate wins back.
  static const int defaultFps = 5;
  static const int minFps = 2;
  static const int maxFps = 15;

  // --- Payload caps (validate before doing any work) ------------------------

  /// Under this size a transfer starts with no warning at all.
  static const int softCapBytes = 256 * 1024; // 256 KB

  /// Above this size the user gets an estimated time and an offer to use LAN
  /// sync instead.
  static const int warnCapBytes = 1024 * 1024; // 1 MB

  /// Above this size the transfer is refused. At the realistic ~10-20 KB/s of
  /// an optical link, 4 MB is already several minutes of holding two phones
  /// steady; beyond it the feature stops being honest.
  static const int hardCapBytes = 4 * 1024 * 1024; // 4 MB

  /// Most frames we will ever accept in one transfer. Guards a hostile manifest
  /// that claims a huge frame count to exhaust receiver memory.
  static const int maxFrames = 20000;

  /// Longest single scanned string we will even look at. A real frame is ~1.5 KB
  /// after base64; anything far larger is not ours.
  static const int maxRawFrameLength = 8 * 1024;

  /// Longest suggested file name we accept from a manifest.
  static const int maxNameLength = 255;

  // --- Session code ---------------------------------------------------------

  /// The alphabet for the session code. Deliberately the *same* one LAN sync
  /// uses, aliased rather than copied so the two can never drift apart: it is
  /// the project's single human-readable alphabet, with the look-alike
  /// characters `0 O 1 I L` excluded, because this code is read aloud or copied
  /// by hand between two people.
  static const String codeAlphabet = SyncConstants.codeAlphabet;

  /// Characters in the short session code.
  static const int shortCodeLength = 6;

  /// The stronger option, for a user who expects the stream to be recorded.
  static const int longCodeLength = 12;

  /// How many characters to group when displaying the code (`ABC-DEF`).
  static const int codeDisplayGroup = 3;

  // --- Payload kinds --------------------------------------------------------

  /// A piece of text taken from inside a document: a selection, a CSV column, a
  /// JSON subtree, an XML element.
  static const String kindSnippet = 'snippet';

  /// A whole document's content, to be saved by the receiver through its own
  /// SAF picker.
  static const String kindDocument = 'document';

  /// Every kind this version understands.
  static const List<String> allKinds = [kindSnippet, kindDocument];

  // --- Payload envelope keys ------------------------------------------------

  static const String envelopeApp = 'app';
  static const String envelopeVersion = 'payloadVersion';
  static const String envelopeKind = 'kind';
  static const String envelopeName = 'name';
  static const String envelopeMime = 'mime';
  static const String envelopeContent = 'content';

  /// Value of the `app` field. Lets a receiver reject a payload from another
  /// app even though the optical transport itself is app-agnostic.
  static const String appId = 'text_data';

  /// Payload envelope version, independent of the frame [protocolVersion].
  static const int payloadVersion = 1;

  // --- Throughput estimate --------------------------------------------------

  /// Bytes per second we assume when telling the user how long a transfer will
  /// take. Measured-in-practice figure for an optical link, not a theoretical
  /// maximum — it already allows for dropped frames and repeat passes.
  static const int estimatedBytesPerSecond = 15 * 1024;
}
