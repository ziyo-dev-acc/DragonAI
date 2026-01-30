import '../platform/android_bridge.dart';

class LocalLlmService {
  Future<Map<String, dynamic>> getModelInfo() => AndroidBridge.getLocalModelInfo();

  Future<void> loadModel(String uri) => AndroidBridge.loadLocalModel(uri);

  Future<String?> rewrite({required String text, required Map<String, dynamic> config}) async {
    return AndroidBridge.rewriteWithLocalLlm(text, config);
  }

  Future<void> unloadModel() => AndroidBridge.unloadLocalModel();

  Future<int?> getModelSizeMb(String uri) => AndroidBridge.getLocalModelSizeMb(uri);
}
