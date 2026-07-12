/// The languages the app can read content aloud in (task 5.5).
///
/// English works out of the box; Malayalam sits behind a guided-install flow
/// because its `ml-IN` voice is often not present on a device.
enum TtsLanguage {
  english('en-US', 'English'),
  malayalam('ml-IN', 'Malayalam');

  final String code;
  final String label;

  const TtsLanguage(this.code, this.label);
}

/// Whether a language can be spoken right now (task 5.5).
///
/// A reader screen asks the [TtsService] for this and never shows a dead
/// button (idea Risks): `ready` → offer speak; `needsInstall` → offer the
/// guided install; `unavailable` → hide the control.
enum TtsAvailability {
  /// The engine and the language's voice are present — safe to speak.
  ready,

  /// A TTS engine exists but this language's voice is missing; the user can be
  /// guided to install it.
  needsInstall,

  /// No usable TTS engine at all; the feature is hidden.
  unavailable,
}
