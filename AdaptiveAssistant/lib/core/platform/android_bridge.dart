import 'dart:async';

import 'package:flutter/services.dart';

class AndroidBridge {
  AndroidBridge._();

  static const _wakeChannel = MethodChannel('adaptiveassistant/wakeword');
  static const _wakeEvents = EventChannel('adaptiveassistant/wakeEvents');
  static const _sttChannel = MethodChannel('adaptiveassistant/stt');
  static const _sttEvents = EventChannel('adaptiveassistant/sttEvents');
  static const _mediaChannel = MethodChannel('adaptiveassistant/media');
  static const _systemChannel = MethodChannel('adaptiveassistant/system');
  static const _notificationsChannel = MethodChannel('adaptiveassistant/notifications');
  static const _llmChannel = MethodChannel('adaptiveassistant/llm');
  static const _settingsChannel = MethodChannel('adaptiveassistant/settings');

  static Stream<dynamic>? _sttStream;
  static Stream<dynamic>? _wakeStream;

  static Future<void> startWakeWord({
    required String assistantName,
    required double sensitivity,
    required bool pauseOnScreenOff,
    required bool pauseOnLowBattery,
    required int lowBatteryThreshold,
    required String wakeWordAsset,
    required String wakeWordSource,
  }) async {
    await _wakeChannel.invokeMethod('start', {
      'assistantName': assistantName,
      'sensitivity': sensitivity,
      'pauseOnScreenOff': pauseOnScreenOff,
      'pauseOnLowBattery': pauseOnLowBattery,
      'lowBatteryThreshold': lowBatteryThreshold,
      'wakeWordAsset': wakeWordAsset,
      'wakeWordSource': wakeWordSource,
    });
  }

  static Future<String?> pickWakeWordFile() async {
    return _wakeChannel.invokeMethod<String>('pickWakeWordFile');
  }

  static Future<void> stopWakeWord() async {
    await _wakeChannel.invokeMethod('stop');
  }

  static Future<void> pauseWakeWord() async {
    await _wakeChannel.invokeMethod('pause');
  }

  static Future<void> resumeWakeWord() async {
    await _wakeChannel.invokeMethod('resume');
  }

  static Future<void> startStt() async {
    await _sttChannel.invokeMethod('start');
  }

  static Future<void> stopStt() async {
    await _sttChannel.invokeMethod('stop');
  }

  static Stream<dynamic> sttEvents() {
    _sttStream ??= _sttEvents.receiveBroadcastStream();
    return _sttStream!;
  }

  static Stream<dynamic> wakeEvents() {
    _wakeStream ??= _wakeEvents.receiveBroadcastStream();
    return _wakeStream!;
  }

  static Future<Map<String, dynamic>?> getLatestFile(String type) async {
    final result = await _mediaChannel.invokeMethod<Map>('getLatestFile', {'type': type});
    return result?.cast<String, dynamic>();
  }

  static Future<List<Map<String, dynamic>>> searchFiles({
    required String query,
    String? type,
  }) async {
    final result = await _mediaChannel.invokeMethod<List>('searchFiles', {
      'query': query,
      'type': type,
    });
    return (result ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> openApp(String alias) async {
    await _systemChannel.invokeMethod('openApp', {'alias': alias});
  }

  static Future<void> openCameraSelfie() async {
    await _systemChannel.invokeMethod('openCameraSelfie');
  }

  static Future<void> setTimer(int minutes) async {
    await _systemChannel.invokeMethod('setTimer', {'minutes': minutes});
  }

  static Future<void> setAlarm(String time) async {
    await _systemChannel.invokeMethod('setAlarm', {'time': time});
  }

  static Future<String?> getTime() async {
    return _systemChannel.invokeMethod<String>('getTime');
  }

  static Future<int?> getBatteryPercent() async {
    return _systemChannel.invokeMethod<int>('getBatteryPercent');
  }

  static Future<int?> getStorageFreeMb() async {
    return _systemChannel.invokeMethod<int>('getStorageFreeMb');
  }

  static Future<bool> setFlashlight(bool on) async {
    final result = await _systemChannel.invokeMethod<bool>('setFlashlight', {'on': on});
    return result ?? false;
  }

  static Future<bool> setBrightness(int percent) async {
    final result = await _systemChannel.invokeMethod<bool>('setBrightness', {'percent': percent});
    return result ?? false;
  }

  static Future<bool> setVolume(int level) async {
    final result = await _systemChannel.invokeMethod<bool>('setVolume', {'level': level});
    return result ?? false;
  }

  static Future<void> openWifiSettings() async {
    await _systemChannel.invokeMethod('openWifiSettings');
  }

  static Future<void> openBluetoothSettings() async {
    await _systemChannel.invokeMethod('openBluetoothSettings');
  }

  static Future<void> openDisplaySettings() async {
    await _systemChannel.invokeMethod('openDisplaySettings');
  }

  static Future<void> shareToTelegram(String uri) async {
    await _systemChannel.invokeMethod('shareToTelegram', {'uri': uri});
  }

  static Future<void> openNotificationAccess() async {
    await _notificationsChannel.invokeMethod('openAccess');
  }

  static Future<Map<String, dynamic>?> getLastTelegramNotification({String? senderContains}) async {
    final result = await _notificationsChannel.invokeMethod<Map>('lastTelegram', {
      'senderContains': senderContains,
    });
    return result?.cast<String, dynamic>();
  }

  static Future<Map<String, dynamic>?> pickDocumentTree() async {
    final result = await _mediaChannel.invokeMethod<Map>('pickDocumentTree');
    return result?.cast<String, dynamic>();
  }

  static Future<List<Map<String, dynamic>>> indexDocumentTree(String treeUri) async {
    final result = await _mediaChannel.invokeMethod<List>('indexDocumentTree', {'uri': treeUri});
    return (result ?? []).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> speak(String text, String assistantName) async {
    await _systemChannel.invokeMethod('speak', {'text': text, 'assistantName': assistantName});
  }

  static Future<void> playEarcon() async {
    await _systemChannel.invokeMethod('playEarcon');
  }

  static Future<Map<String, dynamic>> getLocalModelInfo() async {
    final result = await _llmChannel.invokeMethod<Map>('getModelInfo');
    return result?.cast<String, dynamic>() ?? {};
  }

  static Future<void> loadLocalModel(String uri) async {
    await _llmChannel.invokeMethod('loadModel', {'uri': uri});
  }

  static Future<void> unloadLocalModel() async {
    await _llmChannel.invokeMethod('unloadModel');
  }

  static Future<int?> getLocalModelSizeMb(String uri) async {
    return _llmChannel.invokeMethod<int>('getModelSizeMb', {'uri': uri});
  }

  static Future<String?> pickLocalModel() async {
    return _llmChannel.invokeMethod<String>('pickModel');
  }

  static Future<String?> rewriteWithLocalLlm(String text, Map<String, dynamic> config) async {
    return _llmChannel.invokeMethod<String>('rewrite', {
      'text': text,
      'config': config,
    });
  }

  static Future<bool> isOnline() async {
    final result = await _settingsChannel.invokeMethod<bool>('isOnline');
    return result ?? false;
  }
}
