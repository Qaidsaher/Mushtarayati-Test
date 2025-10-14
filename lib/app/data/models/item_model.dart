class ItemModel {
  final String id;
  final String? menuId;
  final String? categoryId;
  final double qty;
  final double unitPrice;
  final double total;
  final String? notes;
  final int? updatedAt;
  final int deleted;

  ItemModel({required this.id, this.menuId, this.categoryId, this.qty = 0, this.unitPrice = 0, this.total = 0, this.notes, this.updatedAt, this.deleted = 0});

  factory ItemModel.fromMap(Map<String, dynamic> map) => ItemModel(
        id: map['id'] ?? '',
        menuId: map['menu_id'],
        categoryId: map['category_id'],
        qty: (map['qty'] ?? 0).toDouble(),
        unitPrice: (map['unit_price'] ?? 0).toDouble(),
        total: (map['total'] ?? 0).toDouble(),
        notes: map['notes'],
        updatedAt: map['updated_at'],
        deleted: map['deleted'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'menu_id': menuId,
        'category_id': categoryId,
        'qty': qty,
        'unit_price': unitPrice,
        'total': total,
        'notes': notes,
        'updated_at': updatedAt,
        'deleted': deleted
      };
}
