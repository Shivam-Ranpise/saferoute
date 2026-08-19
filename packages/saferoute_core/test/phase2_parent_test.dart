import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 2 — Parent Module & Tracking Calculations', () {
    test('Child Pickup Location getters evaluate correctly', () {
      final childWithLocation = Child(
        id: 'c-101',
        organizationId: 'org-1',
        parentId: 'p-1',
        name: 'Aarav Sharma',
        busId: 'bus-1',
        pickupLatitude: 12.9716,
        pickupLongitude: 77.5946,
        pickupName: 'Gate 2',
        notificationDistanceMeters: 500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final childWithoutLocation = Child(
        id: 'c-102',
        organizationId: 'org-1',
        parentId: 'p-1',
        name: 'Ananya Sharma',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(childWithLocation.hasPickupLocation, isTrue);
      expect(childWithoutLocation.hasPickupLocation, isFalse);
    });

    test('Distance between bus and pickup stop calculated accurately via Haversine', () {
      // Pickup stop: Indiranagar 100ft Rd (12.9784, 77.6408)
      // Bus location: Domlur Bridge (12.9600, 77.6380)
      const pickupLat = 12.9784;
      const pickupLon = 77.6408;
      const busLat = 12.9600;
      const busLon = 77.6380;

      final distanceMeters = Haversine.distanceMeters(
        lat1: busLat,
        lon1: busLon,
        lat2: pickupLat,
        lon2: pickupLon,
      );

      // Distance should be ~2.07 km (within +/- 50m)
      expect(distanceMeters, greaterThan(2000));
      expect(distanceMeters, lessThan(2150));

      final formatted = Haversine.formatDistance(distanceMeters);
      expect(formatted, contains('km'));
    });

    test('Proximity state transition evaluation for 500m geofence', () {
      const pickupLat = 12.9716;
      const pickupLon = 77.5946;
      const threshold = 500.0;
      const buffer = 200.0;

      // Point 1: 1.5 km away -> OUTSIDE
      final d1 = Haversine.distanceMeters(
        lat1: 12.9850,
        lon1: 77.5946,
        lat2: pickupLat,
        lon2: pickupLon,
      );
      expect(d1 > threshold + buffer, isTrue);

      // Point 2: 600m away -> APPROACHING (within 500m + 200m buffer)
      final d2 = Haversine.distanceMeters(
        lat1: 12.9770,
        lon1: 77.5946,
        lat2: pickupLat,
        lon2: pickupLon,
      );
      expect(d2 <= threshold + buffer && d2 > threshold, isTrue);

      // Point 3: 350m away -> ENTERED_RADIUS
      final d3 = Haversine.distanceMeters(
        lat1: 12.9745,
        lon1: 77.5946,
        lat2: pickupLat,
        lon2: pickupLon,
      );
      expect(d3 <= threshold && d3 > 50, isTrue);

      // Point 4: 20m away -> LOCKED (Arrived)
      final d4 = Haversine.distanceMeters(
        lat1: 12.9717,
        lon1: 77.5946,
        lat2: pickupLat,
        lon2: pickupLon,
      );
      expect(d4 <= 50, isTrue);
    });

    test('Stale Trip Telemetry Check detects timeout (> 300s)', () {
      final freshTime = DateTime.now().subtract(const Duration(seconds: 45));
      final staleTime = DateTime.now().subtract(const Duration(seconds: 360));

      final freshTrip = Trip(
        id: 't-1',
        organizationId: 'org-1',
        busId: 'bus-1',
        driverId: 'd-1',
        status: TripStatus.active,
        currentLatitude: 12.9716,
        currentLongitude: 77.5946,
        lastLocationAt: freshTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final staleTrip = Trip(
        id: 't-2',
        organizationId: 'org-1',
        busId: 'bus-1',
        driverId: 'd-1',
        status: TripStatus.active,
        currentLatitude: 12.9716,
        currentLongitude: 77.5946,
        lastLocationAt: staleTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final isFreshStale = DateTime.now().difference(freshTrip.lastLocationAt!).inSeconds > AppConfig.staleTripTimeoutSeconds;
      final isStaleStale = DateTime.now().difference(staleTrip.lastLocationAt!).inSeconds > AppConfig.staleTripTimeoutSeconds;

      expect(isFreshStale, isFalse);
      expect(isStaleStale, isTrue);
    });

    test('NotificationPreferences serialization round-trip', () {
      final prefs = NotificationPreferences(
        id: 'np-1',
        parentId: 'p-1',
        pushEnabled: true,
        whatsappEnabled: false,
        smsEnabled: true,
        updatedAt: DateTime.parse('2026-08-16T12:00:00Z'),
      );

      final json = prefs.toJson();
      final roundtripped = NotificationPreferences.fromJson(json);

      expect(roundtripped.id, equals('np-1'));
      expect(roundtripped.parentId, equals('p-1'));
      expect(roundtripped.pushEnabled, isTrue);
      expect(roundtripped.whatsappEnabled, isFalse);
      expect(roundtripped.smsEnabled, isTrue);
    });
  });
}
