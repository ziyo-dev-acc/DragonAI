import 'dart:math';

import '../models/intent.dart';

class ResponseComposer {
  ResponseComposer({Random? random}) : _random = random ?? Random();

  final Random _random;

  String compose(IntentResult result, {int verbosity = 1}) {
    final options = _templates[result.type] ?? _defaultTemplates;
    final chosen = options[_random.nextInt(options.length)];
    if (verbosity <= 0) {
      return chosen.split('.').first;
    }
    return chosen;
  }
}

const _defaultTemplates = [
  'Mayli, bajarildi.',
  'Tayyor.',
  'Bo‘ldi.',
];

const Map<IntentType, List<String>> _templates = {
  IntentType.getTime: [
    'Hozirgi vaqtni aytdim.',
    'Mana vaqt.',
  ],
  IntentType.setTimer: [
    'Timer yoqildi.',
    'Hisoblashni boshladim.',
  ],
  IntentType.setAlarm: [
    'Budilnik qo‘yildi.',
    'Signal sozlandi.',
  ],
  IntentType.openApp: [
    'Ilovani ochyapman.',
    'Hozir ishga tushiraman.',
  ],
  IntentType.flashlight: [
    'Chiroqni sozladim.',
    'Flashlight holatini o‘zgartirdim.',
  ],
  IntentType.getBatteryPercent: [
    'Batareya holatini ko‘rsatdim.',
  ],
  IntentType.getStorageFree: [
    'Xotira holatini ko‘rsatdim.',
  ],
};
