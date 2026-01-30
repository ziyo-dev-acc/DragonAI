enum AssistantMode {
  idle,
  listening,
  thinking,
  speaking,
}

class ConfirmationOption {
  final String label;
  final Map<String, dynamic> payload;

  const ConfirmationOption({required this.label, required this.payload});
}

class AssistantState {
  final AssistantMode mode;
  final String? transcript;
  final String? response;
  final bool wakeWordActive;
  final List<ConfirmationOption> confirmations;

  const AssistantState({
    required this.mode,
    required this.wakeWordActive,
    this.transcript,
    this.response,
    this.confirmations = const [],
  });

  AssistantState copyWith({
    AssistantMode? mode,
    String? transcript,
    String? response,
    bool? wakeWordActive,
    List<ConfirmationOption>? confirmations,
  }) {
    return AssistantState(
      mode: mode ?? this.mode,
      transcript: transcript ?? this.transcript,
      response: response ?? this.response,
      wakeWordActive: wakeWordActive ?? this.wakeWordActive,
      confirmations: confirmations ?? this.confirmations,
    );
  }
}
