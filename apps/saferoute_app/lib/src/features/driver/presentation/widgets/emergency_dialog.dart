import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/driver_providers.dart';

class EmergencyDialog extends ConsumerStatefulWidget {
  final bool isDelayMode;
  const EmergencyDialog({super.key, this.isDelayMode = false});

  @override
  ConsumerState<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends ConsumerState<EmergencyDialog> {
  late String _selectedReason;
  String _selectedDelayTime = '15 mins';
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  bool _isSending = false;

  final List<String> _delayReasons = [
    'Traffic Jam / Congestion',
    'Route Delay',
    'Severe Weather / Heavy Rain',
    'Road Blockage / Diversion',
    'Vehicle Issue / Slow Speed',
    'Other (Custom Reason)',
  ];

  final List<String> _sosReasons = [
    'Mechanical Breakdown',
    'Severe Traffic / Road Blockage',
    'Medical Situation',
    'Minor Collision / Accident',
    'Extreme Weather Delay',
    'Other (Custom Reason)',
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
    _selectedReason = widget.isDelayMode ? _delayReasons.first : _sosReasons.first;
  }

  @override
  void dispose() {
    _customTitleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  bool get _isOtherSelected => _selectedReason == 'Other (Custom Reason)';

  bool get _isDelayType =>
      widget.isDelayMode ||
      _selectedReason.toLowerCase().contains('traffic') ||
      _selectedReason.toLowerCase().contains('delay') ||
      _selectedReason.toLowerCase().contains('weather') ||
      _selectedReason.toLowerCase().contains('blockage');

  Future<void> _sendAlert() async {
    setState(() => _isSending = true);
    try {
      final String alertTitle;
      if (_isOtherSelected) {
        final typed = _customTitleController.text.trim();
        alertTitle = typed.isNotEmpty ? typed : (widget.isDelayMode ? 'Bus Delay Alert' : 'Emergency Alert');
      } else {
        alertTitle = _selectedReason;
      }

      final String timeInfo = _isDelayType ? ' (Expected delay: $_selectedDelayTime)' : '';
      final String userNotes = _detailsController.text.trim();
      final String details = userNotes.isNotEmpty
          ? '$userNotes$timeInfo'
          : 'Driver reported $alertTitle$timeInfo. Please be ready at your stop.';

      final String broadcastTitle = _isDelayType
          ? 'Bus Delayed by $_selectedDelayTime'
          : 'EMERGENCY: $alertTitle';

      await ref
          .read(driverActiveTripProvider.notifier)
          .triggerEmergency(broadcastTitle, details);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isDelayType
                  ? '✅ Delay notice broadcasted to parents ($broadcastTitle)'
                  : '🚨 Emergency alert broadcasted to parents and admins!',
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
    final reasons = widget.isDelayMode ? _delayReasons : _sosReasons;
    final isDelay = _isDelayType;
    final themeColor = isDelay ? const Color(0xFFD97706) : SafeRouteColors.error;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
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
                      widget.isDelayMode ? 'Report Bus Delay' : 'Emergency SOS Alert',
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.isDelayMode
                    ? 'Notify parents instantly about delay timing:'
                    : 'Select emergency type to immediately alert all parents and school admins:',
                style: const TextStyle(fontSize: 13, height: 1.4, color: SafeRouteColors.textSecondary),
              ),
              const SizedBox(height: 16),

              // Reason Dropdown
              const Text(
                'Alert Reason / Category:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SafeRouteColors.deepNavy),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    isDelay ? Icons.alarm_rounded : Icons.report_problem_rounded,
                    color: themeColor,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: reasons.map((r) {
                  return DropdownMenuItem<String>(
                    value: r,
                    child: Text(
                      r,
                      style: TextStyle(
                        fontWeight: r == 'Other (Custom Reason)' ? FontWeight.bold : FontWeight.normal,
                        color: r == 'Other (Custom Reason)' ? SafeRouteColors.blue : SafeRouteColors.textPrimary,
                        fontSize: 13.5,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedReason = val);
                  }
                },
              ),

              // If 'Other' selected, show custom textfield
              if (_isOtherSelected) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customTitleController,
                  decoration: InputDecoration(
                    labelText: 'Type Custom Reason / Title *',
                    hintText: 'e.g. Tree fallen on road / Route diversion',
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],

              // Quick Select Delay Time Chips
              if (_isDelayType) ...[
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 16, color: SafeRouteColors.deepNavy),
                    SizedBox(width: 6),
                    Text(
                      'Select Delay Duration (Quick Pick):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: SafeRouteColors.deepNavy),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _delayTimePresets.map((time) {
                    final isSelected = _selectedDelayTime == time;
                    return ChoiceChip(
                      label: Text(time),
                      selected: isSelected,
                      selectedColor: const Color(0xFFD97706),
                      backgroundColor: Colors.grey.shade100,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : SafeRouteColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
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

              const SizedBox(height: 14),

              // Additional Details Text Field
              TextField(
                controller: _detailsController,
                decoration: InputDecoration(
                  labelText: 'Additional Details (Optional)',
                  hintText: isDelay
                      ? 'e.g. Heavy traffic near Sony Signal, moving slowly'
                      : 'e.g. Flat tire on 80ft Road, waiting for mechanic',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
                              isDelay ? 'Send Delay Notice' : 'Broadcast SOS',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
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
