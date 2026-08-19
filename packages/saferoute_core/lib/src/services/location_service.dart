import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../utils/haversine.dart';
import '../utils/kalman_filter.dart';
import '../utils/logger.dart';

/// Service responsible for querying and streaming device GPS telemetry.
/// Ensures strict location accuracy, GPS glitch rejection, Kalman smoothing, and permission handling.
class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastValidPosition;
  final GpsKalmanFilter _kalmanFilter = GpsKalmanFilter(processNoise: 3.0);

  /// Checks and requests location permissions.
  Future<bool> checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location services are disabled on device',
          context: 'LocationService');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.warning('Location permission denied by user',
            context: 'LocationService');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.error('Location permission permanently denied',
          context: 'LocationService');
      return false;
    }

    return true;
  }

  /// Gets current one-shot location.
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to get current location',
          error: e, context: 'LocationService');
      return null;
    }
  }

  /// Starts listening to device location stream and outputs validated Positions.
  Stream<Position> startLocationStream({
    int distanceFilterMeters = 5,
    int intervalSeconds = 5,
  }) {
    final controller = StreamController<Position>.broadcast();
    _kalmanFilter.reset();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen(
      (position) {
        // 1. Accuracy Filter: Reject readings with low accuracy (> 35m)
        if (position.accuracy > 35.0) {
          AppLogger.info(
              'Rejected low accuracy GPS reading: ${position.accuracy}m',
              context: 'LocationService');
          return;
        }

        // 2. Glitch & Jump Filter: Validate movement using Haversine
        if (_lastValidPosition != null) {
          final elapsed = position.timestamp
                  .difference(_lastValidPosition!.timestamp)
                  .inMilliseconds /
              1000.0;

          final isValid = Haversine.isValidMovement(
            prevLat: _lastValidPosition!.latitude,
            prevLon: _lastValidPosition!.longitude,
            currLat: position.latitude,
            currLon: position.longitude,
            elapsedSeconds: elapsed > 0 ? elapsed : 1.0,
            maxSpeedKmh: 120.0, // School bus speed threshold
          );

          if (!isValid) {
            AppLogger.warning(
                'Rejected impossible GPS jump from (${_lastValidPosition!.latitude}, ${_lastValidPosition!.longitude}) to (${position.latitude}, ${position.longitude})',
                context: 'LocationService');
            return;
          }
        }

        // 3. Kalman Filter Smoothing
        final smoothed = _kalmanFilter.process(
          rawLat: position.latitude,
          rawLng: position.longitude,
          accuracyMeters: position.accuracy,
          timestamp: position.timestamp,
        );

        final smoothedPosition = Position(
          latitude: smoothed[0],
          longitude: smoothed[1],
          timestamp: position.timestamp,
          accuracy: _kalmanFilter.accuracy,
          altitude: position.altitude,
          altitudeAccuracy: position.altitudeAccuracy,
          heading: position.heading,
          headingAccuracy: position.headingAccuracy,
          speed: position.speed,
          speedAccuracy: position.speedAccuracy,
        );

        _lastValidPosition = smoothedPosition;
        controller.add(smoothedPosition);
      },
      onError: (error) {
        AppLogger.error('Location stream error: $error',
            context: 'LocationService');
        controller.addError(error);
      },
      onDone: () {
        controller.close();
      },
      cancelOnError: false,
    );

    return controller.stream;
  }

  /// Stops and disposes active location subscription.
  Future<void> stopLocationStream() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastValidPosition = null;
    _kalmanFilter.reset();
    AppLogger.info('Location stream stopped', context: 'LocationService');
  }
}
