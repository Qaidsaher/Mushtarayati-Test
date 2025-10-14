import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/menu_items_controller.dart';
import '../../../data/models/item_model.dart';
import '../../../data/models/category_model.dart';

class MenuItemsBulkPage extends StatefulWidget {
  const MenuItemsBulkPage({super.key});

  @override
  State<MenuItemsBulkPage> createState() => _MenuItemsBulkPageState();
}

class _MenuItemsBulkPageState extends State<MenuItemsBulkPage> {
  final Map<String, _CategoryData> _categoryItems = {};
  bool _isSaving = false;
  String? _expandedCategoryId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Initialize with all categories
    Future.microtask(() {
      final c = Get.find<MenuItemsController>();
      for (var cat in c.categories) {
        _categoryItems[cat.id] = _CategoryData(categoryId: cat.id);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (var data in _categoryItems.values) {
      data.dispose();
    }
    super.dispose();
  }

  int _validItemsCount() {
    return _categoryItems.values.where((data) => data.isValid).length;
  }

  double _totalAmount() {
    return _categoryItems.values.fold(0.0, (sum, data) => sum + data.total);
  }

  List<CategoryModel> _filteredCategories(List<CategoryModel> categories) {
    if (_searchQuery.isEmpty) return categories;
    return categories.where((cat) {
      return cat.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (cat.type ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MenuItemsController>();
    final categories = c.categories;
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'إضافة سريعة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.secondaryContainer,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_validItemsCount()} عنصر',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Summary header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withOpacity(0.3),
                    theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'أدخل الكمية والسعر لكل فئة',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_totalAmount().toStringAsFixed(2)} ر.س',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'ابحث عن فئة...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),

            // Category list
            Expanded(
              child: Builder(
                builder: (context) {
                  final filteredCats = _filteredCategories(categories);

                  if (filteredCats.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد نتائج',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'حاول البحث بكلمات أخرى',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filteredCats.length,
                    itemBuilder: (context, i) {
                      final cat = filteredCats[i];
                      final data = _categoryItems[cat.id];
                      if (data == null) return const SizedBox.shrink();

                      return _buildCategoryCard(context, cat, data, theme);
                    },
                  );
                },
              ),
            ),

            // Bottom action bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: FilledButton.icon(
                  onPressed:
                      _validItemsCount() > 0 && !_isSaving
                          ? () => _saveAll(c)
                          : null,
                  icon:
                      _isSaving
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving
                        ? 'جاري الحفظ...'
                        : 'حفظ (${_validItemsCount()} عنصر)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryModel cat,
    _CategoryData data,
    ThemeData theme,
  ) {
    final isExpanded = _expandedCategoryId == cat.id;
    final isValid = data.isValid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isValid
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : theme.colorScheme.outlineVariant,
          width: isValid ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _expandedCategoryId = isExpanded ? null : cat.id;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(cat).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _iconFor(cat),
                        color: _getCategoryColor(cat),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Category name and status
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isValid
                                ? '${data.total.toStringAsFixed(2)} ر.س'
                                : 'اضغط لإضافة',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  isValid
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                              fontWeight:
                                  isValid ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status indicator
                    if (isValid)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green[700],
                          size: 20,
                        ),
                      ),

                    // Expand icon
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // Expanded content
            if (isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                ),
                child: Column(
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: data.qtyController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'الكمية',
                              prefixIcon: const Icon(
                                Icons.shopping_cart_outlined,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: data.priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'السعر',
                              prefixIcon: const Icon(
                                Icons.payments_outlined,
                                size: 20,
                              ),
                              suffixText: 'ر.س',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isValid) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primaryContainer,
                              theme.colorScheme.secondaryContainer,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calculate_rounded,
                              color: theme.colorScheme.onPrimaryContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'الإجمالي:',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${data.total.toStringAsFixed(2)} ر.س',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(CategoryModel cat) {
    final name = cat.name.toLowerCase();
    final type = (cat.type ?? '').toLowerCase();

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
    return Colors.indigo;
  }

  Future<void> _saveAll(MenuItemsController c) async {
    setState(() => _isSaving = true);

    try {
      final items = <ItemModel>[];

      for (var entry in _categoryItems.entries) {
        final data = entry.value;
        if (!data.isValid) continue;

        items.add(
          ItemModel(
            id: '',
            menuId: c.menuId,
            categoryId: data.categoryId,
            qty: data.qty,
            unitPrice: data.price,
            total: data.total,
            notes: '',
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      if (items.isEmpty) {
        Get.snackbar(
          'تنبيه',
          'الرجاء إدخال بيانات صحيحة',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange[100],
        );
        setState(() => _isSaving = false);
        return;
      }

      await c.bulkAdd(items);

      Get.back();
      Get.snackbar(
        'تم بنجاح ✓',
        'تمت إضافة ${items.length} عنصر',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        icon: Icon(Icons.check_circle, color: Colors.green[700]),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء الحفظ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        icon: const Icon(Icons.error, color: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  IconData _iconFor(CategoryModel cat) {
    final name = cat.name.toLowerCase();
    final type = (cat.type ?? '').toLowerCase();

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
}

class _CategoryData {
  final String categoryId;
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  _CategoryData({required this.categoryId});

  double get qty => double.tryParse(qtyController.text) ?? 0;
  double get price => double.tryParse(priceController.text) ?? 0;
  double get total => qty * price;
  bool get isValid => qty > 0 && price > 0;

  void dispose() {
    qtyController.dispose();
    priceController.dispose();
  }
}
