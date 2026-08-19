import 'package:flutter/foundation.dart';

/// SafeRoute application-level enumerations.
/// These mirror the database enums exactly.

enum UserRole {
  superAdmin,
  admin,
  driver,
  parent;

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'SUPER_ADMIN': return UserRole.superAdmin;
      case 'ADMIN': return UserRole.admin;
      case 'DRIVER': return UserRole.driver;
      case 'PARENT': return UserRole.parent;
      default: throw ArgumentError('Unknown role: $value');
    }
  }

  String toDbValue() {
    switch (this) {
      case UserRole.superAdmin: return 'SUPER_ADMIN';
      case UserRole.admin: return 'ADMIN';
      case UserRole.driver: return 'DRIVER';
      case UserRole.parent: return 'PARENT';
    }
  }

  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isAdmin => this == UserRole.admin || this == UserRole.superAdmin;
}

enum TripStatus {
  idle,
  starting,
  active,
  stale,
  completed,
  cancelled;

  static TripStatus fromString(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => TripStatus.idle,
    );
  }

  String toDbValue() => name.toUpperCase();

  bool get isOngoing => this == TripStatus.active || this == TripStatus.starting || this == TripStatus.stale;
}

enum ProximityState {
  outside,
  approaching,
  enteredRadius,
  notified,
  locked;

  static ProximityState fromString(String value) {
    switch (value.toUpperCase()) {
      case 'OUTSIDE': return ProximityState.outside;
      case 'APPROACHING': return ProximityState.approaching;
      case 'ENTERED_RADIUS': return ProximityState.enteredRadius;
      case 'NOTIFIED': return ProximityState.notified;
      case 'LOCKED': return ProximityState.locked;
      default: return ProximityState.outside;
    }
  }

  String toDbValue() {
    switch (this) {
      case ProximityState.outside: return 'OUTSIDE';
      case ProximityState.approaching: return 'APPROACHING';
      case ProximityState.enteredRadius: return 'ENTERED_RADIUS';
      case ProximityState.notified: return 'NOTIFIED';
      case ProximityState.locked: return 'LOCKED';
    }
  }

  /// True when this child has already been notified for this trip.
  bool get isNotificationSent => this == ProximityState.notified || this == ProximityState.locked;
}

enum DevicePlatform {
  android,
  ios,
  web;

  static DevicePlatform fromString(String value) {
    return DevicePlatform.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => DevicePlatform.android,
    );
  }

  String toDbValue() => name.toUpperCase();

  static DevicePlatform get current {
    if (kIsWeb) return DevicePlatform.web;
    // Platform check done in platform-specific code
    return DevicePlatform.android;
  }
}

enum NotificationEventType {
  busNearby,
  tripStarted,
  tripCompleted,
  busDelay,
  emergency,
  customAlert,
  systemAnnouncement;

  static NotificationEventType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'BUS_NEARBY': return NotificationEventType.busNearby;
      case 'TRIP_STARTED': return NotificationEventType.tripStarted;
      case 'TRIP_COMPLETED': return NotificationEventType.tripCompleted;
      case 'BUS_DELAY': return NotificationEventType.busDelay;
      case 'EMERGENCY': return NotificationEventType.emergency;
      case 'CUSTOM_ALERT': return NotificationEventType.customAlert;
      case 'SYSTEM_ANNOUNCEMENT': return NotificationEventType.systemAnnouncement;
      default: return NotificationEventType.customAlert;
    }
  }

  String toDbValue() {
    switch (this) {
      case NotificationEventType.busNearby: return 'BUS_NEARBY';
      case NotificationEventType.tripStarted: return 'TRIP_STARTED';
      case NotificationEventType.tripCompleted: return 'TRIP_COMPLETED';
      case NotificationEventType.busDelay: return 'BUS_DELAY';
      case NotificationEventType.emergency: return 'EMERGENCY';
      case NotificationEventType.customAlert: return 'CUSTOM_ALERT';
      case NotificationEventType.systemAnnouncement: return 'SYSTEM_ANNOUNCEMENT';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationEventType.busNearby: return 'Bus Nearby';
      case NotificationEventType.tripStarted: return 'Trip Started';
      case NotificationEventType.tripCompleted: return 'Trip Completed';
      case NotificationEventType.busDelay: return 'Bus Delay';
      case NotificationEventType.emergency: return 'Emergency Alert';
      case NotificationEventType.customAlert: return 'Custom Alert';
      case NotificationEventType.systemAnnouncement: return 'System Announcement';
    }
  }
}

enum NotificationStatus {
  created,
  queued,
  processing,
  completed,
  partialFailure,
  failed,
  cancelled;

  static NotificationStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CREATED': return NotificationStatus.created;
      case 'QUEUED': return NotificationStatus.queued;
      case 'PROCESSING': return NotificationStatus.processing;
      case 'COMPLETED': return NotificationStatus.completed;
      case 'PARTIAL_FAILURE': return NotificationStatus.partialFailure;
      case 'FAILED': return NotificationStatus.failed;
      case 'CANCELLED': return NotificationStatus.cancelled;
      default: return NotificationStatus.created;
    }
  }

  String toDbValue() {
    switch (this) {
      case NotificationStatus.created: return 'CREATED';
      case NotificationStatus.queued: return 'QUEUED';
      case NotificationStatus.processing: return 'PROCESSING';
      case NotificationStatus.completed: return 'COMPLETED';
      case NotificationStatus.partialFailure: return 'PARTIAL_FAILURE';
      case NotificationStatus.failed: return 'FAILED';
      case NotificationStatus.cancelled: return 'CANCELLED';
    }
  }
}

