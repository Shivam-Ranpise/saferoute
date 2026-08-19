import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 5 — Admin Repositories & Fleet Aggregation Tests', () {
    test('OrganizationFleetStats instantiation and empty state', () {
      final emptyStats = OrganizationFleetStats.empty();
      expect(emptyStats.totalBuses, equals(0));
      expect(emptyStats.activeBuses, equals(0));
      expect(emptyStats.activeTripsCount, equals(0));

      const stats = OrganizationFleetStats(
        totalBuses: 12,
        activeBuses: 10,
        totalDrivers: 14,
        totalStudents: 320,
        activeTripsCount: 8,
      );

      expect(stats.totalBuses, equals(12));
      expect(stats.activeBuses, equals(10));
      expect(stats.totalDrivers, equals(14));
      expect(stats.totalStudents, equals(320));
      expect(stats.activeTripsCount, equals(8));
    });

    test('ActiveTripFleetBundle entity mapping', () {
      final trip = Trip(
        id: 'trip-101',
        organizationId: 'org-1',
        busId: 'bus-1',
        driverId: 'drv-1',
        status: TripStatus.active,
        startedAt: DateTime.parse('2026-08-16T08:00:00Z'),
        createdAt: DateTime.parse('2026-08-16T08:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T08:00:00Z'),
      );

      final bus = Bus(
        id: 'bus-1',
        organizationId: 'org-1',
        busNumber: '04-North',
        registrationNumber: 'KA-01-XX-9999',
        capacity: 45,
        isActive: true,
        createdAt: DateTime.parse('2026-08-16T08:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T08:00:00Z'),
      );

      final driver = Driver(
        id: 'drv-1',
        profileId: 'prof-d1',
        organizationId: 'org-1',
        licenseNumber: 'DL-IND-88221',
        createdAt: DateTime.parse('2026-08-16T08:00:00Z'),
        updatedAt: DateTime.parse('2026-08-16T08:00:00Z'),
      );

      final bundle = ActiveTripFleetBundle(
        trip: trip,
        bus: bus,
        driver: driver,
        driverName: 'Suresh Raina',
      );

      expect(bundle.trip.id, equals('trip-101'));
      expect(bundle.bus?.busNumber, equals('04-North'));
      expect(bundle.driver?.licenseNumber, equals('DL-IND-88221'));
      expect(bundle.driverName, equals('Suresh Raina'));
      expect(bundle.trip.isOngoing, isTrue);
    });

    test('Admin Bus CRUD model validation and copyWith', () {
      final bus = Bus(
        id: 'bus-2',
        organizationId: 'org-1',
        busNumber: '09-South',
        registrationNumber: 'KA-05-ZZ-1111',
        capacity: 30,
        currentDriverId: 'drv-2',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedBus = bus.copyWith(
        capacity: 35,
        isActive: false,
      );

      expect(updatedBus.capacity, equals(35));
      expect(updatedBus.isActive, isFalse);
      expect(updatedBus.busNumber, equals('09-South'));
    });
  });
}
