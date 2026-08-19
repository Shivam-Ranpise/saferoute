import '../constants/enums.dart';

class NotificationEvent {
  final String id;
  final String organizationId;
  final String? tripId;
  final String? senderProfileId;
  final String? childId;
  final NotificationEventType eventType;
  final NotificationPriority priority;
  final String title;
  final String message;
  final NotificationStatus status;
  final Map<String, dynamic>? payload;
  final DateTime? scheduledAt;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationEvent({
    required this.id,
    required this.organizationId,
    this.tripId,
    this.senderProfileId,
    this.childId,
    required this.eventType,
    this.priority = NotificationPriority.normal,
    this.title = '',
    this.message = '',
    this.status = NotificationStatus.created,
    this.payload,
    this.scheduledAt,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationEvent.fromJson(Map<String, dynamic> json) =>
      NotificationEvent(
        id: json['id'] as String,
        organizationId: json['organization_id'] as String,
        tripId: json['trip_id'] as String?,
        senderProfileId: json['sender_profile_id'] as String?,
        childId: json['child_id'] as String?,
        eventType:
            NotificationEventType.fromString(json['event_type'] as String),
        priority: json['priority'] != null
            ? NotificationPriority.fromString(json['priority'] as String)
            : NotificationPriority.normal,
        title: (json['title'] as String?) ?? '',
        message: (json['message'] as String?) ?? '',
        status: json['status'] != null
            ? NotificationStatus.fromString(json['status'] as String)
            : NotificationStatus.created,
        payload: json['payload'] as Map<String, dynamic>?,
        scheduledAt: json['scheduled_at'] != null
            ? DateTime.parse(json['scheduled_at'] as String)
            : null,
        processedAt: json['processed_at'] != null
            ? DateTime.parse(json['processed_at'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organization_id': organizationId,
        'trip_id': tripId,
        'sender_profile_id': senderProfileId,
        'child_id': childId,
        'event_type': eventType.toDbValue(),
        'priority': priority.toDbValue(),
        'title': title,
        'message': message,
        'status': status.toDbValue(),
        'payload': payload,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'processed_at': processedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  NotificationEvent copyWith({
    String? id,
    String? organizationId,
    String? tripId,
    String? senderProfileId,
    String? childId,
    NotificationEventType? eventType,
    NotificationPriority? priority,
    String? title,
    String? message,
    NotificationStatus? status,
    Map<String, dynamic>? payload,
    DateTime? scheduledAt,
    DateTime? processedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      NotificationEvent(
        id: id ?? this.id,
        organizationId: organizationId ?? this.organizationId,
        tripId: tripId ?? this.tripId,
        senderProfileId: senderProfileId ?? this.senderProfileId,
        childId: childId ?? this.childId,
        eventType: eventType ?? this.eventType,
        priority: priority ?? this.priority,
        title: title ?? this.title,
        message: message ?? this.message,
        status: status ?? this.status,
        payload: payload ?? this.payload,
        scheduledAt: scheduledAt ?? this.scheduledAt,
        processedAt: processedAt ?? this.processedAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
