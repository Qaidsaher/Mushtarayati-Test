class ItemModel {
  final String id;
  final String? menuId;
  final String? categoryId;
  final int qty;
  final double unitPrice;
  final double total;
  final String? notes;
  final int? updatedAt;
  final int deleted;

  ItemModel({
    required this.id,
    this.menuId,
    this.categoryId,
    this.qty = 0,
    this.unitPrice = 0,
    this.total = 0,
    this.notes,
    this.updatedAt,
    this.deleted = 0,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) => ItemModel(
    id: map['id'] ?? '',
    menuId: map['menu_id'],
    categoryId: map['category_id'],
    qty: _parseQty(map['qty']),
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
    'deleted': deleted,
  };
}

int _parseQty(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is num) return value.toInt();
  if (value is String && value.trim().isNotEmpty) {
    return int.tryParse(value.trim()) ?? 0;
  }
  return 0;
}
