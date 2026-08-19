import '../models/organization.dart';
import '../utils/logger.dart';

/// Manages multi-tenant boundaries, tenant-level safety policies,
/// and prevents cross-tenant data bleed at runtime.
class TenantContext {
  TenantContext._();
  static final TenantContext instance = TenantContext._();

  Organization? _currentTenant;

  /// Active tenant organization
  Organization? get currentTenant => _currentTenant;

  /// Sets the active tenant context
  void setTenant(Organization organization) {
    _currentTenant = organization;
    AppLogger.info(
      'Tenant context set to: ${organization.name} (${organization.id})',
      context: 'TenantContext',
    );
  }

  /// Clears active tenant context on logout / session termination
  void clearTenant() {
    _currentTenant = null;
    AppLogger.info('Tenant context cleared', context: 'TenantContext');
  }

  /// Verifies that an entity's organization ID matches the active tenant
  bool isAuthorizedForTenant(String entityOrganizationId) {
    if (_currentTenant == null) return false;
    return _currentTenant!.id == entityOrganizationId;
  }

  /// Validates safety policy bounds for a tenant
  static bool validateProximityRadius(int meters) {
    return meters >= 300 && meters <= 2000;
  }

  /// Validates speed warning limits (40 km/h - 100 km/h)
  static bool validateSpeedWarningThreshold(double speedKmh) {
    return speedKmh >= 40.0 && speedKmh <= 100.0;
  }

  /// Validates telemetry data retention policies (30 - 365 days)
  static bool validateTelemetryRetentionDays(int days) {
    return days >= 30 && days <= 365;
  }
}
