import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'app_config.dart';

/// Loads the About config from the asset bundle and, optionally, cross-checks
/// its version/build against the real package info (architecture.md §8.1).
///
/// Any load or parse failure degrades gracefully to [AppConfig.fallback] — the
/// app never crashes on a missing or malformed config (CLAUDE.md §3.4).
class ConfigService {
  static const String assetPath = 'assets/config/app_config.json';

  /// Injectable so tests can supply asset text without the real bundle.
  final Future<String> Function(String path) _loadAsset;

  ConfigService({Future<String> Function(String path)? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.loadString;

  /// Loads and parses the config. Returns [AppConfig.fallback] on any error.
  Future<AppConfig> load() async {
    try {
      final text = await _loadAsset(assetPath);
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return AppConfig.fallback;
      return AppConfig.fromJson(decoded);
    } catch (_) {
      // Bad asset, bad JSON, wrong shape — all degrade to the safe fallback.
      return AppConfig.fallback;
    }
  }

  /// Loads the config, then compares its declared version/build with
  /// `package_info_plus`. On a mismatch it logs a non-fatal note in debug (no
  /// secret data) and returns the config unchanged.
  Future<AppConfig> loadAndVerify({PackageInfo? packageInfo}) async {
    final config = await load();
    try {
      final info = packageInfo ?? await PackageInfo.fromPlatform();
      final mismatch =
          info.version != config.version || info.buildNumber != config.build;
      if (mismatch && kDebugMode) {
        debugPrint(
          'ConfigService: version/build in app_config.json '
          '(${config.version}+${config.build}) does not match the build '
          '(${info.version}+${info.buildNumber}).',
        );
      }
    } catch (_) {
      // Package info unavailable (e.g. in a plain unit test) — ignore.
    }
    return config;
  }
}

final configServiceProvider = Provider<ConfigService>((ref) => ConfigService());

/// The loaded, verified [AppConfig] for the About screen.
final appConfigProvider = FutureProvider<AppConfig>((ref) {
  return ref.watch(configServiceProvider).loadAndVerify();
});
