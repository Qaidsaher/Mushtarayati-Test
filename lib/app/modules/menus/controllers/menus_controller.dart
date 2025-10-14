import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/menu_model.dart';
import '../../../data/repositories/menu_repository.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../data/repositories/item_repository.dart';

class MenusController extends GetxController {
  final MenuRepository _repo = MenuRepository();
  final BranchRepository _branchRepo = BranchRepository();

  final menus = <MenuModel>[].obs;
  final branches = <dynamic>[].obs; // branch models are simple maps or objects; repository returns appropriate models
  final isLoading = false.obs;
  final selectedDate = DateTime.now().obs;
  final ItemRepository _itemRepo = ItemRepository();

  // computed stats per menu
  final menuTotals = <String, double>{}.obs;
  final menuCategoryCounts = <String, int>{}.obs;

  List<DateTime> get availableDates {
    final today = DateTime.now();
    return [
      DateTime(today.year, today.month, today.day - 2),
      DateTime(today.year, today.month, today.day - 1),
      DateTime(today.year, today.month, today.day),
    ];
  }

  List<MenuModel> get filteredMenus {
    final dateStr = _dateToStr(selectedDate.value);
    return menus.where((m) => m.date == dateStr).toList();
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void selectToday() {
    final now = DateTime.now();
    selectedDate.value = DateTime(now.year, now.month, now.day);
  }

  Future<void> load() async {
    isLoading.value = true;
    // load branches and menus
    final b = await _branchRepo.getAll();
    branches.assignAll(b);
    final allMenus = await _repo.list();
    menus.assignAll(allMenus);
    // compute stats for menus
    for (final m in allMenus) {
      final items = await _itemRepo.listByMenu(m.id);
  final total = items.fold<double>(0, (p, e) => p + (e.qty * e.unitPrice));
      final distinctCats = items.map((e) => e.categoryId).where((x) => x != null).toSet().length;
      menuTotals[m.id] = total;
      menuCategoryCounts[m.id] = distinctCats;
    }
    isLoading.value = false;
  }

  Future<void> addMenu(String branchId) async {
    final dateStr = _dateToStr(selectedDate.value);
    // enforce one menu per branch per day
    final exists = await _repo.list(branchId: branchId, date: dateStr);
    if (exists.isNotEmpty) {
      Get.snackbar(
        'تنبيه',
        'هذا الفرع لديه قائمة لهذا اليوم بالفعل',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

  await _repo.createOrUpdate(MenuModel(id: '', name: 'قائمة $dateStr', date: dateStr, branchId: branchId, updatedAt: DateTime.now().millisecondsSinceEpoch));
    await load();
  }

  Future<void> deleteMenu(String id) async {
    await _repo.delete(id);
    await load();
  }

  /// Return rows suitable for exporting a specific menu
  Future<List<Map<String, dynamic>>> exportRowsForMenu(String menuId) async {
    final items = await _itemRepo.listByMenu(menuId);
    return items.map((it) => {
          'id': it.id,
          'notes': it.notes ?? '',
          'qty': it.qty,
          'unit_price': it.unitPrice,
          'total': it.qty * it.unitPrice,
          'categoryId': it.categoryId ?? '',
          'updated_at': it.updatedAt ?? 0,
        }).toList();
  }

  String _dateToStr(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
