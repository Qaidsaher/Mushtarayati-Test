import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/constants.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController ctrl = Get.find();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();
  bool _remember = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
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
            child: Column(
              children: [
                // Header with gradient and logo
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.8)]),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Hero(tag: 'app-logo', child: CircleAvatar(radius: 36, backgroundColor: Colors.white, child: ClipOval(child: Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover)))),
                      const SizedBox(height: 12),
                      Text(Constants.appName, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('تسجيل الدخول', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: email,
                            decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال البريد الإلكتروني' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: password,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
                            ),
                            obscureText: _obscure,
                            validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال كلمة المرور' : null,
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Checkbox(value: _remember, onChanged: (v) {
                              setState(() => _remember = v ?? false);
                              ctrl.setRemember(_remember);
                            }),
                            const SizedBox(width: 6),
                            const Text('تذكرني')
                          ]),
                          const SizedBox(height: 8),
                          Obx(() => SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: ctrl.isLoading.value ? null : _submit,
                                  child: ctrl.isLoading.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('دخول')),
                                ),
                              )),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            TextButton(onPressed: () => Get.toNamed('/auth/forgot'), child: const Text('هل نسيت كلمة المرور؟')),
                            TextButton(onPressed: () => Get.toNamed('/auth/register'), child: const Text('إنشاء حساب')),
                          ])
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    ctrl.login(email.text.trim(), password.text);
  }
}
