class MenuModel {
  final String id;
  final String name;
  final String? date;
  final String? userId;
  final String? branchId;
  final int? updatedAt;
  final int deleted;

  MenuModel({required this.id, required this.name, this.date, this.userId, this.branchId, this.updatedAt, this.deleted = 0});

  factory MenuModel.fromMap(Map<String, dynamic> map) => MenuModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        date: map['date'],
        userId: map['user_id'],
        branchId: map['branch_id'],
        updatedAt: map['updated_at'],
        deleted: map['deleted'] ?? 0,
      );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'date': date, 'user_id': userId, 'branch_id': branchId, 'updated_at': updatedAt, 'deleted': deleted};
}
