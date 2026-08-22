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

      // Dynamically determine morning vs evening based on school opening & closing schedule
      try {
        final bool isMorning = await _isMorningRoute(organizationId);

        final String title = isMorning
            ? 'Morning Bus Route Started'
            : 'Evening Bus Route Started';
        final String message = isMorning
            ? 'The school bus will arrive soon. Please be ready at your pickup stop.'
            : 'The school bus has left the school. Please be ready at your drop-off stop.';

        final driverProfileId = SupabaseService.client.auth.currentUser?.id;
        final eventRes = await SupabaseService.client
            .from(AppConstants.tableNotificationEvents)
            .insert({
              'organization_id': organizationId,
              'event_type': 'TRIP_STARTED',
              'title': title,
              'message': message,
              'trip_id': trip.id,
              'priority': 'NORMAL', // DB enum: NORMAL | HIGH | EMERGENCY
              if (driverProfileId != null) 'sender_profile_id': driverProfileId,
            })
            .select()
            .single();

        final eventId = eventRes['id'] as String;
        await _dispatchDeliveriesForEvent(
          organizationId: organizationId,
          eventId: eventId,
          busId: busId,
        );
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

      // Morning only: Notify parents that bus arrived safely at school
      if (status == TripStatus.completed) {
        final bool isMorning = await _isMorningRoute(trip.organizationId);

        if (isMorning) {
          try {
            final driverProfileId = SupabaseService.client.auth.currentUser?.id;
            final eventRes = await SupabaseService.client
                .from(AppConstants.tableNotificationEvents)
                .insert({
                  'organization_id': trip.organizationId,
                  'event_type': 'TRIP_COMPLETED',
                  'title': 'Bus Arrived at School',
                  'message': 'The school bus has safely arrived at the school campus.',
                  'trip_id': tripId,
                  'priority': 'NORMAL',
                  if (driverProfileId != null) 'sender_profile_id': driverProfileId,
                })
                .select()
                .single();

            final eventId = eventRes['id'] as String;
            await _dispatchDeliveriesForEvent(
              organizationId: trip.organizationId,
              eventId: eventId,
              busId: trip.busId,
            );
          } catch (ne) {
            AppLogger.warning('Failed to log morning TRIP_COMPLETED notification event: $ne');
          }
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

  /// Triggers an emergency notification event linked to the trip and delivers to parents.
  Future<void> triggerEmergencyAlert({
    required String organizationId,
    required String tripId,
    required String busId,
    required String title,
    required String description,
    bool isDelay = false,
    String? targetParentProfileId,
    String? targetChildId,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final driverProfileId = SupabaseService.client.auth.currentUser?.id;
      // DB enum: notification_priority = ('NORMAL', 'HIGH', 'EMERGENCY')
      final eventRes = await SupabaseService.client
          .from(AppConstants.tableNotificationEvents)
          .insert({
            'organization_id': organizationId,
            'event_type': isDelay ? 'BUS_DELAY' : 'EMERGENCY',
            'title': title,
            'message': description,
            'trip_id': tripId,
            'priority': isDelay ? 'NORMAL' : 'EMERGENCY',
            if (driverProfileId != null) 'sender_profile_id': driverProfileId,
            'created_at': now,
          })
          .select()
          .single();

      final eventId = eventRes['id'] as String;

      if (targetParentProfileId != null && targetParentProfileId.isNotEmpty) {
        // Targeted delivery to one specific parent profile
        // DB columns: notification_event_id, organization_id, recipient_profile_id, channel, status, created_at
        await SupabaseService.client
            .from(AppConstants.tableNotificationDeliveries)
            .insert({
              'notification_event_id': eventId,
              'organization_id': organizationId,
              'recipient_profile_id': targetParentProfileId,
              'channel': 'PUSH',
              'status': 'SENT',
            });

        try {
          await SupabaseService.client.functions.invoke(
            'push-dispatch',
            body: {
              'event_id': eventId,
              'organization_id': organizationId,
              'bus_id': busId,
              'title': title,
              'message': description,
              'event_type': isDelay ? 'BUS_DELAY' : 'EMERGENCY',
              'sender_profile_id': driverProfileId,
            },
          );
          AppLogger.info('push-dispatch invoked for targeted parent $targetParentProfileId', context: 'DriverRepository');
        } catch (pushErr) {
          AppLogger.warning('push-dispatch invocation error: $pushErr', context: 'DriverRepository');
        }
      } else {
        // Broadcast to all enrolled parents of this bus
        await _dispatchDeliveriesForEvent(
          organizationId: organizationId,
          eventId: eventId,
          busId: busId,
        );
      }

      AppLogger.info(
        'Alert triggered for trip: $tripId (isDelay: $isDelay, targetParent: $targetParentProfileId)',
        context: 'DriverRepository',
      );
    } catch (e) {
      AppLogger.error('Failed to trigger alert: $tripId', error: e, context: 'DriverRepository');
      rethrow;
    }
  }

  /// Dispatches notification delivery records for an event to all parents of the bus/organization.
  Future<void> _dispatchDeliveriesForEvent({
    required String organizationId,
    required String eventId,
    String? busId,
  }) async {
    try {
      final Set<String> recipientProfileIds = {};

      final currentDriverId = SupabaseService.client.auth.currentUser?.id;

      // Step 1: try finding parents whose children are on this bus
      if (busId != null && busId.isNotEmpty) {
        try {
          final childrenRes = await SupabaseService.client
              .from(AppConstants.tableChildren)
              .select('parent_id')
              .eq('bus_id', busId)
              .eq('is_active', true);

          final parentIds = (childrenRes as List)
              .map((c) => c['parent_id'] as String?)
              .whereType<String>()
              .toSet();

          if (parentIds.isNotEmpty) {
            final parentsRes = await SupabaseService.client
                .from(AppConstants.tableParents)
                .select('id, profile_id')
                .inFilter('id', parentIds.toList());

            for (final p in (parentsRes as List)) {
              final pid = p['profile_id'] as String?;
              if (pid != null && pid.isNotEmpty && pid != currentDriverId) {
                recipientProfileIds.add(pid);
              }
            }
          }
        } catch (cErr) {
          AppLogger.warning('Could not query children for bus $busId: $cErr', context: 'DriverRepository');
        }
      }

      // Step 2: fallback — all parents in the org if none found via bus
      if (recipientProfileIds.isEmpty) {
        try {
          final parentsRes = await SupabaseService.client
              .from(AppConstants.tableParents)
              .select('id, profile_id')
              .eq('organization_id', organizationId);

          for (final p in (parentsRes as List)) {
            final pid = p['profile_id'] as String?;
            if (pid != null && pid.isNotEmpty && pid != currentDriverId) {
              recipientProfileIds.add(pid);
            }
          }
        } catch (pErr) {
          AppLogger.warning('Could not query org parents: $pErr', context: 'DriverRepository');
        }
      }

      if (recipientProfileIds.isEmpty) {
        AppLogger.warning('No parent recipients found for event $eventId', context: 'DriverRepository');
        return;
      }

      // Step 3: batch insert deliveries — one row per parent
      // Schema columns: notification_event_id, organization_id, recipient_profile_id, channel, status
      // recipient_profile_id is NOT NULL — no null/broadcast rows allowed
      final deliveries = recipientProfileIds.map((profileId) => {
        'notification_event_id': eventId,
        'organization_id': organizationId,
        'recipient_profile_id': profileId,
        'channel': 'PUSH',
        'status': 'SENT',
      }).toList();

      await SupabaseService.client
          .from(AppConstants.tableNotificationDeliveries)
          .insert(deliveries);

      AppLogger.info(
        'Dispatched ${deliveries.length} deliveries for event $eventId (busId: $busId)',
        context: 'DriverRepository',
      );

      // Invoke Supabase Edge Function to deliver FCM Push to parent devices
      try {
        await SupabaseService.client.functions.invoke(
          'push-dispatch',
          body: {
            'event_id': eventId,
            'organization_id': organizationId,
            'bus_id': busId,
            'sender_profile_id': currentDriverId,
          },
        );
        AppLogger.info('Triggered FCM push-dispatch for event $eventId', context: 'DriverRepository');
      } catch (pushErr) {
        AppLogger.warning('push-dispatch invocation note: $pushErr', context: 'DriverRepository');
      }
    } catch (delErr) {
      AppLogger.warning(
        'Could not fan out deliveries for event $eventId: $delErr',
        context: 'DriverRepository',
      );
    }
  }

  /// Determines whether the current time corresponds to the Morning pickup route
  /// vs Evening return route based on school opening and closing schedule in the organization.
  Future<bool> _isMorningRoute(String organizationId) async {
    try {
      final orgRes = await SupabaseService.client
          .from('organizations')
          .select('api_parameters')
          .eq('id', organizationId)
          .maybeSingle();

      final schedule = orgRes?['api_parameters']?['school_schedule'];
      if (schedule != null && schedule is Map) {
        final startTimeStr = schedule['start_time'] as String?;
        final endTimeStr = schedule['end_time'] as String?;

        if (startTimeStr != null && endTimeStr != null) {
          final startParts = startTimeStr.split(':').map((s) => int.tryParse(s) ?? 0).toList();
          final endParts = endTimeStr.split(':').map((s) => int.tryParse(s) ?? 0).toList();

          final startMinutes = (startParts.isNotEmpty ? startParts[0] : 8) * 60 + (startParts.length > 1 ? startParts[1] : 0);
          final endMinutes = (endParts.isNotEmpty ? endParts[0] : 17) * 60 + (endParts.length > 1 ? endParts[1] : 0);

          // Midpoint between opening hours and closing hours
          final midpoint = (startMinutes + endMinutes) / 2.0;
          final now = DateTime.now();
          final currentMinutes = now.hour * 60 + now.minute;

          AppLogger.info(
            'School Schedule -> Open: $startTimeStr, Close: $endTimeStr, Midpoint: ${midpoint / 60}h, Current: ${now.hour}:${now.minute} -> ${currentMinutes <= midpoint ? "MORNING" : "EVENING"}',
            context: 'DriverRepository',
          );

          return currentMinutes <= midpoint;
        }
      }
    } catch (e) {
      AppLogger.warning('Error reading school schedule: $e', context: 'DriverRepository');
    }

    // Default fallback if no school schedule is configured
    return DateTime.now().hour < 12;
  }
}
