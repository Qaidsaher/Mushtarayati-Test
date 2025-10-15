import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/user_controller.dart';
import '../../../core/controllers/appearance_controller.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/widgets/theme_palette.dart';
import '../../../core/utils/app_info.dart';
import '../../../modules/auth/controllers/auth_controller.dart' as core_auth;

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<core_auth.AuthController>();
    final userCtrl = Get.find<UserController>();
    final appearance = Get.find<AppearanceController>();
    final theme = Get.find<ThemeController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              stretch: true,
              backgroundColor: theme.colorSeed.value,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [
                  StretchMode.zoomBackground,
                  StretchMode.fadeTitle,
                ],
                centerTitle: true,
                title: Obx(() => Text(
                      userCtrl.displayName.value.isNotEmpty
                          ? userCtrl.displayName.value
                          : 'مستخدم',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorSeed.value.withOpacity(0.9),
                            theme.colorSeed.value.withOpacity(0.6),
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Obx(
                          () => CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Text(
                              userCtrl.displayName.value.isNotEmpty
                                  ? userCtrl.displayName.value[0]
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 40, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Profile section
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileCard(context, userCtrl),
                    const SizedBox(height: 16),
                    _buildAppearanceCard(context, appearance, theme),
                    const SizedBox(height: 16),
                    _buildAppInfoCard(context),
                    const SizedBox(height: 32),
                    _buildLogoutButton(authCtrl, context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, UserController userCtrl) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person, size: 30),
              title: Obx(() => Text(
                    userCtrl.displayName.value.isNotEmpty
                        ? userCtrl.displayName.value
                        : 'غير معروف',
                    style: Theme.of(context).textTheme.titleMedium,
                  )),
              subtitle: Obx(() => Text(
                    userCtrl.email.value.isNotEmpty
                        ? userCtrl.email.value
                        : '---',
                    style: Theme.of(context).textTheme.bodySmall,
                  )),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                onPressed: () async {
                  final controller =
                      TextEditingController(text: userCtrl.displayName.value);
                  await Get.bottomSheet(
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'تعديل الاسم',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: controller,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: OutlinedButton(
                                      onPressed: () => Get.back(),
                                      child: const Text('إلغاء'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: FilledButton(
                                      onPressed: () async {
                                        final res = controller.text.trim();
                                        if (res.isNotEmpty) {
                                          await userCtrl.updateDisplayName(res);
                                          Get.back();
                                          Get.snackbar('تم', 'تم تحديث الاسم');
                                        }
                                      },
                                      child: const Text('حفظ'))),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearanceCard(BuildContext context,
      AppearanceController appearance, ThemeController theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('المظهر',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 12),
            Obx(() => SwitchListTile(
                title: const Text('الوضع المظلم'),
                value: appearance.isDark,
                onChanged: (_) => appearance.toggleTheme())),
            const SizedBox(height: 8),
            const Text('لون التطبيق', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ThemePalette(),
            const SizedBox(height: 12),
            const Text('الخط والحجم', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Obx(() => Row(
                  children: [
                    Expanded(
                        child: Text('الخط: ${theme.fontFamily.value}',
                            style: Theme.of(context).textTheme.bodyMedium)),
                    IconButton(
                        onPressed: theme.resetToDefault,
                        icon: const Icon(Icons.refresh))
                  ],
                )),
            Obx(() => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الحجم: ${theme.baseFontSize.value.toStringAsFixed(0)}'),
                    Slider(
                        value: theme.baseFontSize.value,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: theme.baseFontSize.value.toStringAsFixed(0),
                        onChanged: theme.setBaseFontSize),
                  ],
                )),
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Obx(() => Text(
                      'هذا نص معاينة للخط والحجم',
                      style: TextStyle(
                        fontFamily: theme.fontFamily.value,
                        fontSize: theme.baseFontSize.value,
                      ),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('حول التطبيق'),
        subtitle: Text('الإصدار: ${AppInfo.version}'),
        onTap: () => Get.toNamed('/about'),
      ),
    );
  }

  Widget _buildLogoutButton(core_auth.AuthController authCtrl, BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.logout),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () async => await authCtrl.logout(),
      label: const Text('تسجيل الخروج'),
    );
  }
}
