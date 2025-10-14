import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/app_info.dart';
import '../../../core/controllers/appearance_controller.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/widgets/theme_palette.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});
  final AppearanceController appearance = Get.find();
  final ThemeController theme = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() => SwitchListTile(
                  title: const Text('الوضع المظلم'),
                  value: appearance.isDark,
                  onChanged: (_) => appearance.toggleTheme(),
                )),
            const SizedBox(height: 12),
            const Text('لون التطبيق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ThemePalette(),
            const SizedBox(height: 20),
            const Text('الخط والحجم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Obx(() => Row(children: [
                  const Text('نوع الخط: '),
                  const SizedBox(width: 8),
                  Text(theme.fontFamily.value),
                ])),
            const SizedBox(height: 12),
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حجم الخط: ${theme.baseFontSize.value.toStringAsFixed(0)}'),
                    Slider(value: theme.baseFontSize.value, min: 12, max: 20, divisions: 8, label: theme.baseFontSize.value.toStringAsFixed(0), onChanged: (v) => theme.setBaseFontSize(v)),
                  ],
                )),
            const SizedBox(height: 20),
            const Text('معاينة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: const Text('اسم المستخدم'),
                      subtitle: const Text('البريد الإلكتروني@example.com'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          ElevatedButton(onPressed: () {}, child: const Text('زر رئيسي')),
                          const SizedBox(width: 12),
                          OutlinedButton(onPressed: () {}, child: const Text('ثانوي')),
                          const Spacer(),
                          TextButton(onPressed: () => theme.resetToDefault(), child: const Text('إعادة الافتراضي')),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text('حول التطبيق'),
              subtitle: Text('معلومات المطور والنسخة'),
              onTap: () async {
                Get.toNamed('/about');
              },
            ),
            ListTile(
              title: Text('النسخة'),
              subtitle: Text(AppInfo.version),
            ),
          ],
        ),
      ),
    );
  }
}
