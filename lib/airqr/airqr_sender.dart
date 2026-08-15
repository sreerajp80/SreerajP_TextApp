// Phase 18 — Optical air-gap transfer (AirQR): the sending frame cycle.
//
// The camera link is one-way. The receiver cannot ask for a frame it missed, so
// the sender simply loops the whole set forever: a receiver that misses a frame
// on one pass picks it up on the next. That cyclic repetition is what replaces
// cross-frame erasure coding — see the plan for why a fountain code is not
// worth its complexity here.
//
// The order is reshuffled on every pass. See [AirqrSender.currentFrame] for why
// that is required rather than cosmetic.
//
// This class holds no timer. The provider owns the clock and calls [advance],
// which keeps the whole cycle synchronous and testable.
library;

import 'dart:math';

import 'package:text_data/airqr/airqr_codec.dart';

/// Walks an [AirqrEncoded] set round and round, reshuffling each pass.
class AirqrSender {
  final AirqrEncoded encoded;

  int _position = 0;
  int _pass = 0;

  /// The frame order for the current pass: a permutation of every index.
  late List<int> _order = _orderFor(0);

  AirqrSender(this.encoded);

  /// Frames in one full pass: the manifest plus every data frame.
  int get cycleLength => encoded.allFrames.length;

  /// The frame string to display right now.
  ///
  /// Each pass shows every frame exactly once, but in a freshly shuffled order.
  /// That shuffle is not decoration — it is what makes repetition actually
  /// recover dropped frames:
  ///
  ///   * With a fixed order, a camera dropping frames on a rhythm near the
  ///     cycle length misses the *same* frame every pass, forever.
  ///   * Pinning the manifest to slot 0 and rotating the rest just moved the
  ///     problem: a period-aligned dropper then starved the manifest.
  ///   * Rotating everything by one place per pass still fails whenever the
  ///     drop period divides the cycle length plus one — with a 16-frame cycle
  ///     and a drop every 3rd scan, the +1 shift cancels exactly and every
  ///     third frame is lost on every pass.
  ///
  /// A shuffle has no such arithmetic relationship to break against, so no drop
  /// rhythm can lock onto a frame. All three failures above are regression
  /// tests in `test/airqr/airqr_receiver_test.dart`.
  ///
  /// Because a permutation contains every index once, the manifest still
  /// appears exactly once per pass, so a receiver that starts late waits at
  /// most one cycle to learn what it is receiving.
  String get currentFrame => encoded.allFrames[_order[_position]];

  /// Where we are inside the current pass.
  int get position => _position;

  /// How many complete passes have finished. A receiver almost always needs
  /// more than one, so this is shown to reassure the user that looping is
  /// normal, not a stall.
  int get passesCompleted => _pass;

  /// Moves to the next frame, wrapping to a freshly shuffled pass.
  void advance() {
    _position++;
    if (_position >= cycleLength) {
      _position = 0;
      _pass++;
      _order = _orderFor(_pass);
    }
  }

  /// Back to the first frame of a fresh first pass.
  void reset() {
    _position = 0;
    _pass = 0;
    _order = _orderFor(0);
  }

  /// A deterministic shuffle of every frame index for [pass].
  ///
  /// Seeded by the pass number, so the sequence is reproducible in tests and
  /// costs one shuffle per pass rather than per frame. It carries no security
  /// weight — the payload's protection is AES-GCM, not frame order — so a
  /// plain [Random] is right here and `Random.secure()` would be misleading.
  List<int> _orderFor(int pass) {
    // Pass 0 stays in natural order so the manifest goes out first on the very
    // first pass, which is the common case: both people are already looking.
    final indices = [for (var i = 0; i < cycleLength; i++) i];
    if (pass == 0) return indices;
    return indices..shuffle(Random(pass));
  }
}
