import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  return DriverRepository();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// Bundle holding driver record and assigned bus.
class DriverBusBundle {
  final Driver driver;
  final Bus? bus;

  const DriverBusBundle({
    required this.driver,
    this.bus,
  });
}

/// Driver record and assigned bus for current authenticated profile
final currentDriverBundleProvider = FutureProvider<DriverBusBundle?>((ref) async {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) return null;

  final repo = ref.watch(driverRepositoryProvider);
  final driver = await repo.getDriverByProfileId(profile.id);
  if (driver == null) return null;

  final bus = await repo.getAssignedBusForDriver(driver.id);
  return DriverBusBundle(driver: driver, bus: bus);
});

/// Student roster assigned to this driver's bus
final driverStudentsProvider = FutureProvider<List<Child>>((ref) async {
  final bundle = ref.watch(currentDriverBundleProvider).value;
  if (bundle == null || bundle.bus == null) return [];

  final repo = ref.watch(driverRepositoryProvider);
  return await repo.getStudentsForBus(bundle.bus!.id);
});

/// In-memory passenger roll call state (ChildId -> status: 'pending' | 'boarded' | 'absent' | 'dropped_off')
final passengerStatusProvider =
    StateNotifierProvider<PassengerStatusNotifier, Map<String, String>>((ref) {
  return PassengerStatusNotifier();
});

class PassengerStatusNotifier extends StateNotifier<Map<String, String>> {
  PassengerStatusNotifier() : super({});

  void setStatus(String childId, String status) {
    state = {...state, childId: status};
  }

  void resetRoster(List<Child> students) {
    final Map<String, String> initial = {};
    for (final s in students) {
      initial[s.id] = 'pending';
    }
    state = initial;
  }
}

/// Driver Trip Lifecycle Notifier
class DriverActiveTripNotifier extends StateNotifier<AsyncValue<Trip?>> {
  final DriverRepository _repository;
  final LocationService _locationService;
  final Ref _ref;
  StreamSubscription<Position>? _gpsSubscription;
  bool _isBroadcasting = false;

  DriverActiveTripNotifier(
    this._repository,
    this._locationService,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    _initOngoingTrip();
  }

  bool get isBroadcasting => _isBroadcasting;

  Future<void> _initOngoingTrip() async {
    try {
      final bundle = await _ref.read(currentDriverBundleProvider.future);
      if (bundle == null || bundle.bus == null) {
        state = const AsyncValue.data(null);
        return;
      }

      final ongoing = await _repository.getOngoingTrip(bundle.bus!.id);
      state = AsyncValue.data(ongoing);

      if (ongoing != null && ongoing.status == TripStatus.active) {
        _startGpsBroadcasting(ongoing.id);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Starts a new active trip
  Future<void> startTrip() async {
    final bundle = _ref.read(currentDriverBundleProvider).value;
    if (bundle == null || bundle.bus == null) return;

    state = const AsyncValue.loading();
    try {
      final trip = await _repository.startTrip(
        organizationId: bundle.driver.organizationId,
        busId: bundle.bus!.id,
        driverId: bundle.driver.id,
      );

      // Reset student manifest
      final students = await _repository.getStudentsForBus(bundle.bus!.id);
      _ref.read(passengerStatusProvider.notifier).resetRoster(students);

      state = AsyncValue.data(trip);
      _startGpsBroadcasting(trip.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Toggles GPS broadcasting pause/resume without destroying active trip
  void toggleGpsBroadcasting() {
    final trip = state.value;
    if (trip == null) return;

    if (_isBroadcasting) {
      _stopGpsBroadcasting();
    } else {
      _startGpsBroadcasting(trip.id);
    }
    // Trigger UI refresh
    state = AsyncValue.data(trip);
  }

  /// Completes and ends a trip
  Future<void> endTrip() async {
    final currentTrip = state.value;
    if (currentTrip == null) return;

    try {
      _stopGpsBroadcasting();
      final updated = await _repository.updateTripStatus(
        tripId: currentTrip.id,
        status: TripStatus.completed,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Triggers emergency broadcast or targeted parent alert
  Future<void> triggerEmergency(
    String title,
    String description, {
    bool isDelay = false,
    String? targetParentProfileId,
    String? targetChildId,
  }) async {
    final currentTrip = state.value;
    final bundle = _ref.read(currentDriverBundleProvider).value;
    if (currentTrip == null || bundle == null) return;

    try {
      await _repository.triggerEmergencyAlert(
        organizationId: bundle.driver.organizationId,
        tripId: currentTrip.id,
        busId: bundle.bus?.id ?? '',
        title: title,
        description: description,
        isDelay: isDelay,
        targetParentProfileId: targetParentProfileId,
        targetChildId: targetChildId,
      );
    } catch (e) {
      AppLogger.error('Failed to dispatch emergency', error: e);
    }
  }

  void _startGpsBroadcasting(String tripId) {
    _gpsSubscription?.cancel();
    _isBroadcasting = true;

    final stream = _locationService.startLocationStream(
      distanceFilterMeters: 5,
      intervalSeconds: 3,
    );

    _gpsSubscription = stream.listen((position) {
      // 1. Update live trip location in trips table
      _repository.updateTripLocation(
        tripId: tripId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed > 0 ? (position.speed * 3.6) : 0, // Convert m/s to km/h
        heading: position.heading,
        accuracy: position.accuracy,
      );

      // 2. Record breadcrumb in trip_location_history
      _repository.recordLocationHistory(
        tripId: tripId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed > 0 ? (position.speed * 3.6) : 0,
        heading: position.heading,
        accuracy: position.accuracy,
      );
    });
  }

  void _stopGpsBroadcasting() {
    _isBroadcasting = false;
    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _locationService.stopLocationStream();
  }

  @override
  void dispose() {
    _stopGpsBroadcasting();
    super.dispose();
  }
}

final driverActiveTripProvider =
    StateNotifierProvider<DriverActiveTripNotifier, AsyncValue<Trip?>>((ref) {
  final repo = ref.watch(driverRepositoryProvider);
  final locationService = ref.watch(locationServiceProvider);
  return DriverActiveTripNotifier(repo, locationService, ref);
});
