import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../providers/auth_provider.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/magic_link_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/parent/presentation/parent_home_screen.dart';
import '../features/parent/presentation/set_pickup_location_screen.dart';
import '../features/parent/presentation/parent_settings_screen.dart';
import '../features/parent/presentation/voice_settings_screen.dart';
import '../features/notifications/presentation/notification_inbox_screen.dart';
import '../features/driver/presentation/driver_dashboard_screen.dart';


/// SafeRoute GoRouter configuration.
///
/// SECURITY: Role-based routing is enforced here as the second layer of defense.
/// The first layer is RLS on the database. The application layer NEVER trusts
/// client-provided role claims — role comes from the auth provider which reads
/// from the database profile.
///
/// Users can NEVER manually navigate to another role's screens.
/// Any attempt triggers a redirect to their correct role home.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier =
      ValueNotifier<SafeRouteAuthState>(ref.read(authProvider));

  ref.listen(authProvider, (previous, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.matchedLocation;

      // Always allow splash while loading
      if (auth.isLoading) {
        if (path == AppConstants.routeSplash) return null;
        return AppConstants.routeSplash;
      }

      // Not authenticated — redirect to login
      if (!auth.isAuthenticated) {
        if (path == AppConstants.routeLogin ||
            path == AppConstants.routeMagicLink) {
          return null;
        }
        return AppConstants.routeLogin;
      }

      // Authenticated — enforce role-based routing
      final role = auth.role;
      if (role == null) return AppConstants.routeLogin;

      // Redirect away from auth screens when logged in
      if (path == AppConstants.routeSplash ||
          path == AppConstants.routeLogin ||
          path == AppConstants.routeMagicLink) {
        return _defaultRouteForRole(role);
      }

      // CRITICAL: Prevent cross-role navigation
      // If a parent tries to access /driver/* or /admin/* — redirect them
      if (role == UserRole.parent &&
          (path.startsWith('/driver') || path.startsWith('/admin'))) {
        return AppConstants.routeParentHome;
      }
      if (role == UserRole.driver &&
          (path.startsWith('/parent') || path.startsWith('/admin'))) {
        return AppConstants.routeDriverDashboard;
      }
      if (role == UserRole.admin &&
          (path.startsWith('/parent') || path.startsWith('/driver'))) {
        // Admin is redirected to web admin panel — mobile just shows a message
        return AppConstants.routeAdminDashboard;
      }

      return null; // No redirect needed
    },
    routes: _routes,
  );
});

String _defaultRouteForRole(UserRole role) {
  switch (role) {
    case UserRole.parent:
      return AppConstants.routeParentHome;
    case UserRole.driver:
      return AppConstants.routeDriverDashboard;
    case UserRole.admin:
    case UserRole.superAdmin:
      return AppConstants.routeAdminDashboard;
  }
}

final List<RouteBase> _routes = [
  // Splash
  GoRoute(
    path: AppConstants.routeSplash,
    builder: (context, state) => const SplashScreen(),
  ),

  // Auth
  GoRoute(
    path: AppConstants.routeLogin,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: AppConstants.routeMagicLink,
    builder: (context, state) => const MagicLinkScreen(),
  ),

  // ─── PARENT ROUTES ──────────────────────────────────────────────
  GoRoute(
    path: '/parent',
    redirect: (_, __) => AppConstants.routeParentHome,
  ),
  GoRoute(
    path: AppConstants.routeParentHome,
    builder: (context, state) => const ParentHomeScreen(),
    routes: [
      GoRoute(
        path: 'pickup-location/:childId',
        builder: (context, state) {
          final childId = state.pathParameters['childId'] ?? '';
          return SetPickupLocationScreen(childId: childId);
        },
      ),
      GoRoute(
        path: 'settings',
        builder: (context, state) => const ParentSettingsScreen(),
      ),
      GoRoute(
        path: 'notifications',
        builder: (context, state) => const NotificationInboxScreen(),
      ),
      GoRoute(
        path: 'voice-settings',
        builder: (context, state) => const VoiceSettingsScreen(),
      ),
    ],
  ),
  GoRoute(
    path: '/parent/pickup-location/:childId',
    builder: (context, state) {
      final childId = state.pathParameters['childId'] ?? '';
      return SetPickupLocationScreen(childId: childId);
    },
  ),
  GoRoute(
    path: '/parent/settings',
    builder: (context, state) => const ParentSettingsScreen(),
  ),
  GoRoute(
    path: '/parent/notifications',
    builder: (context, state) => const NotificationInboxScreen(),
  ),
  GoRoute(
    path: '/parent/voice-settings',
    builder: (context, state) => const VoiceSettingsScreen(),
  ),

  // ─── DRIVER ROUTES ──────────────────────────────────────────────
  GoRoute(
    path: AppConstants.routeDriverDashboard,
    builder: (context, state) => const DriverDashboardScreen(),
  ),

  // ─── ADMIN ROUTES (mobile — redirect to web panel) ──────────────
  GoRoute(
    path: AppConstants.routeAdminDashboard,
    builder: (context, state) => const _AdminOnMobileScreen(),
  ),

];

/// Shown to admin users on the mobile app.
/// Admins should use the Flutter Web admin panel.
class _AdminOnMobileScreen extends StatelessWidget {
  const _AdminOnMobileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings,
                  color: Colors.white, size: 64),
              const SizedBox(height: 24),
              const Text(
                'Admin Panel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'The SafeRoute admin panel is available on web browsers only. '
                'Please visit the admin URL on your laptop or desktop.',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              Consumer(
                builder: (context, ref, _) {
                  return TextButton(
                    onPressed: () => ref.read(authProvider.notifier).signOut(),
                    child: const Text('Sign Out',
                        style: TextStyle(color: Colors.yellow)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
