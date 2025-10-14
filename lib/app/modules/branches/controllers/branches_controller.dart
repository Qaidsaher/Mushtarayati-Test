import 'package:get/get.dart';
import '../../menus/controllers/menus_controller.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/repositories/branch_repository.dart';

class BranchesController extends GetxController {
  final BranchRepository _repo = BranchRepository();

  final branches = <BranchModel>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    final list = await _repo.getAll();
    branches.assignAll(list);
    isLoading.value = false;
    // notify MenusController (if exists) to refresh branch list
    if (Get.isRegistered<MenusController>()) {
      try {
        Get.find<MenusController>().load();
      } catch (_) {}
    }
  }

  Future<void> addBranch(String name, String address) async {
    final branch = BranchModel(id: '', name: name, location: address, updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _repo.createOrUpdate(branch);
    await load();
  }

  Future<void> updateBranch(String id, String name, String address) async {
    final branch = BranchModel(id: id, name: name, location: address, updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _repo.createOrUpdate(branch);
    await load();
  }

  Future<void> deleteBranch(String id) async {
    await _repo.delete(id);
    await load();
  }
}
