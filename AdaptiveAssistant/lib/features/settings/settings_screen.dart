import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_settings.dart';
import '../../core/settings/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  List<String> _wakeModels = const ['porcupine/ari.ppn'];

  @override
  void initState() {
    super.initState();
    _loadWakeModels();
  }

  Future<void> _loadWakeModels() async {
    try {
      final manifestJson = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      final models = manifest.keys
          .where((key) => key.startsWith('assets/porcupine/') && key.endsWith('.ppn'))
          .map((key) => key.replaceFirst('assets/', ''))
          .toList()
        ..sort();
      if (models.isNotEmpty) {
        setState(() => _wakeModels = models);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Assistant'),
          TextFormField(
            initialValue: settings.assistantName,
            decoration: const InputDecoration(labelText: 'Assistant name'),
            onFieldSubmitted: (value) {
              controller.update(settings.copyWith(assistantName: value.trim()));
            },
          ),
          SwitchListTile(
            title: const Text('Wake word enabled'),
            value: settings.wakeWordEnabled,
            onChanged: (value) => controller.update(settings.copyWith(wakeWordEnabled: value)),
          ),
          ListTile(
            title: const Text('Wake word sensitivity'),
            subtitle: Slider(
              value: settings.wakeWordSensitivity,
              min: 0.3,
              max: 0.95,
              onChanged: (value) => controller.update(settings.copyWith(wakeWordSensitivity: value)),
            ),
          ),
          SwitchListTile(
            title: const Text('Pause on screen off'),
            value: settings.pauseOnScreenOff,
            onChanged: (value) => controller.update(settings.copyWith(pauseOnScreenOff: value)),
          ),
          SwitchListTile(
            title: const Text('Pause on low battery'),
            value: settings.pauseOnLowBattery,
            onChanged: (value) => controller.update(settings.copyWith(pauseOnLowBattery: value)),
          ),
          ListTile(
            title: const Text('Wake word model (assets)'),
            subtitle: Text(settings.wakeWordAsset),
            trailing: const Icon(Icons.expand_more),
            onTap: () async {
              final selection = await _chooseWakeModel(context, settings.wakeWordAsset);
              if (selection != null) {
                controller.update(
                  settings.copyWith(wakeWordAsset: selection, wakeWordSource: 'asset'),
                );
              }
            },
          ),
          ListTile(
            title: const Text('Import wake word (.ppn)'),
            subtitle: Text(settings.wakeWordSource == 'uri' ? settings.wakeWordAsset : 'Not set'),
            trailing: const Icon(Icons.file_open),
            onTap: () async {
              final uri = await AndroidBridge.pickWakeWordFile();
              if (uri != null) {
                controller.update(settings.copyWith(wakeWordAsset: uri, wakeWordSource: 'uri'));
              }
            },
          ),
          ListTile(
            title: const Text('Low battery threshold'),
            subtitle: Slider(
              value: settings.lowBatteryThreshold.toDouble(),
              min: 5,
              max: 40,
              divisions: 7,
              label: '${settings.lowBatteryThreshold}%',
              onChanged: (value) => controller.update(settings.copyWith(lowBatteryThreshold: value.toInt())),
            ),
          ),
          const Divider(height: 32),
          _sectionTitle('Local LLM'),
          SwitchListTile(
            title: const Text('Enable local LLM'),
            value: settings.localLlmEnabled,
            onChanged: (value) => controller.update(settings.copyWith(localLlmEnabled: value)),
          ),
          ListTile(
            title: const Text('Max tokens'),
            subtitle: Slider(
              value: settings.localMaxTokens.toDouble(),
              min: 32,
              max: 256,
              divisions: 7,
              label: '${settings.localMaxTokens}',
              onChanged: (value) => controller.update(settings.copyWith(localMaxTokens: value.toInt())),
            ),
          ),
          ListTile(
            title: const Text('Temperature'),
            subtitle: Slider(
              value: settings.localTemperature,
              min: 0.1,
              max: 1.0,
              onChanged: (value) => controller.update(settings.copyWith(localTemperature: value)),
            ),
          ),
          ListTile(
            title: const Text('Max inference time (ms)'),
            subtitle: Slider(
              value: settings.localMaxTimeMs.toDouble(),
              min: 500,
              max: 8000,
              divisions: 15,
              label: '${settings.localMaxTimeMs}',
              onChanged: (value) => controller.update(settings.copyWith(localMaxTimeMs: value.toInt())),
            ),
          ),
          ListTile(
            title: const Text('CPU threads'),
            subtitle: Slider(
              value: settings.localThreads.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              label: '${settings.localThreads}',
              onChanged: (value) => controller.update(settings.copyWith(localThreads: value.toInt())),
            ),
          ),
          ListTile(
            title: const Text('Context size'),
            subtitle: Slider(
              value: settings.localContextSize.toDouble(),
              min: 256,
              max: 1024,
              divisions: 3,
              label: '${settings.localContextSize}',
              onChanged: (value) => controller.update(settings.copyWith(localContextSize: value.toInt())),
            ),
          ),
          ListTile(
            title: const Text('Model manager'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/model-manager'),
          ),
          const Divider(height: 32),
          _sectionTitle('Cloud help'),
          SwitchListTile(
            title: const Text('Enable cloud LLM help'),
            value: settings.cloudHelpEnabled,
            onChanged: (value) => controller.update(settings.copyWith(cloudHelpEnabled: value)),
          ),
          SwitchListTile(
            title: const Text('Allow sharing file names/context'),
            subtitle: const Text('Disabled by default'),
            value: settings.allowFileContextToCloud,
            onChanged: (value) => controller.update(settings.copyWith(allowFileContextToCloud: value)),
          ),
          const Divider(height: 32),
          _sectionTitle('Training & Learning'),
          SwitchListTile(
            title: const Text('Training mode'),
            value: settings.trainingMode,
            onChanged: (value) => controller.update(settings.copyWith(trainingMode: value)),
          ),
          ListTile(
            title: const Text('Learned commands'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/learned'),
          ),
          const Divider(height: 32),
          _sectionTitle('Setup'),
          ListTile(
            title: const Text('Permissions & access'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/setup'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  Future<String?> _chooseWakeModel(BuildContext context, String current) async {
    final options = _wakeModels.isEmpty ? [current] : _wakeModels;
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: options
              .map(
                (item) => RadioListTile<String>(
                  title: Text(item),
                  value: item,
                  groupValue: current,
                  onChanged: (value) => Navigator.of(ctx).pop(value),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
