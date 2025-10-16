import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/user_controller.dart';
import '../../../core/controllers/theme_controller.dart';
import '../../../core/theme/palette.dart';
import '../../../core/utils/app_info.dart';
import '../../../core/widgets/font_size_slider.dart';
import '../../../core/widgets/responsive_wrapper.dart';
import '../../../modules/auth/controllers/auth_controller.dart' as core_auth;

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<core_auth.AuthController>();
    final userCtrl = Get.find<UserController>();
    final theme = Get.find<ThemeController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: ResponsiveWrapper(
          padding: EdgeInsets.zero,
          child: CustomScrollView(
            slivers: [
              // Modern header with gradient
              _buildModernHeader(context, userCtrl, theme),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // User Profile Card
                    _buildProfileCard(context, userCtrl),
                    const SizedBox(height: 20),

                    // Theme & Display Section
                    _buildSectionHeader(
                      context,
                      'المظهر والعرض',
                      Icons.palette,
                    ),
                    const SizedBox(height: 12),
                    _buildThemeCard(context, theme),
                    const SizedBox(height: 20),

                    // Accessibility Section
                    _buildSectionHeader(
                      context,
                      'إمكانية الوصول',
                      Icons.accessibility_new,
                    ),
                    const SizedBox(height: 12),
                    _buildAccessibilityCard(context, theme),
                    const SizedBox(height: 20),

                    // Font Settings Section
                    _buildSectionHeader(
                      context,
                      'الخط والحجم',
                      Icons.text_fields,
                    ),
                    const SizedBox(height: 12),
                    _buildFontCard(context, theme),
                    const SizedBox(height: 20),

                    // Color Palette Section
                    _buildSectionHeader(
                      context,
                      'ألوان التطبيق',
                      Icons.color_lens,
                    ),
                    const SizedBox(height: 12),
                    _buildColorPaletteCard(context, theme),
                    const SizedBox(height: 20),

                    // About App
                    _buildSectionHeader(
                      context,
                      'حول التطبيق',
                      Icons.info_outline,
                    ),
                    const SizedBox(height: 12),
                    _buildAppInfoCard(context),
                    const SizedBox(height: 32),

                    // Logout Button
                    _buildLogoutButton(authCtrl, context),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(
    BuildContext context,
    UserController userCtrl,
    ThemeController theme,
  ) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
        centerTitle: true,
        title: const Text(
          'الإعدادات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Obx(
                  () => Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        userCtrl.displayName.value.isNotEmpty
                            ? userCtrl.displayName.value[0].toUpperCase()
                            : '؟',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserController userCtrl) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Obx(
              () => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 28,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  userCtrl.displayName.value.isNotEmpty
                      ? userCtrl.displayName.value
                      : 'مستخدم جديد',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  userCtrl.email.value.isNotEmpty
                      ? userCtrl.email.value
                      : 'البريد الإلكتروني غير محدد',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton.filledTonal(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditNameDialog(context, userCtrl),
                  tooltip: 'تعديل الاسم',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, ThemeController theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر وضع العرض',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Obx(
              () => SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('فاتح'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('داكن'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('تلقائي'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                ],
                selected: {theme.themeMode.value},
                onSelectionChanged: (Set<ThemeMode> newSelection) {
                  theme.setTheme(newSelection.first);
                },
                style: ButtonStyle(visualDensity: VisualDensity.comfortable),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilityCard(BuildContext context, ThemeController theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Obx(
              () => SwitchListTile(
                title: const Text('تباين عالي'),
                subtitle: const Text('لتحسين رؤية النصوص والعناصر'),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.contrast,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                value: theme.highContrast.value,
                onChanged: theme.setHighContrast,
              ),
            ),
            const Divider(height: 1),
            Obx(
              () => SwitchListTile(
                title: const Text('تقليل الحركة'),
                subtitle: const Text('لتقليل التأثيرات المتحركة'),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.motion_photos_off,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                value: theme.reducedMotion.value,
                onChanged: theme.setReducedMotion,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.touch_app, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'حجم الأزرار',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => SegmentedButton<ButtonSize>(
                      segments: const [
                        ButtonSegment(
                          value: ButtonSize.small,
                          label: Text('صغير'),
                        ),
                        ButtonSegment(
                          value: ButtonSize.medium,
                          label: Text('متوسط'),
                        ),
                        ButtonSegment(
                          value: ButtonSize.large,
                          label: Text('كبير'),
                        ),
                      ],
                      selected: {theme.buttonSize.value},
                      onSelectionChanged: (Set<ButtonSize> newSelection) {
                        theme.setButtonSize(newSelection.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontCard(BuildContext context, ThemeController theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Font Size Control
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'حجم الخط',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Obx(
                  () => Text(
                    '${theme.baseFontSize.value.toInt()}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const FontSizeSlider(min: 12, max: 24),
            const SizedBox(height: 20),

            // Font Family Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'نوع الخط',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Obx(
                  () => DropdownButton<String>(
                    value: theme.fontFamily.value,
                    borderRadius: BorderRadius.circular(12),
                    items:
                        theme.availableFonts
                            .map(
                              (font) => DropdownMenuItem(
                                value: font.name,
                                child: Text(font.displayName),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value != null) theme.setFontFamily(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Preview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.preview,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'معاينة',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(
                    () => Text(
                      'هذا نص تجريبي لمعاينة حجم ونوع الخط المختار',
                      style: TextStyle(
                        fontFamily: theme.fontFamily.value,
                        fontSize: theme.baseFontSize.value,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Text(
                      'This is a preview text in English',
                      style: TextStyle(
                        fontFamily: theme.fontFamily.value,
                        fontSize: theme.baseFontSize.value * 0.9,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  theme.resetToDefault();
                  Get.snackbar(
                    'تم',
                    'تم إعادة تعيين الإعدادات إلى الوضع الافتراضي',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    colorText: Theme.of(context).colorScheme.onPrimaryContainer,
                    margin: const EdgeInsets.all(16),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة تعيين الخط'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPaletteCard(BuildContext context, ThemeController theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اختر لون التطبيق',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: Palette.themeColors.length,
              itemBuilder: (context, index) {
                final colorPalette = Palette.themeColors[index];
                return Obx(() {
                  final isSelected =
                      theme.colorSeed.value.value == colorPalette.seed.value;
                  return InkWell(
                    onTap: () => theme.setColor(colorPalette.seed),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorPalette.seed,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: colorPalette.seed.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              colorPalette.icon,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 4,
                              left: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_circle,
                                  color: colorPalette.seed,
                                  size: 20,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                });
              },
            ),
            const SizedBox(height: 16),
            // Show selected color name
            Obx(() {
              final selectedPalette = Palette.themeColors.firstWhere(
                (p) => p.seed.value == theme.colorSeed.value.value,
                orElse: () => Palette.themeColors[0],
              );
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorSeed.value.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorSeed.value.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          selectedPalette.icon,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedPalette.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorSeed.value,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selectedPalette.description,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Get.toNamed('/about'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 28,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حول التطبيق',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الإصدار ${AppInfo.version}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_back_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(
    core_auth.AuthController authCtrl,
    BuildContext context,
  ) {
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.logout),
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 56),
      ),
      onPressed: () async {
        final confirmed = await Get.dialog<bool>(
          AlertDialog(
            title: const Text('تسجيل الخروج'),
            content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Get.back(result: true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('تسجيل الخروج'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await authCtrl.logout();
        }
      },
      label: const Text('تسجيل الخروج'),
    );
  }

  void _showEditNameDialog(BuildContext context, UserController userCtrl) {
    final controller = TextEditingController(text: userCtrl.displayName.value);
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('تعديل الاسم'),
          ],
        ),
        content: TextField(
          controller: controller,
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            labelText: 'الاسم',
            hintText: 'أدخل الاسم الجديد',
            prefixIcon: const Icon(Icons.person_outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await userCtrl.updateDisplayName(name);
                Get.back();
                Get.snackbar(
                  'تم',
                  'تم تحديث الاسم بنجاح',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  colorText: Theme.of(context).colorScheme.onPrimaryContainer,
                  margin: const EdgeInsets.all(16),
                  icon: const Icon(Icons.check_circle),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
