enum IntentType {
  findLatestFile,
  findFile,
  shareFileToTelegram,
  openApp,
  openCameraSelfie,
  setTimer,
  setAlarm,
  getTime,
  getBatteryPercent,
  getStorageFree,
  flashlight,
  setBrightness,
  setVolume,
  wifiSettings,
  bluetoothSettings,
  readLastTelegramNotification,
  unknown,
}

class IntentMatch {
  final IntentType type;
  final double confidence;
  final Map<String, dynamic> slots;

  const IntentMatch({
    required this.type,
    required this.confidence,
    required this.slots,
  });
}

class IntentResult {
  final IntentType type;
  final bool success;
  final String response;
  final Map<String, dynamic>? data;

  const IntentResult({
    required this.type,
    required this.success,
    required this.response,
    this.data,
  });
}
