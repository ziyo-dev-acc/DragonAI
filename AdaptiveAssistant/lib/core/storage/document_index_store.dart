import 'package:sqflite/sqflite.dart';

import 'app_database.dart';

class DocumentIndexStore {
  DocumentIndexStore(this._db);

  final AppDatabase _db;

  Future<Map<String, dynamic>?> latestPdf() async {
    final rows = await _db.raw.query(
      'document_index',
      orderBy: 'modified_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> search(String query) async {
    final rows = await _db.raw.query(
      'document_index',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 5,
    );
    return rows;
  }
}
