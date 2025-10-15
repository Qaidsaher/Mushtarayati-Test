import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../providers/local/migrations.dart';
import '../../providers/local/seeders.dart';

class SqliteProvider {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'saher.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, v) async {
        // run migrations v1
        final batch = db.batch();
        final stmts = Migrations.v1.split(';');
        for (var s in stmts) {
          final sql = s.trim();
          if (sql.isNotEmpty) batch.execute(sql);
        }
        await batch.commit(noResult: true);
        // create indices for faster joins
        await _createIndexes(db);

        await Seeders.seedCategories(db);
        print('🌱 تمت تعبئة جدول التصنيفات بنجاح عبر Seeder');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final stmts = Migrations.v2.split(';');
          for (var s in stmts) {
            final sql = s.trim();
            if (sql.isNotEmpty) {
              await db.execute(sql);
            }
          }
        }
        if (oldVersion < 3) {
          await _applyMigrationV3(db);
        }
      },
    );
    return _db!;
  }

  // helper to insert an operation to sync queue
  static Future<void> addOp(Map<String, dynamic> op) async {
    final db = await database;
    await db.insert('ops', op, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // get unsynced ops
  static Future<List<Map<String, dynamic>>> getUnsyncedOps() async {
    final db = await database;
    return db.query(
      'ops',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'updated_at ASC',
    );
  }

  static Future<void> markOpSynced(String id) async {
    final db = await database;
    await db.update('ops', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> _createIndexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_menu ON items(menu_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_items_category ON items(category_id);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_menus_branch ON menus(branch_id);',
    );
  }

  static Future<void> _applyMigrationV3(Database db) async {
    final categoryColumns = await db.rawQuery('PRAGMA table_info(categories);');
    final hasLastPrice = categoryColumns.any(
      (row) => row['name'] == 'last_price',
    );
    if (!hasLastPrice) {
      await db.execute(
        'ALTER TABLE categories ADD COLUMN last_price REAL DEFAULT 0;',
      );
    }

    final itemColumns = await db.rawQuery('PRAGMA table_info(items);');
    String? qtyType;
    for (final row in itemColumns) {
      if (row['name'] == 'qty') {
        final typeValue = row['type'];
        if (typeValue is String) {
          qtyType = typeValue.toUpperCase();
        }
        break;
      }
    }

    final needsRebuild = qtyType != 'INTEGER';
    if (needsRebuild) {
      await db.execute('DROP TABLE IF EXISTS items_tmp;');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS items_tmp (
          id TEXT PRIMARY KEY,
          menu_id TEXT,
          category_id TEXT,
          qty INTEGER,
          unit_price REAL,
          total REAL,
          notes TEXT,
          updated_at INTEGER,
          deleted INTEGER DEFAULT 0
        );
      ''');
      await db.execute('''
        INSERT INTO items_tmp (id, menu_id, category_id, qty, unit_price, total, notes, updated_at, deleted)
        SELECT id, menu_id, category_id, CAST(qty AS INTEGER), unit_price, total, notes, updated_at, deleted FROM items;
      ''');
      await db.execute('DROP TABLE items;');
      await db.execute('ALTER TABLE items_tmp RENAME TO items;');
    }

    await _createIndexes(db);
  }
}
