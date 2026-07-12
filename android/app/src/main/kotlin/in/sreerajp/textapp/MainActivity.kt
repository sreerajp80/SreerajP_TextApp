package `in`.sreerajp.textapp

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// FlutterFragmentActivity (not FlutterActivity) is required by local_auth for
// biometric prompts (task 13.2).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Scoped-storage (SAF) file access channel.
        flutterEngine.plugins.add(SafChannel())
        // Guided text-to-speech voice install channel (task 11.4).
        flutterEngine.plugins.add(TtsInstallChannel())
        // Screenshot protection (FLAG_SECURE) channel (task 13.2).
        flutterEngine.plugins.add(WindowSecurityChannel())
    }
}
