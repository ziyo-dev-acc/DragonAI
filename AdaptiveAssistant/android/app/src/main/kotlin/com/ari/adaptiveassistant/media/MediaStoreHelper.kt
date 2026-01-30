package com.ari.adaptiveassistant.media

import android.content.ContentResolver
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.provider.MediaStore

class MediaStoreHelper(private val context: Context) {
    private val resolver: ContentResolver = context.contentResolver

    fun getLatestFile(type: String): Map<String, Any?>? {
        val (uri, projection, sort) = when (type) {
            "image" -> Triple(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Images.Media._ID, MediaStore.Images.Media.DISPLAY_NAME, MediaStore.Images.Media.DATE_ADDED),
                "${MediaStore.Images.Media.DATE_ADDED} DESC"
            )
            "video" -> Triple(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.Video.Media._ID, MediaStore.Video.Media.DISPLAY_NAME, MediaStore.Video.Media.DATE_ADDED),
                "${MediaStore.Video.Media.DATE_ADDED} DESC"
            )
            else -> Triple(
                MediaStore.Files.getContentUri("external"),
                arrayOf(MediaStore.Files.FileColumns._ID, MediaStore.Files.FileColumns.DISPLAY_NAME, MediaStore.Files.FileColumns.DATE_ADDED),
                "${MediaStore.Files.FileColumns.DATE_ADDED} DESC"
            )
        }

        resolver.query(uri, projection, null, null, sort)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val id = cursor.getLong(0)
                val name = cursor.getString(1)
                val dateAdded = cursor.getLong(2) * 1000
                val contentUri = ContentUris.withAppendedId(uri, id)
                return mapOf("name" to name, "uri" to contentUri.toString(), "modifiedAt" to dateAdded)
            }
        }
        return null
    }

    fun searchFiles(query: String, type: String?): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} LIKE ?"
        val args = arrayOf("%$query%")

        val targets: List<Uri> = when (type) {
            "image" -> listOf(MediaStore.Images.Media.EXTERNAL_CONTENT_URI)
            "video" -> listOf(MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
            else -> listOf(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, MediaStore.Video.Media.EXTERNAL_CONTENT_URI)
        }

        for (uri in targets) {
            resolver.query(
                uri,
                arrayOf(MediaStore.MediaColumns._ID, MediaStore.MediaColumns.DISPLAY_NAME, MediaStore.MediaColumns.DATE_ADDED),
                selection,
                args,
                "${MediaStore.MediaColumns.DATE_ADDED} DESC"
            )?.use { cursor ->
                while (cursor.moveToNext() && results.size < 5) {
                    val id = cursor.getLong(0)
                    val name = cursor.getString(1)
                    val dateAdded = cursor.getLong(2) * 1000
                    val contentUri = ContentUris.withAppendedId(uri, id)
                    results.add(mapOf("name" to name, "uri" to contentUri.toString(), "modifiedAt" to dateAdded))
                }
            }
        }
        return results
    }
}
