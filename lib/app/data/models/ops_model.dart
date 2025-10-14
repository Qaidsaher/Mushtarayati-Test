class OpsModel {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String? payload;
  final int updatedAt;
  final int synced;

  OpsModel({required this.id, required this.entityType, required this.entityId, required this.action, this.payload, required this.updatedAt, this.synced = 0});

  factory OpsModel.fromMap(Map<String, dynamic> m) => OpsModel(
        id: m['id'] ?? '',
        entityType: m['entity_type'] ?? '',
        entityId: m['entity_id'] ?? '',
        action: m['action'] ?? '',
        payload: m['payload'],
        updatedAt: m['updated_at'] ?? 0,
        synced: m['synced'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'payload': payload,
        'updated_at': updatedAt,
        'synced': synced,
      };
}
