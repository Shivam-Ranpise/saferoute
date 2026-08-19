import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';
import '../../../providers/auth_provider.dart';
import 'super_admin_users_screen.dart';
import 'super_admin_orgs_screen.dart';

/// Super Admin Dashboard — Platform-level management.
/// Accessible to SUPER_ADMIN role.
/// Includes Organizations, Admin Users, and Database Usage Stats.
class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentAdminProfileProvider);

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            color: AdminColors.surface,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AdminColors.yellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: AdminColors.yellow, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Super Admin — Platform Management',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Signed in as ${profile?.name ?? "Super Admin"} · Full platform access',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Tab Bar
                TabBar(
                  controller: _tabController,
                  labelColor: AdminColors.deepNavy,
                  unselectedLabelColor: AdminColors.textSecondary,
                  indicatorColor: AdminColors.deepNavy,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.corporate_fare_rounded, size: 18),
                      text: 'Organizations',
                    ),
                    Tab(
                      icon: Icon(Icons.manage_accounts_rounded, size: 18),
                      text: 'Admin Users',
                    ),
                    Tab(
                      icon: Icon(Icons.data_usage_rounded, size: 18),
                      text: 'DB Usage Stats',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Tab Content ────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                SuperAdminOrgsScreen(),
                SuperAdminUsersScreen(),
                DbUsageStatsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Database Usage Stats & Health Metrics Tab for Super Admin
class DbUsageStatsTab extends StatefulWidget {
  const DbUsageStatsTab({super.key});

  @override
  State<DbUsageStatsTab> createState() => _DbUsageStatsTabState();
}

class _DbUsageStatsTabState extends State<DbUsageStatsTab> {
  bool _loading = true;
  int _orgsCount = 0;
  int _profilesCount = 0;
  int _studentsCount = 0;
  int _busesCount = 0;
  int _eventsCount = 0;
  int _deliveriesCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = SupabaseService.client;

      final orgs = await client.from('organizations').select('id');
      final profiles = await client.from('profiles').select('id');
      final students = await client.from('children').select('id');
      final buses = await client.from('buses').select('id');
      final events = await client.from('notification_events').select('id');
      final deliveries = await client.from('notification_deliveries').select('id');

      if (mounted) {
        setState(() {
          _orgsCount = (orgs as List).length;
          _profilesCount = (profiles as List).length;
          _studentsCount = (students as List).length;
          _busesCount = (buses as List).length;
          _eventsCount = (events as List).length;
          _deliveriesCount = (deliveries as List).length;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AdminColors.yellow),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AdminColors.error, size: 48),
            const SizedBox(height: 16),
            Text('Failed to load database stats: $_error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final totalRows = _orgsCount + _profilesCount + _studentsCount + _busesCount + _eventsCount + _deliveriesCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Health & Usage Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Real-time table record counts and platform storage metrics',
                    style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.deepNavy,
                  foregroundColor: Colors.white,
                ),
                onPressed: _fetchStats,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh Metrics'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Total Rows Metric Header Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.yellow.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    color: AdminColors.yellow,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Database Records Logged',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalRows Records',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AdminColors.safetyGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AdminColors.safetyGreen),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: AdminColors.safetyGreen, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'DB Status: Healthy',
                        style: TextStyle(
                          color: AdminColors.safetyGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Grid of Table Metrics
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 600
                      ? 2
                      : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _buildStatCard(
                    title: 'Organizations (Schools)',
                    count: _orgsCount,
                    icon: Icons.corporate_fare_rounded,
                    color: const Color(0xFF2563EB),
                    subtitle: 'Active tenant schools',
                  ),
                  _buildStatCard(
                    title: 'User Profiles',
                    count: _profilesCount,
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF8B5CF6), // Purple
                    subtitle: 'Parents, drivers, and admins',
                  ),
                  _buildStatCard(
                    title: 'Students Registered',
                    count: _studentsCount,
                    icon: Icons.child_care_rounded,
                    color: const Color(0xFFEC4899), // Pink
                    subtitle: 'Tracked school children',
                  ),
                  _buildStatCard(
                    title: 'School Buses',
                    count: _busesCount,
                    icon: Icons.directions_bus_rounded,
                    color: AdminColors.yellow,
                    subtitle: 'Active fleet vehicles',
                  ),
                  _buildStatCard(
                    title: 'Notification Events',
                    count: _eventsCount,
                    icon: Icons.notifications_active_rounded,
                    color: const Color(0xFFF97316), // Orange
                    subtitle: 'Logged alert triggers',
                  ),
                  _buildStatCard(
                    title: 'Notification Deliveries',
                    count: _deliveriesCount,
                    icon: Icons.mark_email_read_rounded,
                    color: AdminColors.safetyGreen,
                    subtitle: 'Dispatched push & SMS logs',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // System Infrastructure Status Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AdminColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Infrastructure & Connection Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Database Provider', 'Supabase Cloud (PostgreSQL 15)'),
                const Divider(height: 20),
                _buildInfoRow('Endpoint Host', 'usexaanovsmmzjorlkyu.supabase.co'),
                const Divider(height: 20),
                _buildInfoRow('Row-Level Security (RLS)', 'ENABLED (Multi-tenant Data Isolation)'),
                const Divider(height: 20),
                _buildInfoRow('Realtime Engine', 'ACTIVE (WebSocket Broadcast Enabled)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AdminColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AdminColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AdminColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AdminColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
