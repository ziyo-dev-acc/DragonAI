package com.ari.adaptiveassistant.ml

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

object LlamaBridge {
    private var modelUri: String? = null
    private var modelPath: String? = null
    private var modelSizeMb: Long = 0
    private var pendingResult: MethodChannel.Result? = null
    private var initialized = false

    fun getModelInfo(): Map<String, Any?> {
        return mapOf(
            "status" to if (modelPath == null) "Not loaded" else "Loaded",
            "uri" to modelUri,
            "sizeMb" to modelSizeMb
        )
    }

    fun loadModel(context: Context, uri: String) {
        modelUri = uri
        val path = copyToInternal(context, uri)
        modelPath = path
        modelSizeMb = File(path).length() / (1024 * 1024)
        if (!initialized) {
            initialized = LlamaNative.init()
        }
        if (initialized) {
            LlamaNative.loadModel(path)
        }
    }

    fun unloadModel(context: Context) {
        try {
            LlamaNative.release()
        } catch (_: UnsatisfiedLinkError) {
        }
        modelUri = null
        modelPath = null
        modelSizeMb = 0
        val file = File(context.filesDir, "local_model.gguf")
        if (file.exists()) {
            file.delete()
        }
    }

    fun getModelSizeMb(context: Context, uriString: String): Long? {
        return try {
            val uri = Uri.parse(uriString)
            context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                val sizeIndex = cursor.getColumnIndex(android.provider.OpenableColumns.SIZE)
                if (sizeIndex != -1 && cursor.moveToFirst()) {
                    val bytes = cursor.getLong(sizeIndex)
                    return bytes / (1024 * 1024)
                }
            }
            null
        } catch (_: Exception) {
            null
        }
    }

    fun rewrite(text: String, config: Map<String, Any>): String {
        val maxTokens = (config["maxTokens"] as? Number)?.toInt() ?: 96
        val temperature = (config["temperature"] as? Number)?.toFloat() ?: 0.4f
        val maxTimeMs = (config["maxTimeMs"] as? Number)?.toInt() ?: 2000
        val threads = (config["threads"] as? Number)?.toInt() ?: 2
        val contextSize = (config["contextSize"] as? Number)?.toInt() ?: 512
        return try {
            LlamaNative.rewrite(text, maxTokens, temperature, maxTimeMs, threads, contextSize)
        } catch (e: UnsatisfiedLinkError) {
            text
        }
    }

    fun pickModel(activity: Activity, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Already picking a model", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
        }
        activity.startActivityForResult(intent, REQUEST_CODE)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pendingResult
        pendingResult = null
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result?.success(null)
            return true
        }
        val uri = data.data!!
        result?.success(uri.toString())
        return true
    }

    private const val REQUEST_CODE = 9022

    private fun copyToInternal(context: Context, uriString: String): String {
        val uri = Uri.parse(uriString)
        val outFile = File(context.filesDir, "local_model.gguf")
        context.contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(outFile).use { output ->
                input.copyTo(output)
            }
        }
        return outFile.absolutePath
    }
}
