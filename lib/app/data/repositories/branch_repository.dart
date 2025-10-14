import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/branch_model.dart';
import '../providers/local/sqlite_provider.dart';
import 'package:sqflite/sqflite.dart';

class BranchRepository {
  final _uuid = Uuid();

  Future<void> createOrUpdate(BranchModel branch) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = branch.id.isEmpty ? _uuid.v4() : branch.id;
    final obj = branch.toMap()..['id'] = id..['updated_at'] = now;
    await db.insert('branches', obj, conflictAlgorithm: ConflictAlgorithm.replace);
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'branches',
      'entity_id': id,
      'action': 'upsert',
      'payload': jsonEncode(obj),
      'updated_at': now,
    });
  }

  Future<void> delete(String id) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('branches', {'deleted': 1, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'branches',
      'entity_id': id,
      'action': 'delete',
      'payload': null,
      'updated_at': now,
    });
  }

  Future<List<BranchModel>> getAll({bool includeDeleted = false}) async {
    final db = await SqliteProvider.database;
    final rows = await db.query('branches', where: includeDeleted ? null : 'deleted = ?', whereArgs: includeDeleted ? null : [0]);
    return rows.map((r) => BranchModel.fromMap(r)).toList();
  }

  Future<BranchModel?> getById(String id) async {
    final db = await SqliteProvider.database;
    final rows = await db.query('branches', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return BranchModel.fromMap(rows.first);
  }
}