enum DeliveryStatus {
  pending,
  processing,
  sent,
  delivered,
  read,
  failed,
  cancelled;

  static DeliveryStatus fromString(String value) {
    switch (value.toUpperCase()) {
      case 'PENDING': return DeliveryStatus.pending;
      case 'PROCESSING': return DeliveryStatus.processing;
      case 'SENT': return DeliveryStatus.sent;
      case 'DELIVERED': return DeliveryStatus.delivered;
      case 'READ': return DeliveryStatus.read;
      case 'FAILED': return DeliveryStatus.failed;
      case 'CANCELLED': return DeliveryStatus.cancelled;
      default: return DeliveryStatus.pending;
    }
  }

  String toDbValue() => name.toUpperCase();
}

enum DeliveryChannel {
  push,
  whatsapp,
  sms;

  static DeliveryChannel fromString(String value) {
    return DeliveryChannel.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => DeliveryChannel.push,
    );
  }

  String toDbValue() => name.toUpperCase();

  String get displayName {
    switch (this) {
      case DeliveryChannel.push: return 'App (Push)';
      case DeliveryChannel.whatsapp: return 'WhatsApp';
      case DeliveryChannel.sms: return 'SMS';
    }
  }
}

enum NotificationPriority {
  normal,
  high,
  emergency;

  static NotificationPriority fromString(String value) {
    return NotificationPriority.values.firstWhere(
      (e) => e.name.toUpperCase() == value.toUpperCase(),
      orElse: () => NotificationPriority.normal,
    );
  }

  String toDbValue() => name.toUpperCase();
}

enum ProviderType {
  fcm,
  fast2sms,
  maytapi;

  static ProviderType fromString(String value) {
    switch (value.toUpperCase()) {
      case 'FCM': return ProviderType.fcm;
      case 'FAST2SMS': return ProviderType.fast2sms;
      case 'MAYTAPI': return ProviderType.maytapi;
      default: return ProviderType.fcm;
    }
  }

  String toDbValue() {
    switch (this) {
      case ProviderType.fcm: return 'FCM';
      case ProviderType.fast2sms: return 'FAST2SMS';
      case ProviderType.maytapi: return 'MAYTAPI';
    }
  }

  String get displayName {
    switch (this) {
      case ProviderType.fcm: return 'Firebase Cloud Messaging';
      case ProviderType.fast2sms: return 'Fast2SMS';
      case ProviderType.maytapi: return 'Maytapi (WhatsApp)';
    }
  }
}

enum AuditAction {
  create,
  update,
  delete,
  login,
  logout,
  assign,
  unassign,
  sendAlert,
  changePolicy,
  changeProviderConfig,
  emergencyAlert,
  changePermission;

  static AuditAction fromString(String value) {
    switch (value.toUpperCase()) {
      case 'CREATE': return AuditAction.create;
      case 'UPDATE': return AuditAction.update;
      case 'DELETE': return AuditAction.delete;
      case 'LOGIN': return AuditAction.login;
      case 'LOGOUT': return AuditAction.logout;
      case 'ASSIGN': return AuditAction.assign;
      case 'UNASSIGN': return AuditAction.unassign;
      case 'SEND_ALERT': return AuditAction.sendAlert;
      case 'CHANGE_POLICY': return AuditAction.changePolicy;
      case 'CHANGE_PROVIDER_CONFIG': return AuditAction.changeProviderConfig;
      case 'EMERGENCY_ALERT': return AuditAction.emergencyAlert;
      case 'CHANGE_PERMISSION': return AuditAction.changePermission;
      default: return AuditAction.update;
    }
  }

  String toDbValue() {
    switch (this) {
      case AuditAction.create: return 'CREATE';
      case AuditAction.update: return 'UPDATE';
      case AuditAction.delete: return 'DELETE';
      case AuditAction.login: return 'LOGIN';
      case AuditAction.logout: return 'LOGOUT';
      case AuditAction.assign: return 'ASSIGN';
      case AuditAction.unassign: return 'UNASSIGN';
      case AuditAction.sendAlert: return 'SEND_ALERT';
      case AuditAction.changePolicy: return 'CHANGE_POLICY';
      case AuditAction.changeProviderConfig: return 'CHANGE_PROVIDER_CONFIG';
      case AuditAction.emergencyAlert: return 'EMERGENCY_ALERT';
      case AuditAction.changePermission: return 'CHANGE_PERMISSION';
    }
  }
}

/// Alert types available to drivers when sending custom alerts
enum DriverAlertType {
  busProblem,
  accidentEmergency,
  childIssue,
  delay,
  medicalEmergency,
  other;

  String get displayName {
    switch (this) {
      case DriverAlertType.busProblem: return 'Bus Problem';
      case DriverAlertType.accidentEmergency: return 'Accident / Emergency';
      case DriverAlertType.childIssue: return 'Child Issue';
      case DriverAlertType.delay: return 'Delay';
      case DriverAlertType.medicalEmergency: return 'Medical / Other Emergency';
      case DriverAlertType.other: return 'Other';
    }
  }

  NotificationEventType get eventType {
    switch (this) {
      case DriverAlertType.accidentEmergency:
      case DriverAlertType.medicalEmergency:
        return NotificationEventType.emergency;
      case DriverAlertType.delay:
        return NotificationEventType.busDelay;
      default:
        return NotificationEventType.customAlert;
    }
  }

  NotificationPriority get defaultPriority {
    switch (this) {
      case DriverAlertType.accidentEmergency:
      case DriverAlertType.medicalEmergency:
        return NotificationPriority.emergency;
      default:
        return NotificationPriority.normal;
    }
  }
}
