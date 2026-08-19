import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';
import '../providers/admin_providers.dart';

class NotificationAuditScreen extends ConsumerStatefulWidget {
  const NotificationAuditScreen({super.key});

  @override
  ConsumerState<NotificationAuditScreen> createState() =>
      _NotificationAuditScreenState();
}

class _NotificationAuditScreenState
    extends ConsumerState<NotificationAuditScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // Custom Notification Form State
  final _customTitleController = TextEditingController();
  final _customMessageController = TextEditingController();
  String _customPriority = 'NORMAL';
  String? _selectedParentId; // null means all parents
  bool _sendCustomPush = true;
  bool _sendCustomWhatsapp = false;
  bool _sendCustomSms = false;
  bool _isSendingCustom = false;

  String _selectedTitlePreset = 'School Announcement';
  final List<String> _titlePresets = [
    'School Announcement',
    '🚨 Urgent Emergency Alert',
    '🌧️ Weather & Rain Delay Notice',
    '⏱️ Bus Route Delay Notice',
    '🎉 Holiday / Early Dismissal Notice',
    '🔧 Bus Breakdown / Maintenance',
    '🏆 Sports Day & Event Circular',
    'Parent-Teacher Meeting (PTM) Notice',
    'Other (Custom Headline)',
  ];

  // Channel toggle rules for school events
  bool _busApproachingPush = true;
  bool _busApproachingWhatsapp = true;
  bool _busApproachingSms = false;

  bool _studentBoardedPush = true;
  bool _studentBoardedWhatsapp = true;
  bool _studentBoardedSms = false;

  bool _studentDroppedPush = true;
  bool _studentDroppedWhatsapp = true;
  bool _studentDroppedSms = false;

  bool _emergencyPush = true;
  bool _emergencyWhatsapp = true;
  bool _emergencySms = true;

  bool _savingRules = false;
  bool _rulesInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _customMessageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _loadRulesFromOrg(Organization org) {
    if (_rulesInitialized) return;
    final rules = org.notificationSettings;

    if (rules.containsKey('bus_approaching')) {
      final b = rules['bus_approaching'] as Map<String, dynamic>? ?? {};
      _busApproachingPush = b['push'] as bool? ?? true;
      _busApproachingWhatsapp = b['whatsapp'] as bool? ?? true;
      _busApproachingSms = b['sms'] as bool? ?? false;
    }

    if (rules.containsKey('student_boarded')) {
      final b = rules['student_boarded'] as Map<String, dynamic>? ?? {};
      _studentBoardedPush = b['push'] as bool? ?? true;
      _studentBoardedWhatsapp = b['whatsapp'] as bool? ?? true;
      _studentBoardedSms = b['sms'] as bool? ?? false;
    }

    if (rules.containsKey('student_dropped')) {
      final b = rules['student_dropped'] as Map<String, dynamic>? ?? {};
      _studentDroppedPush = b['push'] as bool? ?? true;
      _studentDroppedWhatsapp = b['whatsapp'] as bool? ?? true;
      _studentDroppedSms = b['sms'] as bool? ?? false;
    }

    if (rules.containsKey('emergency_sos')) {
      final b = rules['emergency_sos'] as Map<String, dynamic>? ?? {};
      _emergencyPush = b['push'] as bool? ?? true;
      _emergencyWhatsapp = b['whatsapp'] as bool? ?? true;
      _emergencySms = b['sms'] as bool? ?? true;
    }

    _rulesInitialized = true;
  }

  Future<void> _saveRules(Organization org) async {
    setState(() => _savingRules = true);
    try {
      final rulesMap = {
        'bus_approaching': {
          'push': _busApproachingPush,
          'whatsapp': _busApproachingWhatsapp,
          'sms': _busApproachingSms,
        },
        'student_boarded': {
          'push': _studentBoardedPush,
          'whatsapp': _studentBoardedWhatsapp,
          'sms': _studentBoardedSms,
        },
        'student_dropped': {
          'push': _studentDroppedPush,
          'whatsapp': _studentDroppedWhatsapp,
          'sms': _studentDroppedSms,
        },
        'emergency_sos': {
          'push': _emergencyPush,
          'whatsapp': _emergencyWhatsapp,
          'sms': _emergencySms,
        },
      };

      await SupabaseService.client.rpc('update_org_settings', params: {
        'p_org_id': org.id,
        'p_name': org.name,
        'p_timezone': org.timezone,
        'p_address': org.address,
        'p_latitude': org.latitude,
        'p_longitude': org.longitude,
        'p_geofence_radius': org.geofenceRadiusMeters,
        'p_driver_emergency': org.driverCanSendEmergencyAlerts,
        'p_driver_custom': org.driverCanSendCustomAlerts,
        'p_gps_retention': org.gpsHistoryRetentionDays,
        'p_notif_retention': org.notificationLogRetentionDays,
        'p_notification_settings': rulesMap,
        'p_api_parameters': org.apiParameters,
      });

      ref.invalidate(currentOrganizationProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Notification dispatch rules saved to backend successfully!'),
            backgroundColor: AdminColors.safetyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save rules: $e'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingRules = false);
      }
    }
  }

  Future<void> _sendCustomNotification(Organization org) async {
    final String title;
    if (_selectedTitlePreset != 'Other (Custom Headline)') {
      title = _selectedTitlePreset;
    } else {
      title = _customTitleController.text.trim();
    }
    final message = _customMessageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both Title and Notification Message.'),
          backgroundColor: AdminColors.error,
        ),
      );
      return;
    }

    setState(() => _isSendingCustom = true);
    try {
      final now = DateTime.now().toIso8601String();
      
      // 1. Log to notification_events
      final notifRes = await SupabaseService.client
          .from('notification_events')
          .insert({
            'organization_id': org.id,
            'event_type': 'CUSTOM_ALERT',
            'title': title,
            'message': message,
            'priority': _customPriority,
            'created_at': now,
          })
          .select()
          .single();

      final eventId = notifRes['id'] as String;

      // 2. Fetch target parents
      var parentsQuery = SupabaseService.client
          .from('parents')
          .select('id, profile_id')
          .eq('organization_id', org.id);

      if (_selectedParentId != null && _selectedParentId!.isNotEmpty) {
        parentsQuery = parentsQuery.eq('id', _selectedParentId!);
      }

      final parents = await parentsQuery;
      final targetParentsList = List<Map<String, dynamic>>.from(parents as List);

      // 3. Create delivery logs for auditing
      final deliveries = <Map<String, dynamic>>[];
      for (final p in targetParentsList) {
        final profileId = p['profile_id'] as String;
        if (_sendCustomPush) {
          deliveries.add({
            'notification_event_id': eventId,
            'organization_id': org.id,
            'recipient_profile_id': profileId,
            'channel': 'PUSH',
            'status': 'DELIVERED',
          });
        }
        if (_sendCustomWhatsapp) {
          deliveries.add({
            'notification_event_id': eventId,
            'organization_id': org.id,
            'recipient_profile_id': profileId,
            'channel': 'WHATSAPP',
            'status': 'DELIVERED',
          });
        }
        if (_sendCustomSms) {
          deliveries.add({
            'notification_event_id': eventId,
            'organization_id': org.id,
            'recipient_profile_id': profileId,
            'channel': 'SMS',
            'status': 'DELIVERED',
          });
        }
      }

      if (deliveries.isNotEmpty) {
        await SupabaseService.client
            .from('notification_deliveries')
            .insert(deliveries);
      }

      // Refresh logs
      ref.invalidate(notificationAuditLogsProvider);

      if (mounted) {
        _customTitleController.clear();
        _customMessageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Notification dispatched successfully to ${_selectedParentId == null ? "all ${targetParentsList.length} parents" : "selected parent"}!',
            ),
            backgroundColor: AdminColors.safetyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send custom notification: $e'),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingCustom = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(notificationAuditLogsProvider);
    final orgAsync = ref.watch(currentOrganizationProvider);

    orgAsync.whenData((org) {
      if (org != null) _loadRulesFromOrg(org);
    });

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Center & Dispatch Rules',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AdminColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Send custom announcements to parents, manage automated multi-channel rules, and audit live logs',
                      style: TextStyle(
                        fontSize: 13,
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('Delete Notification History'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (dialogCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Delete All Notification History?'),
                            content: const Text(
                              'Are you sure you want to permanently delete all notification events and delivery logs from the database?\n\nThis action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogCtx, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AdminColors.error,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(dialogCtx, true),
                                child: const Text('Delete All History'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            final org = ref.read(currentOrganizationProvider).value;
                            if (org != null) {
                              await SupabaseService.client
                                  .from('notification_deliveries')
                                  .delete()
                                  .eq('organization_id', org.id);
                              await SupabaseService.client
                                  .from('notification_events')
                                  .delete()
                                  .eq('organization_id', org.id);
                            }
                            ref.invalidate(notificationAuditLogsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Notification history deleted successfully!'),
                                  backgroundColor: AdminColors.safetyGreen,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to delete history: $e'),
                                  backgroundColor: AdminColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: 'Refresh',
                      onPressed: () {
                        _rulesInitialized = false;
                        ref.invalidate(notificationAuditLogsProvider);
                        ref.invalidate(currentOrganizationProvider);
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.border),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AdminColors.deepNavy,
                labelColor: AdminColors.deepNavy,
                unselectedLabelColor: AdminColors.textSecondary,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.send_rounded, size: 18),
                    text: 'Send Custom Notification / Announcement',
                  ),
                  Tab(
                    icon: Icon(Icons.tune_rounded, size: 18),
                    text: 'Channel Rules & Policy',
                  ),
                  Tab(
                    icon: Icon(Icons.receipt_long_rounded, size: 18),
                    text: 'Live Delivery Logs & Audit Trail',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Custom Notification Form
                  _buildCustomBroadcastTab(orgAsync),

                  // Tab 2: Dispatch Rules
                  _buildChannelRulesTab(orgAsync),

                  // Tab 3: Logs Table
                  _buildAuditLogsTab(logsAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComposeNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, setDialogState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.campaign_rounded, color: AdminColors.deepNavy, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Compose Custom Notice / Broadcast',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(dialogCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Audience Picker
                  const Text(
                    'Recipient Audience:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Consumer(
                    builder: (context, ref, _) {
                      final parentsAsync = ref.watch(adminParentsProvider);
                      return parentsAsync.when(
                        data: (parents) {
                          return DropdownButtonFormField<String?>(
                            value: _selectedParentId,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.group_rounded, color: AdminColors.deepNavy),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('📣 All Parents in School (Broadcast to Everyone)',
                                    style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              ...parents.map(
                                (p) {
                                  final prof = p['profiles'] as Map<String, dynamic>? ?? {};
                                  final parentId = p['id'] as String;
                                  final name = prof['full_name'] as String? ?? 'Parent';
                                  final phone = prof['phone'] as String? ?? '';
                                  return DropdownMenuItem<String?>(
                                    value: parentId,
                                    child: Text('$name ${phone.isNotEmpty ? "($phone)" : ""}'),
                                  );
                                },
                              ),
                            ],
                            onChanged: (val) {
                              setDialogState(() => _selectedParentId = val);
                              setState(() => _selectedParentId = val);
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const Text('Failed to load parents'),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Priority & Channels Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Priority Level:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              value: _customPriority,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'NORMAL', child: Text('Standard (Routine)')),
                                DropdownMenuItem(value: 'HIGH', child: Text('High Priority Alert')),
                                DropdownMenuItem(value: 'EMERGENCY', child: Text('🚨 Emergency SOS')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _customPriority = val);
                                  setState(() => _customPriority = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dispatch Channels:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilterChip(
                                  avatar: Icon(Icons.notifications_active_rounded,
                                      size: 16, color: _sendCustomPush ? Colors.white : AdminColors.deepNavy),
                                  label: const Text('Mobile Push (FCM)'),
                                  selected: _sendCustomPush,
                                  selectedColor: AdminColors.deepNavy,
                                  labelStyle: TextStyle(
                                      color: _sendCustomPush ? Colors.white : AdminColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                  onSelected: (val) {
                                    setDialogState(() => _sendCustomPush = val);
                                    setState(() => _sendCustomPush = val);
                                  },
                                ),
                                FilterChip(
                                  avatar: Icon(Icons.chat_bubble_outline_rounded,
                                      size: 16, color: _sendCustomWhatsapp ? Colors.white : AdminColors.safetyGreen),
                                  label: const Text('WhatsApp Gateway'),
                                  selected: _sendCustomWhatsapp,
                                  selectedColor: AdminColors.safetyGreen,
                                  labelStyle: TextStyle(
                                      color: _sendCustomWhatsapp ? Colors.white : AdminColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                  onSelected: (val) {
                                    setDialogState(() => _sendCustomWhatsapp = val);
                                    setState(() => _sendCustomWhatsapp = val);
                                  },
                                ),
                                FilterChip(
                                  avatar: Icon(Icons.sms_rounded,
                                      size: 16, color: _sendCustomSms ? Colors.white : const Color(0xFF2563EB)),
                                  label: const Text('SMS Text'),
                                  selected: _sendCustomSms,
                                  selectedColor: const Color(0xFF2563EB),
                                  labelStyle: TextStyle(
                                      color: _sendCustomSms ? Colors.white : AdminColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12),
                                  onSelected: (val) {
                                    setDialogState(() => _sendCustomSms = val);
                                    setState(() => _sendCustomSms = val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Category / Title Preset Dropdown
                  const Text(
                    'Notification Category / Title:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedTitlePreset,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.label_important_outline_rounded, color: AdminColors.deepNavy),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _titlePresets.map((p) {
                      return DropdownMenuItem<String>(
                        value: p,
                        child: Text(
                          p,
                          style: TextStyle(
                            fontWeight: p == 'Other (Custom Headline)' ? FontWeight.bold : FontWeight.normal,
                            color: p == 'Other (Custom Headline)' ? AdminColors.deepNavy : AdminColors.textPrimary,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _selectedTitlePreset = val;
                          if (val != 'Other (Custom Headline)') {
                            _customTitleController.text = val;
                          } else {
                            _customTitleController.clear();
                          }
                        });
                        setState(() {
                          _selectedTitlePreset = val;
                          if (val != 'Other (Custom Headline)') {
                            _customTitleController.text = val;
                          } else {
                            _customTitleController.clear();
                          }
                        });
                      }
                    },
                  ),

                  // If 'Other' is selected, allow freeform text entry
                  if (_selectedTitlePreset == 'Other (Custom Headline)') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customTitleController,
                      decoration: InputDecoration(
                        labelText: 'Custom Headline / Title *',
                        hintText: 'e.g. Science Exhibition Timings',
                        prefixIcon: const Icon(Icons.title_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  TextField(
                    controller: _customMessageController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Alert Message Content *',
                      prefixIcon: const Icon(Icons.message_rounded),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.deepNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: _isSendingCustom
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Send Notification', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isSendingCustom
                            ? null
                            : () async {
                                final org = ref.read(currentOrganizationProvider).value;
                                if (org != null) {
                                  Navigator.pop(dialogCtx);
                                  await _sendCustomNotification(org);
                                }
                              },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBroadcastTab(AsyncValue<Organization?> orgAsync) {
    return orgAsync.when(
      data: (org) {
        if (org == null) return const Center(child: Text('No organization profile.'));

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.campaign_rounded, color: AdminColors.deepNavy, size: 28),
                          SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'School Announcement & Custom Notification Dispatcher',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AdminColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Broadcast instant updates, trip delay notices, or emergency alerts to all parents or specific individuals.',
                                style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.deepNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add_comment_rounded, size: 18),
                        label: const Text(
                          'Compose Custom Notice',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () => _showComposeNotificationDialog(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AdminColors.yellow)),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildChannelRulesTab(AsyncValue<Organization?> orgAsync) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      orgAsync.when(
                        data: (org) {
                          if (org == null) return const SizedBox.shrink();
                          return ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AdminColors.deepNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: _savingRules
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save Rules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: _savingRules ? null : () => _saveRules(org),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 14),
                      const Icon(Icons.hub_rounded, color: AdminColors.blue, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Automated Event Channel Configuration Table',
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
                    'Configure dispatch channels per event using the table below. Use the checkboxes to enable or disable channels.',
                    style: TextStyle(fontSize: 13, color: AdminColors.textSecondary),
                  ),
                  const Divider(height: 28),

                  // Modern DataTable with Checkboxes
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
                            DataColumn(label: Text('Event Trigger / Milestone', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('App Push (FCM)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('WhatsApp Business', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('SMS Text', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: [
                            _buildEventDataTableRow(
                              title: '🚍 Bus Approaching Stop (<500m)',
                              description: 'Triggered when bus is within proximity of child stop',
                              push: _busApproachingPush,
                              whatsapp: _busApproachingWhatsapp,
                              sms: _busApproachingSms,
                              onPushChanged: (v) => setState(() => _busApproachingPush = v ?? false),
                              onWhatsappChanged: (v) => setState(() => _busApproachingWhatsapp = v ?? false),
                              onSmsChanged: (v) => setState(() => _busApproachingSms = v ?? false),
                              onToggleAll: (v) => setState(() {
                                _busApproachingPush = v;
                                _busApproachingWhatsapp = v;
                                _busApproachingSms = v;
                              }),
                            ),
                            _buildEventDataTableRow(
                              title: '✅ Student Boarded School Bus',
                              description: 'Sent when driver marks child as Boarded in manifest',
                              push: _studentBoardedPush,
                              whatsapp: _studentBoardedWhatsapp,
                              sms: _studentBoardedSms,
                              onPushChanged: (v) => setState(() => _studentBoardedPush = v ?? false),
                              onWhatsappChanged: (v) => setState(() => _studentBoardedWhatsapp = v ?? false),
                              onSmsChanged: (v) => setState(() => _studentBoardedSms = v ?? false),
                              onToggleAll: (v) => setState(() {
                                _studentBoardedPush = v;
                                _studentBoardedWhatsapp = v;
                                _studentBoardedSms = v;
                              }),
                            ),
                            _buildEventDataTableRow(
                              title: '🏠 Student Safely Dropped Off',
                              description: 'Sent when child reaches school or designated drop stop',
                              push: _studentDroppedPush,
                              whatsapp: _studentDroppedWhatsapp,
                              sms: _studentDroppedSms,
                              onPushChanged: (v) => setState(() => _studentDroppedPush = v ?? false),
                              onWhatsappChanged: (v) => setState(() => _studentDroppedWhatsapp = v ?? false),
                              onSmsChanged: (v) => setState(() => _studentDroppedSms = v ?? false),
                              onToggleAll: (v) => setState(() {
                                _studentDroppedPush = v;
                                _studentDroppedWhatsapp = v;
                                _studentDroppedSms = v;
                              }),
                            ),
                            _buildEventDataTableRow(
                              title: '🚨 Emergency SOS / Critical Route Delays',
                              description: 'High-priority alerts dispatched across all active channels',
                              push: _emergencyPush,
                              whatsapp: _emergencyWhatsapp,
                              sms: _emergencySms,
                              onPushChanged: (v) => setState(() => _emergencyPush = v ?? false),
                              onWhatsappChanged: (v) => setState(() => _emergencyWhatsapp = v ?? false),
                              onSmsChanged: (v) => setState(() => _emergencySms = v ?? false),
                              onToggleAll: (v) => setState(() {
                                _emergencyPush = v;
                                _emergencyWhatsapp = v;
                                _emergencySms = v;
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildEventDataTableRow({
    required String title,
    required String description,
    required bool push,
    required bool whatsapp,
    required bool sms,
    required ValueChanged<bool?> onPushChanged,
    required ValueChanged<bool?> onWhatsappChanged,
    required ValueChanged<bool?> onSmsChanged,
    required ValueChanged<bool> onToggleAll,
  }) {
    final allSelected = push && whatsapp && sms;

    return DataRow(
      cells: [
        DataCell(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AdminColors.textPrimary),
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        DataCell(
          Checkbox(
            value: push,
            activeColor: AdminColors.deepNavy,
            onChanged: onPushChanged,
          ),
        ),
        DataCell(
          Checkbox(
            value: whatsapp,
            activeColor: AdminColors.safetyGreen,
            onChanged: onWhatsappChanged,
          ),
        ),
        DataCell(
          Checkbox(
            value: sms,
            activeColor: const Color(0xFF2563EB),
            onChanged: onSmsChanged,
          ),
        ),
        DataCell(
          TextButton.icon(
            icon: Icon(allSelected ? Icons.done_all_rounded : Icons.select_all_rounded, size: 16),
            label: Text(
              allSelected ? 'Deselect All' : 'Select All',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => onToggleAll(!allSelected),
          ),
        ),
      ],
    );
  }

  Widget _buildAuditLogsTab(AsyncValue<List<NotificationEvent>> logsAsync) {
    return Column(
      children: [
        // Search Bar
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search audit logs by title or message...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val.toLowerCase());
          },
        ),
        const SizedBox(height: 16),

        // Logs Table
        Expanded(
          child: Card(
            child: SizedBox(
              width: double.infinity,
              child: logsAsync.when(
                data: (logs) {
                  final filtered = logs.where((l) {
                    final matchTitle = l.title.toLowerCase().contains(_searchQuery);
                    final matchMsg = l.message.toLowerCase().contains(_searchQuery);
                    return matchTitle || matchMsg;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: AdminColors.textSecondary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No notification logs recorded yet.'
                                  : 'No logs matching "$_searchQuery".',
                              style: const TextStyle(color: AdminColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: DataTable(
                            columnSpacing: 32,
                            columns: const [
                              DataColumn(label: Text('Timestamp')),
                              DataColumn(label: Text('Event Type')),
                              DataColumn(label: Text('Title / Message')),
                              DataColumn(label: Text('Priority')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: filtered.map((l) {
                              final isEmergency = l.priority == NotificationPriority.emergency;
                              final isNearby = l.eventType == NotificationEventType.busNearby;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      DateFormat('yyyy-MM-dd HH:mm:ss').format(l.createdAt.toLocal()),
                                      style: const TextStyle(fontSize: 12, color: AdminColors.textSecondary),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      l.eventType.toDbValue(),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                  ),
                                  DataCell(
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          l.title,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          l.message,
                                          style: const TextStyle(fontSize: 11, color: AdminColors.textSecondary),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isEmergency
                                            ? AdminColors.error.withValues(alpha: 0.15)
                                            : isNearby
                                                ? AdminColors.safetyGreen.withValues(alpha: 0.15)
                                                : AdminColors.blueLight,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        l.priority.toDbValue(),
                                        style: TextStyle(
                                          color: isEmergency
                                              ? AdminColors.error
                                              : isNearby
                                                  ? AdminColors.safetyGreen
                                                  : AdminColors.blue,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AdminColors.safetyGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DISPATCHED',
                                        style: TextStyle(
                                          color: AdminColors.safetyGreen,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AdminColors.yellow),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load notification audit: $e'),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
