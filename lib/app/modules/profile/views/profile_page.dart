import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/user_controller.dart';
import '../../../modules/auth/controllers/auth_controller.dart' as core_auth;
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
  final authCtrl = Get.find<core_auth.AuthController>();
  final userCtrl = Get.find<UserController>();

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Obx(() => CircleAvatar(
                        radius: 40,
                        child: Text(userCtrl.displayName.value.isNotEmpty ? userCtrl.displayName.value[0] : '?'),
                      )),
                  const SizedBox(height: 12),
                  Obx(() => Text(userCtrl.displayName.value.isNotEmpty ? userCtrl.displayName.value : 'غير معروف', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 4),
                  Obx(() => Text(userCtrl.email.value.isNotEmpty ? userCtrl.email.value : '---')),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('تعديل الاسم'),
              onTap: () async {
                final controller = TextEditingController(text: userCtrl.displayName.value);
                final res = await Get.dialog<String?>(AlertDialog(
                  title: const Text('تعديل الاسم'),
                  content: TextField(controller: controller, textDirection: TextDirection.rtl, decoration: const InputDecoration()),
                  actions: [
                    TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
                    ElevatedButton(onPressed: () => Get.back(result: controller.text.trim()), child: const Text('حفظ')),
                  ],
                ));
                if (res != null && res.isNotEmpty) {
                  await userCtrl.updateDisplayName(res);
                  Get.snackbar('تم', 'تم تحديث الاسم');
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('تسجيل الخروج'),
              onTap: () async {
                await authCtrl.logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
