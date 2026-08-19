import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/driver_providers.dart';

class EmergencyDialog extends ConsumerStatefulWidget {
  const EmergencyDialog({super.key});

  @override
  ConsumerState<EmergencyDialog> createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends ConsumerState<EmergencyDialog> {
  String _selectedReason = 'Mechanical Breakdown';
  final TextEditingController _detailsController = TextEditingController();
  bool _isSending = false;

  final List<String> _reasons = [
    'Mechanical Breakdown',
    'Severe Traffic / Road Blockage',
    'Medical Situation',
    'Minor Collision / Accident',
    'Extreme Weather Delay',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _sendEmergency() async {
    setState(() => _isSending = true);
    try {
      final title = 'EMERGENCY: $_selectedReason';
      final details = _detailsController.text.trim().isEmpty
          ? 'Driver reported $_selectedReason. Operations and parents are being notified.'
          : _detailsController.text.trim();

      await ref
          .read(driverActiveTripProvider.notifier)
          .triggerEmergency(title, details);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Emergency alert broadcasted to parents and admins!'),
            backgroundColor: SafeRouteColors.error,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SafeRouteColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: SafeRouteColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Emergency SOS Alert',
                    style: TextStyle(
                      color: SafeRouteColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Select emergency type to immediately alert all parents and school administrators:',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              ..._reasons.map(
                (reason) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _selectedReason == reason
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _selectedReason == reason
                        ? SafeRouteColors.error
                        : SafeRouteColors.disabled,
                  ),
                  title: Text(reason, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    setState(() => _selectedReason = reason);
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailsController,
                decoration: const InputDecoration(
                  labelText: 'Additional Details (Optional)',
                  hintText: 'e.g. Flat tire on 80ft Road, waiting for support',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
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
                        backgroundColor: SafeRouteColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSending ? null : _sendEmergency,
                      child: _isSending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Broadcast SOS',
                              style: TextStyle(
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
