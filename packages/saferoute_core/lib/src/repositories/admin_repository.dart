import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bus.dart';
import '../models/child.dart';
import '../models/driver.dart';
import '../models/trip.dart';
import '../constants/enums.dart';
import '../models/notification_event.dart';
import '../models/organization.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

/// Aggregated Organization Fleet KPIs
class OrganizationFleetStats {
  final int totalBuses;
  final int activeBuses;
  final int totalDrivers;
  final int totalStudents;
  final int activeTripsCount;

  const OrganizationFleetStats({
    required this.totalBuses,
    required this.activeBuses,
    required this.totalDrivers,
    required this.totalStudents,
    required this.activeTripsCount,
  });

  factory OrganizationFleetStats.empty() => const OrganizationFleetStats(
        totalBuses: 0,
        activeBuses: 0,
        totalDrivers: 0,
        totalStudents: 0,
        activeTripsCount: 0,
      );
}

/// Active Trip Bundle with Bus and Driver info
class ActiveTripFleetBundle {
  final Trip trip;
  final Bus? bus;
  final Driver? driver;
  final String? driverName;

  const ActiveTripFleetBundle({
    required this.trip,
    this.bus,
    this.driver,
    this.driverName,
  });
}

class AdminRepository {
  final SupabaseClient? _client;

  AdminRepository([SupabaseClient? client]) : _client = client;

  SupabaseClient get _db => _client ?? SupabaseService.client;

  /// Fetches real-time fleet overview statistics
  Future<OrganizationFleetStats> getOrganizationStats(String organizationId) async {
    try {
      final busesRes = await _db
          .from('buses')
          .select('id, is_active')
          .eq('organization_id', organizationId);
      final busesList = busesRes as List;
      final totalBuses = busesList.length;
      final activeBuses = busesList.where((b) => b['is_active'] == true).length;

      final driversRes = await _db
          .from('drivers')
          .select('id')
          .eq('organization_id', organizationId);
      final totalDrivers = (driversRes as List).length;

      final studentsRes = await _db
          .from('children')
          .select('id')
          .eq('organization_id', organizationId);
      final totalStudents = (studentsRes as List).length;

      final activeTripsRes = await _db
          .from('trips')
          .select('id')
          .eq('organization_id', organizationId)
          .eq('status', 'ACTIVE');
      final activeTripsCount = (activeTripsRes as List).length;

      return OrganizationFleetStats(
        totalBuses: totalBuses,
        activeBuses: activeBuses,
        totalDrivers: totalDrivers,
        totalStudents: totalStudents,
        activeTripsCount: activeTripsCount,
      );
    } catch (e) {
      AppLogger.error('Failed to get organization stats',
          error: e, context: 'AdminRepository');
      return OrganizationFleetStats.empty();
    }
  }

  /// Real-time stream of all ongoing trips for organization
  Stream<List<ActiveTripFleetBundle>> watchAllActiveTripsForOrg(
      String organizationId) {
    try {
      return _db
          .from('trips')
          .stream(primaryKey: ['id'])
          .eq('organization_id', organizationId)
          .map((rows) {
            final activeTrips = rows
                .map((r) => Trip.fromJson(r))
                .where((t) => t.status == TripStatus.active)
                .toList();

            return activeTrips.map((trip) {
              return ActiveTripFleetBundle(
                trip: trip,
                bus: null,
                driver: null,
                driverName: 'Driver Assigned',
              );
            }).toList();
          });
    } catch (e) {
      AppLogger.error('Error in watchAllActiveTripsForOrg',
          error: e, context: 'AdminRepository');
      return Stream.value([]);
    }
  }

  /// Fetches all buses belonging to the organization
  Future<List<Bus>> getAllBuses(String organizationId) async {
    try {
      final res = await _db
          .from('buses')
          .select()
          .eq('organization_id', organizationId)
          .order('bus_number', ascending: true);

      return (res as List).map((row) => Bus.fromJson(row)).toList();
    } catch (e) {
      AppLogger.error('Failed to get buses',
          error: e, context: 'AdminRepository');
      return [];
    }
  }

  /// Creates or updates a bus
  Future<Bus?> upsertBus(Bus bus) async {
    try {
      final res = await _db
          .from('buses')
          .upsert(bus.toJson())
          .select()
          .single();
      return Bus.fromJson(res);
    } catch (e) {
      AppLogger.error('Failed to upsert bus',
          error: e, context: 'AdminRepository');
      return null;
    }
  }

  /// Deletes a bus
  Future<bool> deleteBus(String busId) async {
    try {
      await _db.from('buses').delete().eq('id', busId);
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete bus',
          error: e, context: 'AdminRepository');
      return false;
    }
  }

  /// Fetches all drivers for the organization
  Future<List<Map<String, dynamic>>> getAllDriversWithProfiles(
      String organizationId) async {
    try {
      final res = await _db
          .from('drivers')
          .select('*, profiles:profile_id(*)')
          .eq('organization_id', organizationId);

      return List<Map<String, dynamic>>.from(res as List);
    } catch (e) {
      AppLogger.error('Failed to get drivers with profiles',
          error: e, context: 'AdminRepository');
      return [];
    }
  }

  /// Fetches all students enrolled in the school
  Future<List<Child>> getAllStudents(String organizationId) async {
    try {
      final res = await _db
          .from('children')
          .select()
          .eq('organization_id', organizationId)
          .order('name', ascending: true);

      return (res as List).map((row) => Child.fromJson(row)).toList();
    } catch (e) {
      AppLogger.error('Failed to get students',
          error: e, context: 'AdminRepository');
      return [];
    }
  }

  /// Creates or updates a student/child record
  Future<Child?> upsertChild(Child child) async {
    try {
      final res = await _db
          .from('children')
          .upsert(child.toJson())
          .select()
          .single();
      return Child.fromJson(res);
    } catch (e) {
      AppLogger.error('Failed to upsert student',
          error: e, context: 'AdminRepository');
      return null;
    }
  }

  /// Deletes a student/child
  Future<bool> deleteChild(String childId) async {
    try {
      await _db.from('children').delete().eq('id', childId);
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete student',
          error: e, context: 'AdminRepository');
      return false;
    }
  }

  /// Fetches notification audit logs
  Future<List<NotificationEvent>> getNotificationAuditLogs(
    String organizationId, {
    int limit = 100,
  }) async {
    try {
      final res = await _db
          .from('notification_events')
          .select()
          .eq('organization_id', organizationId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (res as List).map((row) => NotificationEvent.fromJson(row)).toList();
    } catch (e) {
      AppLogger.error('Failed to get notification logs',
          error: e, context: 'AdminRepository');
      return [];
    }
  }

  /// Fetches organization details
  Future<Organization?> getOrganization(String organizationId) async {
    try {
      final res = await _db
          .from('organizations')
          .select()
          .eq('id', organizationId)
          .maybeSingle();
      if (res == null) return null;
      return Organization.fromJson(res);
    } catch (e) {
      AppLogger.error('Failed to get organization',
          error: e, context: 'AdminRepository');
      return null;
    }
  }

  /// Updates organization safety settings and details
  Future<Organization?> updateOrganization(Organization organization) async {
    try {
      final res = await _db
          .from('organizations')
          .update(organization.toJson())
          .eq('id', organization.id)
          .select()
          .single();
      return Organization.fromJson(res);
    } catch (e) {
      AppLogger.error('Failed to update organization',
          error: e, context: 'AdminRepository');
      return null;
    }
  }
}
