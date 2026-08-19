import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Haversine Distance Calculator', () {
    test('distance between same point is 0', () {
      final dist = Haversine.distanceMeters(
        lat1: 12.9716, lon1: 77.5946,
        lat2: 12.9716, lon2: 77.5946,
      );
      expect(dist, closeTo(0, 0.001));
    });

    test('calculates known distance between two Bangalore points', () {
      // MG Road to Koramangala — approximately 4.5 km
      final dist = Haversine.distanceMeters(
        lat1: 12.9753, lon1: 77.6094,
        lat2: 12.9347, lon2: 77.6101,
      );
      // Allow 10% tolerance for test
      expect(dist, greaterThan(4000));
      expect(dist, lessThan(5200));
    });

    test('distance is symmetric (A to B == B to A)', () {
      final d1 = Haversine.distanceMeters(
        lat1: 12.9716, lon1: 77.5946,
        lat2: 13.0000, lon2: 77.6000,
      );
      final d2 = Haversine.distanceMeters(
        lat1: 13.0000, lon1: 77.6000,
        lat2: 12.9716, lon2: 77.5946,
      );
      expect(d1, closeTo(d2, 0.001));
    });

    test('500m notification distance correctly evaluated', () {
      // A child at 12.9716, 77.5946
      // Bus at a point ~400m away
      const childLat = 12.9716;
      const childLon = 77.5946;
      // Moving ~400m north
      const busLat = 12.9752; // ~400m north
      const busLon = 77.5946;

      final dist = Haversine.distanceMeters(
        lat1: busLat, lon1: busLon,
        lat2: childLat, lon2: childLon,
      );

      // Bus is within 500m threshold
      expect(dist, lessThan(500));
      expect(Haversine.hasEnteredRadius(
        distanceMeters: dist,
        thresholdMeters: 500,
      ), isTrue);
    });

    test('bus outside threshold is correctly identified', () {
      const childLat = 12.9716;
      const childLon = 77.5946;
      const busLat = 12.9850; // ~1.5km away
      const busLon = 77.5946;

      final dist = Haversine.distanceMeters(
        lat1: busLat, lon1: busLon,
        lat2: childLat, lon2: childLon,
      );

      expect(Haversine.hasEnteredRadius(
        distanceMeters: dist,
        thresholdMeters: 500,
      ), isFalse);
    });

    test('approaching zone detected correctly', () {
      const childLat = 12.9716;
      const childLon = 77.5946;
      // Bus is 650m away — within 500+200=700m approaching zone
      const busLat = 12.9775;
      const busLon = 77.5946;

      final dist = Haversine.distanceMeters(
        lat1: busLat, lon1: busLon,
        lat2: childLat, lon2: childLon,
      );

      expect(Haversine.isApproaching(
        distanceMeters: dist,
        thresholdMeters: 500,
        approachingBufferMeters: 200,
      ), isTrue);
    });
  });

  group('GPS Validity Check', () {
    test('valid movement at realistic bus speed', () {
      // Bus moving at ~40 km/h = 11.1 m/s. In 10 seconds = ~111m
      expect(Haversine.isValidMovement(
        prevLat: 12.9716, prevLon: 77.5946,
        currLat: 12.9725, currLon: 77.5946, // ~100m north
        elapsedSeconds: 10,
        maxSpeedKmh: 150,
      ), isTrue);
    });

    test('impossible jump rejected (GPS glitch)', () {
      // Teleporting 10km in 1 second — impossible
      expect(Haversine.isValidMovement(
        prevLat: 12.9716, prevLon: 77.5946,
        currLat: 13.0700, currLon: 77.5946, // ~11km jump
        elapsedSeconds: 1,
        maxSpeedKmh: 150,
      ), isFalse);
    });

    test('zero elapsed time is invalid', () {
      expect(Haversine.isValidMovement(
        prevLat: 12.9716, prevLon: 77.5946,
        currLat: 12.9716, currLon: 77.5946,
        elapsedSeconds: 0,
      ), isFalse);
    });
  });

  group('ProximityState Machine', () {
    test('OUTSIDE state isNotificationSent is false', () {
      expect(ProximityState.outside.isNotificationSent, isFalse);
    });

    test('NOTIFIED state isNotificationSent is true', () {
      expect(ProximityState.notified.isNotificationSent, isTrue);
    });

    test('LOCKED state isNotificationSent is true', () {
      expect(ProximityState.locked.isNotificationSent, isTrue);
    });

    test('APPROACHING state isNotificationSent is false', () {
      expect(ProximityState.approaching.isNotificationSent, isFalse);
    });

    test('fromString correctly maps DB values', () {
      expect(ProximityState.fromString('OUTSIDE'), equals(ProximityState.outside));
      expect(ProximityState.fromString('APPROACHING'), equals(ProximityState.approaching));
      expect(ProximityState.fromString('ENTERED_RADIUS'), equals(ProximityState.enteredRadius));
      expect(ProximityState.fromString('NOTIFIED'), equals(ProximityState.notified));
      expect(ProximityState.fromString('LOCKED'), equals(ProximityState.locked));
    });

    test('toDbValue produces correct DB enum strings', () {
      expect(ProximityState.outside.toDbValue(), equals('OUTSIDE'));
      expect(ProximityState.enteredRadius.toDbValue(), equals('ENTERED_RADIUS'));
      expect(ProximityState.locked.toDbValue(), equals('LOCKED'));
    });
  });

  group('Notification Distance Validation', () {
    test('validates minimum distance', () {
      expect(Validators.validateNotificationDistance('50'), isNotNull); // below min
    });

    test('validates maximum distance', () {
      expect(Validators.validateNotificationDistance('20000'), isNotNull); // above max
    });

    test('accepts valid distances', () {
      expect(Validators.validateNotificationDistance('500'), isNull);
      expect(Validators.validateNotificationDistance('1000'), isNull);
      expect(Validators.validateNotificationDistance('2000'), isNull);
    });

    test('rejects non-numeric input', () {
      expect(Validators.validateNotificationDistance('abc'), isNotNull);
    });

    test('rejects empty input', () {
      expect(Validators.validateNotificationDistance(''), isNotNull);
    });
  });

  group('Retention Validation', () {
    test('rejects zero days', () {
      expect(Validators.validateRetentionDays('0'), isNotNull);
    });

    test('rejects negative days', () {
      expect(Validators.validateRetentionDays('-5'), isNotNull);
    });

    test('accepts valid retention', () {
      expect(Validators.validateRetentionDays('30'), isNull);
      expect(Validators.validateRetentionDays('365'), isNull);
      expect(Validators.validateRetentionDays('3650'), isNull);
    });

    test('rejects excessive retention', () {
      expect(Validators.validateRetentionDays('9999'), isNotNull);
    });
  });

  group('GPS Coordinate Validation', () {
    test('valid coordinates pass', () {
      expect(Validators.isValidGpsCoordinate(12.9716, 77.5946), isTrue);
      expect(Validators.isValidGpsCoordinate(0, 0), isTrue);
      expect(Validators.isValidGpsCoordinate(-90, -180), isTrue);
    });

    test('invalid coordinates fail', () {
      expect(Validators.isValidGpsCoordinate(91, 0), isFalse);
      expect(Validators.isValidGpsCoordinate(0, 181), isFalse);
      expect(Validators.isValidGpsCoordinate(null, 0), isFalse);
    });
  });

  group('UserRole Enum', () {
    test('fromString handles case-insensitive values', () {
      expect(UserRole.fromString('ADMIN'), equals(UserRole.admin));
      expect(UserRole.fromString('admin'), equals(UserRole.admin));
      expect(UserRole.fromString('DRIVER'), equals(UserRole.driver));
      expect(UserRole.fromString('PARENT'), equals(UserRole.parent));
    });

    test('toDbValue produces uppercase', () {
      expect(UserRole.admin.toDbValue(), equals('ADMIN'));
      expect(UserRole.driver.toDbValue(), equals('DRIVER'));
      expect(UserRole.parent.toDbValue(), equals('PARENT'));
    });
  });

  group('TripStatus', () {
    test('isOngoing returns true for active statuses', () {
      expect(TripStatus.active.isOngoing, isTrue);
      expect(TripStatus.starting.isOngoing, isTrue);
      expect(TripStatus.stale.isOngoing, isTrue);
    });

    test('isOngoing returns false for terminal statuses', () {
      expect(TripStatus.completed.isOngoing, isFalse);
      expect(TripStatus.cancelled.isOngoing, isFalse);
      expect(TripStatus.idle.isOngoing, isFalse);
    });
  });

  group('NotificationDelivery Idempotency', () {
    test('terminal delivery statuses have correct DB values', () {
      // SENT = terminal for FCM push (per spec — no on-device delivery confirmation)
      // DELIVERED = only set by inbound provider webhooks
      expect(DeliveryStatus.sent.toDbValue(), equals('SENT'));
      expect(DeliveryStatus.delivered.toDbValue(), equals('DELIVERED'));
      expect(DeliveryStatus.cancelled.toDbValue(), equals('CANCELLED'));
      // PENDING and FAILED are retryable statuses
      expect(DeliveryStatus.pending.toDbValue(), equals('PENDING'));
      expect(DeliveryStatus.failed.toDbValue(), equals('FAILED'));
    });

    test('delivery channel DB values are correct', () {
      expect(DeliveryChannel.push.toDbValue(), equals('PUSH'));
      expect(DeliveryChannel.sms.toDbValue(), equals('SMS'));
      expect(DeliveryChannel.whatsapp.toDbValue(), equals('WHATSAPP'));
    });

    test('notification priority values are correct', () {
      expect(NotificationPriority.emergency.toDbValue(), equals('EMERGENCY'));
      expect(NotificationPriority.high.toDbValue(), equals('HIGH'));
      expect(NotificationPriority.normal.toDbValue(), equals('NORMAL'));
    });
  });

  group('Model Serialization & CopyWith', () {
    final now = DateTime.now();

    test('Organization JSON roundtrip', () {
      final org = Organization(
        id: 'org-1',
        name: 'DPS School',
        createdAt: now,
        updatedAt: now,
      );
      final json = org.toJson();
      final fromJson = Organization.fromJson(json);
      expect(fromJson.id, equals('org-1'));
      expect(fromJson.name, equals('DPS School'));
      expect(fromJson.isActive, isTrue);
      expect(fromJson.gpsHistoryRetentionDays, equals(30));
    });

    test('Profile JSON roundtrip & copyWith', () {
      final profile = Profile(
        id: 'p-1',
        name: 'Jane Doe',
        email: 'jane@example.com',
        role: UserRole.parent,
        organizationId: 'org-1',
        createdAt: now,
        updatedAt: now,
      );
      final json = profile.toJson();
      final fromJson = Profile.fromJson(json);
      expect(fromJson.id, equals('p-1'));
      expect(fromJson.role, equals(UserRole.parent));

      final updated = profile.copyWith(name: 'Jane Smith');
      expect(updated.name, equals('Jane Smith'));
      expect(updated.id, equals('p-1'));
    });

    test('Trip JSON roundtrip and status getters', () {
      final trip = Trip(
        id: 't-1',
        organizationId: 'org-1',
        busId: 'b-1',
        driverId: 'd-1',
        status: TripStatus.active,
        currentLatitude: 12.9716,
        currentLongitude: 77.5946,
        createdAt: now,
        updatedAt: now,
      );
      expect(trip.isOngoing, isTrue);
      expect(trip.hasLocation, isTrue);

      final json = trip.toJson();
      final fromJson = Trip.fromJson(json);
      expect(fromJson.status, equals(TripStatus.active));
      expect(fromJson.currentLatitude, equals(12.9716));
    });

    test('Child hasPickupLocation getter', () {
      final childWithLoc = Child(
        id: 'c-1',
        organizationId: 'org-1',
        parentId: 'p-1',
        name: 'Tommy',
        pickupLatitude: 12.9716,
        pickupLongitude: 77.5946,
        createdAt: now,
        updatedAt: now,
      );
      expect(childWithLoc.hasPickupLocation, isTrue);

      final childNoLoc = Child(
        id: 'c-2',
        organizationId: 'org-1',
        parentId: 'p-1',
        name: 'Sara',
        createdAt: now,
        updatedAt: now,
      );
      expect(childNoLoc.hasPickupLocation, isFalse);
    });

    test('NotificationTemplate rendering', () {
      final tpl = NotificationTemplate(
        id: 'tpl-1',
        organizationId: 'org-1',
        eventType: NotificationEventType.busNearby,
        channel: DeliveryChannel.sms,
        messageTemplate: 'Bus {{bus_number}} is approaching for {{child_name}}.',
        createdAt: now,
        updatedAt: now,
      );
      final rendered = tpl.render({
        'bus_number': 'KA-01-1234',
        'child_name': 'Tommy',
      });
      expect(rendered, equals('Bus KA-01-1234 is approaching for Tommy.'));
    });
  });
}

