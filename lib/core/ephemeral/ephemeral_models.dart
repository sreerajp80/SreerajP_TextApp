/// How long an ephemeral tab lives before it burns itself (Feature 9).
enum EphemeralDuration {
  fifteenMinutes(minutes: 15),
  oneHour(minutes: 60),
  fourHours(minutes: 240),
  twentyFourHours(minutes: 1440),

  /// No timer at all. Used with "burn after export", or when the user wants to
  /// burn the tab by hand.
  none(minutes: 0),

  /// A user-entered number of minutes; the real value rides in
  /// [EphemeralOption.customMinutes].
  custom(minutes: 0);

  final int minutes;

  const EphemeralDuration({required this.minutes});

  /// Stable value written to settings. Never change these strings.
  String get prefValue => name;

  static EphemeralDuration fromPrefValue(String? value) {
    for (final d in EphemeralDuration.values) {
      if (d.prefValue == value) return d;
    }
    return EphemeralDuration.oneHour;
  }
}

/// What the user chose in the "make this tab ephemeral" sheet.
class EphemeralOption {
  final EphemeralDuration duration;

  /// Minutes for [EphemeralDuration.custom]; ignored otherwise.
  final int customMinutes;

  /// Burn on the first successful export, share, or print of this document.
  final bool burnAfterOutput;

  const EphemeralOption({
    this.duration = EphemeralDuration.oneHour,
    this.customMinutes = 30,
    this.burnAfterOutput = false,
  });

  /// The effective lifetime, or null when there is no timer.
  Duration? get lifetime {
    final minutes = switch (duration) {
      EphemeralDuration.none => 0,
      EphemeralDuration.custom => customMinutes,
      _ => duration.minutes,
    };
    if (minutes <= 0) return null;
    return Duration(minutes: minutes);
  }

  /// True when this option would do nothing at all — no timer and no burn on
  /// output. The sheet refuses to apply such a choice.
  bool get isNoOp => lifetime == null && !burnAfterOutput;

  EphemeralOption copyWith({
    EphemeralDuration? duration,
    int? customMinutes,
    bool? burnAfterOutput,
  }) {
    return EphemeralOption(
      duration: duration ?? this.duration,
      customMinutes: customMinutes ?? this.customMinutes,
      burnAfterOutput: burnAfterOutput ?? this.burnAfterOutput,
    );
  }
}

/// One tab currently marked ephemeral.
///
/// Held only in memory by `EphemeralController` and never persisted: a mark
/// that survived a restart would be a trace of exactly the document the user
/// asked the app to forget.
class EphemeralMark {
  final String tabId;
  final String fingerprint;
  final String displayName;

  /// Wall-clock epoch millis when this tab burns, or null for no timer.
  final int? expiresAtMillis;

  /// Burn on the first successful export, share, or print.
  final bool burnAfterOutput;

  const EphemeralMark({
    required this.tabId,
    required this.fingerprint,
    required this.displayName,
    this.expiresAtMillis,
    this.burnAfterOutput = false,
  });

  bool get hasTimer => expiresAtMillis != null;

  EphemeralMark copyWith({int? expiresAtMillis, bool? burnAfterOutput}) {
    return EphemeralMark(
      tabId: tabId,
      fingerprint: fingerprint,
      displayName: displayName,
      expiresAtMillis: expiresAtMillis ?? this.expiresAtMillis,
      burnAfterOutput: burnAfterOutput ?? this.burnAfterOutput,
    );
  }
}
