import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:saferoute_admin/src/features/admin/presentation/organization_settings_screen.dart';
import 'package:saferoute_admin/src/features/admin/providers/admin_providers.dart';
import 'package:saferoute_admin/src/providers/auth_provider.dart';

void main() {
  final testAdminProfile = Profile(
    id: 'prof-admin-1',
    organizationId: 'org-1',
    email: 'admin@dps.edu',
    name: 'DPS Admin Office',
    role: UserRole.admin,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testOrg = Organization(
    id: 'org-1',
    name: 'Delhi Public School — Bangalore South',
    timezone: 'Asia/Calcutta',
    gpsHistoryRetentionDays: 60,
    notificationLogRetentionDays: 90,
    driverCanSendEmergencyAlerts: true,
    driverCanSendCustomAlerts: true,
    isActive: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('Phase 6 — Multi-Tenant Admin Institutional Settings Widget Tests', () {
    testWidgets('OrganizationSettingsScreen loads profile and safety sliders',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentAdminProfileProvider.overrideWithValue(testAdminProfile),
            currentOrganizationProvider.overrideWith((ref) => Future.value(testOrg)),
          ],
          child: const MaterialApp(
            home: OrganizationSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('School Profile & Safety Policies'), findsOneWidget);
      expect(find.text('Institutional Profile'), findsOneWidget);
      expect(find.text('Delhi Public School — Bangalore South'), findsOneWidget);
      expect(find.text('Asia/Calcutta'), findsOneWidget);
      expect(find.text('Driver Permissions & Alert Controls'), findsOneWidget);
      expect(find.text('60 days'), findsOneWidget);
      expect(find.text('90 days'), findsOneWidget);
      expect(find.text('Save Policy Changes'), findsOneWidget);
    });
  });
}
