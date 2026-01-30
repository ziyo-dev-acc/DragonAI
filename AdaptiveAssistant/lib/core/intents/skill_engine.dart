import 'package:intl/intl.dart';

import '../models/intent.dart';
import '../platform/android_bridge.dart';
import '../storage/document_index_store.dart';

class SkillEngine {
  SkillEngine({DocumentIndexStore? documentIndexStore})
      : _documentIndexStore = documentIndexStore;

  final DocumentIndexStore? _documentIndexStore;

  Future<IntentResult> execute(IntentMatch match) async {
    switch (match.type) {
      case IntentType.findLatestFile:
        return _findLatest(match);
      case IntentType.findFile:
        return _findFile(match);
      case IntentType.shareFileToTelegram:
        return _shareToTelegram(match);
      case IntentType.openApp:
        return _openApp(match);
      case IntentType.openCameraSelfie:
        await AndroidBridge.openCameraSelfie();
        return const IntentResult(
          type: IntentType.openCameraSelfie,
          success: true,
          response: 'Kamera ochildi.',
        );
      case IntentType.setTimer:
        final minutes = match.slots['minutes'] as int?;
        if (minutes == null) {
          return const IntentResult(
            type: IntentType.setTimer,
            success: false,
            response: 'Timer vaqtini aniqlay olmadim.',
          );
        }
        await AndroidBridge.setTimer(minutes);
        return IntentResult(
          type: IntentType.setTimer,
          success: true,
          response: 'Timer $minutes minutga sozlandi.',
        );
      case IntentType.setAlarm:
        final time = match.slots['time'] as String?;
        if (time == null) {
          return const IntentResult(
            type: IntentType.setAlarm,
            success: false,
            response: 'Budilnik vaqtini aniqlay olmadim.',
          );
        }
        await AndroidBridge.setAlarm(time);
        return IntentResult(
          type: IntentType.setAlarm,
          success: true,
          response: 'Budilnik $time ga qo‘yildi.',
        );
      case IntentType.getTime:
        final now = await AndroidBridge.getTime() ?? DateFormat.Hm().format(DateTime.now());
        return IntentResult(
          type: IntentType.getTime,
          success: true,
          response: 'Hozir $now.',
        );
      case IntentType.getBatteryPercent:
        final battery = await AndroidBridge.getBatteryPercent();
        if (battery == null) {
          return const IntentResult(
            type: IntentType.getBatteryPercent,
            success: false,
            response: 'Batareya holatini ololmadim.',
          );
        }
        return IntentResult(
          type: IntentType.getBatteryPercent,
          success: true,
          response: 'Batareya $battery%.',
        );
      case IntentType.getStorageFree:
        final mb = await AndroidBridge.getStorageFreeMb();
        if (mb == null) {
          return const IntentResult(
            type: IntentType.getStorageFree,
            success: false,
            response: 'Xotira ma’lumotini ololmadim.',
          );
        }
        return IntentResult(
          type: IntentType.getStorageFree,
          success: true,
          response: 'Bo‘sh joy $mb MB.',
        );
      case IntentType.flashlight:
        final on = match.slots['on'] as bool? ?? false;
        final ok = await AndroidBridge.setFlashlight(on);
        return IntentResult(
          type: IntentType.flashlight,
          success: ok,
          response: ok ? 'Chiroq holati yangilandi.' : 'Chiroqni boshqara olmadim.',
        );
      case IntentType.setBrightness:
        final percent = match.slots['percent'] as int?;
        if (percent == null) {
          return const IntentResult(
            type: IntentType.setBrightness,
            success: false,
            response: 'Yorqinlik foizini topa olmadim.',
          );
        }
        final ok = await AndroidBridge.setBrightness(percent);
        return IntentResult(
          type: IntentType.setBrightness,
          success: ok,
          response: ok ? 'Yorqinlik sozlandi.' : 'Yorqinlik uchun ruxsat kerak.',
        );
      case IntentType.setVolume:
        final level = match.slots['level'] as int?;
        if (level == null) {
          return const IntentResult(
            type: IntentType.setVolume,
            success: false,
            response: 'Ovoz darajasini topa olmadim.',
          );
        }
        final ok = await AndroidBridge.setVolume(level);
        return IntentResult(
          type: IntentType.setVolume,
          success: ok,
          response: ok ? 'Ovoz sozlandi.' : 'Ovoz sozlashga ruxsat yo‘q.',
        );
      case IntentType.wifiSettings:
        await AndroidBridge.openWifiSettings();
        return const IntentResult(
          type: IntentType.wifiSettings,
          success: true,
          response: 'Wi‑Fi sozlamalarini ochdim.',
        );
      case IntentType.bluetoothSettings:
        await AndroidBridge.openBluetoothSettings();
        return const IntentResult(
          type: IntentType.bluetoothSettings,
          success: true,
          response: 'Bluetooth sozlamalarini ochdim.',
        );
      case IntentType.readLastTelegramNotification:
        final sender = match.slots['senderContains'] as String?;
        final notif = await AndroidBridge.getLastTelegramNotification(senderContains: sender);
        if (notif == null) {
          return const IntentResult(
            type: IntentType.readLastTelegramNotification,
            success: false,
            response: 'Telegram xabar topilmadi.',
          );
        }
        final text = notif['text'] ?? 'Xabar mavjud.';
        return IntentResult(
          type: IntentType.readLastTelegramNotification,
          success: true,
          response: text,
          data: notif,
        );
      case IntentType.unknown:
        return const IntentResult(
          type: IntentType.unknown,
          success: false,
          response: 'Buyruqni tushunmadim.',
        );
    }
  }

