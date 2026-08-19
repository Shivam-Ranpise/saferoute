import '../constants/enums.dart';

/// Notification Channel Definition for Android / iOS
class NotificationChannelConfig {
  final String id;
  final String name;
  final String description;
  final bool playSound;
  final bool enableVibration;
  final bool isHighPriority;

  const NotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    this.playSound = true,
    this.enableVibration = true,
    this.isHighPriority = false,
  });

  static const emergencyChannel = NotificationChannelConfig(
    id: 'saferoute_emergency_alerts',
    name: 'SafeRoute Emergency Alerts',
    description: 'High-priority emergency notices and critical safety alerts',
    playSound: true,
    enableVibration: true,
    isHighPriority: true,
  );

  static const geofenceChannel = NotificationChannelConfig(
    id: 'saferoute_geofence_alerts',
    name: 'SafeRoute Proximity & Arrival',
    description: 'Notifications when the school bus is approaching or has arrived at the stop',
    playSound: true,
    enableVibration: true,
    isHighPriority: true,
  );

  static const routineChannel = NotificationChannelConfig(
    id: 'saferoute_general_updates',
    name: 'SafeRoute General Updates',
    description: 'Routine trip lifecycle, attendance and schedule updates',
    playSound: false,
    enableVibration: false,
    isHighPriority: false,
  );
}

/// Helper for notification payload formatting and channel resolution
class NotificationService {
  /// Resolves the appropriate channel config for an event type
  static NotificationChannelConfig getChannelForEvent(NotificationEventType type) {
    switch (type) {
      case NotificationEventType.emergency:
        return NotificationChannelConfig.emergencyChannel;
      case NotificationEventType.busNearby:
        return NotificationChannelConfig.geofenceChannel;
      default:
        return NotificationChannelConfig.routineChannel;
    }
  }

  /// Parses a deep-link target route from notification payload
  static String? getDeepLinkRoute(Map<String, dynamic> payload) {
    final eventType = payload['event_type'] as String?;
    final childId = payload['child_id'] as String?;

    if (eventType == 'BUS_NEARBY' || eventType == 'TRIP_STARTED' || eventType == 'TRIP_COMPLETED') {
      if (childId != null && childId.isNotEmpty) {
        return '/parent?childId=$childId';
      }
      return '/parent';
    }

    if (eventType == 'EMERGENCY') {
      return '/parent/notifications';
    }

    return '/parent/notifications';
  }
}
