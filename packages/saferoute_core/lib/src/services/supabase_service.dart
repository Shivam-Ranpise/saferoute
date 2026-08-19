import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_config.dart';
import '../utils/logger.dart';

/// SafeRoute Supabase singleton initialization and access.
/// The anon key is the ONLY Supabase credential in client code.
/// Service role key lives ONLY in Edge Function secrets.
class SupabaseService {
  SupabaseService._();

  static bool _initialized = false;

  /// Initialize Supabase. Call once at app startup before runApp().
  static Future<void> initialize() async {
    if (_initialized) return;

    // Validate config before initializing
    AppConfig.validate();

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      debug: false, // Never enable debug in production (logs sensitive data)
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // PKCE for mobile OAuth security
        autoRefreshToken: true,
        detectSessionInUri: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 10, // Throttle realtime to minimize data usage
      ),
    );

    _initialized = true;
    AppLogger.info('Supabase initialized successfully');
  }

  /// The global Supabase client.
  static SupabaseClient get client => Supabase.instance.client;

  /// Current authenticated user (null if not logged in).
  static User? get currentUser => client.auth.currentUser;

  /// Current session (null if not logged in).
  static Session? get currentSession => client.auth.currentSession;

  /// True if a user is currently authenticated.
  static bool get isAuthenticated => currentUser != null;

  /// Auth state change stream — use for reactive auth state management.
  static Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;

  /// Convenience: Get typed Postgres builder for a table
  static PostgrestFilterBuilder<List<Map<String, dynamic>>> from(String table) =>
      client.from(table).select();

  /// Sign out the current user. Clears session tokens.
  static Future<void> signOut() async {
    try {
      await client.auth.signOut();
      AppLogger.info('User signed out');
    } catch (e) {
      AppLogger.error('Error signing out', error: e);
      rethrow;
    }
  }
}
