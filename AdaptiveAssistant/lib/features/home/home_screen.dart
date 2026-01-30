import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/assistant/assistant_controller.dart';
import '../../core/models/assistant_state.dart';
import '../../core/models/intent.dart';
import '../../core/platform/android_bridge.dart';
import '../../core/settings/settings_controller.dart';
import '../../widgets/assistant_pill.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistant = ref.watch(assistantControllerProvider);
    final settings = ref.watch(settingsControllerProvider);

    final status = _statusLabel(assistant.mode, settings.assistantName);

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Salom, ${settings.assistantName}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    assistant.transcript ?? 'Men doimo tinglayman. “Hey ${settings.assistantName}” deyishingiz mumkin.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF3A4248),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showTypedInput(context, ref),
                        icon: const Icon(Icons.keyboard),
                        label: const Text('Type command'),
                      ),
                    ],
                  ),
                  if (assistant.response != null)
                    Text(
                      assistant.response!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF1F5B5E),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  const SizedBox(height: 24),
                  _buildConfirmationCard(context, assistant, ref),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AssistantPill(
              status: status,
              onMute: () async {
                await AndroidBridge.pauseWakeWord();
              },
              onStop: () async {
                await AndroidBridge.stopStt();
              },
              onSettings: () => Navigator.of(context).pushNamed('/settings'),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AssistantMode mode, String name) {
    switch (mode) {
      case AssistantMode.idle:
        return '$name kutmoqda';
      case AssistantMode.listening:
        return '$name tinglayapti';
      case AssistantMode.thinking:
        return '$name o‘ylayapti';
      case AssistantMode.speaking:
        return '$name javob bermoqda';
    }
  }

  Widget _buildConfirmationCard(BuildContext context, AssistantState state, WidgetRef ref) {
    if (state.confirmations.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qaysi buyruqni nazarda tutdingiz?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: state.confirmations
                  .map(
                    (option) => ActionChip(
                      label: Text(option.label),
                      onPressed: () async {
                        final typeName = option.payload['type'] as String? ?? 'unknown';
                        final intentType = IntentType.values.firstWhere(
                          (e) => e.name == typeName,
                          orElse: () => IntentType.unknown,
                        );
                        final slots = option.payload['slots'] as Map<String, dynamic>? ?? {};
                        await ref.read(assistantControllerProvider.notifier).confirmIntent(
                              IntentMatch(type: intentType, confidence: 0.8, slots: slots),
                              state.transcript ?? '',
                            );
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTypedInput(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Type your command',
                ),
                autofocus: true,
                onSubmitted: (value) async {
                  if (value.trim().isEmpty) return;
                  Navigator.of(ctx).pop();
                  await ref.read(assistantControllerProvider.notifier).handleTranscript(value.trim());
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop();
                  await ref.read(assistantControllerProvider.notifier).handleTranscript(controller.text.trim());
                },
                child: const Text('Send'),
              ),
            ],
          ),
        );
      },
    );
  }
}
