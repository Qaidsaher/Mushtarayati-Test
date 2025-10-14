import 'package:flutter/material.dart';
import 'package:saher_kit/app/modules/branches/views/branches_page.dart';
import 'package:saher_kit/app/modules/profile/views/profile_settings_page.dart';
import '../../reports/views/reports_page.dart';
import '../../categories/views/categories_page.dart';
import '../../../data/controllers/sync_controller.dart';
import '../../menus/views/menus_page.dart';
// branches page removed from shell builders; keep the import removed to avoid unused import lint
// profile settings page intentionally not imported here
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
    () => const Center(child: Text('الرئيسية')),
    () => const CategoriesPage(),
    () => const MenusPage(),
    () => const BranchesPage(),
      () => const ReportsPage(),
  ];

  static const List<String> _titles = [
    'الرئيسية',
    'التصنيفات',
    'المشتريات',
    'الفروع',
    'التقارير',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'الملف/الإعدادات',
            icon: const Icon(Icons.settings),
            onPressed: () => setState(() => Get.to(ProfileSettingsPage())),
          ),
          Obx(() {
            final sync = Get.find<SyncController>();
            final status = sync.status.value;
            return IconButton(
              icon:
                  status == 'syncing'
                      ? const Icon(Icons.sync, color: Colors.orange)
                      : const Icon(Icons.sync),
              onPressed: () async {
                Get.snackbar('Sync', 'بدء المزامنة...');
                await sync.syncNow();
                final last = sync.lastSyncAt.value;
                if (last != null)
                  Get.snackbar(
                    'Sync',
                    'تمت المزامنة: ${DateTime.fromMillisecondsSinceEpoch(last)}',
                  );
              },
            );
          }),
        ],
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.category), label: 'التصنيفات'),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag),
            label: 'المشتريات',
          ),
          NavigationDestination(icon: Icon(Icons.store), label: 'الفروع'),

          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'التقارير'),
        ],
      ),
    );
  }
}
