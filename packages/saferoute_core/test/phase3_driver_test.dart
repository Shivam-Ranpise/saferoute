import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 3 — Driver Module & Telemetry Engine Tests', () {
    test('Driver & Bus Model relationships and serialization', () {
      final driver = Driver(
        id: 'drv-101',
        profileId: 'prof-d1',
        organizationId: 'org-1',
        licenseNumber: 'KA-01-2022-0099',
        createdAt: DateTime.parse('2026-08-16T08:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T08:00:00Z'),
      );

      final bus = Bus(
        id: 'bus-1',
        organizationId: 'org-1',
        busNumber: '12-A',
        registrationNumber: 'KA-01-AB-1234',
        capacity: 35,
        currentDriverId: driver.id,
        isActive: true,
        createdAt: DateTime.parse('2026-08-16T08:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T08:00:00Z'),
      );

      expect(bus.currentDriverId, equals(driver.id));
      expect(bus.busNumber, equals('12-A'));

      final json = driver.toJson();
      final roundtripped = Driver.fromJson(json);
      expect(roundtripped.licenseNumber, equals('KA-01-2022-0099'));
    });

    test('Trip status lifecycle transitions and ongoing evaluation', () {
      final activeTrip = Trip(
        id: 'trip-1',
        organizationId: 'org-1',
        busId: 'bus-1',
        driverId: 'drv-101',
        status: TripStatus.active,
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final startingTrip = activeTrip.copyWith(status: TripStatus.starting);
      final completedTrip = activeTrip.copyWith(
        status: TripStatus.completed,
        endedAt: DateTime.now(),
      );
      final cancelledTrip = activeTrip.copyWith(
        status: TripStatus.cancelled,
        endedAt: DateTime.now(),
      );

      expect(activeTrip.isOngoing, isTrue);
      expect(startingTrip.isOngoing, isTrue);
      expect(completedTrip.isOngoing, isFalse);
      expect(cancelledTrip.isOngoing, isFalse);
      expect(completedTrip.endedAt, isNotNull);
    });

    test('GPS Telemetry jump rejection detects impossible movement (> 120 km/h)', () {
      // Move 1 km in 5 seconds = 720 km/h (impossible for a school bus)
      const lat1 = 12.9716;
      const lon1 = 77.5946;
      const lat2 = 12.9806;
      const lon2 = 77.5946;

      final isGlitchValid = Haversine.isValidMovement(
        prevLat: lat1,
        prevLon: lon1,
        currLat: lat2,
        currLon: lon2,
        elapsedSeconds: 5.0,
        maxSpeedKmh: 120.0,
      );

      expect(isGlitchValid, isFalse);

      // Realistic movement: 30m in 5 seconds = 21.6 km/h
      const lat3 = 12.97187;
      const lon3 = 77.5946;

      final isRealisticValid = Haversine.isValidMovement(
        prevLat: lat1,
        prevLon: lon1,
        currLat: lat3,
        currLon: lon3,
        elapsedSeconds: 5.0,
        maxSpeedKmh: 120.0,
      );

      expect(isRealisticValid, isTrue);
    });

    test('TripLocationHistory model serialization', () {
      final history = TripLocationHistory(
        id: 'tlh-1',
        organizationId: 'org-1',
        tripId: 'trip-1',
        latitude: 12.9716,
        longitude: 77.5946,
        speed: 32.5,
        heading: 180.0,
        accuracy: 4.2,
        recordedAt: DateTime.parse('2026-08-16T12:00:00Z'),
        createdAt: DateTime.parse('2026-08-16T12:00:00Z'),
      );

      final json = history.toJson();
      final roundtripped = TripLocationHistory.fromJson(json);

      expect(roundtripped.tripId, equals('trip-1'));
      expect(roundtripped.organizationId, equals('org-1'));
      expect(roundtripped.latitude, equals(12.9716));
      expect(roundtripped.speed, equals(32.5));
      expect(roundtripped.accuracy, equals(4.2));
    });
  });
}
