import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ml/local_llm_service.dart';
import '../../core/platform/android_bridge.dart';

class ModelManagerScreen extends ConsumerStatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  ConsumerState<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends ConsumerState<ModelManagerScreen> {
  Map<String, dynamic> _modelInfo = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    setState(() => _loading = true);
    final service = LocalLlmService();
    final info = await service.getModelInfo();
    setState(() {
      _modelInfo = info;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Model Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${_modelInfo['status'] ?? 'Not loaded'}'),
                  const SizedBox(height: 8),
                  Text('Size: ${_modelInfo['sizeMb'] ?? '-'} MB'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await LocalLlmService().getModelInfo();
                      setState(() => _modelInfo = result);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final uri = await _pickModel();
                      if (uri == null) return;
                      final sizeMb = await LocalLlmService().getModelSizeMb(uri);
                      final shouldContinue = await _confirmLargeModel(context, sizeMb);
                      if (!shouldContinue) return;
                      await LocalLlmService().loadModel(uri);
                      await _loadInfo();
                    },
                    icon: const Icon(Icons.file_open),
                    label: const Text('Select GGUF model'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await LocalLlmService().unloadModel();
                      await _loadInfo();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove model'),
                  ),
                ],
              ),
      ),
    );
  }

  Future<String?> _pickModel() async {
    return AndroidBridge.pickLocalModel();
  }

  Future<bool> _confirmLargeModel(BuildContext context, int? sizeMb) async {
    if (sizeMb == null || sizeMb < 1200) return true;
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Large model'),
            content: Text('This model is about $sizeMb MB. Import anyway?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Import'),
              ),
            ],
          ),
        )) ??
        false;
  }
}
