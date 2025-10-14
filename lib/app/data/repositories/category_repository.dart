import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import '../models/category_model.dart';
import '../providers/local/sqlite_provider.dart';

class CategoryRepository {
  final _uuid = Uuid();

  Future<void> create(CategoryModel category) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = category.id.isEmpty ? _uuid.v4() : category.id;
    final obj = category.toMap()..['updated_at'] = now..['id'] = id;
    await db.insert('categories', obj, conflictAlgorithm: ConflictAlgorithm.replace);
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'category',
      'entity_id': obj['id'],
      'action': 'create',
      'payload': jsonEncode(obj),
      'updated_at': now,
    });
  }

  Future<void> delete(String id) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('categories', {'deleted': 1, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'categories',
      'entity_id': id,
      'action': 'delete',
      'payload': null,
      'updated_at': now,
    });
  }

  Future<List<CategoryModel>> getAll({bool includeDeleted = false}) async {
    final db = await SqliteProvider.database;
    final rows = await db.query('categories', where: includeDeleted ? null : 'deleted = ?', whereArgs: includeDeleted ? null : [0]);
    return rows.map((r) => CategoryModel.fromMap(r)).toList();
  }
}
