import '../providers/local/sqlite_provider.dart';

class ReportService {
  // Monthly totals aggregated by day for a given month/year
  Future<List<Map<String, dynamic>>> monthlyTotals({required int year, required int month, String? branchId, String? categoryId}) async {
    final db = await SqliteProvider.database;
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1).subtract(const Duration(milliseconds: 1));
    final startMs = start.millisecondsSinceEpoch;
    final endMs = end.millisecondsSinceEpoch;

    // Join menus -> items. menus.date stored as ISO string; we use updated_at timestamps on items
    var where = 'items.updated_at BETWEEN ? AND ? AND items.deleted = 0';
  final List<Object?> args = [startMs, endMs];
    if (branchId != null) {
      where += ' AND menus.branch_id = ?';
  args.add(branchId);
    }
    if (categoryId != null) {
      where += ' AND items.category_id = ?';
  args.add(categoryId);
    }

    final sql = '''
      SELECT date(items.updated_at / 1000, 'unixepoch') as day, SUM(items.total) as total
      FROM items
      JOIN menus ON menus.id = items.menu_id
      WHERE $where
      GROUP BY day
      ORDER BY day ASC
    ''';

    final rows = await db.rawQuery(sql, args);
    return rows;
  }

  // Weekly totals grouped by week start (ISO week) for last N weeks
  Future<List<Map<String, dynamic>>> weeklyTotals({required int weeks, String? branchId, String? categoryId}) async {
    final db = await SqliteProvider.database;
    final now = DateTime.now();
    final start = now.subtract(Duration(days: weeks * 7));
    final startMs = start.millisecondsSinceEpoch;

    var where = 'items.updated_at >= ? AND items.deleted = 0';
  final List<Object?> args = [startMs];
    if (branchId != null) {
      where += ' AND menus.branch_id = ?';
  args.add(branchId);
    }
    if (categoryId != null) {
      where += ' AND items.category_id = ?';
  args.add(categoryId);
    }

    final sql = '''
      SELECT (strftime('%Y-%W', items.updated_at / 1000, 'unixepoch')) as week, SUM(items.total) as total
      FROM items
      JOIN menus ON menus.id = items.menu_id
      WHERE $where
      GROUP BY week
      ORDER BY week ASC
    ''';

    final rows = await db.rawQuery(sql, args);
    return rows;
  }
}
