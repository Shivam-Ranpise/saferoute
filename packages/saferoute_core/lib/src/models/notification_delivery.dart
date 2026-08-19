import '../constants/enums.dart';

class NotificationDelivery {
  final String id;
  final String notificationEventId;
  final String organizationId;
  final String recipientProfileId;
  final String? childId;
  final DeliveryChannel channel;
  final ProviderType? provider;
  final String? providerMessageId;
  final DeliveryStatus status;
  final int attemptCount;
  final DateTime? lastAttemptAt;
  final DateTime? nextRetryAt;
  final String? errorCode;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationDelivery({
    required this.id,
    required this.notificationEventId,
    required this.organizationId,
    required this.recipientProfileId,
    this.childId,
    required this.channel,
    this.provider,
    this.providerMessageId,
    this.status = DeliveryStatus.pending,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.nextRetryAt,
    this.errorCode,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationDelivery.fromJson(Map<String, dynamic> json) =>
      NotificationDelivery(
        id: json['id'] as String,
        notificationEventId: json['notification_event_id'] as String,
        organizationId: json['organization_id'] as String,
        recipientProfileId: json['recipient_profile_id'] as String,
        childId: json['child_id'] as String?,
        channel: DeliveryChannel.fromString(json['channel'] as String),
        provider: json['provider'] != null
            ? ProviderType.fromString(json['provider'] as String)
            : null,
        providerMessageId: json['provider_message_id'] as String?,
        status: json['status'] != null
            ? DeliveryStatus.fromString(json['status'] as String)
            : DeliveryStatus.pending,
        attemptCount: json['attempt_count'] as int? ?? 0,
        lastAttemptAt: json['last_attempt_at'] != null
            ? DateTime.parse(json['last_attempt_at'] as String)
            : null,
        nextRetryAt: json['next_retry_at'] != null
            ? DateTime.parse(json['next_retry_at'] as String)
            : null,
        errorCode: json['error_code'] as String?,
        errorMessage: json['error_message'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'notification_event_id': notificationEventId,
        'organization_id': organizationId,
        'recipient_profile_id': recipientProfileId,
        'child_id': childId,
        'channel': channel.toDbValue(),
        'provider': provider?.toDbValue(),
        'provider_message_id': providerMessageId,
        'status': status.toDbValue(),
        'attempt_count': attemptCount,
        'last_attempt_at': lastAttemptAt?.toIso8601String(),
        'next_retry_at': nextRetryAt?.toIso8601String(),
        'error_code': errorCode,
        'error_message': errorMessage,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  NotificationDelivery copyWith({
    String? id,
    String? notificationEventId,
    String? organizationId,
    String? recipientProfileId,
    String? childId,
    DeliveryChannel? channel,
    ProviderType? provider,
    String? providerMessageId,
    DeliveryStatus? status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    DateTime? nextRetryAt,
    String? errorCode,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      NotificationDelivery(
        id: id ?? this.id,
        notificationEventId: notificationEventId ?? this.notificationEventId,
        organizationId: organizationId ?? this.organizationId,
        recipientProfileId: recipientProfileId ?? this.recipientProfileId,
        childId: childId ?? this.childId,
        channel: channel ?? this.channel,
        provider: provider ?? this.provider,
        providerMessageId: providerMessageId ?? this.providerMessageId,
        status: status ?? this.status,
        attemptCount: attemptCount ?? this.attemptCount,
        lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
        nextRetryAt: nextRetryAt ?? this.nextRetryAt,
        errorCode: errorCode ?? this.errorCode,
        errorMessage: errorMessage ?? this.errorMessage,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  DeliveryStatus get deliveryStatus => status;

  bool get isTerminal =>
      status == DeliveryStatus.sent ||
      status == DeliveryStatus.delivered ||
      status == DeliveryStatus.cancelled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationDelivery &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
