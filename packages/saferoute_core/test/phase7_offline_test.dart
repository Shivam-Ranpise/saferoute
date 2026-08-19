import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 7 — Offline Resilience & Kalman Glitch Smoothing Tests', () {
    test('GpsKalmanFilter initialization and smoothing behavior', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);

      expect(filter.isInitialized, isFalse);

      final now = DateTime.now();

      // First GPS reading sets baseline
      final firstPoint = filter.process(
        rawLat: 12.9716,
        rawLng: 77.5946,
        accuracyMeters: 5.0,
        timestamp: now,
      );

      expect(filter.isInitialized, isTrue);
      expect(firstPoint[0], closeTo(12.9716, 0.0001));
      expect(firstPoint[1], closeTo(77.5946, 0.0001));

      // Second noisy GPS reading (multipath jitter +0.0005 deg ~ 55m)
      final secondPoint = filter.process(
        rawLat: 12.9721,
        rawLng: 77.5951,
        accuracyMeters: 15.0, // Lower accuracy measurement
        timestamp: now.add(const Duration(seconds: 2)),
      );

      // Filter should smooth the coordinate rather than jumping all the way to 12.9721
      expect(secondPoint[0], greaterThan(12.9716));
      expect(secondPoint[0], lessThan(12.9721));
      expect(secondPoint[1], greaterThan(77.5946));
      expect(secondPoint[1], lessThan(77.5951));

      // Reset
      filter.reset();
      expect(filter.isInitialized, isFalse);
    });

    test('OfflineSyncQueue buffers telemetry and manifest updates when offline', () {
      final queue = OfflineSyncQueue.instance;
      queue.clearQueue();

      expect(queue.queueLength, equals(0));

      queue.setOnlineStatus(false);
      expect(queue.isOnline, isFalse);

      // Enqueue telemetry breadcrumb
      queue.enqueueTelemetry(
        tripId: 'trip-100',
        organizationId: 'org-1',
        latitude: 12.9716,
        longitude: 77.5946,
        speed: 35.0,
        heading: 90.0,
        accuracy: 4.5,
        recordedAt: DateTime.now(),
      );

      expect(queue.queueLength, equals(1));

      // Enqueue passenger status change
      queue.enqueueManifestUpdate(
        manifestId: 'pass-200',
        status: 'BOARDED',
        updatedTime: DateTime.now(),
      );

      expect(queue.queueLength, equals(2));

      // Teardown
      queue.clearQueue();
      expect(queue.queueLength, equals(0));
      queue.setOnlineStatus(true);
    });
  });
}
