package `in`.sreerajp.textapp

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream

/**
 * Scoped-storage (SAF) file access for the app.
 *
 * The app opens files only through the system picker (ACTION_OPEN_DOCUMENT) and
 * takes a persistable URI permission so a file can be re-opened later from its
 * saved URI. No broad storage permission is requested (CLAUDE.md 3.3).
 *
 * Errors are reported to Dart as stable error codes ("cancelled",
 * "permission_denied", "uri_stale", "io_failure"), which the Dart wrapper maps
 * to typed exceptions. No file contents are ever logged.
 */
class SafChannel :
    FlutterPlugin,
    ActivityAware,
    MethodChannel.MethodCallHandler,
    PluginRegistry.ActivityResultListener {

    companion object {
        private const val CHANNEL = "in.zohomail.sreerajp.text_data/saf"
        private const val REQ_PICK = 0x5AF1
        private const val REQ_CREATE = 0x5AF2
    }

    private var channel: MethodChannel? = null
    private var activity: Activity? = null
    private var pendingResult: MethodChannel.Result? = null

    // Bytes waiting to be written into a document the user is about to create.
    private var pendingCreateBytes: ByteArray? = null

    // --- Plugin lifecycle ---

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
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    // --- Method calls ---

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFile" -> pickFile(call, result)
            "readBytes" -> readBytes(call, result)
            "writeBytes" -> writeBytes(call, result)
            "createDocument" -> createDocument(call, result)
            "isWritable" -> isWritable(call, result)
            "modifiedTime" -> modifiedTime(call, result)
            "isAccessible" -> isAccessible(call, result)
            "releasePermission" -> releasePermission(call, result)
            "persistedUris" -> persistedUris(result)
            else -> result.notImplemented()
        }
    }

    private fun pickFile(call: MethodCall, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("io_failure", "No activity available.", null)
            return
        }
        if (pendingResult != null) {
            result.error("io_failure", "A pick is already in progress.", null)
            return
        }
        @Suppress("UNCHECKED_CAST")
        val mimeTypes = (call.argument<List<String>>("mimeTypes") ?: listOf("*/*"))
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = if (mimeTypes.size == 1) mimeTypes[0] else "*/*"
            if (mimeTypes.size > 1) {
                putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes.toTypedArray())
            }
            // Ask for a grant we can persist for both read and write.
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        pendingResult = result
        try {
            act.startActivityForResult(intent, REQ_PICK)
        } catch (e: Exception) {
            pendingResult = null
            result.error("io_failure", "Could not open the picker.", null)
        }
    }

    private fun createDocument(call: MethodCall, result: MethodChannel.Result) {
        val act = activity
        if (act == null) {
            result.error("io_failure", "No activity available.", null)
            return
        }
        if (pendingResult != null) {
            result.error("io_failure", "A file operation is already in progress.", null)
            return
        }
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null) {
            result.error("io_failure", "No content to write.", null)
            return
        }
        val name = call.argument<String>("suggestedName") ?: "untitled.txt"
        val mime = call.argument<String>("mimeType") ?: "application/octet-stream"
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mime
            putExtra(Intent.EXTRA_TITLE, name)
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        pendingResult = result
        pendingCreateBytes = bytes
        try {
            act.startActivityForResult(intent, REQ_CREATE)
        } catch (e: Exception) {
            pendingResult = null
            pendingCreateBytes = null
            result.error("io_failure", "Could not open the save dialog.", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        return when (requestCode) {
            REQ_PICK -> handlePickResult(resultCode, data)
            REQ_CREATE -> handleCreateResult(resultCode, data)
            else -> false
        }
    }

    private fun handlePickResult(resultCode: Int, data: Intent?): Boolean {
        val result = pendingResult ?: return true
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result.error("cancelled", "File selection was cancelled.", null)
            return true
        }
        val uri = data.data!!
        try {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            activity?.contentResolver?.takePersistableUriPermission(uri, flags)
        } catch (e: SecurityException) {
            // Some providers grant read-only; keep read persistence if possible.
            try {
                activity?.contentResolver?.takePersistableUriPermission(
                    uri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
                )
            } catch (e2: SecurityException) {
                result.error("permission_denied", "Could not keep access to the file.", null)
                return true
            }
        }
        result.success(describe(uri))
        return true
    }

    private fun handleCreateResult(resultCode: Int, data: Intent?): Boolean {
        val result = pendingResult ?: return true
        val bytes = pendingCreateBytes
        pendingResult = null
        pendingCreateBytes = null

        if (resultCode != Activity.RESULT_OK || data?.data == null || bytes == null) {
            result.error("cancelled", "Save was cancelled.", null)
            return true
        }
        val uri = data.data!!
        try {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            activity?.contentResolver?.takePersistableUriPermission(uri, flags)
        } catch (e: SecurityException) {
            // Non-fatal: we can still write to the freshly created document even
            // if the grant cannot be persisted for later.
        }
        try {
            activity?.contentResolver?.openOutputStream(uri, "rwt")?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: run {
                result.error("io_failure", "Could not write the new file.", null)
                return true
            }
        } catch (e: SecurityException) {
            result.error("permission_denied", "No permission to write the new file.", null)
            return true
        } catch (e: Exception) {
            result.error("io_failure", "Could not write the new file.", null)
            return true
        }
        result.success(describe(uri))
        return true
    }

    private fun readBytes(call: MethodCall, result: MethodChannel.Result) {
        val uri = argUri(call, result) ?: return
        try {
            val bytes = activity?.contentResolver?.openInputStream(uri)?.use { input ->
                val buffer = ByteArrayOutputStream()
                input.copyTo(buffer)
                buffer.toByteArray()
            }
            if (bytes == null) {
                result.error("io_failure", "Could not open the file.", null)
            } else {
                result.success(bytes)
            }
        } catch (e: SecurityException) {
            result.error("permission_denied", "No permission to read this file.", null)
        } catch (e: java.io.FileNotFoundException) {
            result.error("uri_stale", "This file is no longer available.", null)
        } catch (e: Exception) {
            result.error("io_failure", "Could not read the file.", null)
        }
    }

    private fun writeBytes(call: MethodCall, result: MethodChannel.Result) {
        val uri = argUri(call, result) ?: return
        val bytes = call.argument<ByteArray>("bytes")
        if (bytes == null) {
            result.error("io_failure", "No content to write.", null)
            return
        }
        try {
            // "rwt" truncates then writes, so a shorter file does not keep old tail bytes.
            activity?.contentResolver?.openOutputStream(uri, "rwt")?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: run {
                result.error("io_failure", "Could not open the file for writing.", null)
                return
            }
            result.success(null)
        } catch (e: SecurityException) {
            result.error("permission_denied", "No permission to write this file.", null)
        } catch (e: java.io.FileNotFoundException) {
            result.error("uri_stale", "This file is no longer available.", null)
        } catch (e: Exception) {
            result.error("io_failure", "Could not write the file.", null)
        }
    }

    private fun isAccessible(call: MethodCall, result: MethodChannel.Result) {
        val uri = argUri(call, result) ?: return
        try {
            val ok = activity?.contentResolver
                ?.openInputStream(uri)
                ?.use { true } ?: false
            result.success(ok)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun isWritable(call: MethodCall, result: MethodChannel.Result) {
        val uri = argUri(call, result) ?: return
        try {
            val writable = activity?.contentResolver?.persistedUriPermissions
                ?.any { it.uri == uri && it.isWritePermission } ?: false
            result.success(writable)
        } catch (e: Exception) {
            result.success(false)
        }
    }

    private fun modifiedTime(call: MethodCall, result: MethodChannel.Result) {
        val uri = argUri(call, result) ?: return
        var millis: Long? = null
        try {
            activity?.contentResolver?.query(uri, null, null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val idx = c.getColumnIndex(
                        android.provider.DocumentsContract.Document.COLUMN_LAST_MODIFIED,
                    )
                    if (idx >= 0 && !c.isNull(idx)) millis = c.getLong(idx)
                }
            }
        } catch (e: Exception) {
            // Best-effort; report null when the provider does not expose a time.
        }
        result.success(millis)
    }

    private fun releasePermission(call: MethodCall, result: MethodChannel.Result) {
        val uri = argUri(call, result) ?: return
        try {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            activity?.contentResolver?.releasePersistableUriPermission(uri, flags)
        } catch (e: Exception) {
            // Already gone — nothing to do.
        }
        result.success(null)
    }

    private fun persistedUris(result: MethodChannel.Result) {
        val uris = activity?.contentResolver?.persistedUriPermissions
            ?.map { it.uri.toString() }
            ?: emptyList()
        result.success(uris)
    }

    // --- Helpers ---

    private fun argUri(call: MethodCall, result: MethodChannel.Result): Uri? {
        val raw = call.argument<String>("uri")
        if (raw == null) {
            result.error("io_failure", "Missing file reference.", null)
            return null
        }
        return Uri.parse(raw)
    }

    /** Reads display name, size, and MIME for a picked URI. No contents read. */
    private fun describe(uri: Uri): Map<String, Any?> {
        var name = "Untitled"
        var size: Long? = null
        try {
            activity?.contentResolver?.query(uri, null, null, null, null)?.use { c ->
                if (c.moveToFirst()) {
                    val nameIdx = c.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                    if (nameIdx >= 0 && !c.isNull(nameIdx)) name = c.getString(nameIdx)
                    val sizeIdx = c.getColumnIndex(android.provider.OpenableColumns.SIZE)
                    if (sizeIdx >= 0 && !c.isNull(sizeIdx)) size = c.getLong(sizeIdx)
                }
            }
        } catch (e: Exception) {
            // Fall back to defaults; metadata is best-effort.
        }
        val mime = try {
            activity?.contentResolver?.getType(uri)
        } catch (e: Exception) {
            null
        }
        return mapOf(
            "uri" to uri.toString(),
            "displayName" to name,
            "mimeType" to mime,
            "size" to size,
        )
    }
}
