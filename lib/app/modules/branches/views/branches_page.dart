import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/branches_controller.dart';
import '../../../data/models/branch_model.dart';

class BranchesPage extends StatelessWidget {
  const BranchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(BranchesController());
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddBranchDialog(context, c),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة فرع'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(14),
          child: Obx(() {
            if (c.branches.isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد فروع حالياً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              );
            }

            return ListView.builder(
              itemCount: c.branches.length,
              itemBuilder: (context, i) {
                final branch = c.branches[i];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withAlpha(
                          (0.08 * 255).toInt(),
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: theme.dividerColor.withAlpha((0.2 * 255).toInt()),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    leading: Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.store_rounded,
                        color: theme.colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    title: Text(
                      branch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        branch.location ?? '',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        IconButton(
                          tooltip: 'تعديل',
                          icon: Icon(
                            Icons.edit_location_alt_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed:
                              () => _showEditBranchDialog(context, c, branch),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: theme.colorScheme.error,
                          ),
                          onPressed:
                              () => _confirmDelete(context, c, branch.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  void _showAddBranchDialog(BuildContext context, BranchesController c) {
    final name = TextEditingController();
    final address = TextEditingController();

    showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('إضافة فرع جديد'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'اسم الفرع'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: 'الموقع / العنوان',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('إضافة'),
              onPressed: () async {
                if (name.text.isNotEmpty && address.text.isNotEmpty) {
                  // show a simple loading state by replacing dialog content
                  Navigator.of(ctx).pop();
                  Get.dialog(
                    Center(child: CircularProgressIndicator()),
                    barrierDismissible: false,
                  );
                  await c.addBranch(name.text, address.text);
                  Get.back();
                  Get.snackbar(
                    'تم',
                    'تمت إضافة الفرع بنجاح',
                    snackPosition: SnackPosition.BOTTOM,
                    margin: const EdgeInsets.all(16),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditBranchDialog(
    BuildContext context,
    BranchesController c,
    BranchModel branch,
  ) {
    final name = TextEditingController(text: branch.name);
    final address = TextEditingController(text: branch.location ?? '');

    showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('تعديل بيانات الفرع'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'اسم الفرع'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: address,
                decoration: const InputDecoration(
                  labelText: 'الموقع / العنوان',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('تحديث'),
              onPressed: () async {
                Navigator.of(ctx).pop();
                Get.dialog(
                  Center(child: CircularProgressIndicator()),
                  barrierDismissible: false,
                );
                await c.updateBranch(branch.id, name.text, address.text);
                Get.back();
                Get.snackbar(
                  'تم',
                  'تم تحديث بيانات الفرع بنجاح',
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, BranchesController c, String id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا الفرع؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          FilledButton.tonal(
            onPressed: () async {
              await c.deleteBranch(id);
              Get.back();
              Get.snackbar('تم', 'تم حذف الفرع بنجاح');
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
