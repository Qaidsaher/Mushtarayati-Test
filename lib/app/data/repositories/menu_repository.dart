import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/menu_model.dart';
import '../providers/local/sqlite_provider.dart';
import 'package:sqflite/sqflite.dart';

class MenuRepository {
  final _uuid = Uuid();

  /// جلب قائمة واحدة حسب المعرّف
  Future<MenuModel?> getById(String id) async {
    final db = await SqliteProvider.database;
    final rows = await db.query(
      'menus',
      where: 'id = ? AND deleted = 0',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return MenuModel.fromMap(rows.first);
  }

  Future<void> createOrUpdate(MenuModel menu) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = menu.id.isEmpty ? _uuid.v4() : menu.id;
    final obj =
        menu.toMap()
          ..['id'] = id
          ..['updated_at'] = now;
    await db.insert('menus', obj, conflictAlgorithm: ConflictAlgorithm.replace);
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'menus',
      'entity_id': id,
      'action': 'upsert',
      'payload': jsonEncode(obj),
      'updated_at': now,
    });
  }

  Future<void> delete(String id) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'menus',
      {'deleted': 1, 'updated_at': now},
      where: 'id = ?',
      whereArgs: [id],
    );
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'menus',
      'entity_id': id,
      'action': 'delete',
      'payload': null,
      'updated_at': now,
    });
  }

  Future<List<MenuModel>> list({String? branchId, String? date}) async {
    final db = await SqliteProvider.database;
    String? where;
    List<Object?>? args;
    if (branchId != null && date != null) {
      where = 'branch_id = ? AND date = ? AND deleted = 0';
      args = [branchId, date];
    } else if (branchId != null) {
      where = 'branch_id = ? AND deleted = 0';
      args = [branchId];
    } else if (date != null) {
      where = 'date = ? AND deleted = 0';
      args = [date];
    } else {
      where = 'deleted = 0';
    }
    final rows = await db.query('menus', where: where, whereArgs: args);
    return rows.map((r) => MenuModel.fromMap(r)).toList();
  }
}
