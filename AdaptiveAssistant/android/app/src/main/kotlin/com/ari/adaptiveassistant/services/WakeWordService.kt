package com.ari.adaptiveassistant.services

import ai.picovoice.porcupine.PorcupineManager
import ai.picovoice.porcupine.PorcupineManagerCallback
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.ari.adaptiveassistant.R
import android.app.Activity
import android.net.Uri
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class WakeWordService : Service() {
    private var porcupineManager: PorcupineManager? = null
    private var isPaused: Boolean = false
    private var intentAsset: String? = null
    private var intentSource: String? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIF_ID, buildNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PAUSE -> {
                isPaused = true
                porcupineManager?.stop()
            }
            ACTION_RESUME -> {
                isPaused = false
                porcupineManager?.start()
            }
            ACTION_STOP -> {
                stopSelf()
            }
            else -> {
                val assistantName = intent?.getStringExtra(EXTRA_NAME) ?: "Ari"
                val sensitivity = intent?.getFloatExtra(EXTRA_SENSITIVITY, 0.6f) ?: 0.6f
                intentAsset = intent?.getStringExtra(EXTRA_ASSET)
                intentSource = intent?.getStringExtra(EXTRA_SOURCE)
                setupPorcupine(assistantName, sensitivity)
            }
        }
        return START_STICKY
    }

    private fun setupPorcupine(assistantName: String, sensitivity: Float) {
        if (porcupineManager != null) return
        val callback = PorcupineManagerCallback {
            val intent = Intent(ACTION_WAKE)
            sendBroadcast(intent)
        }
        val keywordPath = if ((intentSource ?: "asset") == "uri") {
            resolveFromUri(intentAsset ?: "")
        } else {
            extractAssetIfNeeded(intentAsset ?: "porcupine/ari.ppn")
        }
        porcupineManager = PorcupineManager.Builder()
            .setAccessKey(ACCESS_KEY)
            .setKeywordPath(keywordPath)
            .setSensitivity(sensitivity)
            .build(this, callback)
        porcupineManager?.start()
    }

    private fun resolveFromUri(uriString: String): String {
        val uri = Uri.parse(uriString)
        val outFile = File(filesDir, "wakeword.ppn")
        contentResolver.openInputStream(uri)?.use { input ->
            FileOutputStream(outFile).use { output ->
                input.copyTo(output)
            }
        }
        return outFile.absolutePath
    }

    private fun extractAssetIfNeeded(assetName: String): String {
        val outFile = File(filesDir, assetName.substringAfterLast('/'))
        if (!outFile.exists()) {
            assets.open(assetName).use { input ->
                FileOutputStream(outFile).use { output ->
                    input.copyTo(output)
                }
            }
        }
        return outFile.absolutePath
    }

    override fun onDestroy() {
        porcupineManager?.stop()
        porcupineManager?.delete()
        porcupineManager = null
        super.onDestroy()
    }

    private fun buildNotification(): Notification {
        createNotificationChannel()
        val pauseIntent = PendingIntent.getService(
            this,
            0,
            Intent(this, WakeWordService::class.java).setAction(ACTION_PAUSE),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val stopIntent = PendingIntent.getService(
            this,
            1,
            Intent(this, WakeWordService::class.java).setAction(ACTION_STOP),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(getString(R.string.wake_notification_title))
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .addAction(0, getString(R.string.wake_notification_pause), pauseIntent)
            .addAction(0, getString(R.string.wake_notification_stop), stopIntent)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Wake Word",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    companion object {
        const val ACTION_WAKE = "com.ari.adaptiveassistant.WAKE_WORD"
        private const val ACCESS_KEY = "sgRNEExJ2Gwzh2PVZ33rlbtp9J4ivKgcgnm7qZ+TC7j/Zuue41PW/Q=="
        private const val ACTION_PAUSE = "com.ari.adaptiveassistant.WAKE_PAUSE"
        private const val ACTION_RESUME = "com.ari.adaptiveassistant.WAKE_RESUME"
        private const val ACTION_STOP = "com.ari.adaptiveassistant.WAKE_STOP"
        private const val EXTRA_NAME = "assistantName"
        private const val EXTRA_SENSITIVITY = "sensitivity"
        private const val EXTRA_ASSET = "wakeWordAsset"
        private const val EXTRA_SOURCE = "wakeWordSource"
        private const val CHANNEL_ID = "wake_word"
        private const val NOTIF_ID = 42
        private const val REQUEST_CODE = 9033
        private var pendingResult: MethodChannel.Result? = null

        fun start(
            context: Context,
            assistantName: String,
            sensitivity: Float,
            pauseOnScreenOff: Boolean,
            pauseOnLowBattery: Boolean,
            lowBatteryThreshold: Int,
            wakeWordAsset: String,
            wakeWordSource: String,
        ) {
            val intent = Intent(context, WakeWordService::class.java).apply {
                putExtra(EXTRA_NAME, assistantName)
                putExtra(EXTRA_SENSITIVITY, sensitivity)
                putExtra(EXTRA_ASSET, wakeWordAsset)
                putExtra(EXTRA_SOURCE, wakeWordSource)
            }
            ContextCompat.startForegroundService(context, intent)
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, WakeWordService::class.java))
        }

        fun pause(context: Context) {
            val intent = Intent(context, WakeWordService::class.java).setAction(ACTION_PAUSE)
            ContextCompat.startForegroundService(context, intent)
        }

        fun resume(context: Context) {
            val intent = Intent(context, WakeWordService::class.java).setAction(ACTION_RESUME)
            ContextCompat.startForegroundService(context, intent)
        }

        fun pickWakeWord(activity: Activity, result: MethodChannel.Result) {
            if (pendingResult != null) {
                result.error("busy", "Already picking a wake word", null)
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
    }
}
