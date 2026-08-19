import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:saferoute_app/src/features/notifications/presentation/notification_inbox_screen.dart';
import 'package:saferoute_app/src/features/notifications/providers/notification_providers.dart';
import 'package:saferoute_app/src/features/parent/presentation/parent_home_screen.dart';
import 'package:saferoute_app/src/features/parent/providers/parent_providers.dart';
import 'package:saferoute_app/src/providers/auth_provider.dart';

void main() {
  group('Phase 4 — Notification UI Widget Tests', () {
    testWidgets('NotificationInboxScreen shows empty state when list is empty',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWithValue(
              Profile(
                id: 'prof-p1',
                organizationId: 'org-1',
                email: 'parent@example.com',
                name: 'Priya Sharma',
                role: UserRole.parent,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
            parentNotificationsProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
          ],
          child: const MaterialApp(
            home: NotificationInboxScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('No notifications in this category'), findsOneWidget);
    });

    testWidgets('NotificationInboxScreen displays notification items and filters',
        (tester) async {
      final item1 = NotificationItem(
        delivery: NotificationDelivery(
          id: 'del-1',
          notificationEventId: 'evt-1',
          organizationId: 'org-1',
          recipientProfileId: 'prof-p1',
          childId: 'child-1',
          channel: DeliveryChannel.push,
          status: DeliveryStatus.sent,
          createdAt: DateTime.parse('2026-08-16T12:30:00Z'),
          updatedAt: DateTime.parse('2026-08-16T12:30:00Z'),
        ),
        event: NotificationEvent(
          id: 'evt-1',
          organizationId: 'org-1',
          eventType: NotificationEventType.busNearby,
          priority: NotificationPriority.high,
          title: 'Bus Approaching: Aarav',
          message: 'School Bus 12-A is 500m away from your stop.',
          createdAt: DateTime.parse('2026-08-16T12:30:00Z'),
          updatedAt: DateTime.parse('2026-08-16T12:30:00Z'),
        ),
      );

      final item2 = NotificationItem(
        delivery: NotificationDelivery(
          id: 'del-2',
          notificationEventId: 'evt-2',
          organizationId: 'org-1',
          recipientProfileId: 'prof-p1',
          channel: DeliveryChannel.push,
          status: DeliveryStatus.delivered,
          createdAt: DateTime.parse('2026-08-16T11:00:00Z'),
          updatedAt: DateTime.parse('2026-08-16T11:00:00Z'),
        ),
        event: NotificationEvent(
          id: 'evt-2',
          organizationId: 'org-1',
          eventType: NotificationEventType.emergency,
          priority: NotificationPriority.emergency,
          title: 'EMERGENCY: Mechanical Breakdown',
          message: 'Bus 12-A stopped on 80ft Road due to flat tire.',
          createdAt: DateTime.parse('2026-08-16T11:00:00Z'),
          updatedAt: DateTime.parse('2026-08-16T11:00:00Z'),
        ),
      );

      final controller = StreamController<List<NotificationItem>>.broadcast();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWithValue(
              Profile(
                id: 'prof-p1',
                organizationId: 'org-1',
                email: 'parent@example.com',
                name: 'Priya Sharma',
                role: UserRole.parent,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
            parentNotificationsProvider.overrideWith(
              (ref) => controller.stream,
            ),
          ],
          child: const MaterialApp(
            home: NotificationInboxScreen(),
          ),
        ),
      );

      controller.add([item1, item2]);
      await tester.pumpAndSettle();

      expect(find.text('Bus Approaching: Aarav'), findsOneWidget);
      expect(find.text('EMERGENCY: Mechanical Breakdown'), findsOneWidget);
      expect(find.text('School Bus 12-A is 500m away from your stop.'), findsOneWidget);

      // Filter by Emergency
      final emergencyChip = find.byKey(const Key('filter_chip_EMERGENCY'));
      await tester.ensureVisible(emergencyChip);
      await tester.tap(emergencyChip);
      await tester.pumpAndSettle();

      expect(find.text('EMERGENCY: Mechanical Breakdown'), findsOneWidget);
      expect(find.text('Bus Approaching: Aarav'), findsNothing);

      await controller.close();
    });

    testWidgets('ParentHomeScreen shows notification badge when unread exist',
        (tester) async {
      final item1 = NotificationItem(
        delivery: NotificationDelivery(
          id: 'del-1',
          notificationEventId: 'evt-1',
          organizationId: 'org-1',
          recipientProfileId: 'prof-p1',
          channel: DeliveryChannel.push,
          status: DeliveryStatus.sent,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileProvider.overrideWithValue(
              Profile(
                id: 'prof-p1',
                organizationId: 'org-1',
                email: 'parent@example.com',
                name: 'Priya Sharma',
                role: UserRole.parent,
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ),
            parentChildrenStreamProvider.overrideWith(
              (ref) => Stream.value([]),
            ),
            parentNotificationsProvider.overrideWith(
              (ref) => Stream.value([item1]),
            ),
          ],
          child: const MaterialApp(
            home: ParentHomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });
}
