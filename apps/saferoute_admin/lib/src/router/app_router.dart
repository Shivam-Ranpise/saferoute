import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../features/admin/presentation/widgets/admin_scaffold.dart';
import '../features/admin/presentation/fleet_overview_screen.dart';
import '../features/admin/presentation/buses_management_screen.dart';
import '../features/admin/presentation/drivers_management_screen.dart';
import '../features/admin/presentation/students_management_screen.dart';
import '../features/admin/presentation/notification_audit_screen.dart';
import '../features/admin/presentation/organization_settings_screen.dart';
import '../features/admin/presentation/parents_management_screen.dart';
import '../features/admin/presentation/super_admin_dashboard_screen.dart';
import '../features/admin/presentation/db_usage_stats_screen.dart';
import '../features/auth/presentation/admin_login_screen.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(adminAuthProvider);

  return GoRouter(
    initialLocation: '/admin',
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == '/login';

      if (authState.isLoading) return null;

      final isAuthenticated = authState.isAuthenticated && authState.isAdmin;
      final isSuperAdmin =
          authState.profile?.role == UserRole.superAdmin;

      if (!isAuthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        // Super admin lands on /superadmin, school admins on /admin
        return isSuperAdmin ? '/superadmin' : '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      // Super Admin standalone route (no school nav sidebar)
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => AdminScaffold(
          currentPath: '/superadmin',
          child: const SuperAdminDashboardScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AdminScaffold(
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/admin',
            builder: (context, state) => const FleetOverviewScreen(),
          ),
          GoRoute(
            path: '/admin/buses',
            builder: (context, state) => const BusesManagementScreen(),
          ),
          GoRoute(
            path: '/admin/drivers',
            builder: (context, state) => const DriversManagementScreen(),
          ),
          GoRoute(
            path: '/admin/students',
            builder: (context, state) => const StudentsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/parents',
            builder: (context, state) => const ParentsManagementScreen(),
          ),
          GoRoute(
            path: '/admin/notifications',
            builder: (context, state) => const NotificationAuditScreen(),
          ),
          GoRoute(
            path: '/admin/settings',
            builder: (context, state) => const OrganizationSettingsScreen(),
          ),
          GoRoute(
            path: '/admin/stats',
            builder: (context, state) => const DbUsageStatsScreen(),
          ),
        ],
      ),
    ],
  );
});
