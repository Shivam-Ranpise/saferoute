class Driver {
  final String id;
  final String profileId;
  final String organizationId;
  final String? licenseNumber;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Driver({
    required this.id,
    required this.profileId,
    required this.organizationId,
    this.licenseNumber,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) => Driver(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        organizationId: json['organization_id'] as String,
        licenseNumber: json['license_number'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'organization_id': organizationId,
        'license_number': licenseNumber,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Driver copyWith({
    String? id,
    String? profileId,
    String? organizationId,
    String? licenseNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Driver(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        organizationId: organizationId ?? this.organizationId,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Driver &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
