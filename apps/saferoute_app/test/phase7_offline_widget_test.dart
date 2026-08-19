import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_app/src/features/shared/widgets/offline_banner.dart';

void main() {
  group('Phase 7 — Offline HUD Widget Tests', () {
    testWidgets('OfflineBanner renders nothing when online with empty queue',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              isOffline: false,
              queuedCount: 0,
              isSyncing: false,
            ),
          ),
        ),
      );

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.textContaining('Offline Mode'), findsNothing);
      expect(find.textContaining('Syncing'), findsNothing);
    });

    testWidgets('OfflineBanner displays amber offline buffering message',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              isOffline: true,
              queuedCount: 4,
              isSyncing: false,
            ),
          ),
        ),
      );

      expect(find.text('Offline Mode — Buffering telemetry (4 in queue)'),
          findsOneWidget);
      expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
    });

    testWidgets('OfflineBanner displays blue syncing state message',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              isOffline: false,
              queuedCount: 12,
              isSyncing: true,
            ),
          ),
        ),
      );

      expect(find.text('Syncing 12 buffered records...'), findsOneWidget);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);
    });
  });
}
