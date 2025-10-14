import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/repositories/category_repository.dart';

class CategoriesController extends GetxController {
  final CategoryRepository _repo = CategoryRepository();

  final categories = <CategoryModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    categories.assignAll(list.map((m) => CategoryModel(id: m.id, name: m.name, type: m.type, updatedAt: m.updatedAt, deleted: m.deleted)).toList());
    isLoading.value = false;
  }

  Future<void> addCategory(String name, String type) async {
    final cat = CategoryModel(id: '', name: name, type: type, updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _repo.create(cat);
    await load();
  }

  Future<void> updateCategory(String id, String name, String type) async {
    // implement as create with same id to replace
    final cat = CategoryModel(id: id, name: name, type: type, updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _repo.create(cat);
    await load();
  }

  Future<void> deleteCategory(String id) async {
    await _repo.delete(id);
    await load();
  }
}
