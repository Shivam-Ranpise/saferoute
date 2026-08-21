import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../../theme/admin_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../providers/admin_providers.dart';

class AdminScaffold extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AdminScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  Future<void> _handleGlobalRefresh(BuildContext context, WidgetRef ref) async {
    ref.invalidate(adminBusesProvider);
    ref.invalidate(adminDriversProvider);
    ref.invalidate(adminStudentsProvider);
    ref.invalidate(adminParentsProvider);
    ref.invalidate(currentOrganizationProvider);
    ref.invalidate(organizationStatsProvider);
    ref.invalidate(notificationAuditLogsProvider);
    ref.invalidate(currentAdminProfileProvider);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AdminColors.safetyGreen, size: 16),
            SizedBox(width: 8),
            Text('Dashboard data refreshed'),
          ],
        ),
        duration: Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF1E293B),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentAdminProfileProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;

    final sidebarContent = Container(
      width: 260,
      color: AdminColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminColors.yellow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: AdminColors.deepNavy,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SafeRoute',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Fleet Command Center',
                        style: TextStyle(
                          color: AdminColors.sidebarText,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Navigation Items
                  _buildNavItem(
                    context,
                    icon: Icons.dashboard_rounded,
                    label: 'Fleet Overview',
                    route: '/admin',
                    isSelected: currentPath == '/admin',
                    isMobile: isMobile,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.directions_bus_rounded,
                    label: 'Buses & Fleet',
                    route: '/admin/buses',
                    isSelected: currentPath == '/admin/buses',
                    isMobile: isMobile,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.badge_rounded,
                    label: 'Drivers Registry',
                    route: '/admin/drivers',
                    isSelected: currentPath == '/admin/drivers',
                    isMobile: isMobile,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.people_alt_rounded,
                    label: 'Parents & Guardians',
                    route: '/admin/parents',
                    isSelected: currentPath == '/admin/parents',
                    isMobile: isMobile,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.school_rounded,
                    label: 'Students & Stops',
                    route: '/admin/students',
                    isSelected: currentPath == '/admin/students',
                    isMobile: isMobile,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.notifications_active_rounded,
                    label: 'Notification Logs',
                    route: '/admin/notifications',
                    isSelected: currentPath == '/admin/notifications',
                    isMobile: isMobile,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.data_usage_rounded,
                    label: 'DB Usage Stats',
                    route: '/admin/stats',
                    isSelected: currentPath == '/admin/stats',
                    isMobile: isMobile,
                  ),

                  // Super Admin-only: Organizations
                  if (profile?.role == UserRole.superAdmin) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 12, 4),
                      child: Text(
                        'PLATFORM',
                        style: TextStyle(
                          color: AdminColors.sidebarText,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildNavItem(
                      context,
                      icon: Icons.corporate_fare_rounded,
                      label: 'Organizations & Admins',
                      route: '/superadmin',
                      isSelected: currentPath == '/superadmin',
                      isMobile: isMobile,
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(24, 16, 12, 4),
                      child: Text(
                        'SCHOOL',
                        style: TextStyle(
                          color: AdminColors.sidebarText,
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  _buildNavItem(
                    context,
                    icon: Icons.settings_suggest_rounded,
                    label: 'School Settings',
                    route: '/admin/settings',
                    isSelected: currentPath == '/admin/settings' &&
                        profile?.role != UserRole.superAdmin,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Admin Profile & Logout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFF1E293B), width: 1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AdminColors.blue,
                  radius: 16,
                  child: Text(
                    profile?.name.isNotEmpty == true
                        ? profile!.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        profile?.name ?? 'Administrator',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        profile?.role == UserRole.superAdmin
                            ? 'Super Admin'
                            : profile?.role == UserRole.driver
                                ? 'Driver'
                                : 'School Admin',
                        style: const TextStyle(
                          color: AdminColors.sidebarText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: AdminColors.sidebarText,
                    size: 18,
                  ),
                  tooltip: 'Sign Out',
                  onPressed: () {
                    ref.read(adminAuthProvider.notifier).signOut();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        appBar: AppBar(
          backgroundColor: AdminColors.sidebarBg,
          elevation: 0,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white),
              tooltip: 'Open Menu',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AdminColors.yellow,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AdminColors.deepNavy,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'SafeRoute Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AdminColors.yellow, size: 22),
              tooltip: 'Reload Data',
              onPressed: () => _handleGlobalRefresh(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
              tooltip: 'Sign Out',
              onPressed: () {
                ref.read(adminAuthProvider.notifier).signOut();
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: AdminColors.sidebarBg,
          child: SafeArea(
            child: sidebarContent,
          ),
        ),
        body: RefreshIndicator(
          color: AdminColors.yellow,
          backgroundColor: const Color(0xFF0F172A),
          displacement: 20,
          onRefresh: () => _handleGlobalRefresh(context, ref),
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Row(
        children: [
          sidebarContent,
          Expanded(
            child: Container(
              color: AdminColors.background,
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    required bool isSelected,
    required bool isMobile,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? AdminColors.sidebarActive : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            color: isSelected
                ? AdminColors.sidebarTextActive
                : AdminColors.sidebarText,
            size: 20,
          ),
          title: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? AdminColors.sidebarTextActive
                  : AdminColors.sidebarText,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: () {
            if (isMobile) {
              Navigator.of(context).pop(); // Close drawer
            }
            if (!isSelected) {
              context.go(route);
            }
          },
        ),
      ),
    );
  }
}
