import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';

class UserController extends GetxController {
  final _auth = FirebaseAuth.instance;
  final AuthRepository _repo = AuthRepository();

  final displayName = ''.obs;
  final email = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadFromFirebase();
  }
  Future<void> _loadFromFirebase() async {
    final user = _auth.currentUser;
    displayName.value = user?.displayName ?? '';
    email.value = user?.email ?? '';
  }

  @override
  Future<void> refresh() async {
    await _loadFromFirebase();
  }

  Future<void> updateDisplayName(String name) async {
    await _repo.updateDisplayName(name);
    await Future.delayed(Duration(milliseconds: 200));
    await _auth.currentUser?.reload();
    _loadFromFirebase();
  }
}
