package com.ari.adaptiveassistant

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.provider.AlarmClock
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.ari.adaptiveassistant.media.MediaStoreHelper
import com.ari.adaptiveassistant.media.DocumentTreeIndexer
import com.ari.adaptiveassistant.notifications.NotificationCache
import com.ari.adaptiveassistant.services.WakeWordService
import com.ari.adaptiveassistant.settings.SystemActions
import com.ari.adaptiveassistant.stt.SpeechRecognizerManager
import com.ari.adaptiveassistant.ml.LlamaBridge

class MainActivity : FlutterActivity() {
    private var wakeSink: EventChannel.EventSink? = null
    private var sttSink: EventChannel.EventSink? = null
    private lateinit var speechManager: SpeechRecognizerManager
    private lateinit var systemActions: SystemActions
    private lateinit var mediaStoreHelper: MediaStoreHelper
    private lateinit var documentTreeIndexer: DocumentTreeIndexer

    private val wakeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action == WakeWordService.ACTION_WAKE) {
                wakeSink?.success(mapOf("type" to "wake"))
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        systemActions = SystemActions(this)
        speechManager = SpeechRecognizerManager(this) { event ->
            sttSink?.success(event)
        }
        mediaStoreHelper = MediaStoreHelper(this)
        documentTreeIndexer = DocumentTreeIndexer(this)

        registerReceiver(wakeReceiver, IntentFilter(WakeWordService.ACTION_WAKE))

        MethodChannel(messenger, "adaptiveassistant/wakeword").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val assistantName = call.argument<String>("assistantName") ?: "Ari"
                    val sensitivity = call.argument<Double>("sensitivity") ?: 0.6
                    val pauseOnScreenOff = call.argument<Boolean>("pauseOnScreenOff") ?: false
                    val pauseOnLowBattery = call.argument<Boolean>("pauseOnLowBattery") ?: true
                    val lowBatteryThreshold = call.argument<Int>("lowBatteryThreshold") ?: 15
                    val wakeWordAsset = call.argument<String>("wakeWordAsset") ?: "porcupine/ari.ppn"
                    val wakeWordSource = call.argument<String>("wakeWordSource") ?: "asset"
                    WakeWordService.start(
                        this,
                        assistantName,
                        sensitivity.toFloat(),
                        pauseOnScreenOff,
                        pauseOnLowBattery,
                        lowBatteryThreshold,
                        wakeWordAsset,
                        wakeWordSource,
                    )
                    result.success(null)
                }
                "pickWakeWordFile" -> {
                    WakeWordService.pickWakeWord(this, result)
                }
                "stop" -> {
                    WakeWordService.stop(this)
                    result.success(null)
                }
                "pause" -> {
                    WakeWordService.pause(this)
                    result.success(null)
                }
                "resume" -> {
                    WakeWordService.resume(this)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "adaptiveassistant/wakeEvents").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                wakeSink = events
            }

            override fun onCancel(arguments: Any?) {
                wakeSink = null
            }
        })

        MethodChannel(messenger, "adaptiveassistant/stt").setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    speechManager.start()
                    result.success(null)
                }
                "stop" -> {
                    speechManager.stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, "adaptiveassistant/sttEvents").setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                sttSink = events
            }

            override fun onCancel(arguments: Any?) {
                sttSink = null
            }
        })

        MethodChannel(messenger, "adaptiveassistant/media").setMethodCallHandler { call, result ->
            when (call.method) {
                "getLatestFile" -> {
                    val type = call.argument<String>("type") ?: "any"
                    result.success(mediaStoreHelper.getLatestFile(type))
                }
                "searchFiles" -> {
                    val query = call.argument<String>("query") ?: ""
                    val type = call.argument<String>("type")
                    result.success(mediaStoreHelper.searchFiles(query, type))
                }
                "pickDocumentTree" -> {
                    documentTreeIndexer.pickTree(this, result)
                }
                "indexDocumentTree" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    result.success(documentTreeIndexer.indexTree(uri))
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "adaptiveassistant/system").setMethodCallHandler { call, result ->
            when (call.method) {
                "openApp" -> {
                    val alias = call.argument<String>("alias") ?: ""
                    systemActions.openApp(alias)
                    result.success(null)
                }
                "openCameraSelfie" -> {
                    systemActions.openCameraSelfie()
                    result.success(null)
                }
                "setTimer" -> {
                    val minutes = call.argument<Int>("minutes") ?: 1
                    systemActions.setTimer(minutes)
                    result.success(null)
                }
                "setAlarm" -> {
                    val time = call.argument<String>("time") ?: ""
                    systemActions.setAlarm(time)
                    result.success(null)
                }
                "getTime" -> result.success(systemActions.getTime())
                "getBatteryPercent" -> result.success(systemActions.getBatteryPercent())
                "getStorageFreeMb" -> result.success(systemActions.getStorageFreeMb())
                "setFlashlight" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    result.success(systemActions.setFlashlight(on))
                }
                "setBrightness" -> {
                    val percent = call.argument<Int>("percent") ?: 50
                    result.success(systemActions.setBrightness(percent))
                }
                "setVolume" -> {
                    val level = call.argument<Int>("level") ?: 50
                    result.success(systemActions.setVolume(level))
                }
                "openWifiSettings" -> {
                    systemActions.openSettingsPanel(Settings.Panel.ACTION_WIFI)
                    result.success(null)
                }
                "openBluetoothSettings" -> {
                    systemActions.openSettingsPanel(Settings.Panel.ACTION_BLUETOOTH)
                    result.success(null)
                }
                "openDisplaySettings" -> {
                    systemActions.openSettingsPanel(Settings.Panel.ACTION_DISPLAY)
                    result.success(null)
                }
                "shareToTelegram" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    systemActions.shareToTelegram(uri)
                    result.success(null)
                }
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    val assistantName = call.argument<String>("assistantName") ?: "Ari"
                    systemActions.speak(text, assistantName)
                    result.success(null)
                }
                "playEarcon" -> {
                    systemActions.playEarcon()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "adaptiveassistant/notifications").setMethodCallHandler { call, result ->
            when (call.method) {
                "openAccess" -> {
                    systemActions.openNotificationAccess()
                    result.success(null)
                }
                "lastTelegram" -> {
                    val sender = call.argument<String>("senderContains")
                    result.success(NotificationCache.getLastTelegram(sender))
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "adaptiveassistant/llm").setMethodCallHandler { call, result ->
            when (call.method) {
                "getModelInfo" -> result.success(LlamaBridge.getModelInfo())
                "loadModel" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    LlamaBridge.loadModel(this, uri)
                    result.success(null)
                }
                "unloadModel" -> {
                    LlamaBridge.unloadModel(this)
                    result.success(null)
                }
                "getModelSizeMb" -> {
                    val uri = call.argument<String>("uri") ?: ""
                    result.success(LlamaBridge.getModelSizeMb(this, uri))
                }
                "rewrite" -> {
                    val text = call.argument<String>("text") ?: ""
                    val config = call.argument<Map<String, Any>>("config") ?: emptyMap()
                    result.success(LlamaBridge.rewrite(text, config))
                }
                "pickModel" -> {
                    LlamaBridge.pickModel(this, result)
                }
                else -> result.notImplemented()
            }
        }

        MethodChannel(messenger, "adaptiveassistant/settings").setMethodCallHandler { call, result ->
            when (call.method) {
                "isOnline" -> result.success(isOnline())
                else -> result.notImplemented()
            }
        }
    }

    private fun isOnline(): Boolean {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val network = cm.activeNetwork ?: return false
        val caps = cm.getNetworkCapabilities(network) ?: return false
        return caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        val handledTree = documentTreeIndexer.onActivityResult(requestCode, resultCode, data)
        val handledModel = LlamaBridge.onActivityResult(requestCode, resultCode, data)
        val handledWake = WakeWordService.onActivityResult(requestCode, resultCode, data)
        if (handledTree || handledModel || handledWake) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        unregisterReceiver(wakeReceiver)
        speechManager.release()
        super.onDestroy()
    }
}
