import 'dart:convert';

import '../storage/app_database.dart';

class TrainingEvent {
  final int id;
  final String transcript;
  final String? intentName;
  final Map<String, dynamic>? slots;
  final double? confidence;
  final String? outcome;
  final DateTime createdAt;

  TrainingEvent({
    required this.id,
    required this.transcript,
    required this.intentName,
    required this.slots,
    required this.confidence,
    required this.outcome,
    required this.createdAt,
  });
}

class LearnedCommand {
  final int id;
  final String phrase;
  final String intentName;
  final Map<String, dynamic> slots;

  LearnedCommand({
    required this.id,
    required this.phrase,
    required this.intentName,
    required this.slots,
  });
}

class TrainingStore {
  TrainingStore(this._db);

  final AppDatabase _db;

  Future<void> logEvent({
    required String transcript,
    String? intentName,
    Map<String, dynamic>? slots,
    double? confidence,
    String? outcome,
  }) async {
    await _db.raw.insert('training_events', {
      'transcript': transcript,
      'intent_name': intentName,
      'slots_json': slots == null ? null : jsonEncode(slots),
      'confidence': confidence,
      'outcome': outcome,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<LearnedCommand>> getLearnedCommands() async {
    final rows = await _db.raw.query('learned_commands', orderBy: 'created_at DESC');
    return rows
        .map(
          (row) => LearnedCommand(
            id: row['id'] as int,
            phrase: row['phrase'] as String,
            intentName: row['intent_name'] as String,
            slots: row['slots_json'] == null
                ? {}
                : jsonDecode(row['slots_json'] as String) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> addLearnedCommand({
    required String phrase,
    required String intentName,
    required Map<String, dynamic> slots,
  }) async {
    await _db.raw.insert('learned_commands', {
      'phrase': phrase,
      'intent_name': intentName,
      'slots_json': jsonEncode(slots),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> deleteLearned(int id) async {
    await _db.raw.delete('learned_commands', where: 'id = ?', whereArgs: [id]);
  }
}
