class DialogueTurn {
  final String user;
  final String assistant;
  final DateTime timestamp;

  DialogueTurn({
    required this.user,
    required this.assistant,
    required this.timestamp,
  });
}

class DialogueManager {
  DialogueManager({this.maxTurns = 5});

  final int maxTurns;
  final List<DialogueTurn> _turns = [];

  List<DialogueTurn> get turns => List.unmodifiable(_turns);

  void addTurn(String user, String assistant) {
    _turns.add(DialogueTurn(user: user, assistant: assistant, timestamp: DateTime.now()));
    if (_turns.length > maxTurns) {
      _turns.removeRange(0, _turns.length - maxTurns);
    }
  }
}
