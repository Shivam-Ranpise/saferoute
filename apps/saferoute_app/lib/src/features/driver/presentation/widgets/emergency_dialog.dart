import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/driver_providers.dart';

class EmergencyDialog extends ConsumerStatefulWidget {
  final bool isDelayMode;
  const EmergencyDialog({super.key, this.isDelayMode = false});

  @override
  ConsumerState<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends ConsumerState<EmergencyDialog> {
  late String _selectedReasonKey;
  String _selectedDelayTime = '15 mins';
  String _targetMode = 'all'; // 'all' or 'specific'
  Child? _selectedStudent;
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isSending = false;

  final List<Map<String, String>> _delayReasons = [
    {
      'key': 'traffic',
      'en': 'Traffic Jam / Congestion',
      'hi': 'ट्रैफिक जाम / भीड़',
      'mr': 'वाहतूक कोंडी / ट्रॅफिक जाम',
    },
    {
      'key': 'route_delay',
      'en': 'Route Delay',
      'hi': 'मार्ग में सामान्य देरी',
      'mr': 'मार्गावर सामान्य उशीर',
    },
    {
      'key': 'weather',
      'en': 'Severe Weather / Heavy Rain',
      'hi': 'खराब मौसम / भारी बारिश',
      'mr': 'खराब हवामान / मुसळधार पाऊस',
    },
    {
      'key': 'blockage',
      'en': 'Road Blockage / Diversion',
      'hi': 'सड़क बंद / मार्ग परिवर्तन',
      'mr': 'रस्ता बंद / मार्ग बदल',
    },
    {
      'key': 'vehicle',
      'en': 'Vehicle Issue / Slow Speed',
      'hi': 'वाहन समस्या / धीमी गति',
      'mr': 'वाहनात बिघाड / कमी वेग',
    },
    {
      'key': 'other',
      'en': 'Other (Custom Reason)',
      'hi': 'अन्य (कस्टम कारण)',
      'mr': 'इतर (स्वतःचे कारण)',
    },
  ];

  final List<Map<String, String>> _sosReasons = [
    {
      'key': 'breakdown',
      'en': 'Mechanical Breakdown',
      'hi': 'मैकेनिकल खराबी / ब्रेकडाउन',
      'mr': 'यांत्रिकी बिघाड / ब्रेकडाऊन',
    },
    {
      'key': 'traffic_sos',
      'en': 'Severe Traffic / Blockage',
      'hi': 'भारी जाम / मार्ग अवरुद्ध',
      'mr': 'प्रचंड ट्रॅफिक / रस्ता बंद',
    },
    {
      'key': 'medical',
      'en': 'Medical Situation',
      'hi': 'चिकित्सा आपातकाल',
      'mr': 'वैद्यकीय आणीबाणी',
    },
    {
      'key': 'accident',
      'en': 'Minor Collision / Accident',
      'hi': 'दुर्घटना / टक्कर',
      'mr': 'अपघात / धडक',
    },
    {
      'key': 'weather_sos',
      'en': 'Extreme Weather Emergency',
      'hi': 'अत्यधिक खराब मौसम',
      'mr': 'अतिवृष्टी / आपत्कालीन हवामान',
    },
    {
      'key': 'other',
      'en': 'Other (Custom Reason)',
      'hi': 'अन्य (कस्टम कारण)',
      'mr': 'इतर (स्वतःचे कारण)',
    },
  ];

  final List<String> _delayTimePresets = [
    '5 mins',
    '10 mins',
    '15 mins',
    '20 mins',
    '30 mins',
    '45 mins',
    '1 hour',
  ];

  @override
  void initState() {
    super.initState();
    _selectedReasonKey = widget.isDelayMode ? _delayReasons.first['key']! : _sosReasons.first['key']!;
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  bool get _isOtherSelected => _selectedReasonKey == 'other';

  bool get _isDelayType =>
      widget.isDelayMode ||
      _selectedReasonKey == 'traffic' ||
      _selectedReasonKey == 'route_delay' ||
      _selectedReasonKey == 'weather' ||
      _selectedReasonKey == 'blockage';

  String _getReasonLabel(Map<String, String> item, String localeCode) {
    return item[localeCode] ?? item['en']!;
  }

  Future<void> _sendAlert() async {
    setState(() => _isSending = true);
    final loc = ref.read(appLocalizationsProvider);
    final locale = loc.localeCode;

    try {
      final reasons = widget.isDelayMode ? _delayReasons : _sosReasons;
      final selectedMap = reasons.firstWhere(
        (r) => r['key'] == _selectedReasonKey,
        orElse: () => reasons.first,
      );

      final String alertTitle;
      if (_isOtherSelected) {
        final typed = _customTitleController.text.trim();
        alertTitle = typed.isNotEmpty ? typed : (widget.isDelayMode ? loc.reportDelayTitle : loc.emergencySosTitle);
      } else {
        alertTitle = _getReasonLabel(selectedMap, locale);
      }

      final String timeInfo = _isDelayType ? ' (Expected delay: $_selectedDelayTime)' : '';
      final String userNotes = _detailsController.text.trim();
      final String details = userNotes.isNotEmpty
          ? '$userNotes$timeInfo'
          : '$alertTitle$timeInfo';

      final String broadcastTitle = _isDelayType
          ? '${loc.delayButton}: $alertTitle ($_selectedDelayTime)'
          : 'EMERGENCY: $alertTitle';

      String? targetParentProfileId;
      String? targetChildId;

      if (_targetMode == 'specific' && _selectedStudent != null) {
        targetChildId = _selectedStudent!.id;
        // If parentId exists, look up parent's profile_id via database
        if (_selectedStudent!.parentId != null) {
          try {
            final parentRes = await SupabaseService.client
                .from(AppConstants.tableParents)
                .select('profile_id')
                .eq('id', _selectedStudent!.parentId!)
                .maybeSingle();
            if (parentRes != null && parentRes['profile_id'] != null) {
              targetParentProfileId = parentRes['profile_id'] as String;
            }
          } catch (pe) {
            AppLogger.warning('Could not resolve parent profile_id: $pe');
          }
        }
      }

      await ref.read(driverActiveTripProvider.notifier).triggerEmergency(
            broadcastTitle,
            details,
            targetParentProfileId: targetParentProfileId,
            targetChildId: targetChildId,
          );

      if (mounted) {
        Navigator.pop(context);
        final targetDesc = (_targetMode == 'specific' && _selectedStudent != null)
            ? 'for ${_selectedStudent!.name}'
            : 'to all parents';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDelayType
                  ? '✅ Delay notice sent $targetDesc ($broadcastTitle)'
                  : '🚨 Emergency alert dispatched $targetDesc',
            ),
            backgroundColor: _isDelayType ? SafeRouteColors.warning : SafeRouteColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: $e'),
            backgroundColor: SafeRouteColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(appLocalizationsProvider);
    final locale = loc.localeCode;
    final reasons = widget.isDelayMode ? _delayReasons : _sosReasons;
    final isDelay = _isDelayType;
    final themeColor = isDelay ? const Color(0xFFD97706) : SafeRouteColors.error;
    final studentsAsync = ref.watch(driverStudentsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDelay ? Icons.timer_outlined : Icons.warning_amber_rounded,
                      color: themeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.isDelayMode ? loc.reportDelayTitle : loc.emergencySosTitle,
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.isDelayMode ? loc.delayDialogSubtitle : loc.sosDialogSubtitle,
                style: const TextStyle(fontSize: 12.5, height: 1.35, color: SafeRouteColors.onSurfaceVariant),
              ),
              const SizedBox(height: 14),

              // Recipient Target Toggle: All Parents vs Specific Student's Parent
              Text(
                loc.recipientTargetLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SafeRouteColors.deepNavy),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_outline, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              loc.allParentsBroadcast,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      selected: _targetMode == 'all',
                      selectedColor: SafeRouteColors.deepNavy,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: _targetMode == 'all' ? Colors.white : SafeRouteColors.onSurface,
                        fontWeight: _targetMode == 'all' ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _targetMode = 'all';
                            _selectedStudent = null;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              loc.specificParent,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      selected: _targetMode == 'specific',
                      selectedColor: SafeRouteColors.deepNavy,
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: _targetMode == 'specific' ? Colors.white : SafeRouteColors.onSurface,
                        fontWeight: _targetMode == 'specific' ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _targetMode = 'specific');
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Specific Student Dropdown (if specific parent mode is active)
              if (_targetMode == 'specific') ...[
                const SizedBox(height: 12),
                Text(
                  loc.selectStudentLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SafeRouteColors.deepNavy),
                ),
                const SizedBox(height: 6),
                studentsAsync.when(
                  data: (students) {
                    if (students.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'No students assigned to this route yet.',
                          style: TextStyle(fontSize: 12, color: SafeRouteColors.onSurfaceVariant),
                        ),
                      );
                    }

                    return DropdownButtonFormField<Child>(
                      value: _selectedStudent ?? students.first,
                      isExpanded: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.school_rounded, color: SafeRouteColors.deepNavy),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: students.map((child) {
                        return DropdownMenuItem<Child>(
                          value: child,
                          child: Text(
                            '${child.name}${child.pickupName != null ? " (${child.pickupName})" : ""}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStudent = val);
                        }
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Could not load student list'),
                ),
              ],

              const SizedBox(height: 14),

              // Reason Dropdown
              Text(
                loc.alertReasonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SafeRouteColors.deepNavy),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedReasonKey,
                isExpanded: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    isDelay ? Icons.alarm_rounded : Icons.report_problem_rounded,
                    color: themeColor,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: reasons.map((r) {
                  final label = _getReasonLabel(r, locale);
                  final isOther = r['key'] == 'other';
                  return DropdownMenuItem<String>(
                    value: r['key'],
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isOther ? FontWeight.bold : FontWeight.normal,
                        color: isOther ? SafeRouteColors.blue : SafeRouteColors.onSurface,
                        fontSize: 13,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedReasonKey = val);
                  }
                },
              ),

              // If 'Other' selected, show custom textfield
              if (_isOtherSelected) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _customTitleController,
                  decoration: InputDecoration(
                    labelText: loc.customReasonLabel,
                    hintText: loc.customReasonHint,
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ],

              // Quick Select Delay Time Chips
              if (_isDelayType) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 16, color: SafeRouteColors.deepNavy),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        loc.delayDurationLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: SafeRouteColors.deepNavy),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _delayTimePresets.map((time) {
                    final isSelected = _selectedDelayTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      selectedColor: const Color(0xFFD97706),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : SafeRouteColors.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 11.5,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedDelayTime = time);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Additional Details Text Field
              TextField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: loc.additionalDetailsLabel,
                  hintText: isDelay
                      ? loc.additionalDetailsHintDelay
                      : loc.additionalDetailsHintSos,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 18),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        loc.cancelButton,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSending ? null : _sendAlert,
                      child: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              isDelay ? loc.sendDelayBtn : loc.broadcastSosBtn,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
