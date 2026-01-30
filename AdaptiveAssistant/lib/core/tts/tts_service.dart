import '../platform/android_bridge.dart';

class TtsService {
  Future<void> speak(String text, {required String assistantName}) async {
    await AndroidBridge.speak(text, assistantName);
  }
}
