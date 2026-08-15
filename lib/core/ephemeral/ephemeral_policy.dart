import 'package:text_data/core/ephemeral/ephemeral_models.dart';

/// The pure timing rules behind an ephemeral tab (Feature 9).
///
/// Kept free of Flutter, Riverpod, and I/O so every edge — the expiry boundary,
/// a clock that jumps backwards, badge formatting — is unit-testable without a
/// widget tree or a real timer.
class EphemeralPolicy {
  const EphemeralPolicy._();

  /// Time left before [mark] burns, given the current wall clock [nowMillis].
  ///
  /// Returns null when the mark has no timer (burn-after-output only), and
  /// [Duration.zero] when it is already due. Never returns a negative value, so
  /// a device clock that moves backwards can only ever make a tab live longer —
  /// it can never make the badge count upwards.
  static Duration? remaining(EphemeralMark mark, int nowMillis) {
    final expiry = mark.expiresAtMillis;
    if (expiry == null) return null;
    final left = expiry - nowMillis;
    return left <= 0 ? Duration.zero : Duration(milliseconds: left);
  }

  /// True when [mark] has a timer that has run out.
  static bool isExpired(EphemeralMark mark, int nowMillis) {
    final expiry = mark.expiresAtMillis;
    if (expiry == null) return false;
    return nowMillis >= expiry;
  }

  /// The marks in [marks] that are due to burn now.
  static List<EphemeralMark> expired(
    Iterable<EphemeralMark> marks,
    int nowMillis,
  ) {
    return marks.where((m) => isExpired(m, nowMillis)).toList(growable: false);
  }

  /// Text for the countdown badge on a tab chip.
  ///
  /// Under an hour it counts `m:ss` so the last minute is readable at a glance;
  /// an hour or more it shows `Xh Ym`, which is all the precision that is
  /// useful at that range. Returns an empty string when there is no timer.
  static String formatRemaining(Duration? left) {
    if (left == null) return '';
    if (left.inHours >= 1) {
      final hours = left.inHours;
      final minutes = left.inMinutes % 60;
      return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
    }
    final minutes = left.inMinutes;
    final seconds = left.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// True when the badge should switch to the warning colour — the last minute.
  static bool isUrgent(Duration? left) {
    if (left == null) return false;
    return left.inSeconds <= 60;
  }

  /// The expiry stamp for a fresh mark, or null when [option] has no timer.
  static int? expiryFor(EphemeralOption option, int nowMillis) {
    final lifetime = option.lifetime;
    if (lifetime == null) return null;
    return nowMillis + lifetime.inMilliseconds;
  }
}
