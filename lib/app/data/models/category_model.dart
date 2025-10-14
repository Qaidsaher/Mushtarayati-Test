class CategoryModel {
  final String id;
  final String name;
  final String? type;
  final int? updatedAt;
  final int deleted;

  CategoryModel({required this.id, required this.name, this.type, this.updatedAt, this.deleted = 0});

  factory CategoryModel.fromMap(Map<String, dynamic> map) => CategoryModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        type: map['type'],
        updatedAt: map['updated_at'],
        deleted: map['deleted'] ?? 0,
      );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'type': type, 'updated_at': updatedAt, 'deleted': deleted};
}
