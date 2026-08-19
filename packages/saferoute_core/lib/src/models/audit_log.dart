import '../constants/enums.dart';

class AuditLog {
  final String id;
  final String organizationId;
  final String? actorProfileId;
  final AuditAction action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const AuditLog({
    required this.id,
    required this.organizationId,
    this.actorProfileId,
    required this.action,
    required this.entityType,
    this.entityId,
    this.metadata = const {},
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) => AuditLog(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        actorProfileId: json['actor_profile_id'] as String?,
        action: AuditAction.fromString(json['action'] as String),
        entityType: json['entity_type'] as String,
        entityId: json['entity_id'] as String?,
        metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'actor_profile_id': actorProfileId,
        'action': action.toDbValue(),
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
      };

  AuditLog copyWith({
    String? id,
    String? organizationId,
    String? actorProfileId,
    AuditAction? action,
    String? entityType,
    String? entityId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) =>
      AuditLog(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        actorProfileId: actorProfileId ?? this.actorProfileId,
        action: action ?? this.action,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        metadata: metadata ?? this.metadata,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLog &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
