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
      version: 2,
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
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_items_menu ON items(menu_id);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_items_category ON items(category_id);',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_menus_branch ON menus(branch_id);',
        );

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
}
