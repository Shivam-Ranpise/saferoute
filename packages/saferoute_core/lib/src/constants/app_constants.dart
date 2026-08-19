/// SafeRoute application-level string constants.
class AppConstants {
  AppConstants._();

  // ─────────────────────────────────────────────
  // App Identity
  // ─────────────────────────────────────────────
  static const String appName = 'SafeRoute';
  static const String tagline = 'Every Child. Every Mile. Safely.';

  // ─────────────────────────────────────────────
  // Supabase Table Names
  // ─────────────────────────────────────────────
  static const String tableOrganizations = 'organizations';
  static const String tableProfiles = 'profiles';
  static const String tableParents = 'parents';
  static const String tableDrivers = 'drivers';
  static const String tableBuses = 'buses';
  static const String tableChildren = 'children';
  static const String tableTrips = 'trips';
  static const String tableTripLocationHistory = 'trip_location_history';
  static const String tableTripChildProximityState = 'trip_child_proximity_state';
  static const String tableDeviceTokens = 'device_tokens';
  static const String tableNotificationPreferences = 'notification_preferences';
  static const String tableNotificationEventSettings = 'notification_event_settings';
  static const String tableNotificationEvents = 'notification_events';
  static const String tableNotificationDeliveries = 'notification_deliveries';
  static const String tableNotificationTemplates = 'notification_templates';
  static const String tableProviderSettings = 'provider_settings';
  static const String tableAuditLogs = 'audit_logs';

  // ─────────────────────────────────────────────
  // Supabase Edge Function Names
  // ─────────────────────────────────────────────
  static const String fnSendNotification = 'send-notification';
  static const String fnQueueNotification = 'queue-notification';
  static const String fnSendSms = 'send-sms';
  static const String fnSendWhatsapp = 'send-whatsapp';
  static const String fnSendPush = 'send-push';
  static const String fnSmsWebhook = 'sms-delivery-webhook';
  static const String fnWhatsappWebhook = 'whatsapp-delivery-webhook';
  static const String fnTestSms = 'test-sms';
  static const String fnTestWhatsapp = 'test-whatsapp';
  static const String fnTestPush = 'test-push';
  static const String fnUpdateFcmToken = 'update-fcm-token';
  static const String fnResolveRole = 'resolve-role';

  // ─────────────────────────────────────────────
  // Secure Storage Keys (flutter_secure_storage)
  // ─────────────────────────────────────────────
  static const String storageKeySessionToken = 'sr_session_token';
  static const String storageKeyRefreshToken = 'sr_refresh_token';
  static const String storageKeyUserId = 'sr_user_id';
  static const String storageKeyUserRole = 'sr_user_role';
  static const String storageKeyOrgId = 'sr_org_id';

  // ─────────────────────────────────────────────
  // SharedPreferences Keys (non-sensitive cache)
  // ─────────────────────────────────────────────
  static const String prefKeyProfileCache = 'sr_profile_cache';
  static const String prefKeyChildrenCache = 'sr_children_cache';
  static const String prefKeyBusCache = 'sr_bus_cache';
  static const String prefKeyTripCache = 'sr_trip_cache';
  static const String prefKeyNotifPrefsCache = 'sr_notif_prefs_cache';
  static const String prefKeyLastBusLocation = 'sr_last_bus_location';
  static const String prefKeyOfflineGpsQueue = 'sr_offline_gps_queue';

  // ─────────────────────────────────────────────
  // Realtime Channel Names
  // ─────────────────────────────────────────────
  static String realtimeTripChannel(String busId) => 'trip:bus:$busId';
  static String realtimeAdminChannel(String orgId) => 'admin:org:$orgId';
  static String realtimeAlertChannel(String orgId) => 'alerts:org:$orgId';

  // ─────────────────────────────────────────────
  // Route Paths (used by GoRouter)
  // ─────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeMagicLink = '/magic-link';

  // Parent routes
  static const String routeParentHome = '/parent/home';
  static const String routeParentChild = '/parent/child/:childId';
  static const String routeParentPickupMap = '/parent/child/:childId/pickup';
  static const String routeParentLiveTracking = '/parent/track/:busId';
  static const String routeParentNotifications = '/parent/notifications';
  static const String routeParentSettings = '/parent/settings';

  // Driver routes
  static const String routeDriverDashboard = '/driver/dashboard';
  static const String routeDriverSendAlert = '/driver/alert';

  // Admin routes
  static const String routeAdminDashboard = '/admin/dashboard';
  static const String routeAdminLiveMap = '/admin/map';
  static const String routeAdminOrganizations = '/admin/organizations';
  static const String routeAdminBuses = '/admin/buses';
  static const String routeAdminDrivers = '/admin/drivers';
  static const String routeAdminParents = '/admin/parents';
  static const String routeAdminChildren = '/admin/children';
  static const String routeAdminAssignments = '/admin/assignments';
  static const String routeAdminTrips = '/admin/trips';
  static const String routeAdminNotificationPolicies = '/admin/notifications/policies';
  static const String routeAdminNotificationTemplates = '/admin/notifications/templates';
  static const String routeAdminNotificationLogs = '/admin/notifications/logs';
  static const String routeAdminProviderSettings = '/admin/providers';
  static const String routeAdminEmergencyAlerts = '/admin/emergency';
  static const String routeAdminAuditLogs = '/admin/audit';
  static const String routeAdminSystemSettings = '/admin/settings';

  // ─────────────────────────────────────────────
  // User-Facing Error Messages (never raw exceptions)
  // ─────────────────────────────────────────────
  static const String errGpsUnavailable = 'Location services are disabled.';
  static const String errGpsPermissionDenied = 'Location permission is required during an active trip.';
  static const String errOffline = 'You\'re offline. Tracking will continue locally.';
  static const String errInvalidGps = 'Waiting for a reliable location.';
  static const String errNotificationQueued = 'Alert queued. Delivery is pending.';
  static const String errGeneric = 'Something went wrong. Please try again.';
  static const String errSessionExpired = 'Your session has expired. Please log in again.';
  static const String errUnauthorized = 'You don\'t have permission to access this.';

  // ─────────────────────────────────────────────
  // Template Variable Names
  // ─────────────────────────────────────────────
  static const String tplVarChildName = 'child_name';
  static const String tplVarBusNumber = 'bus_number';
  static const String tplVarDistance = 'distance';
  static const String tplVarDriverName = 'driver_name';
  static const String tplVarMessage = 'message';
  static const String tplVarEstimatedTime = 'estimated_time';
}
