import 'encoding.dart';

/// How the editor picks the **line ending** when it saves a file.
///
/// [preserve] keeps whatever the file already used (the safe default). The other
/// values force a chosen style for new saves; the user can still override it per
/// document from the line-ending chooser.
enum LineEndingDefault {
  preserve,
  lf,
  crlf;

  String get label {
    switch (this) {
      case LineEndingDefault.preserve:
        return 'Preserve';
      case LineEndingDefault.lf:
        return 'LF (Unix)';
      case LineEndingDefault.crlf:
        return 'CRLF (Windows)';
    }
  }

  String get prefValue => name;

  static LineEndingDefault fromPrefValue(String? value) {
    for (final v in LineEndingDefault.values) {
      if (v.prefValue == value) return v;
    }
    return LineEndingDefault.preserve;
  }

  /// The concrete [LineEndingStyle] to save with, given the file's detected
  /// style. Returns `null` for [preserve] (keep the detected one).
  LineEndingStyle? resolve() {
    switch (this) {
      case LineEndingDefault.preserve:
        return null;
      case LineEndingDefault.lf:
        return LineEndingStyle.lf;
      case LineEndingDefault.crlf:
        return LineEndingStyle.crlf;
    }
  }
}

/// How the editor picks the **encoding** when it saves a file.
///
/// [preserve] keeps the encoding detected on open (the safe default). The others
/// force a chosen encoding for new saves; still overridable per document.
enum EncodingDefault {
  preserve,
  utf8,
  utf8Bom;

  String get label {
    switch (this) {
      case EncodingDefault.preserve:
        return 'Preserve';
      case EncodingDefault.utf8:
        return 'UTF-8';
      case EncodingDefault.utf8Bom:
        return 'UTF-8 with BOM';
    }
  }

  String get prefValue => name;

  static EncodingDefault fromPrefValue(String? value) {
    for (final v in EncodingDefault.values) {
      if (v.prefValue == value) return v;
    }
    return EncodingDefault.preserve;
  }

  /// The concrete [TextEncodingType] to save with. Returns `null` for [preserve]
  /// (keep the detected one).
  TextEncodingType? resolve() {
    switch (this) {
      case EncodingDefault.preserve:
        return null;
      case EncodingDefault.utf8:
        return TextEncodingType.utf8;
      case EncodingDefault.utf8Bom:
        return TextEncodingType.utf8Bom;
    }
  }
}

/// All editor preferences, in one immutable value (architecture.md §8, task
/// 11.2). Held by the `EditorSettingsController`, hydrated from and saved to the
/// settings store.
///
/// [autoSaveSeconds] is the draft auto-save interval; `0` turns auto-save off.
class EditorSettings {
  final LineEndingDefault lineEndingDefault;
  final EncodingDefault encodingDefault;
  final bool confirmOverwrite;
  final int autoSaveSeconds;
  final bool openReadOnlyByDefault;

  const EditorSettings({
    this.lineEndingDefault = LineEndingDefault.preserve,
    this.encodingDefault = EncodingDefault.preserve,
    this.confirmOverwrite = true,
    this.autoSaveSeconds = defaultAutoSaveSeconds,
    this.openReadOnlyByDefault = false,
  });

  /// The default editor behavior before anything is saved, and the safe fallback
  /// if a stored value is missing or out of range.
  static const EditorSettings defaults = EditorSettings();

  /// Default draft auto-save interval, in seconds.
  static const int defaultAutoSaveSeconds = 5;

  /// The interval choices offered in Settings (`0` = off).
  static const List<int> autoSaveChoices = [0, 2, 5, 10, 30];

  // Preference keys (non-sensitive; live in shared_preferences).
  static const String lineEndingKey = 'editor.line_ending_default';
  static const String encodingKey = 'editor.encoding_default';
  static const String confirmOverwriteKey = 'editor.confirm_overwrite';
  static const String autoSaveSecondsKey = 'editor.autosave_seconds';
  static const String readOnlyDefaultKey = 'editor.read_only_default';

  /// The auto-save interval as a [Duration]; `Duration.zero` means "off".
  Duration get autoSaveInterval => Duration(seconds: autoSaveSeconds);

  bool get autoSaveEnabled => autoSaveSeconds > 0;

  EditorSettings copyWith({
    LineEndingDefault? lineEndingDefault,
    EncodingDefault? encodingDefault,
    bool? confirmOverwrite,
    int? autoSaveSeconds,
    bool? openReadOnlyByDefault,
  }) {
    return EditorSettings(
      lineEndingDefault: lineEndingDefault ?? this.lineEndingDefault,
      encodingDefault: encodingDefault ?? this.encodingDefault,
      confirmOverwrite: confirmOverwrite ?? this.confirmOverwrite,
      autoSaveSeconds: _clampAutoSave(autoSaveSeconds ?? this.autoSaveSeconds),
      openReadOnlyByDefault:
          openReadOnlyByDefault ?? this.openReadOnlyByDefault,
    );
  }

  /// Keeps the interval sane: never negative, and capped so a bad stored value
  /// can never set an absurd timer.
  static int _clampAutoSave(int v) => v.clamp(0, 600);

  @override
  bool operator ==(Object other) =>
      other is EditorSettings &&
      other.lineEndingDefault == lineEndingDefault &&
      other.encodingDefault == encodingDefault &&
      other.confirmOverwrite == confirmOverwrite &&
      other.autoSaveSeconds == autoSaveSeconds &&
      other.openReadOnlyByDefault == openReadOnlyByDefault;

  @override
  int get hashCode => Object.hash(
        lineEndingDefault,
        encodingDefault,
        confirmOverwrite,
        autoSaveSeconds,
        openReadOnlyByDefault,
      );
}
