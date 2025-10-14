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
  final _rows = <_BulkRow>[];
  final _scroll = ScrollController();
  final Set<String> _selectedCats = {};

  @override
  void initState() {
    super.initState();
    _addRow();
  }

  void _addRowsForCategories(List<CategoryModel> cats) {
    setState(() {
      for (var cat in cats) {
        final r = _BulkRow();
        r.catId = cat.id;
        r.name.text = cat.name;
        r.price.text = '0';
        _rows.add(r);
      }
    });
    // scroll to bottom after a short delay
    Future.delayed(const Duration(milliseconds: 200), () => _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
  }

  void _addRow() => setState(() => _rows.add(_BulkRow()));

  void _removeRow(int i) => setState(() {
        _rows.removeAt(i);
      });

  @override
  Widget build(BuildContext context) {
    final c = Get.find<MenuItemsController>();
    final menuId = c.menuId;
  final categories = c.categories;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إدخال جماعي للعناصر')),
        body: Column(
          children: [
            // category quick-select chips
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 8,
                        children: categories.map((cat) {
                          final sel = _selectedCats.contains(cat.id);
                          return FilterChip(
                            selected: sel,
                            avatar: Icon(_iconFor(cat), size: 18, color: sel ? Colors.white : null),
                            label: Text(cat.name),
                            onSelected: (v) => setState(() {
                              if (v) {
                                // when selected, add a row for this category if not already present
                                _selectedCats.add(cat.id);
                                final exists = _rows.any((r) => r.catId == cat.id);
                                if (!exists) {
                                  final r = _BulkRow();
                                  r.catId = cat.id;
                                  r.name.text = cat.name;
                                  _rows.add(r);
                                  // scroll to bottom to show the created row
                                  Future.delayed(const Duration(milliseconds: 120), () => _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut));
                                }
                              } else {
                                // deselected: remove rows with this category
                                _selectedCats.remove(cat.id);
                                _rows.removeWhere((r) => r.catId == cat.id);
                              }
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
            ElevatedButton.icon(
              onPressed: _selectedCats.isNotEmpty
                ? () {
                  final chosen = categories.where((x) => _selectedCats.contains(x.id)).toList();
                  _addRowsForCategories(chosen);
                }
                : null,
              icon: const Icon(Icons.add_task),
              label: const Text('إضافة المحدد')),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                          onPressed: () => _addRowsForCategories(categories), icon: const Icon(Icons.playlist_add), label: const Text('إضافة الكل')),
                    ])
                  ],
                ),
              ),
            const Divider(height: 1),

            const SizedBox(height: 8),
            
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _rows.length,
                itemBuilder: (context, i) {
                  final r = _rows[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(child: TextField(controller: r.name, decoration: const InputDecoration(labelText: 'الاسم (اختياري)'))),
                            IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _removeRow(i)),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: r.catId,
                                  items: categories
                                      .map((cat) => DropdownMenuItem(
                                            value: cat.id,
                                            child: Row(children: [Icon(_iconFor(cat)), const SizedBox(width: 8), Text(cat.name)]),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(() => r.catId = v),
                                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), labelText: 'الفئة'),
                                ),
                              ),
                            const SizedBox(width: 8),
                            SizedBox(width: 90, child: TextField(controller: r.qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'كم'))),
                            const SizedBox(width: 8),
                            SizedBox(width: 120, child: TextField(controller: r.price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'سعر'))),
                          ]),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ElevatedButton.icon(onPressed: _addRow, icon: const Icon(Icons.add), label: const Text('إضافة سطر')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                      onPressed: () async {
                        // create items from rows
                        final items = <ItemModel>[];
                        for (final r in _rows) {
                          final q = double.tryParse(r.qty.text) ?? 0;
                          final p = double.tryParse(r.price.text) ?? 0;
                          if (q <= 0 || p <= 0) continue;
                          items.add(ItemModel(
                              id: '', menuId: menuId, categoryId: r.catId, qty: q, unitPrice: p, total: q * p, notes: r.name.text, updatedAt: DateTime.now().millisecondsSinceEpoch));
                        }
                        if (items.isEmpty) return;
                        // batch create in one transaction
                        await c.bulkAdd(items);
                        Get.back();
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ الكل'))
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  IconData _iconFor(CategoryModel cat) {
    final name = cat.name.toLowerCase();
    final type = (cat.type ?? '').toLowerCase();
    if (type.contains('fruit') || name.contains('فاكه') || name.contains('fruit')) return Icons.eco;
    if (type.contains('vegetable') || name.contains('خض') || name.contains('vegetable')) return Icons.grass;
    if (type.contains('dairy') || name.contains('لبن') || name.contains('dairy')) return Icons.egg;
    if (type.contains('meat') || name.contains('لحم') || name.contains('meat')) return Icons.set_meal;
    if (type.contains('bakery') || name.contains('مخبز') || name.contains('bakery')) return Icons.bakery_dining;
    return Icons.local_grocery_store;
  }

  // _pickCategoryForRow removed; inline dropdown is used instead
}

class _BulkRow {
  final TextEditingController name = TextEditingController();
  final TextEditingController qty = TextEditingController(text: '1');
  final TextEditingController price = TextEditingController(text: '0');
  String? catId;
}
