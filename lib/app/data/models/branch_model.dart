class BranchModel {
  final String id;
  final String name;
  final String? location;
  final String? phoneNumber;
  final int? updatedAt;
  final int deleted;

  BranchModel({required this.id, required this.name, this.location, this.phoneNumber, this.updatedAt, this.deleted = 0});

  factory BranchModel.fromMap(Map<String, dynamic> map) => BranchModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        location: map['location'],
        phoneNumber: map['phone_number'],
        updatedAt: map['updated_at'],
        deleted: map['deleted'] ?? 0,
      );

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'location': location, 'phone_number': phoneNumber, 'updated_at': updatedAt, 'deleted': deleted};
}
