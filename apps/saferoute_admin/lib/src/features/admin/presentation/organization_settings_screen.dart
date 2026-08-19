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
    extends ConsumerState<OrganizationSettingsScreen> {
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

  // School Operating Hours & Bus Schedule
  final _schoolStartTimeController = TextEditingController(text: '10:00');
  final _schoolEndTimeController = TextEditingController(text: '17:00');
  List<String> _workingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  // External API Gateway Controllers
  final _whatsappUrlController = TextEditingController();
  final _whatsappTokenController = TextEditingController();
  final _smsUrlController = TextEditingController();
  final _smsSenderIdController = TextEditingController();
  final _smsApiKeyController = TextEditingController();
  final _fcmProjectIdController = TextEditingController();
  final _fcmEndpointController = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;

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
    _schoolStartTimeController.text = sched['start_time'] as String? ?? '10:00';
    _schoolEndTimeController.text = sched['end_time'] as String? ?? '17:00';
    if (sched['working_days'] is List) {
      _workingDays = List<String>.from(sched['working_days'] as List);
    }

    final api = org.apiParameters;
    _whatsappUrlController.text = api['whatsapp_endpoint'] as String? ?? '';
    _whatsappTokenController.text = api['whatsapp_token'] as String? ?? '';
    _smsUrlController.text = api['sms_endpoint'] as String? ?? '';
    _smsSenderIdController.text = api['sms_sender_id'] as String? ?? '';
    _smsApiKeyController.text = api['sms_api_key'] as String? ?? '';
    _fcmProjectIdController.text = api['fcm_project_id'] as String? ?? '';
    _fcmEndpointController.text = api['fcm_endpoint'] as String? ?? '';
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timezoneController.dispose();
    _addressController.dispose();
    _schoolStartTimeController.dispose();
    _schoolEndTimeController.dispose();
    _whatsappUrlController.dispose();
    _whatsappTokenController.dispose();
    _smsUrlController.dispose();
    _smsSenderIdController.dispose();
    _smsApiKeyController.dispose();
    _fcmProjectIdController.dispose();
    _fcmEndpointController.dispose();
    super.dispose();
  }

  Future<void> _pickSchoolLocationOnMap() async {
    final result = await showDialog<LocationPickResult>(
      context: context,
      builder: (ctx) => AdminMapPickerDialog(
        initialLatitude: _latitude,
        initialLongitude: _longitude,
        initialAddress: _addressController.text,
        title: 'Set School Destination & Campus Geofence',
      ),
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
        _addressController.text = result.address;
      });
    }
  }

  Future<void> _saveSettings(Organization org) async {
    setState(() => _isSaving = true);
    try {
      final scheduleMap = {
        'start_time': _schoolStartTimeController.text.trim(),
        'end_time': _schoolEndTimeController.text.trim(),
        'working_days': _workingDays,
      };

      final apiMap = {
        'whatsapp_endpoint': _whatsappUrlController.text.trim(),
        'whatsapp_token': _whatsappTokenController.text.trim(),
        'sms_endpoint': _smsUrlController.text.trim(),
        'sms_sender_id': _smsSenderIdController.text.trim(),
        'sms_api_key': _smsApiKeyController.text.trim(),
        'fcm_project_id': _fcmProjectIdController.text.trim(),
        'fcm_endpoint': _fcmEndpointController.text.trim(),
        'school_schedule': scheduleMap,
      };

      await SupabaseService.client.from('organizations').update({
        'name': _nameController.text.trim(),
        'timezone': _timezoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'geofence_radius_meters': _geofenceRadius.toInt(),
        'driver_can_send_emergency_alerts': _driverEmergencyAlerts,
        'driver_can_send_custom_alerts': _driverCustomAlerts,
        'gps_history_retention_days': _gpsRetentionDays.toInt(),
        'notification_log_retention_days': _notificationRetentionDays.toInt(),
        'api_parameters': apiMap,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', org.id);

      // Reset so the form reloads fresh data from DB after save
      _initialized = false;
      ref.invalidate(currentOrganizationProvider);
      ref.invalidate(organizationStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ School policies & destination address saved successfully!'),
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
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgAsync = ref.watch(currentOrganizationProvider);

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Profile & Safety Policies',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Configure destination address, map location, driver safety permissions, and API parameters',
                      style: TextStyle(
                        fontSize: 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reload Settings',
                  onPressed: () {
                    _initialized = false;
                    ref.invalidate(currentOrganizationProvider);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: orgAsync.when(
                data: (org) {
                  if (org == null) {
                    return const Center(
                      child: Text('No organization profile found.'),
                    );
                  }

                  _populateForm(org);

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Card 1: School Identity & Destination Location ──
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.domain_rounded,
                                        color: AdminColors.deepNavy, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'School Identity & Destination Address',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'This address and pin point serves as the final morning destination and starting drop depot for all bus trips.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AdminColors.textSecondary),
                                ),
                                const Divider(height: 24),

                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _nameController,
                                        decoration: const InputDecoration(
                                          labelText: 'School / Campus Name *',
                                          prefixIcon: Icon(Icons.school_outlined),
                                          hintText: 'e.g. Delhi Public School',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        controller: _timezoneController,
                                        decoration: const InputDecoration(
                                          labelText: 'Timezone',
                                          prefixIcon: Icon(Icons.access_time_rounded),
                                          hintText: 'Asia/Kolkata',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Destination Address & Map Picker
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _addressController,
                                        decoration: const InputDecoration(
                                          labelText: 'School Destination Street Address',
                                          prefixIcon: Icon(Icons.location_city_rounded),
                                          hintText: 'e.g. 45th Main Road, Ring Road Campus',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AdminColors.deepNavy,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: const Icon(Icons.map_rounded, size: 18),
                                      label: const Text('Pick on Map',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      onPressed: _pickSchoolLocationOnMap,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Location Coordinates Status Banner
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _latitude != null && _longitude != null
                                        ? AdminColors.safetyGreen
                                            .withValues(alpha: 0.1)
                                        : AdminColors.warning
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _latitude != null && _longitude != null
                                          ? AdminColors.safetyGreen
                                              .withValues(alpha: 0.4)
                                          : AdminColors.warning
                                              .withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _latitude != null && _longitude != null
                                            ? Icons.check_circle_rounded
                                            : Icons.warning_amber_rounded,
                                        color: _latitude != null && _longitude != null
                                            ? AdminColors.safetyGreen
                                            : AdminColors.warning,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _latitude != null && _longitude != null
                                              ? 'Destination Pin Active: Lat ${_latitude!.toStringAsFixed(5)}, Lon ${_longitude!.toStringAsFixed(5)} (Arrival Geofence: ${_geofenceRadius.toInt()}m)'
                                              : 'No map coordinate pinned yet. Click "Pick on Map" or search the campus location to place marker.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _latitude != null && _longitude != null
                                                ? AdminColors.safetyGreen
                                                : AdminColors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Card 1.5: School Operating Hours & Bus Schedule ──
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.schedule_rounded,
                                        color: AdminColors.blue, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'School Operating Hours & Bus Schedule',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Automated push notifications for morning pickup and evening return routes dynamically adapt based on these hours.',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AdminColors.textSecondary),
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _schoolStartTimeController,
                                        decoration: const InputDecoration(
                                          labelText: 'School Start Time (e.g. 10:00 AM)',
                                          hintText: '10:00',
                                          prefixIcon: Icon(Icons.wb_sunny_outlined),
                                          helperText: 'Morning bus arrival notification cutoff',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: _schoolEndTimeController,
                                        decoration: const InputDecoration(
                                          labelText: 'School Dispersal Time (e.g. 05:00 PM)',
                                          hintText: '17:00',
                                          prefixIcon: Icon(Icons.nights_stay_outlined),
                                          helperText: 'Evening return route start trigger',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Operating Days:',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AdminColors.textPrimary),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    'Monday',
                                    'Tuesday',
                                    'Wednesday',
                                    'Thursday',
                                    'Friday',
                                    'Saturday',
                                    'Sunday',
                                  ].map((day) {
                                    final isSelected = _workingDays.contains(day);
                                    return FilterChip(
                                      label: Text(day),
                                      selected: isSelected,
                                      selectedColor: AdminColors.deepNavy.withValues(alpha: 0.15),
                                      checkmarkColor: AdminColors.deepNavy,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? AdminColors.deepNavy
                                            : AdminColors.textSecondary,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _workingDays.add(day);
                                          } else {
                                            _workingDays.remove(day);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Card 2: Driver Permissions & Alert Rules ──
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.security_rounded,
                                        color: AdminColors.safetyGreen, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Driver Permissions & Broadcast Controls',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                SwitchListTile(
                                  title: const Text(
                                    'Allow Drivers to Broadcast Emergency SOS Alerts',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  subtitle: const Text(
                                    'When enabled, drivers can trigger instant multi-channel push & SMS emergency dispatches',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.textSecondary),
                                  ),
                                  value: _driverEmergencyAlerts,
                                  activeTrackColor: AdminColors.safetyGreen,
                                  onChanged: (val) {
                                    setState(() => _driverEmergencyAlerts = val);
                                  },
                                ),
                                const Divider(),
                                SwitchListTile(
                                  title: const Text(
                                    'Allow Drivers to Send Delay & Traffic Updates',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                  subtitle: const Text(
                                    'Permits drivers to send custom delay notes to parent passenger manifest',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.textSecondary),
                                  ),
                                  value: _driverCustomAlerts,
                                  activeTrackColor: AdminColors.blue,
                                  onChanged: (val) {
                                    setState(() => _driverCustomAlerts = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Card 3: Data Retention Policies ──
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.auto_delete_rounded,
                                        color: AdminColors.warning, size: 20),
                                    SizedBox(width: 10),
                                    Text(
                                      'Data Retention & Compliance Rules',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // GPS Breadcrumbs Retention
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'GPS Breadcrumb History Retention',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Historical route tracking telemetry purged after this duration',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AdminColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AdminColors.deepNavy,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_gpsRetentionDays.toInt()} days',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _gpsRetentionDays,
                                  min: 30,
                                  max: 365,
                                  divisions: 11,
                                  activeColor: AdminColors.deepNavy,
                                  label: '${_gpsRetentionDays.toInt()} days',
                                  onChanged: (val) {
                                    setState(() => _gpsRetentionDays = val);
                                  },
                                ),

                                const SizedBox(height: 20),

                                // Notification Logs Retention
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Notification Audit Logs Retention',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Delivery receipts and multi-channel audit entries purged after this limit',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: AdminColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AdminColors.blueLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_notificationRetentionDays.toInt()} days',
                                        style: const TextStyle(
                                          color: AdminColors.blue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Slider(
                                  value: _notificationRetentionDays,
                                  min: 30,
                                  max: 365,
                                  divisions: 11,
                                  activeColor: AdminColors.blue,
                                  label: '${_notificationRetentionDays.toInt()} days',
                                  onChanged: (val) {
                                    setState(() => _notificationRetentionDays = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Card 4: External API Gateway & Service Parameters ──
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.api_rounded,
                                        color: AdminColors.deepNavy, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      'External Notification Gateway & API Parameters',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AdminColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Configure REST API endpoints, Webhook tokens, and SMS / WhatsApp provider secrets',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AdminColors.textSecondary),
                                ),
                                const Divider(height: 24),

                                // WhatsApp Business API
                                const Text(
                                  '💬 WhatsApp Business Cloud API',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AdminColors.safetyGreen),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _whatsappUrlController,
                                        decoration: const InputDecoration(
                                          labelText: 'WhatsApp API Endpoint URL',
                                          hintText: 'https://graph.facebook.com/v18.0/FROM_PHONE_ID/messages',
                                          prefixIcon: Icon(Icons.link_rounded),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        controller: _whatsappTokenController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Bearer Access Token',
                                          hintText: 'EAAG...',
                                          prefixIcon: Icon(Icons.key_rounded),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // SMS Gateway
                                const Text(
                                  '📱 SMS Gateway API (Twilio / MSG91 / Fast2SMS)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AdminColors.blue),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        controller: _smsUrlController,
                                        decoration: const InputDecoration(
                                          labelText: 'SMS REST Endpoint URL',
                                          hintText: 'https://api.msg91.com/api/v5/flow/',
                                          prefixIcon: Icon(Icons.http_rounded),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        controller: _smsSenderIdController,
                                        decoration: const InputDecoration(
                                          labelText: 'Sender ID / Header',
                                          hintText: 'SAFRTE',
                                          prefixIcon: Icon(Icons.badge_outlined),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: TextField(
                                        controller: _smsApiKeyController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Auth API Key / Token',
                                          hintText: 'sec_...',
                                          prefixIcon: Icon(Icons.password_rounded),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),

                                // Firebase Cloud Messaging (FCM Push)
                                const Text(
                                  '🔥 Firebase Cloud Messaging (FCM Push V1)',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AdminColors.warning),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _fcmProjectIdController,
                                        decoration: const InputDecoration(
                                          labelText: 'FCM Service Account Project ID',
                                          hintText: 'saferoute-mobile-app',
                                          prefixIcon: Icon(Icons.cloud_outlined),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextField(
                                        controller: _fcmEndpointController,
                                        decoration: const InputDecoration(
                                          labelText: 'Server Key / OAuth Endpoint',
                                          hintText: 'https://fcm.googleapis.com/v1/projects/...',
                                          prefixIcon: Icon(Icons.shield_outlined),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Save Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.deepNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded, size: 18),
                            label: const Text(
                              'Save School Settings & Address',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isSaving ? null : () => _saveSettings(org),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AdminColors.yellow),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load school settings: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
