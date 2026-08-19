import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 4 — Multi-Channel Notification Engine Tests', () {
    test('NotificationEvent model serialization and copyWith', () {
      final event = NotificationEvent(
        id: 'evt-101',
        organizationId: 'org-1',
        tripId: 'trip-1',
        childId: 'child-1',
        eventType: NotificationEventType.busNearby,
        priority: NotificationPriority.high,
        title: 'Bus Approaching Stop',
        message: 'Bus 12-A is 500m away from Oak Street stop.',
        status: NotificationStatus.created,
        createdAt: DateTime.parse('2026-08-16T10:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T10:00:00Z'),
      );

      final json = event.toJson();
      final roundtrip = NotificationEvent.fromJson(json);

      expect(roundtrip.id, equals('evt-101'));
      expect(roundtrip.eventType, equals(NotificationEventType.busNearby));
      expect(roundtrip.priority, equals(NotificationPriority.high));
      expect(roundtrip.title, equals('Bus Approaching Stop'));
      expect(roundtrip.message, contains('500m away'));

      final processed = event.copyWith(
        status: NotificationStatus.completed,
        processedAt: DateTime.parse('2026-08-16T10:00:05Z'),
      );
      expect(processed.status, equals(NotificationStatus.completed));
      expect(processed.processedAt, isNotNull);
    });

    test('NotificationDelivery status evaluation and isUnread getter in NotificationItem', () {
      final delivery = NotificationDelivery(
        id: 'del-1',
        notificationEventId: 'evt-101',
        organizationId: 'org-1',
        recipientProfileId: 'prof-p1',
        childId: 'child-1',
        channel: DeliveryChannel.push,
        provider: ProviderType.fcm,
        status: DeliveryStatus.sent,
        attemptCount: 1,
        createdAt: DateTime.parse('2026-08-16T10:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T10:00:00Z'),
      );

      final event = NotificationEvent(
        id: 'evt-101',
        organizationId: 'org-1',
        eventType: NotificationEventType.busNearby,
        title: 'Bus Nearby',
        message: 'Bus is near.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final itemSent = NotificationItem(delivery: delivery, event: event);
      expect(itemSent.isUnread, isTrue);

      final delivered = delivery.copyWith(status: DeliveryStatus.delivered);
      final itemDelivered = NotificationItem(delivery: delivered, event: event);
      expect(itemDelivered.isUnread, isFalse);
    });

    test('NotificationService channel resolution by event type', () {
      final emergencyChannel =
          NotificationService.getChannelForEvent(NotificationEventType.emergency);
      expect(emergencyChannel.id, equals('saferoute_emergency_alerts'));
      expect(emergencyChannel.isHighPriority, isTrue);
      expect(emergencyChannel.playSound, isTrue);

      final geofenceChannel =
          NotificationService.getChannelForEvent(NotificationEventType.busNearby);
      expect(geofenceChannel.id, equals('saferoute_geofence_alerts'));
      expect(geofenceChannel.isHighPriority, isTrue);

      final routineChannel =
          NotificationService.getChannelForEvent(NotificationEventType.tripStarted);
      expect(routineChannel.id, equals('saferoute_general_updates'));
      expect(routineChannel.isHighPriority, isFalse);
    });

    test('NotificationService deep link resolution', () {
      final proximityRoute = NotificationService.getDeepLinkRoute({
        'event_type': 'BUS_NEARBY',
        'child_id': 'child-42',
      });
      expect(proximityRoute, equals('/parent?childId=child-42'));

      final emergencyRoute = NotificationService.getDeepLinkRoute({
        'event_type': 'EMERGENCY',
      });
      expect(emergencyRoute, equals('/parent/notifications'));
    });

    test('DeviceToken model serialization and platform mapping', () {
      final token = DeviceToken(
        id: 'tok-1',
        profileId: 'prof-p1',
        fcmToken: 'fcm_token_xyz_1234567890',
        platform: DevicePlatform.android,
        isActive: true,
        lastSeenAt: DateTime.parse('2026-08-16T12:00:00Z'),
        createdAt: DateTime.parse('2026-08-16T12:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T12:00:00Z'),
      );

      final json = token.toJson();
      final roundtrip = DeviceToken.fromJson(json);

      expect(roundtrip.fcmToken, equals('fcm_token_xyz_1234567890'));
      expect(roundtrip.platform, equals(DevicePlatform.android));
      expect(roundtrip.isActive, isTrue);
    });
  });
}
