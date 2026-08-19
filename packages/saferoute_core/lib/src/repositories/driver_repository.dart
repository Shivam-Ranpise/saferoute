import '../constants/app_constants.dart';
import '../constants/enums.dart';
import '../models/bus.dart';
import '../models/child.dart';
import '../models/driver.dart';
import '../models/trip.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

/// Repository for driver and live trip operations.
class DriverRepository {
  DriverRepository();

  /// Fetches driver record from profile ID.
  Future<Driver?> getDriverByProfileId(String profileId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableDrivers)
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) return null;
      return Driver.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to fetch driver by profileId: $profileId',
          error: e, context: 'DriverRepository');
      rethrow;
    }
  }

  /// Fetches the bus assigned to a driver.
  Future<Bus?> getAssignedBusForDriver(String driverId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableBuses)
          .select()
          .eq('current_driver_id', driverId)
          .maybeSingle();

      if (response == null) return null;
      return Bus.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to fetch assigned bus for driver: $driverId',
          error: e, context: 'DriverRepository');
      rethrow;
    }
  }

  /// Fetches active student roster for a bus.
  Future<List<Child>> getStudentsForBus(String busId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableChildren)
          .select()
          .eq('bus_id', busId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Child.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch students for bus: $busId',
          error: e, context: 'DriverRepository');
      rethrow;
    }
  }

  /// Fetches currently active or starting trip for a bus.
  Future<Trip?> getOngoingTrip(String busId) async {
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
      AppLogger.error('Failed to get ongoing trip for bus: $busId',
          error: e, context: 'DriverRepository');
      rethrow;
    }
  }

  /// Starts a new trip for a bus.
  Future<Trip> startTrip({
    required String organizationId,
    required String busId,
    required String driverId,
  }) async {
    try {
      final now = DateTime.now();
      final response = await SupabaseService.client
          .from(AppConstants.tableTrips)
          .insert({
            'organization_id': organizationId,
            'bus_id': busId,
            'driver_id': driverId,
            'status': TripStatus.active.toDbValue(),
            'started_at': now.toIso8601String(),
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .select()
          .single();

      AppLogger.info('Trip started successfully: ${response['id']}',
          context: 'DriverRepository');
      final trip = Trip.fromJson(response);

      // Dynamically determine morning vs evening based on organization school schedule or hour
      try {
        final orgRes = await SupabaseService.client
            .from(AppConstants.tableOrganizations)
            .select('school_schedule')
            .eq('id', organizationId)
            .maybeSingle();

        String title = 'School Bus Started';
        String message = 'The school bus has started its route and will arrive soon. Please be ready at your pickup stop.';

        int currentHour = now.hour;
        int morningCutoff = 12;

        if (orgRes != null && orgRes['school_schedule'] != null) {
          final schedule = orgRes['school_schedule'] as Map<String, dynamic>;
          final startTimeStr = schedule['start_time'] as String? ?? '10:00';
          final parts = startTimeStr.split(':');
          if (parts.isNotEmpty) {
            final startH = int.tryParse(parts[0]);
            if (startH != null) {
              morningCutoff = (startH + 2).clamp(10, 14);
            }
          }
        }

        if (currentHour >= morningCutoff) {
          // Evening / Afternoon return trip
          title = 'Evening Bus Route Started';
          message = 'The school bus has started its return route from school. Please be ready at your drop-off stop.';
        } else {
          // Morning pickup trip
          title = 'Morning Bus Route Started';
          message = 'The school bus has started its route and will arrive soon. Please be ready at your pickup stop.';
        }

        await SupabaseService.client
            .from(AppConstants.tableNotificationEvents)
            .insert({
              'organization_id': organizationId,
              'event_type': 'TRIP_STARTED',
              'title': title,
              'message': message,
              'trip_id': trip.id,
              'priority': 'STANDARD',
              'created_at': now.toIso8601String(),
            });
      } catch (ne) {
        AppLogger.warning('Failed to log TRIP_STARTED notification event: $ne');
      }

      return trip;
    } catch (e) {
      AppLogger.error('Failed to start trip for bus: $busId',
          error: e, context: 'DriverRepository');
      rethrow;
    }
  }

  /// Updates trip status (e.g. paused, completed, cancelled).
  Future<Trip> updateTripStatus({
    required String tripId,
    required TripStatus status,
  }) async {
    try {
      final now = DateTime.now();
      final updateData = <String, dynamic>{
        'status': status.toDbValue(),
        'updated_at': now.toIso8601String(),
      };

      if (status == TripStatus.completed || status == TripStatus.cancelled) {
        updateData['ended_at'] = now.toIso8601String();
      }

      final response = await SupabaseService.client
          .from(AppConstants.tableTrips)
          .update(updateData)
          .eq('id', tripId)
          .select()
          .single();

      final trip = Trip.fromJson(response);

      // If completing trip, log contextual arrival notification based on school schedule
      if (status == TripStatus.completed) {
        try {
          final orgRes = await SupabaseService.client
              .from(AppConstants.tableOrganizations)
              .select('school_schedule')
              .eq('id', trip.organizationId)
              .maybeSingle();

          String title = 'Bus Arrived at School';
          String message = 'The school bus has safely arrived at the school campus.';

          int currentHour = now.hour;
          int morningCutoff = 13;

          if (orgRes != null && orgRes['school_schedule'] != null) {
            final schedule = orgRes['school_schedule'] as Map<String, dynamic>;
            final startTimeStr = schedule['start_time'] as String? ?? '10:00';
            final parts = startTimeStr.split(':');
            if (parts.isNotEmpty) {
              final startH = int.tryParse(parts[0]);
              if (startH != null) {
                morningCutoff = (startH + 3).clamp(11, 15);
              }
            }
          }

          if (currentHour >= morningCutoff) {
            // Afternoon / Evening route completion
            title = 'Bus Trip Completed';
            message = 'The school bus has safely completed its evening drop-off route.';
          } else {
            // Morning route completion
            title = 'Bus Arrived at School';
            message = 'The school bus has safely arrived at the school campus.';
          }

          await SupabaseService.client
              .from(AppConstants.tableNotificationEvents)
              .insert({
                'organization_id': trip.organizationId,
                'event_type': 'TRIP_COMPLETED',
                'title': title,
                'message': message,
                'trip_id': tripId,
                'priority': 'STANDARD',
                'created_at': now.toIso8601String(),
              });
        } catch (ne) {
          AppLogger.warning('Failed to log TRIP_COMPLETED notification event: $ne');
        }
      }

      AppLogger.info('Trip status updated to $status for trip: $tripId',
          context: 'DriverRepository');
      return trip;
    } catch (e) {
      AppLogger.error('Failed to update trip status: $tripId',
          error: e, context: 'DriverRepository');
      rethrow;
    }
  }

  /// Broadcasts live telemetry (lat, lon, speed, heading, accuracy) to Supabase.
  Future<void> updateTripLocation({
    required String tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      await SupabaseService.client
          .from(AppConstants.tableTrips)
          .update({
            'current_latitude': latitude,
            'current_longitude': longitude,
            'current_speed': speed,
            'current_heading': heading,
            'current_accuracy': accuracy,
            'last_location_at': now,
            'status': TripStatus.active.toDbValue(),
            'updated_at': now,
          })
          .eq('id', tripId);
    } catch (e) {
      AppLogger.error('Failed to broadcast trip location: $tripId',
          error: e, context: 'DriverRepository');
    }
  }

  /// Appends GPS breadcrumb to trip_location_history.
  Future<void> recordLocationHistory({
    required String tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
    double? accuracy,
  }) async {
    try {
      await SupabaseService.client
          .from(AppConstants.tableTripLocationHistory)
          .insert({
            'trip_id': tripId,
            'latitude': latitude,
            'longitude': longitude,
            'speed': speed,
            'heading': heading,
            'accuracy': accuracy,
            'recorded_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      AppLogger.error('Failed to record location history for trip: $tripId',
          error: e, context: 'DriverRepository');
    }
  }

  /// Triggers an emergency notification event linked to the trip.
  Future<void> triggerEmergencyAlert({
    required String organizationId,
    required String tripId,
    required String title,
    required String description,
  }) async {
    try {
      await SupabaseService.client
          .from(AppConstants.tableNotificationEvents)
          .insert({
            'organization_id': organizationId,
            'event_type': 'EMERGENCY',
            'title': title,
            'message': description,
            'trip_id': tripId,
            'priority': 'URGENT',
            'created_at': DateTime.now().toIso8601String(),
          });

      AppLogger.info('Emergency alert triggered for trip: $tripId',
          context: 'DriverRepository');
    } catch (e) {
      AppLogger.error('Failed to trigger emergency alert: $tripId',
          error: e, context: 'DriverRepository');
      rethrow;
    }
  }
}
