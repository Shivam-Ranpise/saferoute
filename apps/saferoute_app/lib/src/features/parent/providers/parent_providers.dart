import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';

/// Repository Providers
final parentRepositoryProvider = Provider<ParentRepository>((ref) {
  return ParentRepository();
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

/// Parent record for current profile
final currentParentRecordProvider = FutureProvider<Parent?>((ref) async {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) return null;
  final parentRepo = ref.watch(parentRepositoryProvider);
  return await parentRepo.getParentByProfileId(profile.id);
});

/// Stream of children registered under this parent
final parentChildrenStreamProvider = StreamProvider<List<Child>>((ref) {
  final parentAsync = ref.watch(currentParentRecordProvider);
  final parent = parentAsync.value;
  if (parent == null) return Stream.value([]);
  final parentRepo = ref.watch(parentRepositoryProvider);
  return parentRepo.watchChildrenForParent(parent.id);
});

/// Selected Child ID state
final selectedChildIdProvider = StateProvider<String?>((ref) {
  final childrenAsync = ref.watch(parentChildrenStreamProvider);
  final children = childrenAsync.value ?? [];
  if (children.isNotEmpty) return children.first.id;
  return null;
});

/// Selected Child object
final selectedChildProvider = Provider<Child?>((ref) {
  final children = ref.watch(parentChildrenStreamProvider).value ?? [];
  final selectedId = ref.watch(selectedChildIdProvider);
  if (children.isEmpty) return null;
  if (selectedId == null) return children.first;
  return children.firstWhere(
    (c) => c.id == selectedId,
    orElse: () => children.first,
  );
});

/// Stream of the active trip for the selected child's bus
final selectedChildTripStreamProvider = StreamProvider<Trip?>((ref) {
  final child = ref.watch(selectedChildProvider);
  if (child == null || child.busId == null || child.busId!.isEmpty) {
    return Stream.value(null);
  }
  final tripRepo = ref.watch(tripRepositoryProvider);
  return tripRepo.watchActiveTripForBus(child.busId!);
});

/// Bus details for the selected child's bus
final selectedChildBusProvider = FutureProvider<Bus?>((ref) async {
  final child = ref.watch(selectedChildProvider);
  if (child == null || child.busId == null || child.busId!.isEmpty) return null;
  final tripRepo = ref.watch(tripRepositoryProvider);
  return await tripRepo.getBusById(child.busId!);
});

/// Driver profile for active trip
final selectedChildDriverProfileProvider =
    FutureProvider<Profile?>((ref) async {
  final trip = ref.watch(selectedChildTripStreamProvider).value;
  if (trip == null || trip.driverId.isEmpty) return null;
  final tripRepo = ref.watch(tripRepositoryProvider);
  return await tripRepo.getDriverProfile(trip.driverId);
});

/// Destination Arrival and Auto-Stop Tracking State
class DestinationArrivalState {
  final bool isArrived;
  final int secondsRemaining;
  final bool isTrackingStopped;

  const DestinationArrivalState({
    this.isArrived = false,
    this.secondsRemaining = 10,
    this.isTrackingStopped = false,
  });
}

class DestinationArrivalNotifier extends StateNotifier<DestinationArrivalState> {
  Timer? _timer;
  String? _currentTripId;

  DestinationArrivalNotifier() : super(const DestinationArrivalState());

  void checkDistance(double distanceMeters, String tripId) {
    if (_currentTripId != tripId) {
      _currentTripId = tripId;
      _timer?.cancel();
      state = const DestinationArrivalState();
    }

    // Destination reached within 1-5 meters (using 5m threshold)
    if (distanceMeters <= 5.0 && !state.isArrived && !state.isTrackingStopped) {
      state = const DestinationArrivalState(
        isArrived: true,
        secondsRemaining: 10,
        isTrackingStopped: false,
      );

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.secondsRemaining > 1) {
          state = DestinationArrivalState(
            isArrived: true,
            secondsRemaining: state.secondsRemaining - 1,
            isTrackingStopped: false,
          );
        } else {
          timer.cancel();
          state = const DestinationArrivalState(
            isArrived: true,
            secondsRemaining: 0,
            isTrackingStopped: true,
          );
        }
      });
    }
  }

  void reset() {
    _timer?.cancel();
    state = const DestinationArrivalState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final destinationArrivalProvider =
    StateNotifierProvider<DestinationArrivalNotifier, DestinationArrivalState>((ref) {
  return DestinationArrivalNotifier();
});

/// Computed Bus Telemetry state for Parent UI
class BusTelemetryState {
  final Trip? trip;
  final double? distanceMeters;
  final String formattedDistance;
  final ProximityState proximityState;
  final int? estimatedMinutes;
  final bool isStale;
  final bool hasOngoingTrip;
  final bool hasLocation;
  final bool isArrivedAtDestination;
  final int arrivalCountdownSeconds;
  final bool isTrackingStopped;

  const BusTelemetryState({
    this.trip,
    this.distanceMeters,
    required this.formattedDistance,
    required this.proximityState,
    this.estimatedMinutes,
    required this.isStale,
    required this.hasOngoingTrip,
    required this.hasLocation,
    this.isArrivedAtDestination = false,
    this.arrivalCountdownSeconds = 10,
    this.isTrackingStopped = false,
  });

  factory BusTelemetryState.idle() => const BusTelemetryState(
        formattedDistance: '--',
        proximityState: ProximityState.outside,
        isStale: false,
        hasOngoingTrip: false,
        hasLocation: false,
      );
}

/// Live computed telemetry provider combining trip GPS coordinates & child pickup point
final busTelemetryProvider = Provider<BusTelemetryState>((ref) {
  final trip = ref.watch(selectedChildTripStreamProvider).value;
  final child = ref.watch(selectedChildProvider);
  final arrivalState = ref.watch(destinationArrivalProvider);

  if (trip == null || !trip.isOngoing) {
    return BusTelemetryState.idle();
  }

  final hasLocation = trip.hasLocation;
  if (!hasLocation || child == null || !child.hasPickupLocation) {
    return BusTelemetryState(
      trip: trip,
      formattedDistance: '--',
      proximityState: ProximityState.outside,
      isStale: trip.status == TripStatus.stale,
      hasOngoingTrip: true,
      hasLocation: hasLocation,
      isArrivedAtDestination: arrivalState.isArrived,
      arrivalCountdownSeconds: arrivalState.secondsRemaining,
      isTrackingStopped: arrivalState.isTrackingStopped,
    );
  }

  // Calculate Haversine distance from bus to child's pickup point
  final distanceMeters = Haversine.distanceMeters(
    lat1: trip.currentLatitude!,
    lon1: trip.currentLongitude!,
    lat2: child.pickupLatitude!,
    lon2: child.pickupLongitude!,
  );

  // Trigger 10-second countdown when near destination (1-5 meters)
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(destinationArrivalProvider.notifier).checkDistance(distanceMeters, trip.id);
  });

  final threshold = child.notificationDistanceMeters.toDouble();
  const buffer = 200.0; // 200m buffer for approaching zone

  ProximityState proxState;
  if (distanceMeters <= 50) {
    proxState = ProximityState.locked;
  } else if (distanceMeters <= threshold) {
    proxState = ProximityState.enteredRadius;
  } else if (distanceMeters <= threshold + buffer) {
    proxState = ProximityState.approaching;
  } else {
    proxState = ProximityState.outside;
  }

  // Calculate ETA (urban bus assumed ~25 km/h if currentSpeed is null or slow)
  final speedKmh = (trip.currentSpeed != null && trip.currentSpeed! > 5)
      ? trip.currentSpeed!
      : 25.0;
  final speedMps = speedKmh * 1000 / 3600;
  final etaMinutes = (distanceMeters / speedMps / 60).ceil().clamp(1, 120);

  final isStale = trip.status == TripStatus.stale ||
      (trip.lastLocationAt != null &&
          DateTime.now().difference(trip.lastLocationAt!).inSeconds >
              AppConfig.staleTripTimeoutSeconds);

  return BusTelemetryState(
    trip: trip,
    distanceMeters: distanceMeters,
    formattedDistance: Haversine.formatDistance(distanceMeters),
    proximityState: proxState,
    estimatedMinutes: etaMinutes,
    isStale: isStale,
    hasOngoingTrip: true,
    hasLocation: true,
    isArrivedAtDestination: arrivalState.isArrived,
    arrivalCountdownSeconds: arrivalState.secondsRemaining,
    isTrackingStopped: arrivalState.isTrackingStopped,
  );
});

/// Parent notification channel preferences state notifier
class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<NotificationPreferences?>> {
  final ParentRepository _repository;
  final String? _parentId;

  NotificationPreferencesNotifier(this._repository, this._parentId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    final parentId = _parentId;
    if (parentId == null) {
      state = const AsyncValue.data(null);
      return;
    }
    try {
      final prefs = await _repository.getNotificationPreferences(parentId);
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updatePreferences({
    required bool pushEnabled,
    required bool whatsappEnabled,
    required bool smsEnabled,
  }) async {
    final parentId = _parentId;
    if (parentId == null) return;
    state = const AsyncValue.loading();
    try {
      final updated = await _repository.upsertNotificationPreferences(
        parentId: parentId,
        pushEnabled: pushEnabled,
        whatsappEnabled: whatsappEnabled,
        smsEnabled: smsEnabled,
      );
      state = AsyncValue.data(updated);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationPreferencesProvider = StateNotifierProvider<
    NotificationPreferencesNotifier, AsyncValue<NotificationPreferences?>>((ref) {
  final repo = ref.watch(parentRepositoryProvider);
  final parent = ref.watch(currentParentRecordProvider).value;
  return NotificationPreferencesNotifier(repo, parent?.id);
});
