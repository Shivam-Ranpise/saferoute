import '../constants/app_constants.dart';
import '../models/child.dart';
import '../models/notification_preferences.dart';
import '../models/parent.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

/// Repository for parent-specific data operations.
/// All queries are secured by RLS on Supabase and filtered by organization/parent.
class ParentRepository {
  ParentRepository();

  /// Fetches the Parent record corresponding to a profile ID.
  Future<Parent?> getParentByProfileId(String profileId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableParents)
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) return null;
      return Parent.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to get parent by profileId: $profileId',
          error: e, context: 'ParentRepository');
      rethrow;
    }
  }

  /// Fetches all active children associated with a parent.
  Future<List<Child>> getChildrenForParent(String parentId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableChildren)
          .select()
          .eq('parent_id', parentId)
          .eq('is_active', true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => Child.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error('Failed to fetch children for parent: $parentId',
          error: e, context: 'ParentRepository');
      rethrow;
    }
  }

  /// Stream active children list in realtime for a parent with fallback to REST query.
  Stream<List<Child>> watchChildrenForParent(String parentId) {
    try {
      return SupabaseService.client
          .from(AppConstants.tableChildren)
          .stream(primaryKey: ['id'])
          .eq('parent_id', parentId)
          .map((records) => records
              .map((json) => Child.fromJson(json))
              .where((child) => child.isActive)
              .toList())
          .handleError((error) async* {
            AppLogger.error('Realtime subscription error on children, falling back to REST: $error',
                context: 'ParentRepository');
            final direct = await getChildrenForParent(parentId);
            yield direct;
          });
    } catch (e) {
      AppLogger.error('Realtime stream setup error, falling back to REST query',
          error: e, context: 'ParentRepository');
      return Stream.fromFuture(getChildrenForParent(parentId));
    }
  }

  /// Updates a child's designated pickup location and notification distance.
  Future<Child> updateChildPickupLocation({
    required String childId,
    required double latitude,
    required double longitude,
    String? pickupName,
    String? pickupAddress,
    required int notificationDistanceMeters,
  }) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableChildren)
          .update({
            'pickup_latitude': latitude,
            'pickup_longitude': longitude,
            'pickup_name': pickupName,
            'pickup_address': pickupAddress,
            'notification_distance_meters': notificationDistanceMeters,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', childId)
          .select()
          .single();

      AppLogger.info('Updated pickup location for child: $childId',
          context: 'ParentRepository');
      return Child.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to update pickup location for child: $childId',
          error: e, context: 'ParentRepository');
      rethrow;
    }
  }

  /// Fetches notification channel preferences for a parent.
  Future<NotificationPreferences?> getNotificationPreferences(
      String parentId) async {
    try {
      final response = await SupabaseService.client
          .from(AppConstants.tableNotificationPreferences)
          .select()
          .eq('parent_id', parentId)
          .maybeSingle();

      if (response == null) return null;
      return NotificationPreferences.fromJson(response);
    } catch (e) {
      AppLogger.error(
          'Failed to get notification preferences for parent: $parentId',
          error: e,
          context: 'ParentRepository');
      rethrow;
    }
  }

  /// Updates or creates notification preferences for a parent.
  Future<NotificationPreferences> upsertNotificationPreferences({
    required String parentId,
    required bool pushEnabled,
    required bool whatsappEnabled,
    required bool smsEnabled,
  }) async {
    try {
      final existing = await getNotificationPreferences(parentId);
      final now = DateTime.now().toIso8601String();

      Map<String, dynamic> response;
      if (existing == null) {
        response = await SupabaseService.client
            .from(AppConstants.tableNotificationPreferences)
            .insert({
              'parent_id': parentId,
              'push_enabled': pushEnabled,
              'whatsapp_enabled': whatsappEnabled,
              'sms_enabled': smsEnabled,
              'updated_at': now,
            })
            .select()
            .single();
      } else {
        response = await SupabaseService.client
            .from(AppConstants.tableNotificationPreferences)
            .update({
              'push_enabled': pushEnabled,
              'whatsapp_enabled': whatsappEnabled,
              'sms_enabled': smsEnabled,
              'updated_at': now,
            })
            .eq('id', existing.id)
            .select()
            .single();
      }

      AppLogger.info('Updated notification preferences for parent: $parentId',
          context: 'ParentRepository');
      return NotificationPreferences.fromJson(response);
    } catch (e) {
      AppLogger.error(
          'Failed to upsert notification preferences for parent: $parentId',
          error: e,
          context: 'ParentRepository');
      rethrow;
    }
  }
}
