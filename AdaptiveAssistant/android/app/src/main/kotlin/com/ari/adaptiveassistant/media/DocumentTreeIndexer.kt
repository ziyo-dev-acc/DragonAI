package com.ari.adaptiveassistant.media

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicInteger

class DocumentTreeIndexer(private val context: Context) {
    private var pendingResult: MethodChannel.Result? = null

    fun pickTree(activity: Activity, result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error("busy", "Already picking a folder", null)
            return
        }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
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
        context.contentResolver.takePersistableUriPermission(
            uri,
            Intent.FLAG_GRANT_READ_URI_PERMISSION
        )
        result?.success(mapOf("uri" to uri.toString()))
        return true
    }

    fun indexTree(treeUri: String): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val uri = Uri.parse(treeUri)
        val root = DocumentFile.fromTreeUri(context, uri) ?: return results
        for (file in root.listFiles()) {
            if (file.isFile) {
                results.add(
                    mapOf(
                        "name" to (file.name ?: ""),
                        "uri" to file.uri.toString(),
                        "modifiedAt" to file.lastModified(),
                        "mimeType" to (file.type ?: "")
                    )
                )
            }
        }
        return results
    }

    companion object {
        const val REQUEST_CODE = 9011
    }
}
