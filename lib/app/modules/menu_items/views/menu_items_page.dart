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
          elevation: 0,
          title: const Text(
            'عناصر القائمة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            // Quick expenses editor
            IconButton(
              tooltip: 'مصروفات',
              onPressed: () => _showExpensesDialog(context, c),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
                minimumSize: const Size(36, 36),
                padding: const EdgeInsets.all(6),
              ),
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
            ),
            const SizedBox(width: 8),
            // Export menu with modern dropdown
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.ios_share_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              tooltip: 'تصدير',
              onSelected: (value) async {
                if (value == 'excel') {
                  await _exportExcel(context, c);
                } else if (value == 'pdf') {
                  await _exportPdf(context, c);
                }
              },
              itemBuilder:
                  (context) => [
                    PopupMenuItem(
                      value: 'excel',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart, color: Colors.green[700]),
                          const SizedBox(width: 12),
                          const Text('تصدير Excel'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.red[700]),
                          const SizedBox(width: 12),
                          const Text('تصدير PDF'),
                        ],
                      ),
                    ),
                  ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        floatingActionButton: Obx(() {
          if (c.isLoading.value) return const SizedBox.shrink();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bulk add (smaller)
              FloatingActionButton.extended(
                heroTag: 'bulk',
                tooltip: 'إدخال سريع',
                onPressed: () => Get.to(() => const MenuItemsBulkPage()),
                backgroundColor: theme.colorScheme.secondaryContainer,
                foregroundColor: theme.colorScheme.onSecondaryContainer,
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: const Text('إدخال سريع'),
              ),
              const SizedBox(height: 12),
              // Add single item (smaller)
              FloatingActionButton.extended(
                heroTag: 'add',
                tooltip: 'إضافة عنصر',
                onPressed: () => _showModernItemDialog(context, c, null),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة عنصر'),
              ),
            ],
          );
        }),

        body: Obx(() {
          if (c.isLoading.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 3,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'جاري التحميل...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (c.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_basket_outlined,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'لا توجد عناصر بعد',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ بإضافة عناصر إلى القائمة',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _showModernItemDialog(context, c, null),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('إضافة أول عنصر'),
                  ),
                ],
              ),
            );
          }

          // Calculate total
          final totalAmount = c.items.fold<double>(
            0,
            (sum, item) => sum + (item.qty * item.unitPrice),
          );
          final stationery = c.menu.value?.stationeryExpenses ?? 0;
          final transport = c.menu.value?.transportationExpenses ?? 0;
          final expensesTotal = stationery + transport;

          return Column(
            children: [
              // Summary cards - single horizontal row
              Container(
                height: 60,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Builder(
                    builder: (ctx) {
                      final grandTotal = totalAmount + expensesTotal;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            // Put expenses first (like menus page)
                            _statChip(
                              context,
                              Icons.edit_note_rounded,
                              'قرطاسية',
                              '${stationery.toStringAsFixed(2)} ر.س',
                              Colors.purple,
                              onTap: () => _showExpensesDialog(context, c),
                            ),
                            const SizedBox(width: 8),
                            _statChip(
                              context,
                              Icons.local_shipping_rounded,
                              'نقل',
                              '${transport.toStringAsFixed(2)} ر.س',
                              Colors.orange,
                              onTap: () => _showExpensesDialog(context, c),
                            ),
                            const SizedBox(width: 8),
                            _statChip(
                              context,
                              Icons.payments_rounded,
                              'إجمالي العناصر',
                              '${totalAmount.toStringAsFixed(2)} ر.س',
                              theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            _statChip(
                              context,
                              Icons.account_balance_wallet_rounded,
                              'الإجمالي الكلي',
                              '${grandTotal.toStringAsFixed(2)} ر.س',
                              Colors.green,
                              highlighted: true,
                            ),
                            const SizedBox(width: 8),
                            _statChip(
                              context,
                              Icons.inventory_2_rounded,
                              'العناصر',
                              '${c.items.length}',
                              theme.colorScheme.secondary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Items list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: c.items.length,
                  itemBuilder:
                      (context, i) =>
                          _buildModernItemCard(context, c, c.items[i], i),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // Professional stats chip (shared style with menus page)
  Widget _statChip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color, {
    bool highlighted = false,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color:
            highlighted
                ? color.withOpacity(0.12)
                : theme.colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              highlighted
                  ? color.withOpacity(0.4)
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (highlighted ? color : Colors.black).withOpacity(0.06),
            blurRadius: highlighted ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: highlighted ? color : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: chip,
        ),
      );
    }
    return chip;
  }

  Widget _buildModernItemCard(
    BuildContext context,
    MenuItemsController c,
    ItemModel item,
    int index,
  ) {
    final theme = Theme.of(context);
    final cat = _findCategoryById(c.categories, item.categoryId);
    final total = item.qty * item.unitPrice;
    final icon = _getCategoryIcon(cat);
    final color = _getCategoryColor(cat, theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showModernItemDialog(context, c, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat?.name ?? 'عنصر',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildInfoChip(
                            context,
                            Icons.shopping_cart_outlined,
                            '${item.qty}',
                          ),
                          _buildInfoChip(
                            context,
                            Icons.attach_money,
                            '${item.unitPrice.toStringAsFixed(2)} ر.س',
                          ),
                        ],
                      ),
                      if (item.notes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        Text(
                          item.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Total and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${total.toStringAsFixed(2)} ر.س',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed:
                              () => _showModernItemDialog(context, c, item),
                          tooltip: 'تعديل',
                          style: IconButton.styleFrom(
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                title: const Text('تأكيد الحذف'),
                                content: const Text('هل تريد حذف هذا العنصر؟'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text('إلغاء'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Get.back(result: true),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: theme.colorScheme.error,
                                    ),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) c.delete(item.id);
                          },
                          tooltip: 'حذف',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.errorContainer
                                .withOpacity(0.5),
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(CategoryModel? cat) {
    final name = (cat?.name ?? '').toLowerCase();
    final type = (cat?.type ?? '').toLowerCase();

    if (type.contains('فاكهة') ||
        name.contains('فاكهة') ||
        name.contains('fruit')) {
      return Icons.apple_rounded;
    }
    if (type.contains('خضار') ||
        name.contains('خضار') ||
        name.contains('vegetable')) {
      return Icons.eco_rounded;
    }
    if (type.contains('لحم') || name.contains('لحم') || name.contains('meat')) {
      return Icons.set_meal_rounded;
    }
    if (type.contains('ألبان') ||
        name.contains('ألبان') ||
        name.contains('dairy')) {
      return Icons.egg_rounded;
    }
    if (type.contains('مخبوزات') ||
        name.contains('مخبوزات') ||
        name.contains('bakery')) {
      return Icons.bakery_dining_rounded;
    }
    if (type.contains('مشروبات') ||
        name.contains('مشروبات') ||
        name.contains('beverage')) {
      return Icons.local_cafe_rounded;
    }
    return Icons.shopping_basket_rounded;
  }

  Color _getCategoryColor(CategoryModel? cat, ThemeData theme) {
    final name = (cat?.name ?? '').toLowerCase();
    final type = (cat?.type ?? '').toLowerCase();

    if (type.contains('فاكهة') ||
        name.contains('فاكهة') ||
        name.contains('fruit')) {
      return Colors.orange;
    }
    if (type.contains('خضار') ||
        name.contains('خضار') ||
        name.contains('vegetable')) {
      return Colors.green;
    }
    if (type.contains('لحم') || name.contains('لحم') || name.contains('meat')) {
      return Colors.red[700]!;
    }
    if (type.contains('ألبان') ||
        name.contains('ألبان') ||
        name.contains('dairy')) {
      return Colors.blue;
    }
    if (type.contains('مخبوزات') ||
        name.contains('مخبوزات') ||
        name.contains('bakery')) {
      return Colors.brown;
    }
    if (type.contains('مشروبات') ||
        name.contains('مشروبات') ||
        name.contains('beverage')) {
      return Colors.purple;
    }
    return theme.colorScheme.primary;
  }

  Future<void> _exportExcel(BuildContext context, MenuItemsController c) async {
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
          title: const Text('تصدير Excel'),
          content: const Text(
            'هل تريد تصدير جميع العناصر في هذه القائمة إلى ملف Excel؟',
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
        'جارٍ تحضير ملف Excel...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      );

      final rows =
          c.items.map((it) {
            final cat = _findCategoryById(c.categories, it.categoryId);
            return {
              'الفئة': cat?.name ?? '',
              'الكمية': it.qty,
              'سعر الوحدة': it.unitPrice,
              'الإجمالي': (it.qty * it.unitPrice),
              'ملاحظات': it.notes ?? '',
            };
          }).toList();

      final file = await ExportService.createExcelForEntity(
        prefix: 'menu_${c.menuId}_items',
        rows: rows,
      );
      await ExportService.shareFile(
        file,
        subject: 'تصدير Excel - عناصر القائمة',
        text: 'ملف Excel لجميع عناصر القائمة',
      );
      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء ومشاركة ملف Excel',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء التصدير',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, MenuItemsController c) async {
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
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      );

      final arabicRows =
          c.items.map((it) {
            final cat = _findCategoryById(c.categories, it.categoryId);
            return {
              'الفئة': cat?.name ?? '',
              'الكمية': it.qty,
              'سعر الوحدة': it.unitPrice,
              'الإجمالي': (it.qty * it.unitPrice),
              'ملاحظات': it.notes ?? '',
            };
          }).toList();

      final file = await ExportService.createPdfReportForMenu(
        menuName: 'عناصر القائمة',
        rows: arabicRows,
        logoAsset: 'assets/images/logo.png',
        fontAsset: 'assets/fonts/NotoNaskhArabic-Regular.ttf',
      );
      await ExportService.shareFile(
        file,
        subject: 'تقرير PDF - عناصر القائمة',
        text: 'تقرير PDF لجميع عناصر القائمة',
      );
      Get.snackbar(
        'تم بنجاح',
        'تم إنشاء ومشاركة ملف PDF',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء إنشاء ملف PDF',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
      );
    }
  }

  void _showModernItemDialog(
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (ctx, setState) {
              final theme = Theme.of(context);
              final total =
                  (double.tryParse(qty.text) ?? 0) *
                  (double.tryParse(price.text) ?? 0);

              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle bar
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),

                        // Title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                item == null
                                    ? Icons.add_shopping_cart_rounded
                                    : Icons.edit_rounded,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                item == null
                                    ? 'إضافة عنصر جديد'
                                    : 'تعديل العنصر',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Category dropdown
                        DropdownButtonFormField<String>(
                          value: selectedCatId,
                          decoration: InputDecoration(
                            labelText: 'الفئة',
                            prefixIcon: Icon(
                              selectedCatId != null
                                  ? _getCategoryIcon(
                                    _findCategoryById(
                                      c.categories,
                                      selectedCatId,
                                    ),
                                  )
                                  : Icons.category_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                          ),
                          items:
                              c.categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat.id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getCategoryIcon(cat),
                                            size: 20,
                                            color: _getCategoryColor(
                                              cat,
                                              theme,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(cat.name),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => selectedCatId = v),
                          validator:
                              (v) =>
                                  (v == null || v.isEmpty) ? 'اختر فئة' : null,
                        ),
                        const SizedBox(height: 16),

                        // Quantity and Price in a row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: qty,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'الكمية',
                                  prefixIcon: const Icon(
                                    Icons.shopping_cart_outlined,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  filled: true,
                                ),
                                validator: (v) {
                                  final q = double.tryParse(v ?? '0') ?? 0;
                                  if (q <= 0) {
                                    return 'الكمية يجب أن تكون أكبر من صفر';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: price,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'السعر',
                                  prefixIcon: const Icon(Icons.attach_money),
                                  suffixText: 'ر.س',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  filled: true,
                                ),
                                validator: (v) {
                                  final p = double.tryParse(v ?? '0') ?? 0;
                                  if (p <= 0) {
                                    return 'السعر يجب أن يكون أكبر من صفر';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Notes
                        TextFormField(
                          controller: notes,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'ملاحظات (اختياري)',
                            prefixIcon: const Icon(Icons.note_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Total display
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primaryContainer,
                                theme.colorScheme.secondaryContainer,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الإجمالي:',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(2)} ر.س',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(sheetContext),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('إلغاء'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  final qVal = double.tryParse(qty.text) ?? 0;
                                  final p = double.tryParse(price.text) ?? 0;

                                  final newItem = ItemModel(
                                    id: item?.id ?? '',
                                    menuId: c.menuId,
                                    categoryId: selectedCatId,
                                    qty: qVal.toInt(),
                                    unitPrice: p,
                                    total: qVal * p,
                                    notes:
                                        notes.text.isEmpty ? null : notes.text,
                                    updatedAt:
                                        DateTime.now().millisecondsSinceEpoch,
                                  );

                                  Navigator.pop(sheetContext);
                                  await c.addOrUpdate(newItem);

                                  Get.snackbar(
                                    'تم',
                                    item == null
                                        ? 'تمت إضافة العنصر بنجاح'
                                        : 'تم تعديل العنصر بنجاح',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: Colors.green[100],
                                  );
                                },
                                icon: const Icon(Icons.check_rounded),
                                label: Text(item == null ? 'إضافة' : 'حفظ'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  // ---- Expenses dialog ----
  void _showExpensesDialog(BuildContext context, MenuItemsController c) {
    final theme = Theme.of(context);
    final currentStationery =
        (c.menu.value?.stationeryExpenses ?? 0).toString();
    final currentTransport =
        (c.menu.value?.transportationExpenses ?? 0).toString();
    final stationeryCtrl = TextEditingController(text: currentStationery);
    final transportCtrl = TextEditingController(text: currentTransport);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.receipt_long_rounded,
                                color: theme.colorScheme.onTertiaryContainer,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'تعديل المصروفات',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (ctx, cons) {
                            final narrow = cons.maxWidth < 360;
                            final fields = [
                              Expanded(
                                child: TextFormField(
                                  controller: stationeryCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'مصروفات القرطاسية',
                                    prefixIcon: const Icon(
                                      Icons.edit_note_rounded,
                                    ),
                                    suffixText: 'ر.س',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                  ),
                                  validator: (v) {
                                    final n = double.tryParse((v ?? '').trim());
                                    if (n == null || n < 0)
                                      return 'أدخل قيمة صحيحة';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: transportCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'مصروفات النقل',
                                    prefixIcon: const Icon(
                                      Icons.local_shipping_rounded,
                                    ),
                                    suffixText: 'ر.س',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    filled: true,
                                  ),
                                  validator: (v) {
                                    final n = double.tryParse((v ?? '').trim());
                                    if (n == null || n < 0)
                                      return 'أدخل قيمة صحيحة';
                                    return null;
                                  },
                                ),
                              ),
                            ];
                            if (narrow) {
                              return Column(
                                children: [
                                  fields[0],
                                  const SizedBox(height: 12),
                                  fields[2],
                                ],
                              );
                            }
                            return Row(children: fields);
                          },
                        ),
                        const SizedBox(height: 24),
                        Obx(() {
                          final isSaving = c.isSavingExpenses.value;
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isSaving ? null : () => Get.back(),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('إلغاء'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: FilledButton.icon(
                                  onPressed:
                                      isSaving
                                          ? null
                                          : () async {
                                            if (!(formKey.currentState
                                                    ?.validate() ??
                                                false))
                                              return;
                                            final st =
                                                double.tryParse(
                                                  stationeryCtrl.text.trim(),
                                                ) ??
                                                0;
                                            final tr =
                                                double.tryParse(
                                                  transportCtrl.text.trim(),
                                                ) ??
                                                0;
                                            await c.updateExpenses(
                                              stationery: st,
                                              transportation: tr,
                                            );
                                            Get.back();
                                            Get.snackbar(
                                              'تم',
                                              'تم تحديث المصروفات',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                              backgroundColor:
                                                  Colors.green[100],
                                            );
                                          },
                                  icon:
                                      isSaving
                                          ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color:
                                                  theme.colorScheme.onPrimary,
                                            ),
                                          )
                                          : const Icon(Icons.save_rounded),
                                  label: Text(
                                    isSaving ? 'جاري الحفظ...' : 'حفظ',
                                  ),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // Safe lookup without package:collection
  CategoryModel? _findCategoryById(List<CategoryModel> list, String? id) {
    if (id == null) return null;
    for (final c in list) {
      if (c.id == id) return c;
    }
    return null;
  }
}
