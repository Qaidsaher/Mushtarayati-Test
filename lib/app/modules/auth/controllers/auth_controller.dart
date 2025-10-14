
import 'package:get/get.dart';
import '../../../../app/data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final AuthRepository _repo = AuthRepository();

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    final res = await _repo.login(email.trim(), password);
    isLoading.value = false;
    if (res.success) {
      Get.offAllNamed('/home');
    } else {
      Get.snackbar('خطأ', res.message ?? 'حدث خطأ');
    }
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
}
