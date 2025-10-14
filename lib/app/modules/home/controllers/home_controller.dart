import 'package:get/get.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/providers/local/sqlite_provider.dart';

class HomeController extends GetxController {
  final MenuRepository _menuRepo = MenuRepository();
  final BranchRepository _branchRepo = BranchRepository();
  final CategoryRepository _categoryRepo = CategoryRepository();
  final ItemRepository _itemRepo = ItemRepository();

  final isLoading = false.obs;
  final totalPurchasesToday = 0.0.obs;
  final totalPurchasesWeek = 0.0.obs;
  final totalPurchasesMonth = 0.0.obs;
  final totalBranches = 0.obs;
  final totalCategories = 0.obs;
  final totalMenusToday = 0.obs;
  final recentPurchases = <Map<String, dynamic>>[].obs;
  final topCategories = <Map<String, dynamic>>[].obs;
  final branchStats = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadTodayStats(),
        _loadWeekStats(),
        _loadMonthStats(),
        _loadBranchStats(),
        _loadCategoryStats(),
        _loadRecentPurchases(),
        _loadTopCategories(),
      ]);
    } catch (e) {
      Get.snackbar('خطأ', 'فشل تحميل البيانات');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTodayStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayStr = _dateToStr(today);

    final menus = await _menuRepo.list(date: todayStr);
    totalMenusToday.value = menus.length;

    double total = 0.0;
    for (final menu in menus) {
      final items = await _itemRepo.listByMenu(menu.id);
      total += items.fold<double>(
        0,
        (sum, item) => sum + (item.qty * item.unitPrice),
      );
    }
    totalPurchasesToday.value = total;
  }

  Future<void> _loadWeekStats() async {
    final db = await SqliteProvider.database;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final weekAgoMs = weekAgo.millisecondsSinceEpoch;

    final result = await db.rawQuery(
      '''
      SELECT SUM(items.total) as total
      FROM items
      WHERE items.updated_at >= ? AND items.deleted = 0
    ''',
      [weekAgoMs],
    );

    totalPurchasesWeek.value =
        (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _loadMonthStats() async {
    final db = await SqliteProvider.database;
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthStartMs = monthStart.millisecondsSinceEpoch;

    final result = await db.rawQuery(
      '''
      SELECT SUM(items.total) as total
      FROM items
      WHERE items.updated_at >= ? AND items.deleted = 0
    ''',
      [monthStartMs],
    );

    totalPurchasesMonth.value =
        (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> _loadBranchStats() async {
    final branches = await _branchRepo.getAll();
    totalBranches.value = branches.length;

    final db = await SqliteProvider.database;
    final stats = <Map<String, dynamic>>[];

    for (final branch in branches.take(5)) {
      final result = await db.rawQuery(
        '''
        SELECT COUNT(DISTINCT menus.id) as menu_count, SUM(items.total) as total
        FROM menus
        LEFT JOIN items ON items.menu_id = menus.id AND items.deleted = 0
        WHERE menus.branch_id = ? AND menus.deleted = 0
      ''',
        [branch.id],
      );

      stats.add({
        'name': branch.name,
        'id': branch.id,
        'menu_count': (result.first['menu_count'] as num?)?.toInt() ?? 0,
        'total': (result.first['total'] as num?)?.toDouble() ?? 0.0,
      });
    }

    branchStats.assignAll(stats);
  }

  Future<void> _loadCategoryStats() async {
    final categories = await _categoryRepo.getAll();
    totalCategories.value = categories.length;
  }

  Future<void> _loadRecentPurchases() async {
    final db = await SqliteProvider.database;
    final result = await db.rawQuery('''
      SELECT 
        items.id,
        items.notes,
        items.qty,
        items.unit_price,
        items.total,
        items.updated_at,
        categories.name as category_name,
        menus.name as menu_name,
        branches.name as branch_name
      FROM items
      LEFT JOIN categories ON categories.id = items.category_id
      LEFT JOIN menus ON menus.id = items.menu_id
      LEFT JOIN branches ON branches.id = menus.branch_id
      WHERE items.deleted = 0
      ORDER BY items.updated_at DESC
      LIMIT 10
    ''');

    recentPurchases.assignAll(result);
  }

  Future<void> _loadTopCategories() async {
    final db = await SqliteProvider.database;
    final result = await db.rawQuery('''
      SELECT 
        categories.id,
        categories.name,
        COUNT(items.id) as item_count,
        SUM(items.total) as total
      FROM categories
      LEFT JOIN items ON items.category_id = categories.id AND items.deleted = 0
      WHERE categories.deleted = 0
      GROUP BY categories.id
      ORDER BY total DESC
      LIMIT 5
    ''');

    topCategories.assignAll(result);
  }

  String _dateToStr(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> refresh() => loadDashboard();
}
