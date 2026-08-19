import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../../theme/admin_theme.dart';
import '../../../../providers/auth_provider.dart';

class AdminScaffold extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AdminScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentAdminProfileProvider);

    return Scaffold(
      body: Row(
        children: [
          // ─── DESKTOP SIDEBAR ─────────────────────────────────────────
          Container(
            width: 240,
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
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'Fleet Command Center',
                              style: TextStyle(
                                color: AdminColors.sidebarText,
                                fontSize: 10,
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

                const SizedBox(height: 16),

                // Navigation Items
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Fleet Overview',
                  route: '/admin',
                  isSelected: currentPath == '/admin',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.directions_bus_rounded,
                  label: 'Buses & Fleet',
                  route: '/admin/buses',
                  isSelected: currentPath == '/admin/buses',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.badge_rounded,
                  label: 'Drivers Registry',
                  route: '/admin/drivers',
                  isSelected: currentPath == '/admin/drivers',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.school_rounded,
                  label: 'Students & Stops',
                  route: '/admin/students',
                  isSelected: currentPath == '/admin/students',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.people_alt_rounded,
                  label: 'Parents & Guardians',
                  route: '/admin/parents',
                  isSelected: currentPath == '/admin/parents',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.notifications_active_rounded,
                  label: 'Notification Logs',
                  route: '/admin/notifications',
                  isSelected: currentPath == '/admin/notifications',
                ),
                _buildNavItem(
                  context,
                  icon: Icons.data_usage_rounded,
                  label: 'DB Usage Stats',
                  route: '/admin/stats',
                  isSelected: currentPath == '/admin/stats',
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
                ),

                const Spacer(),

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
          ),

          // ─── MAIN CONTENT AREA ───────────────────────────────────────
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
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            if (!isSelected) {
              context.go(route);
            }
          },
        ),
      ),
    );
  }
}
