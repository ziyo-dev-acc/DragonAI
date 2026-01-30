import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  throw UnimplementedError('settingsControllerProvider must be overridden');
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController(this._prefs, AppSettings settings) : super(settings);

  final SharedPreferences _prefs;

  static const _assistantNameKey = 'assistantName';
  static const _wakeEnabledKey = 'wakeWordEnabled';
  static const _wakeSensitivityKey = 'wakeWordSensitivity';
  static const _pauseScreenKey = 'pauseOnScreenOff';
  static const _pauseBatteryKey = 'pauseOnLowBattery';
  static const _lowBatteryKey = 'lowBatteryThreshold';
  static const _wakeWordAssetKey = 'wakeWordAsset';
  static const _wakeWordSourceKey = 'wakeWordSource';
  static const _trainingKey = 'trainingMode';
  static const _cloudHelpKey = 'cloudHelpEnabled';
  static const _cloudFileContextKey = 'allowFileContextToCloud';
  static const _verbosityKey = 'verbosity';
  static const _localEnabledKey = 'localLlmEnabled';
  static const _localTokensKey = 'localMaxTokens';
  static const _localTempKey = 'localTemperature';
  static const _localMaxTimeKey = 'localMaxTimeMs';
  static const _localThreadsKey = 'localThreads';
  static const _localContextKey = 'localContextSize';

  static Future<SettingsController> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = AppSettings.defaults();
    final settings = defaults.copyWith(
      assistantName: prefs.getString(_assistantNameKey),
      wakeWordEnabled: prefs.getBool(_wakeEnabledKey),
      wakeWordSensitivity: prefs.getDouble(_wakeSensitivityKey),
      pauseOnScreenOff: prefs.getBool(_pauseScreenKey),
      pauseOnLowBattery: prefs.getBool(_pauseBatteryKey),
      lowBatteryThreshold: prefs.getInt(_lowBatteryKey),
      wakeWordAsset: prefs.getString(_wakeWordAssetKey),
      wakeWordSource: prefs.getString(_wakeWordSourceKey),
      trainingMode: prefs.getBool(_trainingKey),
      cloudHelpEnabled: prefs.getBool(_cloudHelpKey),
      allowFileContextToCloud: prefs.getBool(_cloudFileContextKey),
      verbosity: prefs.getInt(_verbosityKey),
      localLlmEnabled: prefs.getBool(_localEnabledKey),
      localMaxTokens: prefs.getInt(_localTokensKey),
      localTemperature: prefs.getDouble(_localTempKey),
      localMaxTimeMs: prefs.getInt(_localMaxTimeKey),
      localThreads: prefs.getInt(_localThreadsKey),
      localContextSize: prefs.getInt(_localContextKey),
    );

    return SettingsController(prefs, settings);
  }

  Future<void> update(AppSettings next) async {
    state = next;
    await _prefs.setString(_assistantNameKey, next.assistantName);
    await _prefs.setBool(_wakeEnabledKey, next.wakeWordEnabled);
    await _prefs.setDouble(_wakeSensitivityKey, next.wakeWordSensitivity);
    await _prefs.setBool(_pauseScreenKey, next.pauseOnScreenOff);
    await _prefs.setBool(_pauseBatteryKey, next.pauseOnLowBattery);
    await _prefs.setInt(_lowBatteryKey, next.lowBatteryThreshold);
    await _prefs.setString(_wakeWordAssetKey, next.wakeWordAsset);
    await _prefs.setString(_wakeWordSourceKey, next.wakeWordSource);
    await _prefs.setBool(_trainingKey, next.trainingMode);
    await _prefs.setBool(_cloudHelpKey, next.cloudHelpEnabled);
    await _prefs.setBool(_cloudFileContextKey, next.allowFileContextToCloud);
    await _prefs.setInt(_verbosityKey, next.verbosity);
    await _prefs.setBool(_localEnabledKey, next.localLlmEnabled);
    await _prefs.setInt(_localTokensKey, next.localMaxTokens);
    await _prefs.setDouble(_localTempKey, next.localTemperature);
    await _prefs.setInt(_localMaxTimeKey, next.localMaxTimeMs);
    await _prefs.setInt(_localThreadsKey, next.localThreads);
    await _prefs.setInt(_localContextKey, next.localContextSize);
  }
}
