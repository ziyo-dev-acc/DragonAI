class AppSettings {
  final String assistantName;
  final bool wakeWordEnabled;
  final double wakeWordSensitivity;
  final bool pauseOnScreenOff;
  final bool pauseOnLowBattery;
  final int lowBatteryThreshold;
  final String wakeWordAsset;
  final String wakeWordSource;
  final bool trainingMode;
  final bool cloudHelpEnabled;
  final bool allowFileContextToCloud;
  final int verbosity;
  final bool localLlmEnabled;
  final int localMaxTokens;
  final double localTemperature;
  final int localMaxTimeMs;
  final int localThreads;
  final int localContextSize;

  const AppSettings({
    required this.assistantName,
    required this.wakeWordEnabled,
    required this.wakeWordSensitivity,
    required this.pauseOnScreenOff,
    required this.pauseOnLowBattery,
    required this.lowBatteryThreshold,
    required this.wakeWordAsset,
    required this.wakeWordSource,
    required this.trainingMode,
    required this.cloudHelpEnabled,
    required this.allowFileContextToCloud,
    required this.verbosity,
    required this.localLlmEnabled,
    required this.localMaxTokens,
    required this.localTemperature,
    required this.localMaxTimeMs,
    required this.localThreads,
    required this.localContextSize,
  });

  factory AppSettings.defaults() => const AppSettings(
        assistantName: 'Ari',
        wakeWordEnabled: true,
        wakeWordSensitivity: 0.6,
        pauseOnScreenOff: false,
        pauseOnLowBattery: true,
        lowBatteryThreshold: 15,
        wakeWordAsset: 'porcupine/ari.ppn',
        wakeWordSource: 'asset',
        trainingMode: false,
        cloudHelpEnabled: false,
        allowFileContextToCloud: false,
        verbosity: 1,
        localLlmEnabled: false,
        localMaxTokens: 96,
        localTemperature: 0.4,
        localMaxTimeMs: 2000,
        localThreads: 2,
        localContextSize: 512,
      );

  AppSettings copyWith({
    String? assistantName,
    bool? wakeWordEnabled,
    double? wakeWordSensitivity,
    bool? pauseOnScreenOff,
    bool? pauseOnLowBattery,
    int? lowBatteryThreshold,
    String? wakeWordAsset,
    String? wakeWordSource,
    bool? trainingMode,
    bool? cloudHelpEnabled,
    bool? allowFileContextToCloud,
    int? verbosity,
    bool? localLlmEnabled,
    int? localMaxTokens,
    double? localTemperature,
    int? localMaxTimeMs,
    int? localThreads,
    int? localContextSize,
  }) {
    return AppSettings(
      assistantName: assistantName ?? this.assistantName,
      wakeWordEnabled: wakeWordEnabled ?? this.wakeWordEnabled,
      wakeWordSensitivity: wakeWordSensitivity ?? this.wakeWordSensitivity,
      pauseOnScreenOff: pauseOnScreenOff ?? this.pauseOnScreenOff,
      pauseOnLowBattery: pauseOnLowBattery ?? this.pauseOnLowBattery,
      lowBatteryThreshold: lowBatteryThreshold ?? this.lowBatteryThreshold,
      wakeWordAsset: wakeWordAsset ?? this.wakeWordAsset,
      wakeWordSource: wakeWordSource ?? this.wakeWordSource,
      trainingMode: trainingMode ?? this.trainingMode,
      cloudHelpEnabled: cloudHelpEnabled ?? this.cloudHelpEnabled,
      allowFileContextToCloud: allowFileContextToCloud ?? this.allowFileContextToCloud,
      verbosity: verbosity ?? this.verbosity,
      localLlmEnabled: localLlmEnabled ?? this.localLlmEnabled,
      localMaxTokens: localMaxTokens ?? this.localMaxTokens,
      localTemperature: localTemperature ?? this.localTemperature,
      localMaxTimeMs: localMaxTimeMs ?? this.localMaxTimeMs,
      localThreads: localThreads ?? this.localThreads,
      localContextSize: localContextSize ?? this.localContextSize,
    );
  }
}
