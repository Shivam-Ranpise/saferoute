import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 12 — Developer Experience & Mock Sandbox Tests', () {
    test('MockRouteSimulator default Bangalore route initialization', () {
      final simulator = MockRouteSimulator();
      expect(simulator.waypoints.length, equals(8));
      expect(simulator.currentIndex, equals(0));
      expect(simulator.isRunning, isFalse);
    });

    test('MockRouteSimulator streams simulated GPS fixes and calculates bearings', () async {
      final customRoute = [
        (12.9716, 77.5946),
        (12.9750, 77.5980),
        (12.9800, 77.6020),
      ];

      final simulator = MockRouteSimulator(waypoints: customRoute, defaultSpeedKmh: 40.0);

      final points = <SimulatedGpsPoint>[];
      final stream = simulator.startSimulation(
        speedMultiplier: 10.0,
        interval: const Duration(milliseconds: 200),
      );

      final subscription = stream.listen((point) {
        points.add(point);
      });

      // Wait for simulation to complete
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(points.length, greaterThanOrEqualTo(2));
      expect(points.first.latitude, equals(12.9716));
      expect(points.first.longitude, equals(77.5946));
      expect(points.first.headingDegrees, greaterThan(0));
      expect(points.first.speedKmh, equals(40.0));

      await subscription.cancel();
      simulator.stop();
    });

    test('MockRouteSimulator pause and resume controls', () async {
      final simulator = MockRouteSimulator();
      expect(simulator.isPaused, isFalse);

      simulator.pause();
      expect(simulator.isPaused, isTrue);

      simulator.resume();
      expect(simulator.isPaused, isFalse);

      simulator.stop();
      expect(simulator.currentIndex, equals(0));
    });

    test('DemoCredentials personas validate all three platform roles', () {
      expect(DemoCredentials.allPersonas.length, equals(3));

      // Parent
      expect(DemoCredentials.parent.email, equals('parent@dps.edu'));
      expect(DemoCredentials.parent.role, equals(UserRole.parent));

      // Driver
      expect(DemoCredentials.driver.email, equals('driver@dps.edu'));
      expect(DemoCredentials.driver.role, equals(UserRole.driver));

      // Admin
      expect(DemoCredentials.admin.email, equals('admin@dps.edu'));
      expect(DemoCredentials.admin.role, equals(UserRole.admin));
    });
  });
}
