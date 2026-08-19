import 'dart:async';
import 'haversine.dart';

/// Simulated GPS Telemetry Data Point
class SimulatedGpsPoint {
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double headingDegrees;
  final double accuracyMeters;
  final DateTime timestamp;
  final int waypointIndex;
  final int totalWaypoints;

  const SimulatedGpsPoint({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.headingDegrees,
    required this.accuracyMeters,
    required this.timestamp,
    required this.waypointIndex,
    required this.totalWaypoints,
  });

  bool get isCompleted => waypointIndex >= totalWaypoints - 1;
}

/// In-App GPS Route Simulator
/// Simulates realistic bus movement along pre-defined geographic waypoints
/// with bearing, speed interpolation, and configurable speed multipliers.
class MockRouteSimulator {
  /// Default pre-configured Bangalore School Bus Route
  static const List<(double lat, double lng)> defaultBangaloreRoute = [
    (12.9352, 77.6245), // 1. Koramangala 5th Block Depot (Start)
    (12.9410, 77.6280), // 2. Sony World Junction
    (12.9540, 77.6385), // 3. Domlur Flyover / Inner Ring Rd
    (12.9620, 77.6440), // 4. Indiranagar 100ft Rd Stop (Alice Pickup)
    (12.9680, 77.6520), // 5. HAL Main Gate
    (12.9716, 77.5946), // 6. Central Junction
    (12.9560, 77.7010), // 7. Marathahalli Bridge
    (12.9698, 77.7499), // 8. Whitefield School Campus (Destination)
  ];

  final List<(double lat, double lng)> waypoints;
  final double defaultSpeedKmh;
  final double accuracyMeters;

  int _currentIndex = 0;
  Timer? _timer;
  StreamController<SimulatedGpsPoint>? _controller;
  bool _isPaused = false;

  MockRouteSimulator({
    List<(double lat, double lng)>? waypoints,
    this.defaultSpeedKmh = 35.0,
    this.accuracyMeters = 5.0,
  }) : waypoints = waypoints ?? defaultBangaloreRoute;

  /// Start or restart the simulation stream
  Stream<SimulatedGpsPoint> startSimulation({
    double speedMultiplier = 1.0,
    Duration interval = const Duration(seconds: 1),
  }) {
    _stopTimer();
    _controller?.close();
    _controller = StreamController<SimulatedGpsPoint>.broadcast();
    _currentIndex = 0;
    _isPaused = false;

    final stepDurationMs = (interval.inMilliseconds / speedMultiplier).round().clamp(50, 10000);

    // Schedule initial waypoint emission so listeners catch it
    scheduleMicrotask(() {
      _emitCurrentPoint();
    });

    _timer = Timer.periodic(Duration(milliseconds: stepDurationMs), (timer) {
      if (_isPaused) return;

      if (_currentIndex < waypoints.length - 1) {
        _currentIndex++;
        _emitCurrentPoint();
      } else {
        _stopTimer();
        _controller?.close();
      }
    });

    return _controller!.stream;
  }

  void _emitCurrentPoint() {
    if (_controller == null || _controller!.isClosed) return;

    final curr = waypoints[_currentIndex];
    double heading = 0.0;
    double speed = defaultSpeedKmh;

    if (_currentIndex < waypoints.length - 1) {
      final next = waypoints[_currentIndex + 1];
      heading = Haversine.bearingDegrees(
        lat1: curr.$1,
        lon1: curr.$2,
        lat2: next.$1,
        lon2: next.$2,
      );
    } else if (_currentIndex > 0) {
      final prev = waypoints[_currentIndex - 1];
      heading = Haversine.bearingDegrees(
        lat1: prev.$1,
        lon1: prev.$2,
        lat2: curr.$1,
        lon2: curr.$2,
      );
      speed = 0.0; // Stopped at destination
    }

    final point = SimulatedGpsPoint(
      latitude: curr.$1,
      longitude: curr.$2,
      speedKmh: speed,
      headingDegrees: heading,
      accuracyMeters: accuracyMeters,
      timestamp: DateTime.now(),
      waypointIndex: _currentIndex,
      totalWaypoints: waypoints.length,
    );

    _controller!.add(point);
  }

  /// Pause simulation
  void pause() {
    _isPaused = true;
  }

  /// Resume simulation
  void resume() {
    _isPaused = false;
  }

  /// Stop simulation
  void stop() {
    _stopTimer();
    _controller?.close();
    _currentIndex = 0;
    _isPaused = false;
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int get currentIndex => _currentIndex;
  bool get isPaused => _isPaused;
  bool get isRunning => _timer != null && !_isPaused;
}