  Future<IntentResult> _findLatest(IntentMatch match) async {
    final type = match.slots['type'] as String? ?? 'any';
    if (type == 'pdf' && _documentIndexStore != null) {
      final doc = await _documentIndexStore!.latestPdf();
      if (doc != null) {
        return IntentResult(
          type: IntentType.findLatestFile,
          success: true,
          response: 'Oxirgi PDF topildi: ${doc['name']}',
          data: doc,
        );
      }
    }
    final file = await AndroidBridge.getLatestFile(type);
    if (file == null) {
      return const IntentResult(
        type: IntentType.findLatestFile,
        success: false,
        response: 'Oxirgi fayl topilmadi.',
      );
    }
    return IntentResult(
      type: IntentType.findLatestFile,
      success: true,
      response: 'Oxirgi fayl topildi: ${file['name']}',
      data: file,
    );
  }

  Future<IntentResult> _findFile(IntentMatch match) async {
    final query = match.slots['query'] as String? ?? '';
    if (query.isEmpty) {
      return const IntentResult(
        type: IntentType.findFile,
        success: false,
        response: 'Qidiruv so‘rovi kerak.',
      );
    }
    final type = match.slots['type'] as String?;
    if (type == 'pdf' && _documentIndexStore != null) {
      final rows = await _documentIndexStore!.search(query);
      if (rows.isNotEmpty) {
        return IntentResult(
          type: IntentType.findFile,
          success: true,
          response: 'Hujjat topildi: ${rows.first['name']}',
          data: {'results': rows},
        );
      }
    }
    final results = await AndroidBridge.searchFiles(query: query, type: type);
    if (results.isEmpty) {
      return const IntentResult(
        type: IntentType.findFile,
        success: false,
        response: 'Fayl topilmadi.',
      );
    }
    return IntentResult(
      type: IntentType.findFile,
      success: true,
      response: 'Bitta fayl topildi: ${results.first['name']}',
      data: {'results': results},
    );
  }

  Future<IntentResult> _shareToTelegram(IntentMatch match) async {
    final file = match.slots['fileUri'] as String?;
    if (file == null) {
      return const IntentResult(
        type: IntentType.shareFileToTelegram,
        success: false,
        response: 'Ulash uchun fayl topilmadi.',
      );
    }
    await AndroidBridge.shareToTelegram(file);
    return const IntentResult(
      type: IntentType.shareFileToTelegram,
      success: true,
      response: 'Telegram ulash oynasini ochdim.',
    );
  }

  Future<IntentResult> _openApp(IntentMatch match) async {
    final alias = match.slots['appAlias'] as String?;
    if (alias == null || alias.isEmpty) {
      return const IntentResult(
        type: IntentType.openApp,
        success: false,
        response: 'Ilova nomi kerak.',
      );
    }
    await AndroidBridge.openApp(alias);
    return IntentResult(
      type: IntentType.openApp,
      success: true,
      response: '$alias ilovasini ochyapman.',
    );
  }
}
