import '../constants/enums.dart';

class DeviceToken {
  final String id;
  final String profileId;
  final String fcmToken;
  final DevicePlatform platform;
  final bool isActive;
  final DateTime lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeviceToken({
    required this.id,
    required this.profileId,
    required this.fcmToken,
    required this.platform,
    this.isActive = true,
    required this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) => DeviceToken(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        fcmToken: json['fcm_token'] as String,
        platform: DevicePlatform.fromString(json['platform'] as String),
        isActive: json['is_active'] as bool? ?? true,
        lastSeenAt: DateTime.parse(json['last_seen_at'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profile_id': profileId,
        'fcm_token': fcmToken,
        'platform': platform.toDbValue(),
        'is_active': isActive,
        'last_seen_at': lastSeenAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  DeviceToken copyWith({
    String? id,
    String? profileId,
    String? fcmToken,
    DevicePlatform? platform,
    bool? isActive,
    DateTime? lastSeenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DeviceToken(
        id: id ?? this.id,
        profileId: profileId ?? this.profileId,
        fcmToken: fcmToken ?? this.fcmToken,
        platform: platform ?? this.platform,
        isActive: isActive ?? this.isActive,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceToken &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
