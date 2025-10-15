import 'package:get/get.dart';
import '../../../data/models/item_model.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/menu_model.dart';
import '../../../data/repositories/menu_repository.dart';

class MenuItemsController extends GetxController {
  final ItemRepository _repo = ItemRepository();
  final MenuRepository _menuRepo = MenuRepository();

  final items = <ItemModel>[].obs;
  final isLoading = false.obs;
  String menuId = '';
  final categories = <CategoryModel>[].obs;
  final catRepo = CategoryRepository();
  final menu = Rxn<MenuModel>();
  final isSavingExpenses = false.obs;

  Future<void> loadForMenu(String id) async {
    menuId = id;
    isLoading.value = true;
    try {
      final list = await _repo.listByMenu(id);
      items.assignAll(list);
      final cats = await catRepo.getAll();
      categories.assignAll(cats);
      final menuData = await _menuRepo.getById(id);
      menu.value = menuData;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addOrUpdate(ItemModel item) async {
    await _repo.createOrUpdate(item);
    await loadForMenu(menuId);
  }

  Future<void> bulkAdd(List<ItemModel> items) async {
    await _repo.bulkCreateOrUpdate(items);
    await loadForMenu(menuId);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await loadForMenu(menuId);
  }

  Future<void> updateExpenses({
    required double stationery,
    required double transportation,
  }) async {
    final current = menu.value;
    if (current == null) return;
    isSavingExpenses.value = true;
    try {
      final updated = MenuModel(
        id: current.id,
        name: current.name,
        date: current.date,
        userId: current.userId,
        branchId: current.branchId,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        deleted: current.deleted,
        stationeryExpenses: stationery,
        transportationExpenses: transportation,
      );
      await _menuRepo.createOrUpdate(updated);
      menu.value = updated;
    } finally {
      isSavingExpenses.value = false;
    }
  }
}
