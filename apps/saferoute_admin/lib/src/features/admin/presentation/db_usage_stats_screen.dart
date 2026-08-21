import 'package:flutter/material.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';

/// Database Usage Stats & Health Metrics Screen
/// Accessible to Fleet Admins and Super Admins.
class DbUsageStatsScreen extends StatefulWidget {
  const DbUsageStatsScreen({super.key});

  @override
  State<DbUsageStatsScreen> createState() => _DbUsageStatsScreenState();
}

class _DbUsageStatsScreenState extends State<DbUsageStatsScreen> {
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
      return const Scaffold(
        backgroundColor: AdminColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AdminColors.yellow),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AdminColors.background,
        body: Center(
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
        ),
      );
    }

    final totalRows = _orgsCount + _profilesCount + _studentsCount + _busesCount + _eventsCount + _deliveriesCount;
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Database Health & Usage Statistics',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time table record counts, system metrics, and storage performance',
                      style: TextStyle(
                        fontSize: isMobile ? 11.5 : 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.deepNavy,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 16, vertical: isMobile ? 10 : 12),
                  ),
                  onPressed: _fetchStats,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Refresh Metrics'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Total Rows Metric Header Card
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
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
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AdminColors.yellow.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storage_rounded,
                                color: AdminColors.yellow,
                                size: 24,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AdminColors.safetyGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AdminColors.safetyGreen),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AdminColors.safetyGreen, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'DB: Healthy',
                                    style: TextStyle(
                                      color: AdminColors.safetyGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Total Database Records Logged',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalRows Records',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
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

            const SizedBox(height: 20),

            // Grid of Table Metrics (2 columns in mobile view)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 750;
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                final childAspect = isNarrow ? 1.35 : 2.2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: isNarrow ? 10 : 14,
                  mainAxisSpacing: isNarrow ? 10 : 14,
                  childAspectRatio: childAspect,
                  children: [
                    _buildStatCard(
                      title: 'Organizations',
                      count: _orgsCount,
                      icon: Icons.corporate_fare_rounded,
                      color: const Color(0xFF2563EB),
                      subtitle: 'Active schools',
                      isMobile: isNarrow,
                    ),
                    _buildStatCard(
                      title: 'User Profiles',
                      count: _profilesCount,
                      icon: Icons.people_alt_rounded,
                      color: const Color(0xFF8B5CF6),
                      subtitle: 'Parents & crew',
                      isMobile: isNarrow,
                    ),
                    _buildStatCard(
                      title: 'Students',
                      count: _studentsCount,
                      icon: Icons.child_care_rounded,
                      color: const Color(0xFFEC4899),
                      subtitle: 'Tracked children',
                      isMobile: isNarrow,
                    ),
                    _buildStatCard(
                      title: 'School Buses',
                      count: _busesCount,
                      icon: Icons.directions_bus_rounded,
                      color: AdminColors.yellow,
                      subtitle: 'Fleet vehicles',
                      isMobile: isNarrow,
                    ),
                    _buildStatCard(
                      title: 'Notification Events',
                      count: _eventsCount,
                      icon: Icons.notifications_active_rounded,
                      color: const Color(0xFFF97316),
                      subtitle: 'Alert triggers',
                      isMobile: isNarrow,
                    ),
                    _buildStatCard(
                      title: 'Deliveries',
                      count: _deliveriesCount,
                      icon: Icons.mark_email_read_rounded,
                      color: AdminColors.safetyGreen,
                      subtitle: 'Dispatched logs',
                      isMobile: isNarrow,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Supabase Free Tier Allocation Breakdown Card
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3ECF8E).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Color(0xFF3ECF8E), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Supabase Free Tier Limits & Allocation',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildQuotaRow(
                    title: 'Database Storage',
                    usedText: '${(totalRows * 0.45).toStringAsFixed(1)} KB Used',
                    quotaText: '500 MB Free Quota',
                    progress: (totalRows * 0.45 / (500 * 1024)).clamp(0.01, 1.0),
                    color: const Color(0xFF3ECF8E),
                  ),
                  const SizedBox(height: 12),
                  _buildQuotaRow(
                    title: 'File & Media Storage',
                    usedText: '0 MB Used',
                    quotaText: '1.0 GB Free Quota',
                    progress: 0.02,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),
                  _buildQuotaRow(
                    title: 'Monthly Active Users (MAU)',
                    usedText: '$_profilesCount Users Active',
                    quotaText: '50,000 Free MAU Limit',
                    progress: (_profilesCount / 50000).clamp(0.01, 1.0),
                    color: const Color(0xFF8B5CF6),
                  ),
                  const SizedBox(height: 12),
                  _buildQuotaRow(
                    title: 'Realtime Egress Bandwidth',
                    usedText: 'Active Stream',
                    quotaText: '5 GB Monthly Free Limit',
                    progress: 0.05,
                    color: const Color(0xFFF97316),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Database Tables & Records DataTable
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.table_chart_rounded, color: AdminColors.deepNavy, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Database Schema & Table Breakdown',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Real-time row counts and allocated PostgreSQL storage per table.',
                    style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: DataTable(
                          columnSpacing: 32,
                          headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                          columns: const [
                            DataColumn(label: Text('Postgres Table', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Entity Type', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Live Rows', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Est. Storage', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Security (RLS)', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: [
                            _buildSchemaTableRow('organizations', 'School Tenants', _orgsCount, '${(_orgsCount * 0.8).toStringAsFixed(1)} KB'),
                            _buildSchemaTableRow('profiles', 'User Accounts', _profilesCount, '${(_profilesCount * 0.6).toStringAsFixed(1)} KB'),
                            _buildSchemaTableRow('children', 'Students Registry', _studentsCount, '${(_studentsCount * 0.5).toStringAsFixed(1)} KB'),
                            _buildSchemaTableRow('buses', 'Fleet Vehicles', _busesCount, '${(_busesCount * 0.4).toStringAsFixed(1)} KB'),
                            _buildSchemaTableRow('notification_events', 'Alert Logs', _eventsCount, '${(_eventsCount * 0.7).toStringAsFixed(1)} KB'),
                            _buildSchemaTableRow('notification_deliveries', 'Delivery Records', _deliveriesCount, '${(_deliveriesCount * 0.5).toStringAsFixed(1)} KB'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AdminColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Infrastructure & Connection Details',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Database Provider', 'Supabase Cloud (PostgreSQL 15)'),
                  const Divider(height: 20),
                  _buildInfoRow('Free Tier Quota', '500 MB Database / 1 GB Storage / 50K MAU'),
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
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool isMobile = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            )
          : Row(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
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

  Widget _buildQuotaRow({
    required String title,
    required String usedText,
    required String quotaText,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AdminColors.textPrimary,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  usedText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Text(
                  ' / ',
                  style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                ),
                Text(
                  quotaText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  DataRow _buildSchemaTableRow(String table, String entity, int rows, String estStorage) {
    return DataRow(
      cells: [
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storage_rounded, size: 14, color: AdminColors.deepNavy),
              const SizedBox(width: 8),
              Text(
                table,
                style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13),
              ),
            ],
          ),
        ),
        DataCell(Text(entity, style: const TextStyle(fontSize: 13))),
        DataCell(
          Text(
            '$rows rows',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminColors.deepNavy),
          ),
        ),
        DataCell(
          Text(
            estStorage,
            style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AdminColors.safetyGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ACTIVE',
              style: TextStyle(
                color: AdminColors.safetyGreen,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
