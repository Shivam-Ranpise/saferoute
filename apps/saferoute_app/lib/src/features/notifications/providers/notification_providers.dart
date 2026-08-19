import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';

import '../services/app_notification_service.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Local set of notification delivery IDs marked as read
final readNotificationIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Local set of notification delivery IDs cleared/deleted by user
final clearedNotificationIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Realtime notification stream for the logged-in user
final parentNotificationsProvider =
    StreamProvider.autoDispose<List<NotificationItem>>((ref) {
  final profile = ref.watch(currentProfileProvider);
  if (profile == null) {
    AppLogger.info('parentNotificationsProvider: profile is null', context: 'NotificationStream');
    return Stream.value([]);
  }

  final clearedIds = ref.watch(clearedNotificationIdsProvider);
  final readIds = ref.watch(readNotificationIdsProvider);

  AppLogger.info('parentNotificationsProvider: Active stream listener for profileId: ${profile.id} (${profile.name})', context: 'NotificationStream');

  final repo = ref.watch(notificationRepositoryProvider);
  return repo.watchNotificationsForRecipient(profile.id).map((items) {
    // Exclude user cleared/deleted notifications
    final visibleItems = items.where((i) => !clearedIds.contains(i.id)).toList();

    AppLogger.info('parentNotificationsProvider: Received ${visibleItems.length} visible notification items', context: 'NotificationStream');
    for (final item in visibleItems) {
      final isItemUnread = !readIds.contains(item.id) && item.isUnread;
      AppLogger.info('Evaluating notification delivery ID: ${item.id} | title: "${item.title}" | isUnread: $isItemUnread', context: 'NotificationStream');
      if (isItemUnread) {
        AppNotificationHelper.showSystemNotification(
          deliveryId: item.id,
          title: item.title,
          message: item.message,
          createdAt: item.createdAt,
        );
      }
    }
    return visibleItems;
  });
});

/// Unread notification count provider (Only > 0 displays badge count)
final unreadNotificationCountProvider = Provider.autoDispose<int>((ref) {
  final notificationsAsync = ref.watch(parentNotificationsProvider);
  final readIds = ref.watch(readNotificationIdsProvider);

  return notificationsAsync.when(
    data: (items) => items.where((i) => !readIds.contains(i.id) && i.isUnread).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Selected filter category ('ALL' | 'EMERGENCY' | 'BUS_NEARBY' | 'TRIP')
final notificationFilterProvider = StateProvider<String>((ref) => 'ALL');

/// Filtered notifications list
final filteredNotificationsProvider =
    Provider.autoDispose<AsyncValue<List<NotificationItem>>>((ref) {
  final notificationsAsync = ref.watch(parentNotificationsProvider);
  final filter = ref.watch(notificationFilterProvider);

  return notificationsAsync.whenData((items) {
    if (filter == 'ALL') return items;
    if (filter == 'EMERGENCY') {
      return items
          .where((i) =>
              i.eventType == NotificationEventType.emergency ||
              i.priority == NotificationPriority.emergency)
          .toList();
    }
    if (filter == 'BUS_NEARBY') {
      return items
          .where((i) => i.eventType == NotificationEventType.busNearby)
          .toList();
    }
    if (filter == 'TRIP') {
      return items
          .where((i) =>
              i.eventType == NotificationEventType.tripStarted ||
              i.eventType == NotificationEventType.tripCompleted ||
              i.eventType == NotificationEventType.busDelay)
          .toList();
    }
    return items;
  });
});
