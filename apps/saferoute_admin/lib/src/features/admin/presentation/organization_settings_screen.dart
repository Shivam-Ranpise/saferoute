import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';
import '../providers/admin_providers.dart';
import 'widgets/admin_map_picker_dialog.dart';

class OrganizationSettingsScreen extends ConsumerStatefulWidget {
  const OrganizationSettingsScreen({super.key});

  @override
  ConsumerState<OrganizationSettingsScreen> createState() =>
      _OrganizationSettingsScreenState();
}

class _OrganizationSettingsScreenState
    extends ConsumerState<OrganizationSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _nameController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _addressController = TextEditingController();

  // School Destination Coordinates
  double? _latitude;
  double? _longitude;
  double _geofenceRadius = 200;

  // Policies & Retentions
  double _gpsRetentionDays = 30;
  double _notificationRetentionDays = 90;
  bool _driverEmergencyAlerts = false;
  bool _driverCustomAlerts = true;

  // Daily Operating Schedule for Monday..Sunday
  final Map<String, Map<String, dynamic>> _dailySchedule = {
    'Monday': {'enabled': true, 'start_time': '10:00', 'end_time': '17:00'},
    'Tuesday': {'enabled': true, 'start_time': '10:00', 'end_time': '17:00'},
    'Wednesday': {'enabled': true, 'start_time': '10:00', 'end_time': '17:00'},
    'Thursday': {'enabled': true, 'start_time': '10:00', 'end_time': '17:00'},
    'Friday': {'enabled': true, 'start_time': '10:00', 'end_time': '17:00'},
    'Saturday': {'enabled': true, 'start_time': '07:00', 'end_time': '11:00'},
    'Sunday': {'enabled': false, 'start_time': '09:00', 'end_time': '15:00'},
  };

  // External API Gateway Controllers
  final _whatsappUrlController = TextEditingController();
  final _whatsappTokenController = TextEditingController();
  final _smsUrlController = TextEditingController();
  final _smsSenderIdController = TextEditingController();
  final _smsApiKeyController = TextEditingController();
  final _fcmProjectIdController = TextEditingController();
  final _fcmClientEmailController = TextEditingController();
  final _fcmPrivateKeyController = TextEditingController();
  final _fcmEndpointController = TextEditingController();

  bool _showPrivateKey = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _timezoneController.dispose();
    _addressController.dispose();
    _whatsappUrlController.dispose();
    _whatsappTokenController.dispose();
    _smsUrlController.dispose();
    _smsSenderIdController.dispose();
    _smsApiKeyController.dispose();
    _fcmProjectIdController.dispose();
    _fcmEndpointController.dispose();
    super.dispose();
  }

  void _populateForm(Organization org) {
    if (_initialized) return;
    _nameController.text = org.name;
    _timezoneController.text = org.timezone;
    _addressController.text = org.address ?? '';
    _latitude = org.latitude;
    _longitude = org.longitude;
    _geofenceRadius = org.geofenceRadiusMeters.toDouble().clamp(50, 1000);

    _gpsRetentionDays =
        org.gpsHistoryRetentionDays.toDouble().clamp(30, 365);
    _notificationRetentionDays =
        org.notificationLogRetentionDays.toDouble().clamp(30, 365);
    _driverEmergencyAlerts = org.driverCanSendEmergencyAlerts;
    _driverCustomAlerts = org.driverCanSendCustomAlerts;

    final sched = org.schoolSchedule;
    if (sched.containsKey('daily_schedule') && sched['daily_schedule'] is Map) {
      final daily = sched['daily_schedule'] as Map<String, dynamic>;
      daily.forEach((day, data) {
        if (_dailySchedule.containsKey(day) && data is Map) {
          _dailySchedule[day]!['enabled'] = data['enabled'] as bool? ?? true;
          _dailySchedule[day]!['start_time'] = data['start_time'] as String? ?? '10:00';
          _dailySchedule[day]!['end_time'] = data['end_time'] as String? ?? '17:00';
        }
      });
    }

    final api = org.apiParameters;
    _whatsappUrlController.text = api['whatsapp_endpoint'] as String? ?? '';
    _whatsappTokenController.text = api['whatsapp_token'] as String? ?? '';
    _smsUrlController.text = api['sms_endpoint'] as String? ?? '';
    _smsSenderIdController.text = api['sms_sender_id'] as String? ?? '';
    _smsApiKeyController.text = api['sms_api_key'] as String? ?? '';
    
    // Resolve FCM fields from nested map or flat keys
    final fcmMap = api['fcm'] is Map ? (api['fcm'] as Map) : null;
    _fcmProjectIdController.text = fcmMap?['project_id'] as String? ?? api['fcm_project_id'] as String? ?? 'saferoute-80c5b';
    _fcmClientEmailController.text = fcmMap?['client_email'] as String? ?? api['fcm_client_email'] as String? ?? '';
    _fcmPrivateKeyController.text = fcmMap?['private_key'] as String? ?? api['fcm_private_key'] as String? ?? '';
    _fcmEndpointController.text = api['fcm_endpoint'] as String? ?? '';
    _initialized = true;
  }

  Future<void> _saveSettings(Organization currentOrg) async {
    setState(() => _isSaving = true);
    try {
      final workingDaysList = _dailySchedule.entries
          .where((e) => e.value['enabled'] == true)
          .map((e) => e.key)
          .toList();

      final updatedSchedule = {
        'daily_schedule': _dailySchedule,
        'working_days': workingDaysList,
      };

      final fcmConfig = {
        'project_id': _fcmProjectIdController.text.trim().isNotEmpty
            ? _fcmProjectIdController.text.trim()
            : 'saferoute-80c5b',
        'client_email': _fcmClientEmailController.text.trim(),
        'private_key': _fcmPrivateKeyController.text.trim(),
      };

      final updatedApi = {
        'whatsapp_endpoint': _whatsappUrlController.text.trim(),
        'whatsapp_token': _whatsappTokenController.text.trim(),
        'sms_endpoint': _smsUrlController.text.trim(),
        'sms_sender_id': _smsSenderIdController.text.trim(),
        'sms_api_key': _smsApiKeyController.text.trim(),
        'fcm_project_id': fcmConfig['project_id'],
        'fcm_client_email': fcmConfig['client_email'],
        'fcm_private_key': fcmConfig['private_key'],
        'fcm_endpoint': _fcmEndpointController.text.trim(),
        if (fcmConfig['private_key']!.isNotEmpty && fcmConfig['client_email']!.isNotEmpty)
          'fcm': fcmConfig,
      };

      final updatedOrg = Organization(
        id: currentOrg.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        timezone: _timezoneController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        geofenceRadiusMeters: _geofenceRadius.toInt(),
        gpsHistoryRetentionDays: _gpsRetentionDays.toInt(),
        notificationLogRetentionDays: _notificationRetentionDays.toInt(),
        driverCanSendEmergencyAlerts: _driverEmergencyAlerts,
        driverCanSendCustomAlerts: _driverCustomAlerts,
        schoolSchedule: updatedSchedule,
        apiParameters: updatedApi,
        notificationSettings: currentOrg.notificationSettings,
        createdAt: currentOrg.createdAt,
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(adminRepositoryProvider);
      await repo.updateOrganization(updatedOrg);

      ref.invalidate(currentOrganizationProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ School settings & operating schedule saved successfully!'),
            backgroundColor: AdminColors.safetyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganizationProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: orgAsync.when(
        data: (org) {
          if (org == null) {
            return const Center(child: Text('No organization profile found'));
          }

          _populateForm(org);

          return Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row with Title & Save Button
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
                          '${org.name} — School Settings',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: AdminColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Configure daily operating hours, geofence, and API keys',
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
                            horizontal: isMobile ? 16 : 22, vertical: isMobile ? 10 : 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: const Text('Save All Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isSaving ? null : () => _saveSettings(org),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Navigation Tabs Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorColor: AdminColors.deepNavy,
                    indicatorWeight: 3,
                    labelColor: AdminColors.deepNavy,
                    unselectedLabelColor: AdminColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'School Identity'),
                      Tab(icon: Icon(Icons.access_time_filled_rounded, size: 18), text: 'Weekly Operating Hours'),
                      Tab(icon: Icon(Icons.security_rounded, size: 18), text: 'Safety & Data Policies'),
                      Tab(icon: Icon(Icons.api_rounded, size: 18), text: 'API & Push Gateways'),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Tab Views Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildIdentityTab(),
                      _buildOperatingHoursTab(),
                      _buildSafetyPoliciesTab(),
                      _buildApiGatewaysTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AdminColors.yellow),
        ),
        error: (err, _) => Center(
          child: Text('Failed to load organization settings: $err'),
        ),
      ),
    );
  }

  // ── Tab 1: School Identity & Location ──────────────────────────────────────
  Widget _buildIdentityTab() {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'School Identity & Location Profile',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'School / Institution Name *',
                  prefixIcon: Icon(Icons.corporate_fare_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _timezoneController,
                decoration: const InputDecoration(
                  labelText: 'Timezone *',
                  prefixIcon: Icon(Icons.language_rounded),
                  hintText: 'Asia/Kolkata',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'School Physical Address',
                  prefixIcon: Icon(Icons.place_rounded),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'School Arrival Destination Coordinates',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AdminColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _latitude != null && _longitude != null
                            ? 'Lat: ${_latitude!.toStringAsFixed(5)}, Lng: ${_longitude!.toStringAsFixed(5)}'
                            : 'No destination coordinates set on OpenStreetMap',
                        style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 16),
                    label: const Text('Pick Location on OpenStreetMap', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      final result = await showDialog<Map<String, double>>(
                        context: context,
                        builder: (ctx) => AdminMapPickerDialog(
                          initialLatitude: _latitude,
                          initialLongitude: _longitude,
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _latitude = result['lat'];
                          _longitude = result['lng'];
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Geofence Arrival Radius: ${_geofenceRadius.toInt()} meters',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    value: _geofenceRadius,
                    min: 50,
                    max: 1000,
                    divisions: 19,
                    label: '${_geofenceRadius.toInt()}m',
                    activeColor: AdminColors.deepNavy,
                    onChanged: (val) => setState(() => _geofenceRadius = val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 2: Weekly Operating Schedule (Interactive DataTable) ───────────────
  Widget _buildOperatingHoursTab() {
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded, color: AdminColors.deepNavy, size: 24),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Weekly Operating Schedule',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Configure specific start and end times for each day',
                            style: TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.flash_on_rounded, size: 16, color: AdminColors.deepNavy),
                        label: const Text('Set Mon–Fri 10–5', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() {
                            for (final d in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
                              _dailySchedule[d]!['enabled'] = true;
                              _dailySchedule[d]!['start_time'] = '10:00';
                              _dailySchedule[d]!['end_time'] = '17:00';
                            }
                          });
                        },
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.wb_sunny_rounded, size: 16, color: Color(0xFFF97316)),
                        label: const Text('Set Sat 7–11 AM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() {
                            _dailySchedule['Saturday']!['enabled'] = true;
                            _dailySchedule['Saturday']!['start_time'] = '07:00';
                            _dailySchedule['Saturday']!['end_time'] = '11:00';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // Interactive DataTable for 7-Day Schedule
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 24,
                      horizontalMargin: 16,
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      columns: const [
                        DataColumn(label: Text('Day of Week', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Operating Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Opening / Start Time', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Closing / End Time', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: daysOfWeek.map((day) {
                        final dayData = _dailySchedule[day]!;
                        final isEnabled = dayData['enabled'] as bool;
                        final startTime = dayData['start_time'] as String;
                        final endTime = dayData['end_time'] as String;

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  Icon(
                                    day == 'Sunday' || day == 'Saturday'
                                        ? Icons.weekend_rounded
                                        : Icons.calendar_today_rounded,
                                    size: 16,
                                    color: isEnabled ? AdminColors.deepNavy : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    day,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isEnabled ? AdminColors.textPrimary : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  Checkbox(
                                    value: isEnabled,
                                    activeColor: AdminColors.deepNavy,
                                    onChanged: (val) {
                                      setState(() {
                                        _dailySchedule[day]!['enabled'] = val ?? false;
                                      });
                                    },
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isEnabled
                                          ? AdminColors.safetyGreen.withValues(alpha: 0.15)
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      isEnabled ? 'Open / Active' : 'Closed',
                                      style: TextStyle(
                                        color: isEnabled ? AdminColors.safetyGreen : Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              isEnabled
                                  ? InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () async {
                                        final parts = startTime.split(':');
                                        final initialTime = TimeOfDay(
                                          hour: int.tryParse(parts[0]) ?? 10,
                                          minute: int.tryParse(parts[1]) ?? 0,
                                        );
                                        final picked = await showTimePicker(context: context, initialTime: initialTime);
                                        if (picked != null) {
                                          final formatted =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                          setState(() {
                                            _dailySchedule[day]!['start_time'] = formatted;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AdminColors.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time_filled_rounded, size: 14, color: AdminColors.deepNavy),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatTimeString(startTime),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const Text('—', style: TextStyle(color: Colors.grey)),
                            ),
                            DataCell(
                              isEnabled
                                  ? InkWell(
                                      borderRadius: BorderRadius.circular(6),
                                      onTap: () async {
                                        final parts = endTime.split(':');
                                        final initialTime = TimeOfDay(
                                          hour: int.tryParse(parts[0]) ?? 17,
                                          minute: int.tryParse(parts[1]) ?? 0,
                                        );
                                        final picked = await showTimePicker(context: context, initialTime: initialTime);
                                        if (picked != null) {
                                          final formatted =
                                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                          setState(() {
                                            _dailySchedule[day]!['end_time'] = formatted;
                                          });
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AdminColors.border),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time_rounded, size: 14, color: AdminColors.deepNavy),
                                            const SizedBox(width: 6),
                                            Text(
                                              _formatTimeString(endTime),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const Text('—', style: TextStyle(color: Colors.grey)),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  TextButton(
                                    style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                                    onPressed: () {
                                      setState(() {
                                        _dailySchedule[day]!['enabled'] = !_dailySchedule[day]!['enabled'];
                                      });
                                    },
                                    child: Text(
                                      isEnabled ? 'Mark Closed' : 'Mark Open',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isEnabled ? Colors.redAccent : AdminColors.safetyGreen,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 3: Safety & Data Policies ──────────────────────────────────────────
  Widget _buildSafetyPoliciesTab() {
    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Driver Privileges & Safety Alert Rules',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Drivers Can Send Emergency SOS Alerts'),
                subtitle: const Text('Allows driver app to trigger emergency broadcasts to parents'),
                value: _driverEmergencyAlerts,
                activeColor: AdminColors.deepNavy,
                onChanged: (val) => setState(() => _driverEmergencyAlerts = val),
              ),
              SwitchListTile(
                title: const Text('Drivers Can Send Custom Announcements'),
                subtitle: const Text('Allows drivers to dispatch route delay or custom notices'),
                value: _driverCustomAlerts,
                activeColor: AdminColors.deepNavy,
                onChanged: (val) => setState(() => _driverCustomAlerts = val),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Data Retention & Storage Limits',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              ),
              const SizedBox(height: 16),
              Text(
                'GPS History Retention: ${_gpsRetentionDays.toInt()} Days',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Slider(
                value: _gpsRetentionDays,
                min: 30,
                max: 365,
                divisions: 11,
                label: '${_gpsRetentionDays.toInt()} Days',
                activeColor: AdminColors.deepNavy,
                onChanged: (val) => setState(() => _gpsRetentionDays = val),
              ),
              const SizedBox(height: 12),
              Text(
                'Notification Log Retention: ${_notificationRetentionDays.toInt()} Days',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Slider(
                value: _notificationRetentionDays,
                min: 30,
                max: 365,
                divisions: 11,
                label: '${_notificationRetentionDays.toInt()} Days',
                activeColor: AdminColors.deepNavy,
                onChanged: (val) => setState(() => _notificationRetentionDays = val),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper methods for Firebase Service Account JSON Upload & Parsing ──
  Future<void> _handleUploadJson() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileBytes = file.bytes;
        if (fileBytes != null) {
          final jsonString = utf8.decode(fileBytes);
          _parseAndApplyFcmJson(jsonString);
        } else {
          _showPasteJsonDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        _showPasteJsonDialog();
      }
    }
  }

  void _parseAndApplyFcmJson(String jsonString) {
    try {
      final Map<String, dynamic> data = json.decode(jsonString);
      final projectId = data['project_id'] as String?;
      final clientEmail = data['client_email'] as String?;
      final privateKey = data['private_key'] as String?;

      if (projectId == null || clientEmail == null || privateKey == null) {
        throw 'Invalid service account JSON: Missing project_id, client_email, or private_key';
      }

      setState(() {
        _fcmProjectIdController.text = projectId;
        _fcmClientEmailController.text = clientEmail;
        _fcmPrivateKeyController.text = privateKey;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Firebase Service Account JSON parsed successfully! Click "Save All Settings" to persist.'),
          backgroundColor: AdminColors.safetyGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error parsing JSON: $e'),
          backgroundColor: AdminColors.error,
        ),
      );
    }
  }

  void _showPasteJsonDialog() {
    final pasteController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.code_rounded, color: AdminColors.deepNavy),
            SizedBox(width: 10),
            Text('Paste Service Account JSON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste the complete contents of your firebase-service-account.json below:',
                style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pasteController,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: '{\n  "type": "service_account",\n  "project_id": "saferoute-80c5b",\n  ...\n}',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.deepNavy,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Parse & Apply'),
            onPressed: () {
              final text = pasteController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(dialogCtx);
                _parseAndApplyFcmJson(text);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminColors.textSecondary),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AdminColors.textPrimary),
          ),
        ),
      ],
    );
  }

  // ── Tab 4: API Gateways & Cloud Messaging ──────────────────────────────────
  Widget _buildApiGatewaysTab() {
    final bool isFcmConfigured = _fcmPrivateKeyController.text.trim().isNotEmpty &&
        _fcmClientEmailController.text.trim().isNotEmpty;

    return SingleChildScrollView(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Firebase Cloud Messaging (FCM) Push Gateway',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'Connects your school organization to Google FCM to dispatch high-priority push notifications and floating banners to parent devices when closed or locked.',
                style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
              ),
              const SizedBox(height: 16),

              if (isFcmConfigured) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AdminColors.safetyGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.safetyGreen.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AdminColors.safetyGreen, size: 22),
                          const SizedBox(width: 10),
                          const Text(
                            'Firebase Service Account Configured',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AdminColors.safetyGreen),
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminColors.deepNavy,
                                  side: const BorderSide(color: AdminColors.deepNavy),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.upload_file_rounded, size: 16),
                                label: const Text('Replace JSON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: _handleUploadJson,
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AdminColors.error,
                                  side: const BorderSide(color: AdminColors.error),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                label: const Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  setState(() {
                                    _fcmClientEmailController.clear();
                                    _fcmPrivateKeyController.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildDetailRow('Project ID', _fcmProjectIdController.text),
                      const SizedBox(height: 10),
                      _buildDetailRow('Client Email', _fcmClientEmailController.text),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            width: 120,
                            child: Text(
                              'Private Key:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminColors.textSecondary),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _showPrivateKey
                                        ? _fcmPrivateKeyController.text
                                        : '•••••••••••••••••••••••••••••••••••••••••••• (RSA 2048-bit Encrypted Private Key)',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: _showPrivateKey ? Colors.black87 : Colors.grey.shade700,
                                    ),
                                    maxLines: _showPrivateKey ? null : 1,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _showPrivateKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    size: 18,
                                    color: AdminColors.textSecondary,
                                  ),
                                  onPressed: () => setState(() => _showPrivateKey = !_showPrivateKey),
                                  tooltip: _showPrivateKey ? 'Hide Private Key' : 'Show Private Key',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            'Firebase Service Account JSON Not Uploaded',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.amber.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload your firebase-service-account.json downloaded from Firebase Console > Project Settings > Service accounts.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.deepNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: const Text('Upload JSON File', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _handleUploadJson,
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdminColors.deepNavy,
                              side: const BorderSide(color: AdminColors.deepNavy),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            ),
                            icon: const Icon(Icons.paste_rounded, size: 18),
                            label: const Text('Paste JSON Text', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _showPasteJsonDialog,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'External Multi-Channel Messaging Gateways',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AdminColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _whatsappUrlController,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp Business API Endpoint URL',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _whatsappTokenController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'WhatsApp API Bearer Token',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: _smsUrlController,
                decoration: const InputDecoration(
                  labelText: 'SMS Gateway HTTP Endpoint',
                  prefixIcon: Icon(Icons.sms_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _smsSenderIdController,
                decoration: const InputDecoration(
                  labelText: 'SMS Sender ID / Header',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _smsApiKeyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'SMS API Key Secret',
                  prefixIcon: Icon(Icons.lock_rounded),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final tod = TimeOfDay(hour: hour, minute: minute);
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      final formattedHour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final formattedMinute = tod.minute.toString().padLeft(2, '0');
      return '$formattedHour:$formattedMinute $period';
    } catch (_) {
      return timeStr;
    }
  }
}
