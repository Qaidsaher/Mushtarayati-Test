import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/categories_controller.dart';
import '../../../data/models/category_model.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Color _typeColor(String? type) =>
      type == 'خضار' ? Colors.green.shade500 : Colors.orange.shade500;

  IconData _typeIcon(String? type) =>
      type == 'خضار' ? Icons.eco_rounded : Icons.local_pizza_rounded;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CategoriesController());
    final theme = Theme.of(context);
  final ScrollController scrollController = ScrollController();
  final bool isDesktop = Theme.of(context).platform == TargetPlatform.windows || Theme.of(context).platform == TargetPlatform.macOS || Theme.of(context).platform == TargetPlatform.linux;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'بحث',
              icon: const Icon(Icons.search_rounded),
              onPressed: () {},
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddCategoryDialog(context, c),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة تصنيف'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = 2;
              if (constraints.maxWidth > 1200) {
                crossAxisCount = 5;
              } else if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              }

              return Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (c.categories.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد تصنيفات حالياً',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return Scrollbar(
                  controller: scrollController,
                  thumbVisibility: isDesktop ? true : false,
                  thickness: isDesktop ? 12 : 6,
                  radius: const Radius.circular(8),
                  child: GridView.builder(
                    controller: scrollController,
                    itemCount: c.categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (context, i) {
                    final cat = c.categories[i];
                    final color = _typeColor(cat.type);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: color.withAlpha((0.08 * 255).toInt()),
                        border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
                        boxShadow: [
                          BoxShadow(
                            color: color.withAlpha((0.1 * 255).toInt()),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                  onPressed: () => _showEditCategoryDialog(context, c, cat),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: theme.colorScheme.error,
                                  ),
                                  onPressed: () => _confirmDelete(context, c, cat.id),
                                ),
                              ],
                            ),
                            Icon(_typeIcon(cat.type), size: 46, color: color),
                            Column(
                              children: [
                                Text(
                                  cat.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withAlpha((0.15 * 255).toInt()),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    cat.type ?? '',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                    ),
                );
              });
            },
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, CategoriesController c) {
    final name = TextEditingController();
    final RxString type = 'فاكهة'.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(14),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'إضافة تصنيف جديد',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'اسم التصنيف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: type.value,
                    items: const [
                      DropdownMenuItem(value: 'فاكهة', child: Text('فاكهة')),
                      DropdownMenuItem(value: 'خضار', child: Text('خضار')),
                    ],
                    onChanged: (val) => type.value = val ?? 'فاكهة',
                    decoration: const InputDecoration(
                      labelText: 'النوع',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (name.text.isNotEmpty) {
                        // close bottom sheet
                        Navigator.pop(context);
                        // show progress
                        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                        await c.addCategory(name.text, type.value);
                        // close progress
                        Get.back();
                        Get.snackbar(
                          'تم',
                          'تمت إضافة التصنيف بنجاح',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('إضافة'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(BuildContext context, CategoriesController c, CategoryModel cat) {
    final name = TextEditingController(text: cat.name);
    final RxString type = (cat.type ?? 'فاكهة').obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'تعديل التصنيف',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'اسم التصنيف',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => DropdownButtonFormField<String>(
                    value: type.value,
                    items: const [
                      DropdownMenuItem(value: 'فاكهة', child: Text('فاكهة')),
                      DropdownMenuItem(value: 'خضار', child: Text('خضار')),
                    ],
                    onChanged: (val) => type.value = val ?? 'فاكهة',
                    decoration: const InputDecoration(
                      labelText: 'النوع',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (name.text.isNotEmpty) {
                        Navigator.pop(context);
                        Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
                        await c.updateCategory(cat.id, name.text, type.value);
                        Get.back();
                        Get.snackbar(
                          'تم',
                          'تم تحديث التصنيف بنجاح',
                          snackPosition: SnackPosition.BOTTOM,
                          margin: const EdgeInsets.all(16),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('تحديث'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, CategoriesController c, String id) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف هذا التصنيف؟'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          FilledButton.tonal(
            onPressed: () {
              c.deleteCategory(id);
              Get.back();
              Get.snackbar('تم', 'تم حذف التصنيف بنجاح');
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
