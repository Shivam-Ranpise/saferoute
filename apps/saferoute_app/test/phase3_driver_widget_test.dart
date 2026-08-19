import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:saferoute_app/src/features/driver/presentation/driver_dashboard_screen.dart';
import 'package:saferoute_app/src/features/driver/presentation/widgets/passenger_manifest_sheet.dart';
import 'package:saferoute_app/src/features/driver/providers/driver_providers.dart';
import 'package:saferoute_app/src/providers/auth_provider.dart';

class FakeDriverActiveTripNotifier extends StateNotifier<AsyncValue<Trip?>>
    implements DriverActiveTripNotifier {
  final bool _broadcasting;

  FakeDriverActiveTripNotifier({Trip? trip, bool broadcasting = false})
      : _broadcasting = broadcasting,
        super(AsyncValue.data(trip));

  @override
  bool get isBroadcasting => _broadcasting;

  @override
  Future<void> startTrip() async {}

  @override
  void toggleGpsBroadcasting() {}

  @override
  Future<void> endTrip() async {}

  @override
  Future<void> triggerEmergency(String title, String description) async {}
}

void main() {
  group('Phase 3 — Driver UI Widget Tests', () {
    testWidgets('DriverDashboardScreen shows empty state when no bus assigned',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWithValue(
              Profile(
                id: 'prof-d1',
                organizationId: 'org-1',
                email: 'driver@example.com',
                name: 'Ramesh Kumar',
                role: UserRole.driver,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
            currentDriverBundleProvider.overrideWith(
              (ref) => Future.value(null),
            ),
          ],
          child: const MaterialApp(
            home: DriverDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SafeRoute Driver'), findsOneWidget);
      expect(find.text('Driver: Ramesh Kumar'), findsOneWidget);
      expect(find.text('No Bus Assigned'), findsOneWidget);
    });

    testWidgets('DriverDashboardScreen shows assigned bus and START TRIP button',
        (tester) async {
      final driver = Driver(
        id: 'd-1',
        profileId: 'prof-d1',
        organizationId: 'org-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final bus = Bus(
        id: 'b-1',
        organizationId: 'org-1',
        busNumber: '07-B',
        registrationNumber: 'KA-01-EF-5678',
        capacity: 40,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWithValue(
              Profile(
                id: 'prof-d1',
                organizationId: 'org-1',
                email: 'driver@example.com',
                name: 'Ramesh Kumar',
                role: UserRole.driver,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
            currentDriverBundleProvider.overrideWith(
              (ref) => Future.value(DriverBusBundle(driver: driver, bus: bus)),
            ),
            driverStudentsProvider.overrideWith(
              (ref) => Future.value(<Child>[]),
            ),
            driverActiveTripProvider.overrideWith(
              (ref) => FakeDriverActiveTripNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: DriverDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Bus 07-B'), findsOneWidget);
      expect(find.text('KA-01-EF-5678'), findsOneWidget);
      expect(find.text('START TRIP'), findsOneWidget);
    });

    testWidgets('PassengerManifestSheet displays student roll call items',
        (tester) async {
      final student1 = Child(
        id: 's-1',
        organizationId: 'org-1',
        parentId: 'p-1',
        name: 'Rohan Verma',
        pickupName: 'Gate 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final student2 = Child(
        id: 's-2',
        organizationId: 'org-1',
        parentId: 'p-2',
        name: 'Sneha Patel',
        pickupName: 'Clubhouse Stop',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            driverStudentsProvider.overrideWith(
              (ref) => Future.value([student1, student2]),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PassengerManifestSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Total: 2 Students'), findsOneWidget);
      expect(find.text('Rohan Verma'), findsOneWidget);
      expect(find.text('Sneha Patel'), findsOneWidget);
    });
  });
}
