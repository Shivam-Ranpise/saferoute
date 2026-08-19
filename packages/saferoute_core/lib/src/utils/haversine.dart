import 'dart:math' as math;

/// Pure Dart Haversine distance calculator.
/// No external APIs, no mapping services, no internet required.
/// This is the ONLY proximity calculation method used in SafeRoute.
class Haversine {
  Haversine._();

  static const double _earthRadiusM = 6371000.0; // Earth radius in meters

  /// Calculate the great-circle distance in meters between two geographic points
  /// using the Haversine formula.
  ///
  /// Parameters are in decimal degrees (WGS84).
  /// Returns distance in meters.
  ///
  /// Accuracy: within ~0.5% for distances under 1000km (more than sufficient
  /// for school bus proximity detection at sub-2km distances).
  static double distanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusM * c;
  }

  /// Calculate bearing from point 1 to point 2 in degrees (0-360, true north).
  static double bearingDegrees({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  /// Format a distance in meters to a human-readable string.
  /// e.g., 450 → "450 m", 1200 → "1.2 km"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km';
    }
  }

  /// Determine if the bus is approaching a child's pickup point.
  /// Returns true if within [approachingBuffer] meters outside the threshold.
  static bool isApproaching({
    required double distanceMeters,
    required double thresholdMeters,
    required double approachingBufferMeters,
  }) {
    return distanceMeters <= (thresholdMeters + approachingBufferMeters) &&
        distanceMeters > thresholdMeters;
  }

  /// Determine if the bus has entered a child's notification radius.
  static bool hasEnteredRadius({
    required double distanceMeters,
    required double thresholdMeters,
  }) {
    return distanceMeters <= thresholdMeters;
  }

  /// Check if a GPS point implies an impossible movement.
  /// Returns true if the point is valid.
  ///
  /// [prevLat], [prevLon]: previous GPS point
  /// [currLat], [currLon]: current GPS point
  /// [elapsedSeconds]: time since previous point
  /// [maxSpeedKmh]: maximum realistic speed (default 150 km/h for buses)
  static bool isValidMovement({
    required double prevLat,
    required double prevLon,
    required double currLat,
    required double currLon,
    required double elapsedSeconds,
    double maxSpeedKmh = 150.0,
  }) {
    if (elapsedSeconds <= 0) return false;

    final distM = distanceMeters(
      lat1: prevLat,
      lon1: prevLon,
      lat2: currLat,
      lon2: currLon,
    );

    final speedKmh = (distM / elapsedSeconds) * 3.6;
    return speedKmh <= maxSpeedKmh;
  }

  /// Predict bus position based on last known position, heading, and speed.
  /// IMPORTANT: Predictions must NEVER trigger proximity notifications alone.
  /// A real GPS fix must confirm any threshold crossing.
  ///
  /// Returns [lat, lon] of predicted position.
  static (double lat, double lon) predictPosition({
    required double lat,
    required double lon,
    required double headingDegrees,
    required double speedKmh,
    required double elapsedSeconds,
  }) {
    final distM = (speedKmh / 3.6) * elapsedSeconds;
    final heading = _toRadians(headingDegrees);
    final latRad = _toRadians(lat);
    final lonRad = _toRadians(lon);

    final newLatRad = math.asin(
      math.sin(latRad) * math.cos(distM / _earthRadiusM) +
          math.cos(latRad) * math.sin(distM / _earthRadiusM) * math.cos(heading),
    );

    final newLonRad = lonRad +
        math.atan2(
          math.sin(heading) * math.sin(distM / _earthRadiusM) * math.cos(latRad),
          math.cos(distM / _earthRadiusM) - math.sin(latRad) * math.sin(newLatRad),
        );

    return (_toDegrees(newLatRad), _toDegrees(newLonRad));
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;
}
