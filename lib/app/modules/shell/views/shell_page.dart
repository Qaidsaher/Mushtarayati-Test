import 'package:flutter/material.dart';
import 'package:saher_kit/app/modules/branches/views/branches_page.dart';
import 'package:saher_kit/app/modules/profile/views/profile_settings_page.dart';
import '../../home/views/home_page.dart';
import '../../reports/views/reports_page.dart';
import '../../categories/views/categories_page.dart';
import '../../../data/controllers/sync_controller.dart';
import '../../menus/views/menus_page.dart';
import 'package:get/get.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _index = 0;

  // lazy builders to avoid creating all pages (and their controllers) at once
  late final List<Widget Function()> _pageBuilders = [
    () => const HomePage(),
    () => const MenusPage(),
    () => const CategoriesPage(),
    () => const BranchesPage(),
    () => const ReportsPage(),
  ];

  static const List<String> _titles = [
    'الرئيسية',
    'المشتريات',
    'الاصنف',
    'الفروع',
    'التقارير',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title with icon
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getPageIcon(_index),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _titles[_index],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _getSubtitle(_index),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    Row(
                      children: [
                        // Sync button with animation
                        Obx(() {
                          final sync = Get.find<SyncController>();
                          final status = sync.status.value;
                          final isSyncing = status == 'syncing';
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon:
                                  isSyncing
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : const Icon(
                                        Icons.sync,
                                        color: Colors.white,
                                      ),
                              onPressed:
                                  isSyncing
                                      ? null
                                      : () async {
                                        try {
                                          Get.snackbar(
                                            'مزامنة',
                                            'بدء المزامنة...',
                                            backgroundColor: Colors.blue
                                                .withOpacity(0.8),
                                            colorText: Colors.white,
                                            icon: const Icon(
                                              Icons.sync,
                                              color: Colors.white,
                                            ),
                                          );
                                          await sync.syncNow();
                                          final last = sync.lastSyncAt.value;
                                          if (last != null) {
                                            Get.snackbar(
                                              'مزامنة',
                                              'تمت المزامنة بنجاح',
                                              backgroundColor: Colors.green
                                                  .withOpacity(0.8),
                                              colorText: Colors.white,
                                              icon: const Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          Get.snackbar(
                                            'خطأ',
                                            'فشلت المزامنة: ${e.toString()}',
                                            backgroundColor: Colors.red
                                                .withOpacity(0.8),
                                            colorText: Colors.white,
                                            icon: const Icon(
                                              Icons.error,
                                              color: Colors.white,
                                            ),
                                          );
                                        }
                                      },
                              tooltip: 'مزامنة البيانات',
                            ),
                          );
                        }),
                        const SizedBox(width: 8),
                        // Settings button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            tooltip: 'الإعدادات',
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed:
                                () => Get.to(() => const ProfileSettingsPage()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              // use a ValueKey so AnimatedSwitcher recognizes changes
              key: ValueKey<int>(_index),
              child: _pageBuilders[_index](),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            indicatorColor: Theme.of(context).colorScheme.primaryContainer,
            animationDuration: const Duration(milliseconds: 400),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_outlined),
                selectedIcon: Icon(Icons.shopping_bag),
                label: 'المشتريات',
              ),
              NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'الأصناف',
              ),
              NavigationDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store),
                label: 'الفروع',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'التقارير',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to get icon for current page
  IconData _getPageIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.shopping_bag;
      case 2:
        return Icons.category;
      case 3:
        return Icons.store;
      case 4:
        return Icons.bar_chart;
      default:
        return Icons.dashboard;
    }
  }

  // Helper method to get subtitle for current page
  String _getSubtitle(int index) {
    switch (index) {
      case 0:
        return 'لوحة التحكم الرئيسية';
      case 1:
        return 'إدارة المشتريات والعناصر';
      case 2:
        return 'تصنيفات المنتجات';
      case 3:
        return 'إدارة الفروع';
      case 4:
        return 'التحليلات والإحصائيات';
      default:
        return '';
    }
  }
}
