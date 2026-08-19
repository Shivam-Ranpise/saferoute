import '../constants/enums.dart';

class NotificationTemplate {
  final String id;
  final String organizationId;
  final NotificationEventType eventType;
  final DeliveryChannel channel;
  final String? title;
  final String messageTemplate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationTemplate({
    required this.id,
    required this.organizationId,
    required this.eventType,
    required this.channel,
    this.title,
    required this.messageTemplate,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) =>
      NotificationTemplate(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        eventType:
            NotificationEventType.fromString(json['event_type'] as String),
        channel: DeliveryChannel.fromString(json['channel'] as String),
        title: json['title'] as String?,
        messageTemplate: json['message_template'] as String,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'event_type': eventType.toDbValue(),
        'channel': channel.toDbValue(),
        'title': title,
        'message_template': messageTemplate,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  NotificationTemplate copyWith({
    String? id,
    String? organizationId,
    NotificationEventType? eventType,
    DeliveryChannel? channel,
    String? title,
    String? messageTemplate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      NotificationTemplate(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        eventType: eventType ?? this.eventType,
        channel: channel ?? this.channel,
        title: title ?? this.title,
        messageTemplate: messageTemplate ?? this.messageTemplate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  String render(Map<String, String> vars) {
    var result = messageTemplate;
    vars.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
