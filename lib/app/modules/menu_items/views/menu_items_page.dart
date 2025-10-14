import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/menu_items_controller.dart';
import '../../../data/models/item_model.dart';
import 'menu_items_bulk_page.dart';
import '../../../core/services/export_service.dart';
import '../../../data/models/category_model.dart';

class MenuItemsPage extends StatelessWidget {
  const MenuItemsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(MenuItemsController());
    final theme = Theme.of(context);
    final args = Get.arguments;
    final menuId =
        args is Map && args['menuId'] != null ? args['menuId'] as String : '';
    if (menuId.isNotEmpty) {
      c.loadForMenu(menuId);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عناصر القائمة'),
          actions: [
            IconButton(
              tooltip: 'تصدير إكسل (كل العناصر)',
              icon: const Icon(Icons.table_chart),
              onPressed: () async {
                try {
                  if (c.isLoading.value) {
                    Get.snackbar(
                      'تنبيه',
                      'الرجاء الانتظار حتى انتهاء التحميل',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  if (c.items.isEmpty) {
                    Get.snackbar(
                      'تنبيه',
                      'لا توجد عناصر للتصدير',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  final confirmed = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('تصدير إكسل'),
                      content: const Text(
                        'هل تريد تصدير جميع العناصر في هذه القائمة إلى ملف إكسل؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('تصدير'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;

                  Get.snackbar(
                    'تصدير',
                    'جارٍ تحضير ملف الإكسل...',
                    snackPosition: SnackPosition.BOTTOM,
                  );

                  final rows =
                      c.items.map((it) {
                        final cat = c.categories.firstWhereOrNull(
                          (x) => x.id == it.categoryId,
                        );
                        return {
                          'id': it.id,
                          'menuId': it.menuId,
                          'الفئة': cat?.name ?? '',
                          'notes': it.notes ?? '',
                          'qty': it.qty,
                          'unit_price': it.unitPrice,
                          'total': (it.qty * it.unitPrice),
                          'updated_at':
                              DateTime.fromMillisecondsSinceEpoch(
                                it.updatedAt ?? 0,
                              ).toString(),
                        };
                      }).toList();

                  final file = await ExportService.createExcelForEntity(
                    prefix: 'menu_${c.menuId}_items',
                    rows: rows,
                  );
                  await ExportService.shareFile(
                    file,
                    subject: 'تصدير إكسل - عناصر القائمة',
                    text: 'ملف الإكسل لجميع عناصر القائمة',
                  );
                  Get.snackbar('تم', 'تم إنشاء ومشاركة ملف الإكسل');
                } catch (e) {
                  Get.snackbar('خطأ', 'حدث خطأ أثناء التصدير');
                }
              },
            ),
            IconButton(
              tooltip: 'تصدير PDF (كل العناصر)',
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () async {
                try {
                  if (c.isLoading.value) {
                    Get.snackbar(
                      'تنبيه',
                      'الرجاء الانتظار حتى انتهاء التحميل',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }
                  if (c.items.isEmpty) {
                    Get.snackbar(
                      'تنبيه',
                      'لا توجد عناصر للتصدير',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                    return;
                  }

                  final confirmed = await Get.dialog<bool>(
                    AlertDialog(
                      title: const Text('تصدير PDF'),
                      content: const Text(
                        'هل تريد إنشاء ملف PDF يحتوي على جميع عناصر هذه القائمة؟',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(result: false),
                          child: const Text('إلغاء'),
                        ),
                        FilledButton(
                          onPressed: () => Get.back(result: true),
                          child: const Text('إنشاء'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;

                  Get.snackbar(
                    'تصدير',
                    'جارٍ إنشاء ملف PDF...',
                    snackPosition: SnackPosition.BOTTOM,
                  );

                  final arabicRows =
                      c.items.map((it) {
                        final cat = c.categories.firstWhereOrNull(
                          (x) => x.id == it.categoryId,
                        );
                        return {
                          'ملاحظة': it.notes ?? '',
                          'كمية': it.qty,
                          'سعر الوحدة': it.unitPrice,
                          'الفئة': cat?.name ?? '',
                          'الإجمالي': (it.qty * it.unitPrice),
                        };
                      }).toList();

                  final file = await ExportService.createPdfReportForMenu(
                    menuName: 'عناصر القائمة',
                    rows: arabicRows,
                    logoAsset: 'assets/images/logo.png',
                  );
                  await ExportService.shareFile(
                    file,
                    subject: 'تقرير PDF - عناصر القائمة',
                    text: 'تقرير PDF لجميع عناصر القائمة',
                  );
                  Get.snackbar('تم', 'تم إنشاء ومشاركة ملف PDF');
                } catch (e) {
                  Get.snackbar('خطأ', 'حدث خطأ أثناء إنشاء ملف PDF');
                }
              },
            ),
          ],
        ),
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
          if (c.isLoading.value)
            return const Center(child: CircularProgressIndicator());
          if (c.items.isEmpty)
            return const Center(child: Text('لا توجد عناصر بعد'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: c.items.length,
            itemBuilder: (context, i) {
              final it = c.items[i];
              final cat = c.categories.firstWhereOrNull(
                (x) => x.id == it.categoryId,
              );
              final theme = Theme.of(context);

              IconData iconForCategory(CategoryModel? cat) {
                final name = (cat?.name ?? '').toLowerCase();
                final type = (cat?.type ?? '').toLowerCase();
                if (type.contains('فاكهة') ||
                    name.contains('فاكهة') ||
                    name.contains('fruit'))
                  return Icons.apple;
                if (type.contains('خضار') ||
                    name.contains('خضار') ||
                    name.contains('vegetable'))
                  return Icons.eco;
                return Icons.local_grocery_store;
              }

              final total = it.qty * it.unitPrice;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.colorScheme.primary.withOpacity(
                      0.15,
                    ),
                    child: Icon(
                      iconForCategory(cat),
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  title: Text(
                    cat?.name ?? 'عنصر',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'الكمية: ${it.qty} • السعر: ${it.unitPrice.toStringAsFixed(2)} ر.س\nالإجمالي: ${total.toStringAsFixed(2)} ر.س',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _showEditItemDialog(context, c, it),
                        tooltip: 'تعديل',
                        color: theme.colorScheme.primary,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_forever_rounded),
                        onPressed: () => c.delete(it.id),
                        tooltip: 'حذف',
                        color: theme.colorScheme.error,
                      ),
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

  void _showEditItemDialog(
    BuildContext context,
    MenuItemsController c,
    ItemModel? item,
  ) {
    final qty = TextEditingController(text: item?.qty.toString() ?? '1');
    final price = TextEditingController(
      text: item?.unitPrice.toString() ?? '0',
    );
    final notes = TextEditingController(text: item?.notes ?? '');
    String? selectedCatId = item?.categoryId;
    final formKey = GlobalKey<FormState>();
    bool formValid = false;

    IconData iconForCategoryModel(CategoryModel? cat) {
      final name = (cat?.name ?? '').toLowerCase();
      final type = (cat?.type ?? '').toLowerCase();
      if (type.contains('fruit') ||
          name.contains('فاكه') ||
          name.contains('fruit'))
        return Icons.eco;
      if (type.contains('vegetable') ||
          name.contains('خض') ||
          name.contains('vegetable'))
        return Icons.grass;
      if (type.contains('dairy') ||
          name.contains('لبن') ||
          name.contains('dairy'))
        return Icons.egg;
      if (type.contains('meat') ||
          name.contains('لحم') ||
          name.contains('meat'))
        return Icons.set_meal;
      if (type.contains('bakery') ||
          name.contains('مخبز') ||
          name.contains('bakery'))
        return Icons.bakery_dining;
      return Icons.local_grocery_store;
    }

    showDialog(
      context: context,
      builder:
          (dialogCtx) => StatefulBuilder(
            builder: (ctx2, setState) {
              double calcTotal() =>
                  (double.tryParse(qty.text) ?? 0) *
                  (double.tryParse(price.text) ?? 0);

              // ensure selectedCatId is valid for current categories
              if (selectedCatId != null &&
                  c.categories
                      .where((cat) => cat.id == selectedCatId)
                      .isEmpty) {
                selectedCatId = null;
              }

              void updateValid() {
                final valid = formKey.currentState?.validate() ?? false;
                if (valid != formValid) setState(() => formValid = valid);
              }

              // ensure initial validation runs after first frame
              Future.microtask(() => updateValid());

              // make dialog content scrollable and constrained to a max width so it works on small and large screens
              final mq = MediaQuery.of(dialogCtx);
              final maxW = mq.size.width * 0.92;
              return AlertDialog(
                title: Text(item == null ? 'إضافة عنصر' : 'تعديل العنصر'),
                content: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxW, minWidth: 0),
                    child: Form(
                      key: formKey,
                      onChanged: updateValid,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // category dropdown
                          DropdownButtonFormField<String>(
                            value: selectedCatId,
                            isExpanded: true,
                            items:
                                c.categories
                                    .map(
                                      (cat) => DropdownMenuItem(
                                        value: cat.id,
                                        child: Row(
                                          children: [
                                            Icon(iconForCategoryModel(cat)),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                cat.name,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (v) => setState(() {
                                  selectedCatId = v;
                                  updateValid();
                                }),
                            validator:
                                (v) =>
                                    (v == null || v.isEmpty)
                                        ? 'اختر فئة'
                                        : null,
                            decoration: const InputDecoration(
                              labelText: 'الفئة',
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: qty,
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              labelText: 'الكمية',
                            ),
                            validator: (v) {
                              final q = double.tryParse(v ?? '0') ?? 0;
                              if (q <= 0)
                                return 'الكمية يجب أن تكون أكبر من صفر';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: price,
                            keyboardType: TextInputType.number,
                            maxLines: 1,
                            decoration: const InputDecoration(
                              labelText: 'سعر الوحدة',
                              suffixText: 'ريال',
                            ),
                            validator: (v) {
                              final p = double.tryParse(v ?? '0') ?? 0;
                              if (p <= 0)
                                return 'سعر الوحدة يجب أن يكون أكبر من صفر';
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: notes,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الإجمالي:'),
                              Text(
                                '${calcTotal().toStringAsFixed(2)} ريال',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogCtx),
                    child: const Text('إلغاء'),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('حفظ'),
                    onPressed:
                        formValid
                            ? () async {
                              if (!(formKey.currentState?.validate() ?? false))
                                return;
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
                                updatedAt:
                                    DateTime.now().millisecondsSinceEpoch,
                              );
                              // close dialog first to avoid using BuildContext after await
                              Get.back();
                              await c.addOrUpdate(newItem);
                            }
                            : null,
                  ),
                ],
              );
            },
          ),
    );
  }
}
