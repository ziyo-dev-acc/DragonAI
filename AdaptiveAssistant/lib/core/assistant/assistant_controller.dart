import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dialogue/dialogue_manager.dart';
import '../intents/intent_parser.dart';
import '../intents/skill_engine.dart';
import '../learning/learned_matcher.dart';
import '../learning/training_store.dart';
import '../ml/local_llm_service.dart';
import '../models/app_settings.dart';
import '../models/assistant_state.dart';
import '../models/intent.dart';
import '../platform/android_bridge.dart';
import '../responses/response_composer.dart';
import '../settings/settings_controller.dart';
import '../storage/app_database.dart';
import '../storage/document_index_store.dart';
import '../tts/tts_service.dart';

final assistantControllerProvider =
    StateNotifierProvider<AssistantController, AssistantState>((ref) {
  final settings = ref.watch(settingsControllerProvider);
  final db = ref.watch(appDatabaseProvider);
  return AssistantController(
    settingsController: ref.read(settingsControllerProvider.notifier),
    settings: settings,
    parser: IntentParser(),
    skillEngine: SkillEngine(documentIndexStore: DocumentIndexStore(db)),
    responseComposer: ResponseComposer(),
    dialogueManager: DialogueManager(),
    trainingStore: TrainingStore(db),
    learnedMatcher: LearnedMatcher(TrainingStore(db)),
    ttsService: TtsService(),
    localLlmService: LocalLlmService(),
  );
});

class AssistantController extends StateNotifier<AssistantState> {
  AssistantController({
    required this.settingsController,
    required this.settings,
    required this.parser,
    required this.skillEngine,
    required this.responseComposer,
    required this.dialogueManager,
    required this.trainingStore,
    required this.learnedMatcher,
    required this.ttsService,
    required this.localLlmService,
  }) : super(const AssistantState(mode: AssistantMode.idle, wakeWordActive: false)) {
    _listenWake();
    _listenStt();
    _syncWakeWord();
  }

  final SettingsController settingsController;
  final AppSettings settings;
  final IntentParser parser;
  final SkillEngine skillEngine;
  final ResponseComposer responseComposer;
  final DialogueManager dialogueManager;
  final TrainingStore trainingStore;
  final LearnedMatcher learnedMatcher;
  final TtsService ttsService;
  final LocalLlmService localLlmService;

  StreamSubscription? _wakeSub;
  StreamSubscription? _sttSub;
  IntentMatch? _pendingMatch;

  void updateSettings(dynamic next) {
    _syncWakeWord();
  }

  Future<void> _syncWakeWord() async {
    if (settings.wakeWordEnabled) {
      await AndroidBridge.startWakeWord(
        assistantName: settings.assistantName,
        sensitivity: settings.wakeWordSensitivity,
        pauseOnScreenOff: settings.pauseOnScreenOff,
        pauseOnLowBattery: settings.pauseOnLowBattery,
        lowBatteryThreshold: settings.lowBatteryThreshold,
        wakeWordAsset: settings.wakeWordAsset,
        wakeWordSource: settings.wakeWordSource,
      );
      state = state.copyWith(wakeWordActive: true);
    } else {
      await AndroidBridge.stopWakeWord();
      state = state.copyWith(wakeWordActive: false);
    }
  }

  void _listenWake() {
    _wakeSub?.cancel();
    _wakeSub = AndroidBridge.wakeEvents().listen((event) async {
      if (event is Map && event['type'] == 'wake') {
        await AndroidBridge.playEarcon();
        state = state.copyWith(mode: AssistantMode.listening, confirmations: []);
        await AndroidBridge.startStt();
      }
    });
  }

  void _listenStt() {
    _sttSub?.cancel();
    _sttSub = AndroidBridge.sttEvents().listen((event) async {
      if (event is Map && event['type'] == 'partial') {
        state = state.copyWith(transcript: event['text'] as String?);
      } else if (event is Map && event['type'] == 'final') {
        final text = event['text'] as String?;
        if (text == null || text.isEmpty) return;
        await handleTranscript(text);
      }
    });
  }

  Future<void> handleTranscript(String transcript) async {
    state = state.copyWith(mode: AssistantMode.thinking, transcript: transcript, confirmations: []);
    IntentMatch match = parser.parse(transcript);

    final learned = await learnedMatcher.match(transcript);
    if (learned != null && learned.confidence > match.confidence) {
      match = learned;
    }

    if (match.confidence < 0.5) {
      _pendingMatch = match;
      state = state.copyWith(
        mode: AssistantMode.listening,
        response: 'Aniq emas. Tasdiqlaysizmi?',
        confirmations: _buildSuggestions(transcript),
      );
      return;
    }

    await _executeMatch(match, transcript);
  }

  List<ConfirmationOption> _buildSuggestions(String transcript) {
    return [
      ConfirmationOption(
        label: 'Timer qo‘yish',
        payload: {'type': IntentType.setTimer.name, 'slots': {'minutes': 5}},
      ),
      ConfirmationOption(
        label: 'Budilnik sozlash',
        payload: {'type': IntentType.setAlarm.name, 'slots': {'time': '07:00'}},
      ),
      ConfirmationOption(
        label: 'Ilovani ochish',
        payload: {'type': IntentType.openApp.name, 'slots': {'appAlias': 'Telegram'}},
      ),
      ConfirmationOption(
        label: 'Vaqtni aytish',
        payload: {'type': IntentType.getTime.name, 'slots': {}},
      ),
    ];
  }

  Future<void> confirmIntent(IntentMatch match, String transcript) async {
    await _executeMatch(match, transcript);
  }

  Future<void> _executeMatch(IntentMatch match, String transcript) async {
    final result = await skillEngine.execute(match);
    var response = result.response;

    if (settings.localLlmEnabled) {
      final rewrite = await localLlmService.rewrite(
        text: response,
        config: {
          'maxTokens': settings.localMaxTokens,
          'temperature': settings.localTemperature,
          'maxTimeMs': settings.localMaxTimeMs,
          'threads': settings.localThreads,
          'contextSize': settings.localContextSize,
        },
      );
      if (rewrite != null && rewrite.isNotEmpty) {
        response = rewrite;
      }
    }

    if (settings.trainingMode) {
      await trainingStore.logEvent(
        transcript: transcript,
        intentName: match.type.name,
        slots: match.slots,
        confidence: match.confidence,
        outcome: result.success ? 'success' : 'failure',
      );
    }

    dialogueManager.addTurn(transcript, response);
    state = state.copyWith(mode: AssistantMode.speaking, response: response, confirmations: []);
    await ttsService.speak(response, assistantName: settings.assistantName);
    state = state.copyWith(mode: AssistantMode.idle);
  }

  @override
  void dispose() {
    _wakeSub?.cancel();
    _sttSub?.cancel();
    super.dispose();
  }
}
