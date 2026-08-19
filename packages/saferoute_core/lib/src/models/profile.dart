import '../constants/enums.dart';

class Profile {
  final String id;
  final String name;
  final String? phone;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final String organizationId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.name,
    this.phone,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.organizationId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String,
        role: UserRole.fromString(json['role'] as String),
        avatarUrl: json['avatar_url'] as String?,
        organizationId: json['organization_id'] as String,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role.toDbValue(),
        'avatar_url': avatarUrl,
        'organization_id': organizationId,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Profile copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? organizationId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Profile(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        organizationId: organizationId ?? this.organizationId,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
