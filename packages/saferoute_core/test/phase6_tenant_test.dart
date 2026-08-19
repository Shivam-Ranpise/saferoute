import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 6 — Multi-Tenant Architecture & Enterprise Isolation Tests', () {
    final tenantA = Organization(
      id: 'org-dps',
      name: 'Delhi Public School',
      timezone: 'Asia/Kolkata',
      gpsHistoryRetentionDays: 90,
      notificationLogRetentionDays: 180,
      isActive: true,
      createdAt: DateTime.parse('2026-08-16T00:00:00Z'),
      updatedAt: DateTime.parse('2026-08-16T00:00:00Z'),
    );

    final tenantB = Organization(
      id: 'org-nps',
      name: 'National Public School',
      timezone: 'Asia/Kolkata',
      gpsHistoryRetentionDays: 60,
      notificationLogRetentionDays: 90,
      isActive: true,
      createdAt: DateTime.parse('2026-08-16T00:00:00Z'),
      updatedAt: DateTime.parse('2026-08-16T00:00:00Z'),
    );

    setUp(() {
      TenantContext.instance.clearTenant();
    });

    test('TenantContext lifecycle and runtime isolation', () {
      expect(TenantContext.instance.currentTenant, isNull);
      expect(TenantContext.instance.isAuthorizedForTenant('org-dps'), isFalse);

      // Set Tenant A
      TenantContext.instance.setTenant(tenantA);
      expect(TenantContext.instance.currentTenant?.id, equals('org-dps'));
      expect(TenantContext.instance.currentTenant?.name, equals('Delhi Public School'));

      // Verify cross-tenant isolation
      expect(TenantContext.instance.isAuthorizedForTenant('org-dps'), isTrue);
      expect(TenantContext.instance.isAuthorizedForTenant('org-nps'), isFalse);
      expect(TenantContext.instance.isAuthorizedForTenant('unknown-org'), isFalse);

      // Switch to Tenant B
      TenantContext.instance.setTenant(tenantB);
      expect(TenantContext.instance.isAuthorizedForTenant('org-nps'), isTrue);
      expect(TenantContext.instance.isAuthorizedForTenant('org-dps'), isFalse);

      // Clear Context
      TenantContext.instance.clearTenant();
      expect(TenantContext.instance.currentTenant, isNull);
      expect(TenantContext.instance.isAuthorizedForTenant('org-nps'), isFalse);
    });

    test('Tenant safety policy boundary validations', () {
      // Proximity Geofence Radius (300m - 2000m)
      expect(TenantContext.validateProximityRadius(300), isTrue);
      expect(TenantContext.validateProximityRadius(500), isTrue);
      expect(TenantContext.validateProximityRadius(2000), isTrue);
      expect(TenantContext.validateProximityRadius(250), isFalse);
      expect(TenantContext.validateProximityRadius(2500), isFalse);

      // Speed Warning Threshold (40 km/h - 100 km/h)
      expect(TenantContext.validateSpeedWarningThreshold(40.0), isTrue);
      expect(TenantContext.validateSpeedWarningThreshold(65.0), isTrue);
      expect(TenantContext.validateSpeedWarningThreshold(100.0), isTrue);
      expect(TenantContext.validateSpeedWarningThreshold(35.0), isFalse);
      expect(TenantContext.validateSpeedWarningThreshold(120.0), isFalse);

      // Telemetry Retention Period (30 - 365 days)
      expect(TenantContext.validateTelemetryRetentionDays(30), isTrue);
      expect(TenantContext.validateTelemetryRetentionDays(90), isTrue);
      expect(TenantContext.validateTelemetryRetentionDays(365), isTrue);
      expect(TenantContext.validateTelemetryRetentionDays(15), isFalse);
      expect(TenantContext.validateTelemetryRetentionDays(400), isFalse);
    });

    test('Organization model copyWith updates institutional parameters', () {
      final updatedTenant = tenantA.copyWith(
        name: 'Delhi Public School — North Campus',
        gpsHistoryRetentionDays: 120,
        notificationLogRetentionDays: 200,
        driverCanSendEmergencyAlerts: true,
      );

      expect(updatedTenant.id, equals('org-dps'));
      expect(updatedTenant.name, equals('Delhi Public School — North Campus'));
      expect(updatedTenant.gpsHistoryRetentionDays, equals(120));
      expect(updatedTenant.notificationLogRetentionDays, equals(200));
      expect(updatedTenant.driverCanSendEmergencyAlerts, isTrue);
      expect(updatedTenant.timezone, equals('Asia/Kolkata'));
    });
  });
}
