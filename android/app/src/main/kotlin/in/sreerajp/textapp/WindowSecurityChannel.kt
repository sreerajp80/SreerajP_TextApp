package `in`.sreerajp.textapp

import android.app.Activity
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Screenshot protection (task 13.2).
 *
 * Toggles the window's FLAG_SECURE. When set, Android blocks screenshots and
 * hides the window from the recent-apps thumbnail and screen recording. The app
 * turns this on globally when the "block screenshots" setting is enabled, and
 * always while the P2P pairing code / QR is on screen (security-rules).
 *
 * No third-party package is used (CLAUDE.md §3.1). Window flags must be set on
 * the UI thread, so all work runs on the activity.
 */
class WindowSecurityChannel :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL = "app/window_security"
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
            "setSecure" -> {
                val secure = call.argument<Boolean>("secure") ?: false
                result.success(setSecure(secure))
            }
            else -> result.notImplemented()
        }
    }

    /** Adds or clears FLAG_SECURE on the activity window. Returns whether it ran. */
    private fun setSecure(secure: Boolean): Boolean {
        val act = activity ?: return false
        act.runOnUiThread {
            if (secure) {
                act.window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
            } else {
                act.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
            }
        }
        return true
    }
}
