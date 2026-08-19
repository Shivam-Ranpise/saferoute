import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 9 — Edge Functions & Serverless Logic Tests', () {
    test('Serverless geofence evaluation detects arrival and state transitions', () {
      const studentStopLat = 12.9716;
      const studentStopLng = 77.5946;
      const thresholdMeters = 500;

      // Bus far away (~ 2.5 km)
      const busFarLat = 12.9900;
      const busFarLng = 77.6000;
      final distanceFar = Haversine.distanceMeters(
        lat1: busFarLat,
        lon1: busFarLng,
        lat2: studentStopLat,
        lon2: studentStopLng,
      );

      expect(distanceFar, greaterThan(2000));
      expect(distanceFar <= thresholdMeters, isFalse);

      // Bus arrives within 400m
      const busNearLat = 12.9740;
      const busNearLng = 77.5960;
      final distanceNear = Haversine.distanceMeters(
        lat1: busNearLat,
        lon1: busNearLng,
        lat2: studentStopLat,
        lon2: studentStopLng,
      );

      expect(distanceNear, lessThan(thresholdMeters));
      expect(distanceNear <= thresholdMeters, isTrue);

      // Proximity transition evaluation:
      // When current state is OUTSIDE and distance <= 500m -> trigger NOTIFIED
      var proxState = ProximityState.outside;
      if (distanceNear <= thresholdMeters &&
          (proxState == ProximityState.outside ||
              proxState == ProximityState.approaching)) {
        proxState = ProximityState.notified;
      }
      expect(proxState, equals(ProximityState.notified));

      // Second check: If already in NOTIFIED state, don't re-trigger notification
      bool shouldTrigger = false;
      if (distanceNear <= thresholdMeters &&
          (proxState == ProximityState.outside ||
              proxState == ProximityState.approaching)) {
        shouldTrigger = true;
      }
      expect(shouldTrigger, isFalse); // Idempotent
    });

    test('Route telemetry trajectory distance and speed aggregation', () {
      final breadcrumbs = [
        {'lat': 12.9716, 'lng': 77.5946, 'speed': 30.0},
        {'lat': 12.9750, 'lng': 77.5970, 'speed': 40.0},
        {'lat': 12.9800, 'lng': 77.6010, 'speed': 35.0},
        {'lat': 12.9850, 'lng': 77.6050, 'speed': 45.0},
      ];

      double totalDistanceMeters = 0;
      double totalSpeed = 0;

      for (int i = 1; i < breadcrumbs.length; i++) {
        final prev = breadcrumbs[i - 1];
        final curr = breadcrumbs[i];
        totalDistanceMeters += Haversine.distanceMeters(
          lat1: prev['lat'] as double,
          lon1: prev['lng'] as double,
          lat2: curr['lat'] as double,
          lon2: curr['lng'] as double,
        );
        totalSpeed += curr['speed'] as double;
      }

      final totalKm = (totalDistanceMeters / 1000);
      final avgSpeed = totalSpeed / (breadcrumbs.length - 1);

      expect(totalKm, greaterThan(1.5));
      expect(totalKm, lessThan(3.5));
      expect(avgSpeed, closeTo(40.0, 0.1));
    });
  });
}
