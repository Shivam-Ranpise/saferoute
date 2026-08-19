import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';
import '../providers/parent_providers.dart';

class ParentSettingsScreen extends ConsumerStatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  ConsumerState<ParentSettingsScreen> createState() =>
      _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends ConsumerState<ParentSettingsScreen> {
  bool _pushEnabled = true;
  bool _whatsappEnabled = true;
  bool _smsEnabled = true;
  bool _initialized = false;
  bool _isSaving = false;

  void _initFromPreferences(NotificationPreferences? prefs) {
    if (_initialized || prefs == null) return;
    _initialized = true;
    _pushEnabled = prefs.pushEnabled;
    _whatsappEnabled = prefs.whatsappEnabled;
    _smsEnabled = prefs.smsEnabled;
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updatePreferences(
            pushEnabled: _pushEnabled,
            whatsappEnabled: _whatsappEnabled,
            smsEnabled: _smsEnabled,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully!'),
            backgroundColor: SafeRouteColors.safetyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: SafeRouteColors.error,
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
    final profile = ref.watch(currentProfileProvider);
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    prefsAsync.whenData(_initFromPreferences);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        backgroundColor: SafeRouteColors.deepNavy,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePreferences,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: SafeRouteColors.yellow,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: SafeRouteColors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Parent Profile Info Card
          if (profile != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SafeRouteColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: SafeRouteColors.deepNavy,
                    child: Text(
                      profile.name.isNotEmpty
                          ? profile.name[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: SafeRouteColors.yellow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: SafeRouteColors.deepNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: SafeRouteColors.onSurfaceVariant,
                          ),
                        ),
                        if (profile.phone != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            profile.phone!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: SafeRouteColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Text(
            'Delivery Channels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: SafeRouteColors.deepNavy,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you would like to receive proximity and delay alerts for your children.',
            style: TextStyle(
              fontSize: 13,
              color: SafeRouteColors.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Channel Toggles
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active_outlined,
                      color: SafeRouteColors.blue),
                  title: const Text('In-App Push Notifications'),
                  subtitle: const Text('Instant alerts on your device'),
                  value: _pushEnabled,
                  onChanged: (val) {
                    setState(() => _pushEnabled = val);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.chat_bubble_outline,
                      color: SafeRouteColors.safetyGreen),
                  title: const Text('WhatsApp Messages'),
                  subtitle: const Text('Updates sent directly to your WhatsApp'),
                  value: _whatsappEnabled,
                  onChanged: (val) {
                    setState(() => _whatsappEnabled = val);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  secondary: const Icon(Icons.sms_outlined,
                      color: SafeRouteColors.orange),
                  title: const Text('SMS Text Messages'),
                  subtitle: const Text('Standard SMS message alerts'),
                  value: _smsEnabled,
                  onChanged: (val) {
                    setState(() => _smsEnabled = val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Spoken Voice Announcements Card Link
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SafeRouteColors.deepNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.record_voice_over_rounded, color: SafeRouteColors.deepNavy),
              ),
              title: const Text(
                'Voice & Speech Alerts (TTS)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Custom spoken announcements when bus arrives'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/parent/voice-settings'),
            ),
          ),
          const SizedBox(height: 24),

          // Emergency Override Notice
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SafeRouteColors.infoLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SafeRouteColors.info.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined,
                    color: SafeRouteColors.info, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Emergency alerts bypass channel preferences to ensure critical safety updates reach you immediately across all available channels.',
                    style: TextStyle(
                      fontSize: 12,
                      color: SafeRouteColors.deepNavy,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Save Button
          ElevatedButton(
            onPressed: _isSaving ? null : _savePreferences,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save Preferences'),
          ),
        ],
      ),
    );
  }
}
