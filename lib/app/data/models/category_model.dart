class CategoryModel {
  final String id;
  final String name;
  final String? type;
  final double lastPrice;
  final int? updatedAt;
  final int deleted;

  CategoryModel({
    required this.id,
    required this.name,
    this.type,
    this.lastPrice = 0,
    this.updatedAt,
    this.deleted = 0,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    type: map['type'],
    lastPrice: _parseNullableDouble(map['last_price'] ?? map['lastPrice']) ?? 0,
    updatedAt: map['updated_at'],
    deleted: map['deleted'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type,
    'last_price': lastPrice,
    'updated_at': updatedAt,
    'deleted': deleted,
  };
}

double? _parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String && value.trim().isNotEmpty) {
    return double.tryParse(value.trim());
  }
  return null;
}
