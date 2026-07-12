/// Typed values for the About screen, loaded from `assets/config/app_config.json`
/// (architecture.md §8.1). Changing About content is a config edit, not a code
/// change.
class AppConfig {
  final String appName;
  final String description;
  final String version;
  final String build;
  final Map<String, String> details;

  const AppConfig({
    required this.appName,
    required this.description,
    required this.version,
    required this.build,
    this.details = const {},
  });

  /// A safe built-in value used when the config file is missing or malformed, so
  /// the app never crashes on a bad config (CLAUDE.md §3.4).
  static const AppConfig fallback = AppConfig(
    appName: 'Text & Data App',
    description:
        'Open, read, edit, and save TXT, MD, CSV, JSON, and XML files.',
    version: '0.0.0',
    build: '0',
    details: {'License': 'All libraries used are open source.'},
  );

  /// Parses a decoded JSON map. Missing fields fall back to the [fallback]
  /// values field-by-field; a wrong type for any field is ignored rather than
  /// thrown, so a partly-broken file still yields a usable config.
  factory AppConfig.fromJson(Map<String, dynamic> json) {
    String str(String key, String fallbackValue) {
      final value = json[key];
      return value is String ? value : fallbackValue;
    }

    Map<String, String> parseStringMap(String key) {
      final raw = json[key];
      if (raw is! Map) return const {};
      final out = <String, String>{};
      raw.forEach((key, value) {
        if (key is String && value is String) out[key] = value;
      });
      return out;
    }

    return AppConfig(
      appName: str('appName', fallback.appName),
      description: str('description', fallback.description),
      version: str('version', fallback.version),
      build: str('build', fallback.build),
      details: parseStringMap('details'),
    );
  }
}
