import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/enums.dart';
import '../models/device_token.dart';
import '../models/notification_delivery.dart';
import '../models/notification_event.dart';
import '../services/supabase_service.dart';
import '../utils/logger.dart';

/// Presentation model combining a delivery record with its event details
class NotificationItem {
  final NotificationDelivery delivery;
  final NotificationEvent? event;

  const NotificationItem({
    required this.delivery,
    this.event,
  });

  String get id => delivery.id;
  String get title => event?.title ?? 'Notification';
  String get message => event?.message ?? '';
  NotificationEventType get eventType =>
      event?.eventType ?? NotificationEventType.customAlert;
  NotificationPriority get priority =>
      event?.priority ?? NotificationPriority.normal;
  DeliveryStatus get status => delivery.status;
  DateTime get createdAt => delivery.createdAt;
  bool get isUnread => delivery.status != DeliveryStatus.read;
}

class NotificationRepository {
  final SupabaseClient? _client;

  NotificationRepository([SupabaseClient? client])
      : _client = client;

  SupabaseClient get _db => _client ?? SupabaseService.client;

  /// Registers / refreshes an FCM device push token for a user profile
  Future<DeviceToken?> registerDeviceToken({
    required String profileId,
    required String fcmToken,
    required DevicePlatform platform,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _db
          .from('device_tokens')
          .upsert(
            {
              'profile_id': profileId,
              'fcm_token': fcmToken,
              'platform': platform.toDbValue(),
              'is_active': true,
              'last_seen_at': now,
              'updated_at': now,
            },
            onConflict: 'fcm_token',
          )
          .select()
          .single();

      return DeviceToken.fromJson(response);
    } catch (e) {
      AppLogger.error('Failed to register device token',
          error: e, context: 'NotificationRepository');
      return null;
    }
  }

  /// Deactivates a device token upon logout
  Future<void> unregisterDeviceToken(String fcmToken) async {
    try {
      await _db
          .from('device_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('fcm_token', fcmToken);
    } catch (e) {
      AppLogger.error('Failed to unregister device token',
          error: e, context: 'NotificationRepository');
    }
  }

  /// Fetches notification history for a user profile
  Future<List<NotificationItem>> getNotificationsForRecipient(
    String profileId, {
    int limit = 50,
  }) async {
    try {
      AppLogger.info('Fetching notification deliveries for recipient profileId: $profileId', context: 'NotificationRepository');
      final deliveriesData = await _db
          .from('notification_deliveries')
          .select('*, notification_events(*)')
          .or('recipient_profile_id.eq.$profileId,recipient_profile_id.is.null')
          .order('created_at', ascending: false)
          .limit(limit);

      final items = (deliveriesData as List).map((row) {
        final delivery = NotificationDelivery.fromJson(row);
        NotificationEvent? event;
        if (row['notification_events'] != null) {
          event = NotificationEvent.fromJson(
              row['notification_events'] as Map<String, dynamic>);
        }
        return NotificationItem(delivery: delivery, event: event);
      }).toList();

      AppLogger.info('Successfully fetched ${items.length} notification deliveries for profileId: $profileId', context: 'NotificationRepository');
      return items;
    } catch (e) {
      AppLogger.error('Failed to fetch notifications for recipient profileId: $profileId',
          error: e, context: 'NotificationRepository');
      return [];
    }
  }

  /// Watches notifications in real time for a user profile with periodic REST polling backup
  Stream<List<NotificationItem>> watchNotificationsForRecipient(
      String profileId) {
    late StreamController<List<NotificationItem>> controller;
    StreamSubscription<List<NotificationItem>>? subscription;
    Timer? pollTimer;

    controller = StreamController<List<NotificationItem>>(
      onListen: () {
        AppLogger.info('Started watching notifications for profileId: $profileId', context: 'NotificationRepository');
        
        // Initial REST fetch so UI loads immediately
        getNotificationsForRecipient(profileId).then((items) {
          if (!controller.isClosed) controller.add(items);
        }).catchError((e) {
          AppLogger.warning('Initial REST fetch error: $e', context: 'NotificationRepository');
        });

        // Periodic REST polling every 3 seconds as fail-safe
        pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
          if (controller.isClosed) return;
          try {
            final items = await getNotificationsForRecipient(profileId);
            if (!controller.isClosed) controller.add(items);
          } catch (e) {
            AppLogger.warning('Polling REST error: $e', context: 'NotificationRepository');
          }
        });

        try {
          subscription = _db
              .from('notification_deliveries')
              .stream(primaryKey: ['id'])
              .order('created_at', ascending: false)
              .asyncMap((list) async {
                final List<NotificationItem> items = [];
                for (final row in list) {
                  final delivery = NotificationDelivery.fromJson(row);
                  if (delivery.recipientProfileId != null &&
                      delivery.recipientProfileId != profileId) {
                    continue;
                  }
                  NotificationEvent? event;
                  try {
                    final eventRow = await _db
                        .from('notification_events')
                        .select()
                        .eq('id', delivery.notificationEventId)
                        .maybeSingle();
                    if (eventRow != null) {
                      event = NotificationEvent.fromJson(eventRow);
                    }
                  } catch (e) {
                    AppLogger.warning('Error fetching event row: $e', context: 'NotificationRepository');
                  }
                  items.add(NotificationItem(delivery: delivery, event: event));
                }
                return items;
              })
              .listen(
                (items) {
                  AppLogger.info('Realtime stream received ${items.length} notifications', context: 'NotificationRepository');
                  if (!controller.isClosed) controller.add(items);
                },
                onError: (err) async {
                  AppLogger.warning('Realtime notification stream error, relying on REST polling: $err',
                      context: 'NotificationRepository');
                },
              );
        } catch (e) {
          AppLogger.warning('Error setting up stream subscription: $e', context: 'NotificationRepository');
        }
      },
      onCancel: () {
        AppLogger.info('Stopped watching notifications for profileId: $profileId', context: 'NotificationRepository');
        pollTimer?.cancel();
        subscription?.cancel();
      },
    );

    return controller.stream;
  }

  /// Marks a specific delivery as read
  Future<void> markAsRead(String deliveryId) async {
    try {
      await _db
          .from('notification_deliveries')
          .update({
            'status': 'READ',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', deliveryId);
    } catch (e) {
      AppLogger.error('Failed to mark notification as read',
          error: e, context: 'NotificationRepository');
    }
  }

  /// Marks all notifications for a recipient as read
  Future<void> markAllAsRead(String profileId) async {
    try {
      await _db
          .from('notification_deliveries')
          .update({
            'status': 'READ',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('recipient_profile_id', profileId);
    } catch (e) {
      AppLogger.error('Failed to mark all notifications as read',
          error: e, context: 'NotificationRepository');
    }
  }
}
