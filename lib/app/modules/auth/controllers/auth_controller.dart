import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../core/controllers/user_controller.dart';

class AuthController extends GetxController {
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final AuthRepository _repo = AuthRepository();
  final _box = GetStorage();
  static const _kRememberKey = 'auth_remember';

  Future<void> login(String email, String password) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final res = await _repo.login(email.trim(), password);
      isLoading.value = false;

      if (res.success) {
        // preserve remember preference
        final remember = _box.read<bool>(_kRememberKey) ?? false;
        if (remember) {
          // Keep user signed in via Firebase persistent session
        }

        // Show success message
        Get.snackbar(
          'مرحباً',
          'تم تسجيل الدخول بنجاح',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed('/home');
      } else {
        errorMessage.value = res.message ?? 'حدث خطأ في تسجيل الدخول';
        _showErrorSnackbar(errorMessage.value);
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'حدث خطأ غير متوقع: ${e.toString()}';
      _showErrorSnackbar(errorMessage.value);
    }
  }

  /// Set the 'remember me' flag
  void setRemember(bool v) {
    _box.write(_kRememberKey, v);
  }

  Future<void> register(
    String email,
    String password,
    String displayName,
  ) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final res = await _repo.register(email.trim(), password);

      if (res.success) {
        // Update display name
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && displayName.isNotEmpty) {
          await user.updateDisplayName(displayName);

          // Update user controller
          try {
            final userCtrl = Get.find<UserController>();
            await userCtrl.updateDisplayName(displayName);
          } catch (_) {
            // UserController might not be initialized yet
          }
        }

        isLoading.value = false;

        // Show success message
        Get.snackbar(
          'مرحباً $displayName',
          'تم إنشاء حسابك بنجاح',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );

        await Future.delayed(const Duration(milliseconds: 500));
        Get.offAllNamed('/home');
      } else {
        isLoading.value = false;
        errorMessage.value = res.message ?? 'حدث خطأ في إنشاء الحساب';
        _showErrorSnackbar(errorMessage.value);
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'حدث خطأ غير متوقع: ${e.toString()}';
      _showErrorSnackbar(errorMessage.value);
    }
  }

  Future<void> logout() async {
    await _repo.signOut();
    // clear remembered flag on explicit logout
    _box.remove(_kRememberKey);
    Get.offAllNamed('/auth/login');
  }

  Future<void> sendPasswordReset(String email) async {
    errorMessage.value = '';
    isLoading.value = true;

    try {
      final res = await _repo.sendPasswordReset(email.trim());
      isLoading.value = false;

      if (res.success) {
        Get.snackbar(
          'تم بنجاح',
          'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
          icon: const Icon(Icons.check_circle, color: Colors.white),
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );

        await Future.delayed(const Duration(milliseconds: 800));
        Get.back();
      } else {
        errorMessage.value = res.message ?? 'حدث خطأ في إرسال الرابط';
        _showErrorSnackbar(errorMessage.value);
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'حدث خطأ غير متوقع: ${e.toString()}';
      _showErrorSnackbar(errorMessage.value);
    }
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'خطأ',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withOpacity(0.9),
      colorText: Colors.white,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );
  }

  @override
  void onInit() {
    super.onInit();
    final remember = _box.read<bool>(_kRememberKey) ?? false;
    if (remember) {
      // Session will be checked in splash screen
    }
  }
}
