package `in`.sreerajp.textapp

import android.app.Activity
import android.content.Intent
import android.speech.tts.TextToSpeech
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Guided text-to-speech voice install (task 11.4).
 *
 * Fires the standard Android intents so the user can install a missing voice
 * (for example Malayalam / ml-IN) or open the system Text-to-speech settings.
 * No third-party package is used (CLAUDE.md 3.1).
 *
 * Each method returns true to Dart when an activity handled the intent, false
 * when nothing could handle it, so the UI can show a friendly notice and never
 * a dead button (CLAUDE.md 3.4).
 */
class TtsInstallChannel :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "app/tts_install"
    }

    private var channel: MethodChannel? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "openInstallVoiceData" ->
                result.success(startIntent(TextToSpeech.Engine.ACTION_INSTALL_TTS_DATA))
            "openTtsSettings" ->
                result.success(startIntent("com.android.settings.TTS_SETTINGS"))
            else -> result.notImplemented()
        }
    }

    /** Starts [action] if something can handle it. Returns whether it launched. */
    private fun startIntent(action: String): Boolean {
        val act = activity ?: return false
        val intent = Intent(action)
        if (intent.resolveActivity(act.packageManager) == null) return false
        return try {
            act.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
