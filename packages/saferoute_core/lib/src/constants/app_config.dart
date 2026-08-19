/// SafeRoute centralized application configuration.
/// Reads from environment variables injected at build time.
/// Never stores or returns secrets — only non-sensitive config.
///
/// SECURITY: Supabase anon key is the ONLY Supabase credential here.
/// Service role key lives only in Supabase Edge Function secrets.
class AppConfig {
  AppConfig._();

  // ─────────────────────────────────────────────
  // Supabase (anon/public key only)
  // ─────────────────────────────────────────────

  /// Your Supabase project URL.
  /// Set SUPABASE_URL environment variable or update this default.
  static String get supabaseUrl =>
      const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://usexaanovsmmzjorlkyu.supabase.co',
      );

  /// Supabase anon (public) key — safe to be in client code.
  /// This key has RLS enforced. Service role key is NEVER here.
  static String get supabaseAnonKey =>
      const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: 'sb_publishable_Bv8JT2ZGmqyvtPiuK_N6WQ_OvxzAWI6',
      );

  // ─────────────────────────────────────────────
  // Map Tiles (OpenStreetMap — no Google Maps)
  // ─────────────────────────────────────────────

  static String get mapTileUrl =>
      const String.fromEnvironment(
        'MAP_TILE_URL',
        defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      );

  static String get mapTileAttribution =>
      const String.fromEnvironment(
        'MAP_TILE_ATTRIBUTION',
        defaultValue: '© OpenStreetMap contributors',
      );

  static double get mapMaxZoom =>
      double.tryParse(
        const String.fromEnvironment('MAP_MAX_ZOOM', defaultValue: '19'),
      ) ??
      19.0;

  // ─────────────────────────────────────────────
  // GPS Tracking Intervals (milliseconds)
  // ─────────────────────────────────────────────

  static int get gpsIntervalStoppedMs =>
      int.tryParse(
        const String.fromEnvironment('GPS_INTERVAL_STOPPED_MS', defaultValue: '45000'),
      ) ??
      45000;

  static int get gpsIntervalSlowMs =>
      int.tryParse(
        const String.fromEnvironment('GPS_INTERVAL_SLOW_MS', defaultValue: '15000'),
      ) ??
      15000;

  static int get gpsIntervalNormalMs =>
      int.tryParse(
        const String.fromEnvironment('GPS_INTERVAL_NORMAL_MS', defaultValue: '10000'),
      ) ??
      10000;

  static int get gpsIntervalFastMs =>
      int.tryParse(
        const String.fromEnvironment('GPS_INTERVAL_FAST_MS', defaultValue: '7000'),
      ) ??
      7000;

  static int get gpsIntervalApproachingMs =>
      int.tryParse(
        const String.fromEnvironment('GPS_INTERVAL_APPROACHING_MS', defaultValue: '3000'),
      ) ??
      3000;

  static double get gpsUploadMinDistanceM =>
      double.tryParse(
        const String.fromEnvironment('GPS_UPLOAD_MIN_DISTANCE_M', defaultValue: '10'),
      ) ??
      10.0;

  static int get gpsUploadMaxIntervalMs =>
      int.tryParse(
        const String.fromEnvironment('GPS_UPLOAD_MAX_INTERVAL_MS', defaultValue: '60000'),
      ) ??
      60000;

  static double get gpsMaxSpeedKmh =>
      double.tryParse(
        const String.fromEnvironment('GPS_MAX_SPEED_KMH', defaultValue: '150'),
      ) ??
      150.0;

  static double get gpsMinAccuracyM =>
      double.tryParse(
        const String.fromEnvironment('GPS_MIN_ACCURACY_M', defaultValue: '50'),
      ) ??
      50.0;

  // ─────────────────────────────────────────────
  // Proximity Detection
  // ─────────────────────────────────────────────

  static double get proximityApproachingBufferM =>
      double.tryParse(
        const String.fromEnvironment('PROXIMITY_APPROACHING_BUFFER_M', defaultValue: '200'),
      ) ??
      200.0;

  static double get proximityMinAccuracyForNotifyM =>
      double.tryParse(
        const String.fromEnvironment('PROXIMITY_MIN_ACCURACY_FOR_NOTIFY_M', defaultValue: '100'),
      ) ??
      100.0;

  // ─────────────────────────────────────────────
  // Stale Trip Detection
  // ─────────────────────────────────────────────

  static int get staleTripTimeoutSeconds =>
      int.tryParse(
        const String.fromEnvironment('STALE_TRIP_TIMEOUT_SECONDS', defaultValue: '300'),
      ) ??
      300;

  // ─────────────────────────────────────────────
  // Offline Queue
  // ─────────────────────────────────────────────

  static int get offlineQueueMaxSize =>
      int.tryParse(
        const String.fromEnvironment('OFFLINE_QUEUE_MAX_SIZE', defaultValue: '200'),
      ) ??
      200;

  // ─────────────────────────────────────────────
  // Notification Retry
  // ─────────────────────────────────────────────

  static int get notificationMaxRetryAttempts =>
      int.tryParse(
        const String.fromEnvironment('NOTIFICATION_MAX_RETRY_ATTEMPTS', defaultValue: '5'),
      ) ??
      5;

  static int get notificationRetryBackoffBaseSeconds =>
      int.tryParse(
        const String.fromEnvironment(
          'NOTIFICATION_RETRY_BACKOFF_BASE_SECONDS',
          defaultValue: '30',
        ),
      ) ??
      30;

  // ─────────────────────────────────────────────
  // Feature Flags
  // ─────────────────────────────────────────────

  static bool get featureMagicLinkEnabled =>
      const String.fromEnvironment('FEATURE_MAGIC_LINK_ENABLED', defaultValue: 'true') == 'true';

  static bool get featureWhatsappEnabled =>
      const String.fromEnvironment('FEATURE_WHATSAPP_ENABLED', defaultValue: 'true') == 'true';

  static bool get featureSmsEnabled =>
      const String.fromEnvironment('FEATURE_SMS_ENABLED', defaultValue: 'true') == 'true';

  static bool get featureAdminLiveMapEnabled =>
      const String.fromEnvironment('FEATURE_ADMIN_LIVE_MAP_ENABLED', defaultValue: 'true') == 'true';

  static bool get featureBatteryReportingEnabled =>
      const String.fromEnvironment('FEATURE_BATTERY_REPORTING_ENABLED', defaultValue: 'true') == 'true';

  // ─────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────

  /// Validates that critical configuration is present.
  /// Call during app initialization.
  static void validate() {
    if (supabaseUrl.isEmpty) {
      throw StateError(
        'SUPABASE_URL is not configured. '
        'Set it via --dart-define=SUPABASE_URL=your_url or in your build config.',
      );
    }
    if (supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_ANON_KEY is not configured. '
        'Set it via --dart-define=SUPABASE_ANON_KEY=your_anon_key. '
        'NEVER use the service role key here.',
      );
    }
  }

  // ─────────────────────────────────────────────
  // Notification Distance Options (for parent UI)
  // ─────────────────────────────────────────────

  static const List<int> notificationDistanceOptions = [500, 750, 1000, 1500, 2000];
  static const int notificationDistanceMin = 100;
  static const int notificationDistanceMax = 10000;

  // ─────────────────────────────────────────────
  // Retention Bounds (enforced by DB CHECK constraints too)
  // ─────────────────────────────────────────────

  static const int retentionMinDays = 1;
  static const int retentionMaxDays = 3650; // 10 years
}
