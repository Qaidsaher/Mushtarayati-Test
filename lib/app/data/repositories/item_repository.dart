import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';
import '../providers/local/sqlite_provider.dart';
import 'package:sqflite/sqflite.dart';

class ItemRepository {
  final _uuid = Uuid();

  Future<void> createOrUpdate(ItemModel item) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = item.id.isEmpty ? _uuid.v4() : item.id;
    final obj = item.toMap()..['id'] = id..['updated_at'] = now;
    await db.insert('items', obj, conflictAlgorithm: ConflictAlgorithm.replace);
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'items',
      'entity_id': id,
      'action': 'upsert',
      'payload': jsonEncode(obj),
      'updated_at': now,
    });
  }

  Future<void> delete(String id) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update('items', {'deleted': 1, 'updated_at': now}, where: 'id = ?', whereArgs: [id]);
    await SqliteProvider.addOp({
      'id': _uuid.v4(),
      'entity_type': 'items',
      'entity_id': id,
      'action': 'delete',
      'payload': null,
      'updated_at': now,
    });
  }

  Future<void> bulkCreateOrUpdate(List<ItemModel> items) async {
    if (items.isEmpty) return;
    final db = await SqliteProvider.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction((txn) async {
      for (var item in items) {
        final id = item.id.isEmpty ? _uuid.v4() : item.id;
        final obj = item.toMap()..['id'] = id..['updated_at'] = now;
        await txn.insert('items', obj, conflictAlgorithm: ConflictAlgorithm.replace);
        final op = {
          'id': _uuid.v4(),
          'entity_type': 'items',
          'entity_id': id,
          'action': 'upsert',
          'payload': jsonEncode(obj),
          'updated_at': now,
        };
        await txn.insert('ops', op, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<ItemModel>> listByMenu(String menuId) async {
    final db = await SqliteProvider.database;
    final rows = await db.query('items', where: 'menu_id = ? AND deleted = 0', whereArgs: [menuId]);
    return rows.map((r) => ItemModel.fromMap(r)).toList();
  }
}
