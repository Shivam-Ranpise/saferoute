class NotificationPreferences {
  final String id;
  final String parentId;
  final bool pushEnabled;
  final bool whatsappEnabled;
  final bool smsEnabled;
  final DateTime updatedAt;

  const NotificationPreferences({
    required this.id,
    required this.parentId,
    this.pushEnabled = true,
    this.whatsappEnabled = true,
    this.smsEnabled = true,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      NotificationPreferences(
        id: json['id'] as String,
        parentId: json['parent_id'] as String,
        pushEnabled: json['push_enabled'] as bool? ?? true,
        whatsappEnabled: json['whatsapp_enabled'] as bool? ?? true,
        smsEnabled: json['sms_enabled'] as bool? ?? true,
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'parent_id': parentId,
        'push_enabled': pushEnabled,
        'whatsapp_enabled': whatsappEnabled,
        'sms_enabled': smsEnabled,
        'updated_at': updatedAt.toIso8601String(),
      };

  NotificationPreferences copyWith({
    String? id,
    String? parentId,
    bool? pushEnabled,
    bool? whatsappEnabled,
    bool? smsEnabled,
    DateTime? updatedAt,
  }) =>
      NotificationPreferences(
        id: id ?? this.id,
        parentId: parentId ?? this.parentId,
        pushEnabled: pushEnabled ?? this.pushEnabled,
        whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationPreferences &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
