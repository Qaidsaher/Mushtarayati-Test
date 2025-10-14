import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/constants.dart';
import '../controllers/auth_controller.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  final AuthController ctrl = Get.find();
  final TextEditingController email = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.85)]),
                ),
                  child: Column(children: [
                  Hero(tag: 'app-logo', child: CircleAvatar(radius: 36, backgroundColor: Colors.white, child: ClipOval(child: Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover)))),
                  const SizedBox(height: 12),
                  Text(Constants.appName, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('استعادة كلمة المرور', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                ]),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: ctrl.isLoading.value ? null : () => ctrl.sendPasswordReset(email.text.trim()),
                            child: ctrl.isLoading.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('إرسال رابط', style: TextStyle(fontSize: 16)),
                          ),
                        )),
                    const SizedBox(height: 12),
                    Center(child: TextButton(onPressed: () => Get.offNamed('/auth/login'), child: const Text('العودة إلى تسجيل الدخول'))),
                  ]),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
