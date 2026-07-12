/// The one place that lists the selectable fonts, so the settings UI and the
/// theme never drift apart or hard-code family strings (CLAUDE.md §5).
///
/// A `null` value means "platform default" (no bundled family forced). The
/// family strings must match the `family:` names declared in `pubspec.yaml`.
///
/// English faces are Latin-only; Malayalam text is rendered by whichever
/// Malayalam face the user picks, applied as a font fallback everywhere (see
/// [AppThemes] and the editor surfaces). All fonts here are open source (OFL /
/// OFL+GPL) — see `fonts/README.md`.
class AppFonts {
  const AppFonts._();

  /// English (Latin) choices: menu label -> family name (`null` = default).
  static const Map<String, String?> english = {
    'Default': null,
    'Inter': 'Inter',
    'Lora': 'Lora',
    'JetBrains Mono': 'JetBrains Mono',
  };

  /// Malayalam choices: menu label -> family name (`null` = default).
  static const Map<String, String?> malayalam = {
    'Default': null,
    'Manjari': 'Manjari',
    'Rachana': 'Rachana',
    'Noto Sans Malayalam': 'Noto Sans Malayalam',
  };

  /// The fallback family list to apply so Malayalam text renders in the chosen
  /// Malayalam face. Returns `null` when no Malayalam font is chosen, so the
  /// platform fallback chain is left untouched.
  static List<String>? malayalamFallback(String? malayalamFamily) =>
      (malayalamFamily == null || malayalamFamily.isEmpty)
      ? null
      : [malayalamFamily];

  /// Maps a stored family back to its menu label (falls back to `Default` for
  /// an unknown or cleared value), for showing the current dropdown selection.
  static String labelFor(Map<String, String?> choices, String? family) {
    for (final entry in choices.entries) {
      if (entry.value == family) return entry.key;
    }
    return 'Default';
  }
}
