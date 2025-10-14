
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../app/data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final AuthRepository _repo = AuthRepository();
  final _box = GetStorage();
  static const _kRememberKey = 'auth_remember';

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    final res = await _repo.login(email.trim(), password);
    isLoading.value = false;
    if (res.success) {
      // preserve remember preference (if set previously) - default false
      final remember = _box.read<bool>(_kRememberKey) ?? false;
      if (remember) {
        // Keep user signed in via Firebase persistent session
      }
      Get.offAllNamed('/home');
    } else {
      Get.snackbar('خطأ', res.message ?? 'حدث خطأ');
    }
  }

  /// Set the 'remember me' flag. If true, the app will not prompt login on next start
  void setRemember(bool v) {
    _box.write(_kRememberKey, v);
  }

  Future<void> register(String email, String password) async {
    isLoading.value = true;
    final res = await _repo.register(email.trim(), password);
    isLoading.value = false;
    if (res.success) {
      Get.offAllNamed('/home');
    } else {
      Get.snackbar('خطأ', res.message ?? 'حدث خطأ');
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    // clear remembered flag on explicit logout
    _box.remove(_kRememberKey);
    Get.offAllNamed('/auth/login');
  }

  Future<void> sendPasswordReset(String email) async {
    isLoading.value = true;
    final res = await _repo.sendPasswordReset(email.trim());
    isLoading.value = false;
    if (res.success) {
      Get.snackbar('تم', 'تم إرسال رابط إعادة تعيين كلمة المرور');
      Get.back();
    } else {
      Get.snackbar('خطأ', res.message ?? 'حدث خطأ');
    }
  }

  @override
  void onInit() {
    super.onInit();
    // if user previously chose remember and Firebase has a current user, navigate to home
    final remember = _box.read<bool>(_kRememberKey) ?? false;
    if (remember) {
      // AuthRepository / FirebaseAuth will provide current user on start; rely on app bootstrap to call this controller
      // We don't await here to avoid blocking startup; simply redirect if user is signed in.
      // The actual current user check is left to app bootstrap or other services; keep this minimal.
    }
  }
}
