import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:saher_kit/app/core/services/day_pdf_export_services.dart';
import 'package:saher_kit/app/core/services/excel_export_services.dart';
import '../controllers/menus_controller.dart';
import '../../categories/controllers/categories_controller.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/excel_service.dart';
// import '../../../core/services/day_services.dart';

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
    final catC = Get.put(CategoriesController());
    c.selectToday(); // تأكيد تحديد اليوم الحالي عند الفتح
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,

        /// زر الإضافة يظهر فقط عندما يكون اليوم الحالي محدد
        floatingActionButton: Obx(() {
          final today = DateTime.now();
          final isToday =
              c.selectedDate.value.year == today.year &&
              c.selectedDate.value.month == today.month &&
              c.selectedDate.value.day == today.day;

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
            // شريط الأيام الثلاثة فقط + أزرار التصدير
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Obx(() {
                final dates = c.availableDates;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // ✅ قائمة الأيام القابلة للاختيار
                      Row(
                        children:
                            dates.map((d) {
                              final isSelected = c.selectedDate.value == d;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    formatDate(d),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          isSelected
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  selected: isSelected,
                                  onSelected: (_) => c.selectedDate.value = d,
                                  selectedColor:
                                      theme.colorScheme.primaryContainer,
                                  backgroundColor: theme
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withAlpha((0.6 * 255).toInt()),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),

                      const SizedBox(width: 20),

                      // ✅ أزرار التصدير
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          IconButton(
                            tooltip: 'تصدير إكسل (اليوم)',
                            icon: const Icon(Icons.table_chart),
                            onPressed: () async {
                              try {
                                Get.snackbar(
                                  'تصدير',
                                  'جارٍ تحضير ملف الإكسل...',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                final menusForDate = c.filteredMenus;
                                if (menusForDate.isEmpty) {
                                  Get.snackbar(
                                    'تنبيه',
                                    'لا توجد قوائم لهذا اليوم',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                final ds = c.selectedDate.value;
                                final file =
                                    await ExcelExportServices.createDayStyleExcel(
                                      ds,
                                    );
                               
                                await PdfService.shareFile(
                                  file,
                                  subject:
                                      'تصدير إكسل - ${ds.year}/${ds.month}/${ds.day}',
                                  text:
                                      'ملف الإكسل لقوائم التاريخ ${ds.year}/${ds.month}/${ds.day}',
                                );
                                Get.snackbar(
                                  'تم',
                                  'تم إنشاء ومشاركة ملف الإكسل',
                                );
                              } catch (e) {
                                Get.snackbar('خطأ', 'حدث خطأ أثناء التصدير');
                              }
                            },
                          ),
                          IconButton(
                            tooltip: 'تصدير PDF (اليوم)',
                            icon: const Icon(Icons.picture_as_pdf),
                            onPressed: () async {
                              try {
                                Get.snackbar(
                                  'تصدير',
                                  'جارٍ إنشاء ملف PDF...',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                final menusForDate = c.filteredMenus;
                                if (menusForDate.isEmpty) {
                                  Get.snackbar(
                                    'تنبيه',
                                    'لا توجد قوائم لهذا اليوم',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  return;
                                }
                                final ds = c.selectedDate.value;
                                final file =
                                    await DayPdfExportServices.createDayHorizontalPdf(
                                      ds,
                                      fontAsset:
                                          'assets/fonts/NotoNaskhArabic-Regular.ttf',
                                      logoAsset: 'assets/images/logo.png',
                                    );
                                await PdfService.shareFile(
                                  file,
                                  subject: 'تقرير PDF لليوم',
                                  text:
                                      'ملف PDF لقوائم التاريخ ${ds.year}/${ds.month}/${ds.day}',
                                );
                                Get.snackbar('تم', 'تم إنشاء ومشاركة ملف PDF');
                              } catch (e) {
                                Get.snackbar(
                                  'خطأ',
                                  'حدث خطأ أثناء إنشاء ملف PDF',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 10),

            /// عرض القوائم اليومية
            Expanded(
              child: Obx(() {
                final menus = c.filteredMenus;
                if (menus.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'لا توجد قوائم لهذا اليوم',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: menus.length,
                  itemBuilder: (context, i) {
                    final m = menus[i];
                    final branchName =
                        c.branches.firstWhere((b) => b.id == m.branchId).name;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Material(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap:
                              () => Get.toNamed(
                                '/menus/items',
                                arguments: {'menuId': m.id},
                              ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 54,
                                      width: 54,
                                      decoration: BoxDecoration(
                                        color:
                                            theme.colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.menu_book_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            m.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            branchName,
                                            style: TextStyle(
                                              color: theme.colorScheme.outline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // أزرار التحكم (عرض/حذف)
                                    Column(
                                      children: [
                                        IconButton(
                                          tooltip: 'عرض العناصر',
                                          icon: Icon(
                                            Icons.list_alt,
                                            color: theme.colorScheme.primary,
                                          ),
                                          onPressed:
                                              () => Get.toNamed(
                                                '/menus/items',
                                                arguments: {'menuId': m.id},
                                              ),
                                        ),
                                        IconButton(
                                          tooltip: 'حذف',
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: theme.colorScheme.error,
                                          ),
                                          onPressed: () => c.deleteMenu(m.id),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'الإجمالي: ${c.menuTotals[m.id]?.toStringAsFixed(2) ?? '0.00'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'عدد الفئات: ${c.menuCategoryCounts[m.id] ?? 0}',
                                      style: TextStyle(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.table_chart),
                                        label: const Text('تصدير إكسل'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                        ),
                                        onPressed: () async {
                                          try {
                                            Get.snackbar(
                                              'تصدير',
                                              'جارٍ تحضير ملف الإكسل...',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );

                                            final file2 =
                                                await ExcelExportServices.createMenuStyleExcel(
                                                  m.id,
                                                );
                                            await PdfService.shareFile(
                                              file2,
                                              subject: 'تصدير إكسل للقائمة',
                                              text:
                                                  'ملف الإكسل للقائمة ${m.name}',
                                            );
                                            Get.snackbar(
                                              'تم',
                                              'تم إنشاء الملف ومشاركته',
                                            );
                                          } catch (e) {
                                            Get.snackbar(
                                              'خطأ',
                                              'حدث خطأ أثناء التصدير',
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.picture_as_pdf),
                                        label: const Text('تصدير PDF'),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          try {
                                            Get.snackbar(
                                              'تصدير',
                                              'جارٍ إنشاء ملف PDF...',
                                              snackPosition:
                                                  SnackPosition.BOTTOM,
                                            );
                                            final rows = await c
                                                .exportRowsForMenu(m.id);
                                            if (catC.categories.isEmpty) {
                                              await catC.load();
                                            }
                                            final arabicRows =
                                                rows.map((r) {
                                                  final catId =
                                                      r['categoryId'] ?? '';
                                                  dynamic found;
                                                  try {
                                                    found = catC.categories
                                                        .firstWhere(
                                                          (x) => x.id == catId,
                                                        );
                                                  } catch (_) {
                                                    found = null;
                                                  }
                                                  return {
                                                    'ملاحظة': r['notes'] ?? '',
                                                    'كمية': r['qty'] ?? 0,
                                                    'سعر الوحدة':
                                                        r['unit_price'] ??
                                                        r['unitPrice'] ??
                                                        0,
                                                    'الفئة':
                                                        found != null
                                                            ? (found.name ?? '')
                                                            : '',
                                                    'الإجمالي': r['total'] ?? 0,
                                                  };
                                                }).toList();

                                            final file =
                                                await PdfService.createPdfReportForMenu(
                                                  menuName: m.name,
                                                  rows: arabicRows,
                                                  logoAsset:
                                                      'assets/images/logo.png',
                                                  fontAsset:
                                                      'assets/fonts/NotoNaskhArabic-Regular.ttf',
                                                  totalKey: 'الإجمالي',
                                                );
                                            await PdfService.shareFile(
                                              file,
                                              subject: 'تقرير PDF للقائمة',
                                              text:
                                                  'تقرير PDF للقائمة ${m.name}',
                                            );
                                            Get.snackbar(
                                              'تم',
                                              'تم إنشاء ملف PDF ومشاركته',
                                            );
                                          } catch (e) {
                                            Get.snackbar(
                                              'خطأ',
                                              'حدث خطأ أثناء إنشاء PDF',
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
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

  /// نافذة إضافة قائمة جديدة
  void _showAddMenuDialog(BuildContext context, MenusController c) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    String? selectedBranchId;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 46,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'إضافة قائمة اليوم',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children:
                            c.branches.map((b) {
                              final isSelected = selectedBranchId == b.id;
                              return ChoiceChip(
                                label: Text(b.name),
                                selected: isSelected,
                                onSelected:
                                    (s) => setState(
                                      () => selectedBranchId = s ? b.id : null,
                                    ),
                                selectedColor:
                                    theme.colorScheme.primaryContainer,
                                backgroundColor: theme
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha((0.5 * 255).toInt()),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('حفظ'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final selected = c.selectedDate.value;
                          final today = DateTime(now.year, now.month, now.day);

                          if (selected.isBefore(today)) {
                            Get.snackbar(
                              'تنبيه',
                              'لا يمكن إضافة قائمة في تاريخ سابق',
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                            );
                            return;
                          }

                          if (selectedBranchId != null) {
                            c.addMenu(selectedBranchId!);
                            Navigator.pop(context);
                          } else {
                            Get.snackbar(
                              'تنبيه',
                              'اختر الفرع أولاً',
                              snackPosition: SnackPosition.BOTTOM,
                              margin: const EdgeInsets.all(16),
                            );
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
    );
  }
}
