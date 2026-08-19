/// Telemetry Compactor
/// Compresses float precision coordinates, speeds, and timestamps into
/// optimized micro-payloads to minimize bandwidth over edge 2G/3G networks.
class TelemetryCompactor {
  TelemetryCompactor._();

  /// Formats coordinate to 6 decimal places (approx. 11 cm precision).
  /// Strips unnecessary 64-bit float mantissa tails.
  static double compactCoordinate(double coord) {
    return double.parse(coord.toStringAsFixed(6));
  }

  /// Compacts speed to 1 decimal place.
  static double compactSpeed(double speedKmh) {
    return double.parse(speedKmh.toStringAsFixed(1));
  }

  /// Compacts heading to nearest integer (0-359 degrees).
  static int compactHeading(double headingDegrees) {
    return headingDegrees.round() % 360;
  }

  /// Creates a compacted JSON map ready for transmission.
  static Map<String, dynamic> compactPayload({
    required String tripId,
    required double latitude,
    required double longitude,
    required double speedKmh,
    required double headingDegrees,
    required double accuracyMeters,
    required DateTime timestamp,
  }) {
    return {
      't': tripId,
      'lat': compactCoordinate(latitude),
      'lng': compactCoordinate(longitude),
      's': compactSpeed(speedKmh),
      'h': compactHeading(headingDegrees),
      'a': accuracyMeters.round(),
      'ts': timestamp.millisecondsSinceEpoch,
    };
  }
}
