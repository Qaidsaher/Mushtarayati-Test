import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/constants.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthController ctrl = Get.find();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _obscure = true;
  final _formKey = GlobalKey<FormState>();
  double _pwStrength = 0.0;
  bool _agree = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  double _estimateStrength(String v) {
    if (v.isEmpty) return 0.0;
    var score = 0.0;
    if (v.length >= 6) score += 0.3;
    if (v.length >= 10) score += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(v)) score += 0.15;
    if (RegExp(r'[0-9]').hasMatch(v)) score += 0.2;
    if (RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(v)) score += 0.15;
    return score.clamp(0.0, 1.0);
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
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.9)]),
                    borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  child: Column(children: [
                    Hero(tag: 'app-logo', child: CircleAvatar(radius: 36, backgroundColor: Colors.white, child: ClipOval(child: Image.asset('assets/images/logo.png', width: 40, height: 40, fit: BoxFit.cover)))),
                    const SizedBox(height: 12),
                    Text(Constants.appName, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('إنشاء حساب', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
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
                        Form(
                          key: _formKey,
                          child: Column(children: [
                            TextFormField(
                              controller: email,
                              decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
                              keyboardType: TextInputType.emailAddress,
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
                              onChanged: (v) => setState(() => _pwStrength = _estimateStrength(v)),
                              validator: (v) => (v == null || v.length < 6) ? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' : null,
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: _pwStrength, minHeight: 6, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(_pwStrength > 0.7 ? Colors.green : (_pwStrength > 0.4 ? Colors.orange : Colors.red))),
                            const SizedBox(height: 8),
                            Row(children: [
                              Checkbox(value: _agree, onChanged: (v) => setState(() => _agree = v ?? false)),
                              const SizedBox(width: 6),
                              Expanded(child: Text('أوافق على الشروط وسياسة الخصوصية'))
                            ]),
                            const SizedBox(height: 12),
                            Obx(() => SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                                    onPressed: (!ctrl.isLoading.value && _agree)
                                        ? () {
                                            if (_formKey.currentState?.validate() ?? false) ctrl.register(email.text.trim(), password.text);
                                          }
                                        : null,
                                    child: ctrl.isLoading.value ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('تسجيل', style: TextStyle(fontSize: 16)),
                                  ),
                                )),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => Get.offNamed('/auth/login'),
                                child: const Text('لدي حساب بالفعل — تسجيل الدخول'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Divider(color: Colors.grey.shade300)),
                            ]),
                          ]),
                        ),
                      ]),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
