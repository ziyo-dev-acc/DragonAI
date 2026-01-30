import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/learning/training_store.dart';
import '../../core/storage/app_database.dart';

class LearnedCommandsScreen extends ConsumerStatefulWidget {
  const LearnedCommandsScreen({super.key});

  @override
  ConsumerState<LearnedCommandsScreen> createState() => _LearnedCommandsScreenState();
}

class _LearnedCommandsScreenState extends ConsumerState<LearnedCommandsScreen> {
  late TrainingStore _store;
  List<LearnedCommand> _commands = [];

  @override
  void initState() {
    super.initState();
    _store = TrainingStore(ref.read(appDatabaseProvider));
    _load();
  }

  Future<void> _load() async {
    final items = await _store.getLearnedCommands();
    setState(() => _commands = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learned Commands')),
      body: ListView.builder(
        itemCount: _commands.length,
        itemBuilder: (context, index) {
          final item = _commands[index];
          return ListTile(
            title: Text(item.phrase),
            subtitle: Text(item.intentName),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                await _store.deleteLearned(item.id);
                await _load();
              },
            ),
          );
        },
      ),
    );
  }
}
