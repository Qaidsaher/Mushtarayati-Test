class MenuModel {
  final String id;
  final String name;
  final String? date;
  final String? userId;
  final String? branchId;
  final int? updatedAt;
  final int deleted;
  final double? stationeryExpenses;
  final double? transportationExpenses;

  MenuModel({
    required this.id,
    required this.name,
    this.date,
    this.userId,
    this.branchId,
    this.updatedAt,
    this.deleted = 0,
    this.stationeryExpenses,
    this.transportationExpenses,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map) => MenuModel(
    id: map['id'] ?? '',
    name: map['name'] ?? '',
    date: map['date'],
    userId: map['user_id'],
    branchId: map['branch_id'],
    updatedAt: map['updated_at'],
    deleted: map['deleted'] ?? 0,
    stationeryExpenses: _parseNullableDouble(
      map['stationery_expenses'] ?? map['stationeryExpenses'],
    ),
    transportationExpenses: _parseNullableDouble(
      map['transportation_expenses'] ?? map['transportationExpenses'],
    ),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'date': date,
    'user_id': userId,
    'branch_id': branchId,
    'updated_at': updatedAt,
    'deleted': deleted,
    'stationery_expenses': stationeryExpenses,
    'transportation_expenses': transportationExpenses,
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
