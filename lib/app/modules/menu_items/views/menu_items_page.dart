import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/menu_items_controller.dart';
import '../../../data/models/item_model.dart';
import 'menu_items_bulk_page.dart';
import '../../../data/models/category_model.dart';

class MenuItemsPage extends StatelessWidget {
  const MenuItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MenuItemsController());
    final theme = Theme.of(context);
    final args = Get.arguments;
    final menuId = args is Map && args['menuId'] != null ? args['menuId'] as String : '';
    if (menuId.isNotEmpty) {
      c.loadForMenu(menuId);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عناصر القائمة')),
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton.extended(
              onPressed: () => _showEditItemDialog(context, c, null),
              icon: const Icon(Icons.add),
              label: const Text('إضافة عنصر'),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'bulk',
              onPressed: () => Get.to(() => const MenuItemsBulkPage()),
              tooltip: 'إدخال جماعي',
              child: const Icon(Icons.playlist_add),
            ),
          ],
        ),
        body: Obx(() {
          if (c.isLoading.value) return const Center(child: CircularProgressIndicator());
          if (c.items.isEmpty) return const Center(child: Text('لا توجد عناصر بعد'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: c.items.length,
            itemBuilder: (context, i) {
              final it = c.items[i];
              final cat = c.categories.firstWhereOrNull((x) => x.id == it.categoryId);
              IconData iconForCategory(CategoryModel? cat) {
                final name = (cat?.name ?? '').toLowerCase();
                final type = (cat?.type ?? '').toLowerCase();
                if (type.contains('fruit') || name.contains('فاكه') || name.contains('fruit')) return Icons.eco;
                if (type.contains('vegetable') || name.contains('خض') || name.contains('vegetable')) return Icons.grass;
                if (type.contains('dairy') || name.contains('لبن') || name.contains('dairy')) return Icons.egg;
                if (type.contains('meat') || name.contains('لحم') || name.contains('meat')) return Icons.set_meal;
                if (type.contains('bakery') || name.contains('مخبز') || name.contains('bakery')) return Icons.bakery_dining;
                return Icons.local_grocery_store;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(iconForCategory(cat), color: theme.colorScheme.onPrimaryContainer),
                  ),
                  title: Text(cat?.name ?? 'عنصر', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('كمية: ${it.qty} • سعر الوحدة: ${it.unitPrice} ريال • الإجمالي: ${ (it.qty * it.unitPrice).toStringAsFixed(2) } ريال'),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _showEditItemDialog(context, c, it)),
                      IconButton(icon: const Icon(Icons.delete), onPressed: () => c.delete(it.id)),
                    ],
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, MenuItemsController c, ItemModel? item) {
    final qty = TextEditingController(text: item?.qty.toString() ?? '1');
    final price = TextEditingController(text: item?.unitPrice.toString() ?? '0');
    final notes = TextEditingController(text: item?.notes ?? '');
  String? selectedCatId = (item?.categoryId != null && (item!.categoryId ?? '').isNotEmpty) ? item.categoryId : null;
    final formKey = GlobalKey<FormState>();
    bool formValid = false;

    IconData iconForCategoryModel(CategoryModel? cat) {
      final name = (cat?.name ?? '').toLowerCase();
      final type = (cat?.type ?? '').toLowerCase();
      if (type.contains('fruit') || name.contains('فاكه') || name.contains('fruit')) return Icons.eco;
      if (type.contains('vegetable') || name.contains('خض') || name.contains('vegetable')) return Icons.grass;
      if (type.contains('dairy') || name.contains('لبن') || name.contains('dairy')) return Icons.egg;
      if (type.contains('meat') || name.contains('لحم') || name.contains('meat')) return Icons.set_meal;
      if (type.contains('bakery') || name.contains('مخبز') || name.contains('bakery')) return Icons.bakery_dining;
      return Icons.local_grocery_store;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(item == null ? 'إضافة عنصر' : 'تعديل العنصر'),
        content: StatefulBuilder(builder: (ctx, setState) {
          double calcTotal() => (double.tryParse(qty.text) ?? 0) * (double.tryParse(price.text) ?? 0);

          // make sure the selectedCatId is valid for the current categories list
          if (selectedCatId != null && c.categories.where((cat) => cat.id == selectedCatId).isEmpty) {
            selectedCatId = null;
          }

          void updateValid() {
            final valid = formKey.currentState?.validate() ?? false;
            if (valid != formValid) setState(() => formValid = valid);
          }

          // ensure initial validation runs after the first frame so Save button state is correct
          Future.microtask(() => updateValid());

          return Form(
            key: formKey,
            onChanged: updateValid,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // category dropdown
                DropdownButtonFormField<String>(
                  value: selectedCatId,
                  items: c.categories.map((cat) => DropdownMenuItem(
                        value: cat.id,
                        child: Row(children: [Icon(iconForCategoryModel(cat)), const SizedBox(width: 8), Text(cat.name)]),
                      )).toList(),
                  onChanged: (v) => setState(() {
                    selectedCatId = v;
                    updateValid();
                  }),
                  validator: (v) => (v == null || v.isEmpty) ? 'اختر فئة' : null,
                  decoration: const InputDecoration(labelText: 'الفئة'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: qty,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                  validator: (v) {
                    final q = double.tryParse(v ?? '0') ?? 0;
                    if (q <= 0) return 'الكمية يجب أن تكون أكبر من صفر';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'سعر الوحدة', suffixText: 'ريال'),
                  validator: (v) {
                    final p = double.tryParse(v ?? '0') ?? 0;
                    if (p <= 0) return 'سعر الوحدة يجب أن يكون أكبر من صفر';
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                TextFormField(controller: notes, decoration: const InputDecoration(labelText: 'ملاحظات')),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('الإجمالي:'), Text('${calcTotal().toStringAsFixed(2)} ريال', style: const TextStyle(fontWeight: FontWeight.bold))]),
              ],
            ),
          );
        }),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('حفظ'),
              onPressed: formValid
                  ? () async {
                      // final validation pass
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      final q = double.tryParse(qty.text) ?? 0;
                      final p = double.tryParse(price.text) ?? 0;

                      final newItem = ItemModel(
                        id: item?.id ?? '',
                        menuId: c.menuId,
                        categoryId: selectedCatId,
                        qty: q,
                        unitPrice: p,
                        total: q * p, // still store total for legacy
                        notes: notes.text,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      );
                      // close dialog first to avoid using BuildContext after await
                      Get.back();
                      await c.addOrUpdate(newItem);
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}
