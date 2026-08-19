class Parent {
  final String id;
  final String profileId;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parent({
    required this.id,
    required this.profileId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Parent.fromJson(Map<String, dynamic> json) => Parent(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        organizationId: json['organization_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'organization_id': organizationId,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Parent copyWith({
    String? id,
    String? profileId,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Parent(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        organizationId: organizationId ?? this.organizationId,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Parent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
