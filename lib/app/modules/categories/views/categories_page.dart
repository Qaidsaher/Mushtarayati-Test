import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/categories_controller.dart';
import '../../../data/models/category_model.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Color _typeColor(String? type) =>
      type == 'خضار' ? Colors.green.shade600 : Colors.orange.shade600;

  IconData _typeIcon(String? type) =>
      type == 'خضار' ? Icons.eco_rounded : Icons.local_pizza_rounded;

  @override
  Widget build(BuildContext context) {
    final c = Get.put(CategoriesController());
    final theme = Theme.of(context);
    final RxString selectedFilter = 'الكل'.obs;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddCategoryDialog(context, c),
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة تصنيف'),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        body: Column(
          children: [
            // Filter Chips Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        context: context,
                        label: 'الكل',
                        icon: Icons.apps_rounded,
                        isSelected: selectedFilter.value == 'الكل',
                        onTap: () => selectedFilter.value = 'الكل',
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterChip(
                        context: context,
                        label: 'خضار',
                        icon: Icons.eco_rounded,
                        isSelected: selectedFilter.value == 'خضار',
                        onTap: () => selectedFilter.value = 'خضار',
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 12),
                      _buildFilterChip(
                        context: context,
                        label: 'فاكهة',
                        icon: Icons.local_pizza_rounded,
                        isSelected: selectedFilter.value == 'فاكهة',
                        onTap: () => selectedFilter.value = 'فاكهة',
                        color: Colors.orange.shade600,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Categories List
            Expanded(
              child: Obx(() {
                if (c.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter categories based on selected filter
                final filteredCategories =
                    selectedFilter.value == 'الكل'
                        ? c.categories
                        : c.categories
                            .where((cat) => cat.type == selectedFilter.value)
                            .toList();

                if (filteredCategories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 80,
                          color: theme.colorScheme.outline.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد تصنيفات',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'اضغط على زر الإضافة لإنشاء تصنيف جديد',
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredCategories.length,
                  itemBuilder: (context, i) {
                    final cat = filteredCategories[i];
                    final color = _typeColor(cat.type);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: color.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                color.withOpacity(0.08),
                                color.withOpacity(0.03),
                              ],
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _typeIcon(cat.type),
                                color: color,
                                size: 28,
                              ),
                            ),
                            title: Text(
                              cat.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Chip(
                                label: Text(
                                  cat.type ?? '',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                backgroundColor: color.withOpacity(0.12),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: theme.colorScheme.primary,
                                    size: 22,
                                  ),
                                  onPressed:
                                      () => _showEditCategoryDialog(
                                        context,
                                        c,
                                        cat,
                                      ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: theme.colorScheme.error,
                                    size: 22,
                                  ),
                                  onPressed:
                                      () => _confirmDelete(context, c, cat.id),
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.error
                                        .withOpacity(0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, CategoriesController c) {
    final name = TextEditingController();
    final RxString type = 'فاكهة'.obs;
    final RxString errorMessage = ''.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.add_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إضافة تصنيف جديد',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'اسم التصنيف',
                    hintText: 'أدخل اسم التصنيف',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                  ),
                  onChanged: (value) => errorMessage.value = '',
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر نوع التصنيف',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _buildTypeChip(
                          context: context,
                          label: 'فاكهة',
                          icon: Icons.local_pizza_rounded,
                          color: Colors.orange.shade600,
                          isSelected: type.value == 'فاكهة',
                          onTap: () => type.value = 'فاكهة',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeChip(
                          context: context,
                          label: 'خضار',
                          icon: Icons.eco_rounded,
                          color: Colors.green.shade600,
                          isSelected: type.value == 'خضار',
                          onTap: () => type.value = 'خضار',
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () =>
                      errorMessage.value.isNotEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage.value,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) {
                        errorMessage.value = 'الرجاء إدخال اسم التصنيف';
                        return;
                      }

                      // Check for duplicate name
                      final duplicateName = c.categories.any(
                        (cat) =>
                            cat.name.trim().toLowerCase() ==
                            name.text.trim().toLowerCase(),
                      );

                      if (duplicateName) {
                        errorMessage.value = 'يوجد تصنيف بنفس الاسم بالفعل';
                        return;
                      }

                      // Check for duplicate name + type
                      final duplicateNameAndType = c.categories.any(
                        (cat) =>
                            cat.name.trim().toLowerCase() ==
                                name.text.trim().toLowerCase() &&
                            cat.type == type.value,
                      );

                      if (duplicateNameAndType) {
                        errorMessage.value =
                            'يوجد تصنيف بنفس الاسم والنوع بالفعل';
                        return;
                      }

                      // close bottom sheet
                      Navigator.pop(context);
                      // show progress
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );
                      await c.addCategory(name.text.trim(), type.value);
                      // close progress
                      Get.back();
                      Get.snackbar(
                        'تم',
                        'تمت إضافة التصنيف بنجاح',
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        colorText: theme.colorScheme.onPrimaryContainer,
                        icon: Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة التصنيف'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    CategoriesController c,
    CategoryModel cat,
  ) {
    final name = TextEditingController(text: cat.name);
    final RxString type = (cat.type ?? 'فاكهة').obs;
    final RxString errorMessage = ''.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'تعديل التصنيف',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: name,
                  decoration: InputDecoration(
                    labelText: 'اسم التصنيف',
                    hintText: 'أدخل اسم التصنيف',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(0.3),
                  ),
                  onChanged: (value) => errorMessage.value = '',
                ),
                const SizedBox(height: 16),
                Text(
                  'اختر نوع التصنيف',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _buildTypeChip(
                          context: context,
                          label: 'فاكهة',
                          icon: Icons.local_pizza_rounded,
                          color: Colors.orange.shade600,
                          isSelected: type.value == 'فاكهة',
                          onTap: () => type.value = 'فاكهة',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTypeChip(
                          context: context,
                          label: 'خضار',
                          icon: Icons.eco_rounded,
                          color: Colors.green.shade600,
                          isSelected: type.value == 'خضار',
                          onTap: () => type.value = 'خضار',
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () =>
                      errorMessage.value.isNotEmpty
                          ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage.value,
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          : const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) {
                        errorMessage.value = 'الرجاء إدخال اسم التصنيف';
                        return;
                      }

                      // Check for duplicate name (excluding current category)
                      final duplicateName = c.categories.any(
                        (otherCat) =>
                            otherCat.id != cat.id &&
                            otherCat.name.trim().toLowerCase() ==
                                name.text.trim().toLowerCase(),
                      );

                      if (duplicateName) {
                        errorMessage.value = 'يوجد تصنيف بنفس الاسم بالفعل';
                        return;
                      }

                      // Check for duplicate name + type (excluding current category)
                      final duplicateNameAndType = c.categories.any(
                        (otherCat) =>
                            otherCat.id != cat.id &&
                            otherCat.name.trim().toLowerCase() ==
                                name.text.trim().toLowerCase() &&
                            otherCat.type == type.value,
                      );

                      if (duplicateNameAndType) {
                        errorMessage.value =
                            'يوجد تصنيف بنفس الاسم والنوع بالفعل';
                        return;
                      }

                      Navigator.pop(context);
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );
                      await c.updateCategory(
                        cat.id,
                        name.text.trim(),
                        type.value,
                      );
                      Get.back();
                      Get.snackbar(
                        'تم',
                        'تم تحديث التصنيف بنجاح',
                        snackPosition: SnackPosition.BOTTOM,
                        margin: const EdgeInsets.all(16),
                        backgroundColor: theme.colorScheme.primaryContainer,
                        colorText: theme.colorScheme.onPrimaryContainer,
                        icon: Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('حفظ التغييرات'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? color : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CategoriesController c, String id) {
    final theme = Theme.of(context);
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('تأكيد الحذف'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا التصنيف؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () {
              c.deleteCategory(id);
              Get.back();
              Get.snackbar(
                'تم',
                'تم حذف التصنيف بنجاح',
                snackPosition: SnackPosition.BOTTOM,
                margin: const EdgeInsets.all(16),
                backgroundColor: theme.colorScheme.errorContainer,
                colorText: theme.colorScheme.onErrorContainer,
                icon: Icon(Icons.check_circle, color: theme.colorScheme.error),
              );
            },
            icon: const Icon(Icons.delete_rounded),
            label: const Text('حذف'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
