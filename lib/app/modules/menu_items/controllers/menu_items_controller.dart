import 'package:get/get.dart';
import '../../../data/models/item_model.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/repositories/category_repository.dart';
import '../../../data/models/category_model.dart';

class MenuItemsController extends GetxController {
  final ItemRepository _repo = ItemRepository();

  final items = <ItemModel>[].obs;
  final isLoading = false.obs;
  String menuId = '';
  final categories = <CategoryModel>[].obs;
  final catRepo = CategoryRepository();

  Future<void> loadForMenu(String id) async {
    menuId = id;
    isLoading.value = true;
    final list = await _repo.listByMenu(id);
    items.assignAll(list);
    final cats = await catRepo.getAll();
    categories.assignAll(cats);
    isLoading.value = false;
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
}
