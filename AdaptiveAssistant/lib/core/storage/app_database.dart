import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('appDatabaseProvider must be overridden');
});

class AppDatabase {
  AppDatabase(this._db);

  final Database _db;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'adaptive_assistant.db');
    final db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
CREATE TABLE training_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  transcript TEXT NOT NULL,
  intent_name TEXT,
  slots_json TEXT,
  confidence REAL,
  outcome TEXT,
  created_at INTEGER
)
''');
        await db.execute('''
CREATE TABLE learned_commands (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  phrase TEXT NOT NULL,
  intent_name TEXT NOT NULL,
  slots_json TEXT,
  created_at INTEGER
)
''');
        await db.execute('''
CREATE TABLE document_index (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  uri TEXT NOT NULL,
  modified_at INTEGER,
  mime_type TEXT
)
''');
      },
    );
    return AppDatabase(db);
  }

  Database get raw => _db;
}
