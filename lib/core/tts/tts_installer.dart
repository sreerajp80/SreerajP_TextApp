import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Launches the Android system flows that let a user install a missing
/// text-to-speech voice (task 11.4).
///
/// Behind an interface so the Settings widget stays host-testable (arch §12):
/// tests inject a fake that records the calls. The real implementation talks to
/// a small native method channel (`app/tts_install`) that fires the standard
/// Android intents — no third-party package (CLAUDE.md §3.1).
abstract class TtsInstaller {
  /// Opens the "install voice data" flow (`ACTION_INSTALL_TTS_DATA`). Returns
  /// `true` if an activity handled it.
  Future<bool> openInstallVoiceData();

  /// Opens the system Text-to-speech settings screen. Returns `true` if an
  /// activity handled it.
  Future<bool> openTtsSettings();
}

/// Real [TtsInstaller] backed by the native method channel.
class ChannelTtsInstaller implements TtsInstaller {
  static const MethodChannel channel = MethodChannel('app/tts_install');

  const ChannelTtsInstaller();

  @override
  Future<bool> openInstallVoiceData() => _invoke('openInstallVoiceData');

  @override
  Future<bool> openTtsSettings() => _invoke('openTtsSettings');

  /// Invokes [method] and never throws: a missing handler or no matching
  /// activity returns `false` so the UI can show a friendly notice instead of
  /// crashing (CLAUDE.md §3.4).
  Future<bool> _invoke(String method) async {
    try {
      final result = await channel.invokeMethod<bool>(method);
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final ttsInstallerProvider =
    Provider<TtsInstaller>((ref) => const ChannelTtsInstaller());
