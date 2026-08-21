import '../constants/app_constants.dart';
import '../constants/enums.dart';
import '../models/bus.dart';
import '../models/profile.dart';
import '../models/trip.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

/// Active trip telemetry bundle combining trip, bus details, and driver info.
class ActiveTripDetails {
  final Trip trip;
  final Bus? bus;
  final Profile? driverProfile;

  const ActiveTripDetails({
    required this.trip,
    this.bus,
    this.driverProfile,
  });
}

/// Repository for trip tracking and telemetry operations.
class TripRepository {
  TripRepository();

  /// Fetches the current active or recent trip for a given bus ID.
  Future<Trip?> getActiveTripForBus(String busId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableTrips)
          .select()
          .eq('bus_id', busId)
          .inFilter('status', [
            TripStatus.starting.toDbValue(),
            TripStatus.active.toDbValue(),
            TripStatus.stale.toDbValue(),
          ])
          .order('created_at', ascending: false)
          .maybeSingle();

      if (response == null) return null;
      return Trip.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get active trip for bus: $busId',
          error: e, context: 'TripRepository');
      rethrow;
    }
  }

  /// Fetches the most recent trip for a bus (even if completed), for history/status display.
  Future<Trip?> getLatestTripForBus(String busId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableTrips)
          .select()
          .eq('bus_id', busId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return Trip.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get latest trip for bus: $busId',
          error: e, context: 'TripRepository');
      rethrow;
    }
  }

  /// Streams realtime updates for a specific trip (coordinates, speed, heading, status).
  Stream<Trip?> watchTrip(String tripId) {
    return SupabaseService.client
        .from(AppConstants.tableTrips)
        .stream(primaryKey: ['id'])
        .eq('id', tripId)
        .map((records) {
          if (records.isEmpty) return null;
          return Trip.fromJson(records.first);
        });
  }

  /// Streams active trips for a specific bus with real-time 2-second polling.
  Stream<Trip?> watchActiveTripForBus(String busId) async* {
    while (true) {
      try {
        final trip = await getActiveTripForBus(busId);
        yield trip;
      } catch (e) {
        AppLogger.warning('Poll error for bus trip $busId: $e', context: 'TripRepository');
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Fetches bus info by ID.
  Future<Bus?> getBusById(String busId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableBuses)
          .select()
          .eq('id', busId)
          .maybeSingle();

      if (response == null) return null;
      return Bus.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get bus by id: $busId',
          error: e, context: 'TripRepository');
      return null;
    }
  }

  /// Fetches driver profile by driver profile ID.
  Future<Profile?> getDriverProfile(String profileId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableProfiles)
          .select()
          .eq('id', profileId)
          .maybeSingle();

      if (response == null) return null;
      return Profile.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get driver profile by id: $profileId',
          error: e, context: 'TripRepository');
      return null;
    }
  }

  /// Bundles live trip, bus, and driver profile together.
  Future<ActiveTripDetails?> getActiveTripDetailsForBus(String busId) async {
    final trip = await getActiveTripForBus(busId) ??
        await getLatestTripForBus(busId);
    if (trip == null) return null;

    final bus = await getBusById(busId);
    Profile? driverProfile;
    if (trip.driverId.isNotEmpty) {
      driverProfile = await getDriverProfile(trip.driverId);
    }

    return ActiveTripDetails(
      trip: trip,
      bus: bus,
      driverProfile: driverProfile,
    );
  }
}
