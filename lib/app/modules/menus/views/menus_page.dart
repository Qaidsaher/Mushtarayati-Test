import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/menus_controller.dart';

/// الصفحة الرئيسية للقوائم اليومية
class MenusPage extends StatelessWidget {
  const MenusPage({super.key});

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    if (diff == 2) return 'قبل أمس';
    return '${date.day}/${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MenusController());
    // ensure today's date is selected when the page is shown
    c.selectToday();
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,

        /// زر الإضافة يظهر فقط عندما يكون اليوم الحالي محدد
        floatingActionButton: Obx(() {
          final today = DateTime.now();
          final isToday = c.selectedDate.value.year == today.year && c.selectedDate.value.month == today.month && c.selectedDate.value.day == today.day;

          return isToday
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddMenuDialog(context, c),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة قائمة'),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                )
              : const SizedBox.shrink();
        }),

        /// جسم الصفحة
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // شريط الأيام الثلاثة فقط
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Obx(() {
                final dates = c.availableDates;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dates.map((d) {
                      final isSelected = c.selectedDate.value == d;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text(
                            formatDate(d),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) => c.selectedDate.value = d,
                          selectedColor: theme.colorScheme.primaryContainer,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.6 * 255).toInt()),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),

            /// عرض القوائم بطريقة حديثة ومتجاوبة
            Expanded(
              child: Obx(() {
                final menus = c.filteredMenus;
                if (menus.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد قوائم لهذا اليوم',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: menus.length,
                  itemBuilder: (context, i) {
                    final m = menus[i];
                    final branchName = c.branches.firstWhere((b) => b.id == m.branchId).name;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(color: theme.shadowColor.withAlpha((0.08 * 255).toInt()), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
                          ),
                          title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(branchName),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('الإجمالي: ${c.menuTotals[m.id]?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Text('عدد الفئات: ${c.menuCategoryCounts[m.id] ?? 0}', style: TextStyle(color: theme.colorScheme.outline)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Wrap(
                            spacing: 6,
                            children: [
                              IconButton(
                                tooltip: 'عرض العناصر',
                                icon: Icon(Icons.list_alt, color: theme.colorScheme.primary),
                                onPressed: () => Get.toNamed('/menus/items', arguments: {'menuId': m.id}),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                                onPressed: () => c.deleteMenu(m.id),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// نافذة إضافة قائمة جديدة (لليوم فقط)
  void _showAddMenuDialog(BuildContext context, MenusController c) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    String? selectedBranchId;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline_rounded, size: 46, color: theme.colorScheme.primary),
                const SizedBox(height: 6),
                const Text('إضافة قائمة اليوم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: c.branches.map((b) {
                    final isSelected = selectedBranchId == b.id;
                    return ChoiceChip(
                      label: Text(b.name),
                      selected: isSelected,
                      onSelected: (s) => setState(() => selectedBranchId = s ? b.id : null),
                      selectedColor: theme.colorScheme.primaryContainer,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).toInt()),
                      labelStyle: TextStyle(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('حفظ'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(45), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () {
                    final selected = c.selectedDate.value;
                    final today = DateTime(now.year, now.month, now.day);

                    if (selected.isBefore(today)) {
                      Get.snackbar('تنبيه', 'لا يمكن إضافة قائمة في تاريخ سابق', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
                      return;
                    }

                    if (selectedBranchId != null) {
                      c.addMenu(selectedBranchId!);
                      Navigator.pop(context);
                    } else {
                      Get.snackbar('تنبيه', 'اختر الفرع أولاً', snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
                    }
                  },
                )
              ],
            );
          }),
        ),
      ),
    );
  }
}
