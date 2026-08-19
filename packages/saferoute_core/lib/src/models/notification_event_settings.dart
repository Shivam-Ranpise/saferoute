import '../constants/enums.dart';

class NotificationEventSettings {
  final String id;
  final String organizationId;
  final NotificationEventType eventType;
  final bool pushEnabled;
  final bool whatsappEnabled;
  final bool smsEnabled;
  final bool emergencyOverride;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationEventSettings({
    required this.id,
    required this.organizationId,
    required this.eventType,
    this.pushEnabled = true,
    this.whatsappEnabled = false,
    this.smsEnabled = false,
    this.emergencyOverride = false,
    this.enabled = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationEventSettings.fromJson(Map<String, dynamic> json) =>
      NotificationEventSettings(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        eventType:
            NotificationEventType.fromString(json['event_type'] as String),
        pushEnabled: json['push_enabled'] as bool? ?? true,
        whatsappEnabled: json['whatsapp_enabled'] as bool? ?? false,
        smsEnabled: json['sms_enabled'] as bool? ?? false,
        emergencyOverride: json['emergency_override'] as bool? ?? false,
        enabled: json['enabled'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'event_type': eventType.toDbValue(),
        'push_enabled': pushEnabled,
        'whatsapp_enabled': whatsappEnabled,
        'sms_enabled': smsEnabled,
        'emergency_override': emergencyOverride,
        'enabled': enabled,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  NotificationEventSettings copyWith({
    String? id,
    String? organizationId,
    NotificationEventType? eventType,
    bool? pushEnabled,
    bool? whatsappEnabled,
    bool? smsEnabled,
    bool? emergencyOverride,
    bool? enabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      NotificationEventSettings(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        eventType: eventType ?? this.eventType,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        emergencyOverride: emergencyOverride ?? this.emergencyOverride,
        enabled: enabled ?? this.enabled,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEventSettings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
