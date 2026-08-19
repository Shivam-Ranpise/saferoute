import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../providers/notification_providers.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredNotificationsProvider);
    final activeFilter = ref.watch(notificationFilterProvider);
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: profile == null
                ? null
                : () async {
                    final items = filteredAsync.value ?? [];
                    final allIds = items.map((i) => i.id).toSet();
                    ref.read(readNotificationIdsProvider.notifier).update(
                          (state) => {...state, ...allIds},
                        );

                    await ref
                        .read(notificationRepositoryProvider)
                        .markAllAsRead(profile.id);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            tooltip: 'Delete / Clear all',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () async {
              final items = filteredAsync.value ?? [];
              if (items.isEmpty) return;

              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Delete All Notifications?'),
                  content: const Text(
                    'Are you sure you want to delete all notifications from your inbox?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SafeRouteColors.error,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      child: const Text('Delete All'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                final allIds = items.map((i) => i.id).toSet();
                ref.read(clearedNotificationIdsProvider.notifier).update(
                      (state) => {...state, ...allIds},
                    );
                ref.read(readNotificationIdsProvider.notifier).update(
                      (state) => {...state, ...allIds},
                    );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications deleted'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: SafeRouteColors.outline.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'All',
                    filterKey: 'ALL',
                    isSelected: activeFilter == 'ALL',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'Proximity & Arrival',
                    filterKey: 'BUS_NEARBY',
                    isSelected: activeFilter == 'BUS_NEARBY',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'Emergency SOS',
                    filterKey: 'EMERGENCY',
                    isSelected: activeFilter == 'EMERGENCY',
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    ref,
                    label: 'Trip Lifecycle',
                    filterKey: 'TRIP',
                    isSelected: activeFilter == 'TRIP',
                  ),
                ],
              ),
            ),
          ),

          // Notifications List
          Expanded(
            child: filteredAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notifications_none_rounded,
                            size: 64,
                            color: SafeRouteColors.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No notifications in your inbox',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: SafeRouteColors.deepNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You will receive real-time bus proximity alerts and safety notices here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: SafeRouteColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _NotificationTile(item: item);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: SafeRouteColors.yellow),
              ),
              error: (err, _) => Center(
                child: Text('Failed to load notifications: $err'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String filterKey,
    required bool isSelected,
  }) {
    return ChoiceChip(
      key: Key('filter_chip_$filterKey'),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : SafeRouteColors.deepNavy,
        ),
      ),
      selected: isSelected,
      selectedColor: SafeRouteColors.deepNavy,
      backgroundColor: SafeRouteColors.surfaceVariant,
      onSelected: (bool selected) {
        if (selected) {
          ref.read(notificationFilterProvider.notifier).state = filterKey;
        }
      },
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final NotificationItem item;

  const _NotificationTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readIds = ref.watch(readNotificationIdsProvider);
    final isRead = readIds.contains(item.id) || !item.isUnread;

    return InkWell(
      onTap: () {
        ref.read(readNotificationIdsProvider.notifier).update(
              (state) => {...state, item.id},
            );
        ref.read(notificationRepositoryProvider).markAsRead(item.id);
      },
      child: Container(
        color: isRead ? Colors.white : SafeRouteColors.yellow.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            _buildLeadingIcon(item.eventType, item.priority),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            fontSize: 14,
                            color: SafeRouteColors.deepNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(item.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isRead
                              ? SafeRouteColors.onSurfaceVariant
                              : SafeRouteColors.deepNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: SafeRouteColors.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Delete Individual Item Icon
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
              tooltip: 'Delete notification',
              onPressed: () {
                ref.read(clearedNotificationIdsProvider.notifier).update(
                      (state) => {...state, item.id},
                    );
                ref.read(readNotificationIdsProvider.notifier).update(
                      (state) => {...state, item.id},
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(
      NotificationEventType eventType, NotificationPriority priority) {
    IconData iconData = Icons.notifications_rounded;
    Color iconColor = SafeRouteColors.deepNavy;

    if (priority == NotificationPriority.emergency ||
        eventType == NotificationEventType.emergency) {
      iconData = Icons.warning_amber_rounded;
      iconColor = SafeRouteColors.error;
    } else if (eventType == NotificationEventType.busNearby) {
      iconData = Icons.directions_bus_rounded;
      iconColor = SafeRouteColors.yellow;
    } else if (eventType == NotificationEventType.tripStarted ||
        eventType == NotificationEventType.tripCompleted) {
      iconData = Icons.alt_route_rounded;
      iconColor = SafeRouteColors.primaryBlue;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return DateFormat('h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
