import '../models/intent.dart';
import '../utils/text_utils.dart';
import 'training_store.dart';

class LearnedMatcher {
  LearnedMatcher(this._store);

  final TrainingStore _store;

  Future<IntentMatch?> match(String transcript) async {
    final learned = await _store.getLearnedCommands();
    if (learned.isEmpty) return null;
    final tokens = tokenize(transcript);

    double bestScore = 0;
    LearnedCommand? best;
    for (final cmd in learned) {
      final score = _score(tokens, tokenize(cmd.phrase));
      if (score > bestScore) {
        bestScore = score;
        best = cmd;
      }
    }

    if (best == null || bestScore < 0.55) return null;
    return IntentMatch(
      type: _mapIntent(best.intentName),
      confidence: bestScore,
      slots: best.slots,
    );
  }

  double _score(Set<String> a, Set<String> b) {
    final jaccard = jaccardSimilarity(a, b);
    final cosine = cosineSimilarity(a, b);
    return (jaccard * 0.6) + (cosine * 0.4);
  }

  IntentType _mapIntent(String name) {
    return IntentType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => IntentType.unknown,
    );
  }
}
