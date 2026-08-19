import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 10 — Performance Optimization & Sub-Second Latency Tests', () {
    test('AdaptiveTelemetryThrottler adapts intervals based on speed and heading', () {
      final throttler = AdaptiveTelemetryThrottler();

      final t0 = DateTime(2026, 8, 17, 8, 0, 0);

      // 1. Initial point always transmits
      final shouldTransmit1 = throttler.shouldTransmit(
        lat: 12.9716,
        lng: 77.5946,
        speedKmh: 45.0,
        headingDegrees: 90.0,
        timestamp: t0,
      );
      expect(shouldTransmit1, isTrue);

      // 2. High speed (> 30 km/h): 1 second later should be throttled (3s required)
      final t1 = t0.add(const Duration(seconds: 1));
      final shouldTransmit2 = throttler.shouldTransmit(
        lat: 12.9720,
        lng: 77.5950,
        speedKmh: 45.0,
        headingDegrees: 90.0,
        timestamp: t1,
      );
      expect(shouldTransmit2, isFalse);

      // 3. High speed: 3 seconds later should transmit
      final t2 = t0.add(const Duration(seconds: 3));
      final shouldTransmit3 = throttler.shouldTransmit(
        lat: 12.9730,
        lng: 77.5960,
        speedKmh: 45.0,
        headingDegrees: 90.0,
        timestamp: t2,
      );
      expect(shouldTransmit3, isTrue);

      // 4. Stationary (< 5 km/h): 4 seconds later should be throttled (12s required)
      final t3 = t2.add(const Duration(seconds: 4));
      final shouldTransmit4 = throttler.shouldTransmit(
        lat: 12.9730,
        lng: 77.5960,
        speedKmh: 0.0,
        headingDegrees: 90.0,
        timestamp: t3,
      );
      expect(shouldTransmit4, isFalse);

      // 5. Stationary: 12 seconds later transmits
      final t4 = t2.add(const Duration(seconds: 12));
      final shouldTransmit5 = throttler.shouldTransmit(
        lat: 12.9730,
        lng: 77.5960,
        speedKmh: 0.0,
        headingDegrees: 90.0,
        timestamp: t4,
      );
      expect(shouldTransmit5, isTrue);

      // 6. Heading change trigger: Sharp 90-degree turn after 2 seconds transmits immediately
      final t5 = t4.add(const Duration(milliseconds: 2000));
      final shouldTransmit6 = throttler.shouldTransmit(
        lat: 12.9735,
        lng: 77.5965,
        speedKmh: 25.0,
        headingDegrees: 180.0, // 90 degree delta
        timestamp: t5,
      );
      expect(shouldTransmit6, isTrue);
    });

    test('TelemetryCompactor strips precision redundancy and reduces bandwidth', () {
      const rawLat = 12.971598274819284;
      const rawLng = 77.594563819274019;
      const rawSpeed = 42.84719283;
      const rawHeading = 89.6;

      final compactedLat = TelemetryCompactor.compactCoordinate(rawLat);
      final compactedLng = TelemetryCompactor.compactCoordinate(rawLng);
      final compactedSpeed = TelemetryCompactor.compactSpeed(rawSpeed);
      final compactedHeading = TelemetryCompactor.compactHeading(rawHeading);

      expect(compactedLat, equals(12.971598));
      expect(compactedLng, equals(77.594564));
      expect(compactedSpeed, equals(42.8));
      expect(compactedHeading, equals(90));

      final packet = TelemetryCompactor.compactPayload(
        tripId: 'trip-1',
        latitude: rawLat,
        longitude: rawLng,
        speedKmh: rawSpeed,
        headingDegrees: rawHeading,
        accuracyMeters: 5.4,
        timestamp: DateTime(2026, 8, 17, 8, 0, 0),
      );

      expect(packet['lat'], equals(12.971598));
      expect(packet['lng'], equals(77.594564));
      expect(packet['s'], equals(42.8));
      expect(packet['h'], equals(90));
      expect(packet['a'], equals(5));
    });

    test('Sub-millisecond high-throughput pipeline benchmark (10,000 coordinates)', () {
      final kalman = GpsKalmanFilter();
      final throttler = AdaptiveTelemetryThrottler();

      final stopwatch = Stopwatch()..start();
      var baseTime = DateTime(2026, 8, 17, 8, 0, 0);

      int transmissions = 0;

      for (int i = 0; i < 10000; i++) {
        final rawLat = 12.9716 + (i * 0.00001);
        final rawLng = 77.5946 + (i * 0.00001);
        final smoothed = kalman.process(
          rawLat: rawLat,
          rawLng: rawLng,
          accuracyMeters: 5.0,
          timestamp: baseTime,
        );

        final speed = (i % 2 == 0) ? 35.0 : 5.0;
        final heading = (i * 5.0) % 360;

        final shouldSend = throttler.shouldTransmit(
          lat: smoothed[0],
          lng: smoothed[1],
          speedKmh: speed,
          headingDegrees: heading,
          timestamp: baseTime,
        );

        if (shouldSend) {
          transmissions++;
          TelemetryCompactor.compactPayload(
            tripId: 'trip-bench',
            latitude: smoothed[0],
            longitude: smoothed[1],
            speedKmh: speed,
            headingDegrees: heading,
            accuracyMeters: 5.0,
            timestamp: baseTime,
          );
        }

        baseTime = baseTime.add(const Duration(milliseconds: 500));
      }

      stopwatch.stop();

      // Total time for 10,000 full pipeline cycles must be under 500ms (< 0.05ms per coordinate)
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      expect(transmissions, greaterThan(0));
    });
  });
}
