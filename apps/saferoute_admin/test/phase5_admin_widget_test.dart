import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:saferoute_admin/src/features/admin/presentation/fleet_overview_screen.dart';
import 'package:saferoute_admin/src/features/admin/presentation/buses_management_screen.dart';
import 'package:saferoute_admin/src/features/admin/presentation/drivers_management_screen.dart';
import 'package:saferoute_admin/src/features/admin/presentation/students_management_screen.dart';
import 'package:saferoute_admin/src/features/admin/presentation/notification_audit_screen.dart';
import 'package:saferoute_admin/src/features/auth/presentation/admin_login_screen.dart';
import 'package:saferoute_admin/src/features/admin/providers/admin_providers.dart';
import 'package:saferoute_admin/src/providers/auth_provider.dart';

class FakeAdminAuthNotifier extends StateNotifier<AdminAuthState>
    implements AdminAuthNotifier {
  FakeAdminAuthNotifier([AdminAuthState? initial])
      : super(initial ?? const AdminAuthState(isLoading: false));

  @override
  Future<void> signInWithIdentifier(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  final testAdminProfile = Profile(
    id: 'prof-admin-1',
    organizationId: 'org-1',
    email: 'admin@dps.edu',
    name: 'DPS Admin Office',
    role: UserRole.admin,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Phase 5 — Admin Web Dashboard UI Widget Tests', () {
    testWidgets('AdminLoginScreen renders login form and validates fields',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adminAuthProvider.overrideWith((ref) => FakeAdminAuthNotifier()),
          ],
          child: const MaterialApp(
            home: AdminLoginScreen(),
          ),
        ),
      );

      expect(find.text('SafeRoute Admin'), findsOneWidget);
      expect(find.text('School Fleet & Operations Portal'), findsOneWidget);
      expect(find.text('Sign In to Console'), findsOneWidget);

      await tester.tap(find.text('Sign In to Console'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('FleetOverviewScreen displays KPI cards and active routes',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const mockStats = OrganizationFleetStats(
        totalBuses: 15,
        activeBuses: 12,
        totalDrivers: 14,
        totalStudents: 340,
        activeTripsCount: 4,
      );

      final trip = Trip(
        id: 'trip-1',
        organizationId: 'org-1',
        busId: 'bus-1',
        driverId: 'drv-1',
        status: TripStatus.active,
        currentLatitude: 12.9716,
        currentLongitude: 77.5946,
        currentSpeed: 38.5,
        startedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bus = Bus(
        id: 'bus-1',
        organizationId: 'org-1',
        busNumber: 'Route 12-A',
        registrationNumber: 'KA-01-XX-1122',
        capacity: 40,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bundle = ActiveTripFleetBundle(
        trip: trip,
        bus: bus,
        driverName: 'Ramesh Kumar',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProfileProvider.overrideWithValue(testAdminProfile),
            organizationStatsProvider.overrideWith((ref) => Future.value(mockStats)),
            fleetLiveTripsStreamProvider.overrideWith((ref) => Stream.value([bundle])),
          ],
          child: const MaterialApp(
            home: FleetOverviewScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fleet Overview & Live Tracking'), findsOneWidget);
      expect(find.text('Active Trips'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('340'), findsOneWidget);
      expect(find.text('Route 12-A'), findsWidgets);
      expect(find.text('EN ROUTE'), findsOneWidget);
    });

    testWidgets('BusesManagementScreen displays registered buses and opens add modal',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final bus = Bus(
        id: 'bus-1',
        organizationId: 'org-1',
        busNumber: 'Bus 04-North',
        registrationNumber: 'KA-04-E-5566',
        capacity: 35,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProfileProvider.overrideWithValue(testAdminProfile),
            adminBusesProvider.overrideWith((ref) => Future.value([bus])),
          ],
          child: const MaterialApp(
            home: BusesManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bus Fleet Management'), findsOneWidget);
      expect(find.text('Bus 04-North'), findsOneWidget);
      expect(find.text('KA-04-E-5566'), findsOneWidget);
      expect(find.text('35 Seats'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      await tester.tap(find.text('Add New Bus'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Bus'), findsWidgets);
      expect(find.text('Bus Number / Route Name'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('DriversManagementScreen displays verified drivers list',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final driverMap = {
        'id': 'drv-1',
        'license_number': 'DL-KA-2022001',
        'profiles': {
          'name': 'Suresh Raina',
          'email': 'suresh@dps.edu',
          'phone': '+91 98765 43210',
        },
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProfileProvider.overrideWithValue(testAdminProfile),
            adminDriversProvider.overrideWith((ref) => Future.value([driverMap])),
          ],
          child: const MaterialApp(
            home: DriversManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Driver & Crew Registry'), findsOneWidget);
      expect(find.text('Suresh Raina'), findsOneWidget);
      expect(find.text('DL-KA-2022001'), findsOneWidget);
      expect(find.text('VERIFIED'), findsOneWidget);
    });

    testWidgets('StudentsManagementScreen displays students and geofence state',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final child = Child(
        id: 'child-1',
        organizationId: 'org-1',
        parentId: 'parent-1',
        name: 'Aarav Sharma',
        pickupName: 'Indiranagar Club Stop',
        pickupAddress: 'Indiranagar 100ft Road',
        pickupLatitude: 12.9716,
        pickupLongitude: 77.5946,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProfileProvider.overrideWithValue(testAdminProfile),
            adminStudentsProvider.overrideWith((ref) => Future.value([child])),
          ],
          child: const MaterialApp(
            home: StudentsManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Student Roster & Stop Management'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Indiranagar Club Stop'), findsOneWidget);
      expect(find.text('Indiranagar 100ft Road'), findsOneWidget);
      expect(find.text('SET'), findsOneWidget);
    });

    testWidgets('NotificationAuditScreen displays dispatched events',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final event = NotificationEvent(
        id: 'evt-1',
        organizationId: 'org-1',
        eventType: NotificationEventType.emergency,
        priority: NotificationPriority.emergency,
        title: 'EMERGENCY: Flat Tire',
        message: 'Bus 12-A delayed on Outer Ring Road',
        createdAt: DateTime.parse('2026-08-16T15:30:00Z'),
        updatedAt: DateTime.parse('2026-08-16T15:30:00Z'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProfileProvider.overrideWithValue(testAdminProfile),
            notificationAuditLogsProvider.overrideWith((ref) => Future.value([event])),
          ],
          child: const MaterialApp(
            home: NotificationAuditScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Delivery Audit Trail'), findsOneWidget);
      expect(find.text('EMERGENCY: Flat Tire'), findsOneWidget);
      expect(find.text('Bus 12-A delayed on Outer Ring Road'), findsOneWidget);
      expect(find.text('DISPATCHED'), findsOneWidget);
    });
  });
}
