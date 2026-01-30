import '../models/intent.dart';
import '../utils/text_utils.dart';

class IntentParser {
  IntentMatch parse(String transcript) {
    final normalized = normalizeText(transcript);

    if (_matches(normalized, ['find latest file', 'latest file', 'latest photo', 'latest image'])) {
      return IntentMatch(
        type: IntentType.findLatestFile,
        confidence: 0.72,
        slots: {'type': _inferType(normalized)},
      );
    }

    if (_matches(normalized, ['find file', 'search file', 'find document'])) {
      return IntentMatch(
        type: IntentType.findFile,
        confidence: 0.68,
        slots: {'query': _extractQuery(normalized)},
      );
    }

    if (_matches(normalized, ['share to telegram', 'send to telegram'])) {
      return IntentMatch(
        type: IntentType.shareFileToTelegram,
        confidence: 0.7,
        slots: {'targetName': _extractTargetName(normalized)},
      );
    }

    if (_matches(normalized, ['open app', 'launch'])) {
      return IntentMatch(
        type: IntentType.openApp,
        confidence: 0.7,
        slots: {'appAlias': _extractAppAlias(normalized)},
      );
    }

    if (_matches(normalized, ['selfie', 'front camera', 'open camera'])) {
      return const IntentMatch(
        type: IntentType.openCameraSelfie,
        confidence: 0.75,
        slots: {},
      );
    }

    final timerMinutes = _extractMinutes(normalized);
    if (_matches(normalized, ['set timer', 'timer']) && timerMinutes != null) {
      return IntentMatch(
        type: IntentType.setTimer,
        confidence: 0.76,
        slots: {'minutes': timerMinutes},
      );
    }

    final alarmTime = _extractAlarm(normalized);
    if (_matches(normalized, ['set alarm', 'alarm']) && alarmTime != null) {
      return IntentMatch(
        type: IntentType.setAlarm,
        confidence: 0.74,
        slots: {'time': alarmTime},
      );
    }

    if (_matches(normalized, ['time', 'what time'])) {
      return const IntentMatch(
        type: IntentType.getTime,
        confidence: 0.8,
        slots: {},
      );
    }

    if (_matches(normalized, ['battery'])) {
      return const IntentMatch(
        type: IntentType.getBatteryPercent,
        confidence: 0.7,
        slots: {},
      );
    }

    if (_matches(normalized, ['storage', 'free space'])) {
      return const IntentMatch(
        type: IntentType.getStorageFree,
        confidence: 0.7,
        slots: {},
      );
    }

    if (_matches(normalized, ['flashlight', 'torch'])) {
      final on = normalized.contains('on') || normalized.contains('enable');
      return IntentMatch(
        type: IntentType.flashlight,
        confidence: 0.68,
        slots: {'on': on},
      );
    }

    final brightness = _extractPercent(normalized);
    if (_matches(normalized, ['brightness']) && brightness != null) {
      return IntentMatch(
        type: IntentType.setBrightness,
        confidence: 0.68,
        slots: {'percent': brightness},
      );
    }

    final volume = _extractPercent(normalized);
    if (_matches(normalized, ['volume', 'sound']) && volume != null) {
      return IntentMatch(
        type: IntentType.setVolume,
        confidence: 0.68,
        slots: {'level': volume},
      );
    }

    if (_matches(normalized, ['wifi', 'wi fi'])) {
      return const IntentMatch(
        type: IntentType.wifiSettings,
        confidence: 0.72,
        slots: {},
      );
    }

    if (_matches(normalized, ['bluetooth', 'bt'])) {
      return const IntentMatch(
        type: IntentType.bluetoothSettings,
        confidence: 0.72,
        slots: {},
      );
    }

    if (_matches(normalized, ['last telegram', 'telegram message'])) {
      return IntentMatch(
        type: IntentType.readLastTelegramNotification,
        confidence: 0.72,
        slots: {'senderContains': _extractTargetName(normalized)},
      );
    }

    return const IntentMatch(
      type: IntentType.unknown,
      confidence: 0.2,
      slots: {},
    );
  }

  bool _matches(String input, List<String> phrases) {
    return phrases.any((p) => input.contains(p));
  }

  String _inferType(String input) {
    if (input.contains('pdf')) return 'pdf';
    if (input.contains('image') || input.contains('photo') || input.contains('foto')) return 'image';
    if (input.contains('video')) return 'video';
    return 'any';
  }

  String? _extractQuery(String input) {
    final idx = input.indexOf('find');
    if (idx == -1) return null;
    return input.substring(idx).replaceAll('find', '').replaceAll('file', '').trim();
  }

  String? _extractTargetName(String input) {
    final words = input.split(' ');
    if (words.length < 2) return null;
    return words.last;
  }

  String? _extractAppAlias(String input) {
    final words = input.split(' ');
    if (words.isEmpty) return null;
    return words.last;
  }

  int? _extractMinutes(String input) {
    final match = RegExp(r'(\d{1,3})\s*(minute|min)').firstMatch(input);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }

  String? _extractAlarm(String input) {
    final match = RegExp(r'(\d{1,2})[:.](\d{2})').firstMatch(input);
    if (match == null) return null;
    return '${match.group(1)}:${match.group(2)}';
  }

  int? _extractPercent(String input) {
    final match = RegExp(r'(\d{1,3})\s*(percent|%)').firstMatch(input);
    if (match == null) return null;
    final value = int.tryParse(match.group(1)!);
    if (value == null) return null;
    return value.clamp(0, 100);
  }
}
