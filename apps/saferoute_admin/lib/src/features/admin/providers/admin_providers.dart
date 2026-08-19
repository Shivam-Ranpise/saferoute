import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

/// Current organization ID for logged in admin
final currentAdminOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(currentAdminProfileProvider);
  return profile?.organizationId;
});

/// Current active organization entity
final currentOrganizationProvider =
    FutureProvider.autoDispose<Organization?>((ref) async {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return null;

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getOrganization(orgId);
});

/// Realtime Organization Fleet KPIs
final organizationStatsProvider =
    FutureProvider.autoDispose<OrganizationFleetStats>((ref) async {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return OrganizationFleetStats.empty();

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getOrganizationStats(orgId);
});

/// Realtime stream of all ongoing trips for current organization
final fleetLiveTripsStreamProvider =
    StreamProvider.autoDispose<List<ActiveTripFleetBundle>>((ref) {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return Stream.value([]);

  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchAllActiveTripsForOrg(orgId);
});

/// Buses list for current organization
final adminBusesProvider =
    FutureProvider.autoDispose<List<Bus>>((ref) async {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return [];

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getAllBuses(orgId);
});

/// Drivers list for current organization
final adminDriversProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return [];

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getAllDriversWithProfiles(orgId);
});

/// Students list for current organization
final adminStudentsProvider =
    FutureProvider.autoDispose<List<Child>>((ref) async {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return [];

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getAllStudents(orgId);
});

/// Parents list for current organization with profiles and children
final adminParentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return [];

  try {
    final res = await SupabaseService.client
        .from('parents')
        .select('*, profiles:profile_id(*), children(*)')
        .eq('organization_id', orgId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(res as List);
  } catch (e) {
    AppLogger.error('Failed to get parents with profiles',
        error: e, context: 'AdminRepository');
    return [];
  }
});

/// Notification audit logs for organization
final notificationAuditLogsProvider =
    FutureProvider.autoDispose<List<NotificationEvent>>((ref) async {
  final orgId = ref.watch(currentAdminOrgIdProvider);
  if (orgId == null) return [];

  final repo = ref.watch(adminRepositoryProvider);
  return await repo.getNotificationAuditLogs(orgId);
});
