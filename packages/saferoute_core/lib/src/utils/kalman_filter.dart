import 'dart:math' as math;

/// 2D Kalman Filter for smoothing noisy GPS coordinates, speed, and accuracy estimates.
class GpsKalmanFilter {
  final double processNoise; // Q: Process noise covariance (meters/sec^2)
  double _lat = 0.0;
  double _lng = 0.0;
  double _variance = -1.0; // P: Estimation error covariance (negative indicates uninitialized)
  DateTime? _lastTimestamp;

  GpsKalmanFilter({this.processNoise = 3.0});

  /// True if filter has received at least one coordinate
  bool get isInitialized => _variance >= 0;

  /// Current smoothed latitude
  double get latitude => _lat;

  /// Current smoothed longitude
  double get longitude => _lng;

  /// Current accuracy variance estimate (in meters)
  double get accuracy => _variance > 0 ? math.sqrt(_variance) : 0.0;

  /// Resets the filter state
  void reset() {
    _lat = 0.0;
    _lng = 0.0;
    _variance = -1.0;
    _lastTimestamp = null;
  }

  /// Processes a raw GPS coordinate fix and returns smoothed [latitude, longitude].
  /// [accuracyMeters] is the measurement standard deviation reported by GPS hardware.
  List<double> process({
    required double rawLat,
    required double rawLng,
    required double accuracyMeters,
    required DateTime timestamp,
  }) {
    final measurementNoise = accuracyMeters * accuracyMeters; // R = measurement variance

    if (!isInitialized) {
      _lat = rawLat;
      _lng = rawLng;
      _variance = measurementNoise;
      _lastTimestamp = timestamp;
      return [_lat, _lng];
    }

    // Calculate time elapsed in seconds
    final dt = (_lastTimestamp != null)
        ? (timestamp.difference(_lastTimestamp!).inMilliseconds / 1000.0).clamp(0.1, 10.0)
        : 1.0;
    _lastTimestamp = timestamp;

    // 1. Prediction step: increase variance with time elapsed
    _variance += (processNoise * processNoise) * dt;

    // 2. Kalman Gain (K = P / (P + R))
    final kalmanGain = _variance / (_variance + measurementNoise);

    // 3. Update estimate with measurement
    _lat += kalmanGain * (rawLat - _lat);
    _lng += kalmanGain * (rawLng - _lng);

    // 4. Update error covariance (P = (1 - K) * P)
    _variance = (1.0 - kalmanGain) * _variance;

    return [_lat, _lng];
  }
}
