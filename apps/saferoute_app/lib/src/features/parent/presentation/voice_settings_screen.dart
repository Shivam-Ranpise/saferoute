import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../../notifications/providers/voice_settings_provider.dart';
import '../../notifications/services/app_voice_service.dart';

class VoiceSettingsScreen extends ConsumerWidget {
  const VoiceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(voiceSettingsProvider);
    final notifier = ref.read(voiceSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: SafeRouteColors.background,
      appBar: AppBar(
        title: const Text('Voice & Speech Alerts'),
        backgroundColor: Colors.white,
        foregroundColor: SafeRouteColors.deepNavy,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Master Enable Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SafeRouteColors.surfaceVariant),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: settings.enabled
                        ? SafeRouteColors.deepNavy.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    settings.enabled
                        ? Icons.record_voice_over_rounded
                        : Icons.voice_over_off_rounded,
                    color: settings.enabled ? SafeRouteColors.deepNavy : Colors.grey,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Spoken Voice Alerts',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: SafeRouteColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.enabled
                            ? 'Speaks bus arrival & school updates out loud'
                            : 'Voice announcements are disabled',
                        style: const TextStyle(
                          fontSize: 12,
                          color: SafeRouteColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: settings.enabled,
                  activeColor: SafeRouteColors.deepNavy,
                  onChanged: (val) => notifier.setEnabled(val),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (settings.enabled) ...[
            // Voice Controls Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: SafeRouteColors.surfaceVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voice Controls & Speech Rate',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: SafeRouteColors.deepNavy,
                    ),
                  ),
                  // Speech Language Selector
                  const Text(
                    'Voice Language / भाषा:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('English')),
                      ButtonSegment(value: 'hi', label: Text('हिंदी')),
                      ButtonSegment(value: 'mr', label: Text('मराठी')),
                    ],
                    selected: {ref.watch(appLocaleProvider).languageCode},
                    onSelectionChanged: (newSet) {
                      if (newSet.isNotEmpty) {
                        ref.read(appLocaleProvider.notifier).setLanguage(newSet.first);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Speech Rate Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Speech Speed:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        settings.speechRate < 0.4
                            ? 'Slow'
                            : settings.speechRate > 0.6
                                ? 'Fast'
                                : 'Normal (${(settings.speechRate * 2).toStringAsFixed(1)}x)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: SafeRouteColors.deepNavy,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.speechRate,
                    min: 0.2,
                    max: 0.8,
                    divisions: 6,
                    activeColor: SafeRouteColors.deepNavy,
                    onChanged: (val) => notifier.setSpeechRate(val),
                  ),

                  const SizedBox(height: 8),

                  // Volume Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Voice Volume:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(settings.volume * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: SafeRouteColors.deepNavy,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.volume,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    activeColor: SafeRouteColors.deepNavy,
                    onChanged: (val) => notifier.setVolume(val),
                  ),

                  const SizedBox(height: 12),

                  // Test Play Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SafeRouteColors.deepNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      label: const Text(
                        'Test Play Voice Sample',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        AppVoiceService.instance.speak(
                          'Attention: Your child\'s school bus is approaching your stop. Please be ready!',
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Spoken Announcement Templates',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: SafeRouteColors.deepNavy,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Template 1: Bus Approaching
            _buildTemplateCard(
              icon: Icons.directions_bus_rounded,
              color: SafeRouteColors.yellow,
              title: 'Bus Approaching Pickup Stop',
              spokenText:
                  'Attention: Your child\'s school bus is approaching your stop. Please be ready!',
            ),

            // Template 2: Bus Reached School
            _buildTemplateCard(
              icon: Icons.school_rounded,
              color: SafeRouteColors.safetyGreen,
              title: 'Bus Reached School Safely',
              spokenText: 'Good news! Your child has safely reached the school.',
            ),

            /*
            // =========================================================================
            // FUTURE FEATURE: Student Boarded & Dropped Off Template Preview Cards
            // (Uncomment if RFID / manual check-in is enabled in future)
            // =========================================================================
            // Template 3: Student Boarded
            _buildTemplateCard(
              icon: Icons.how_to_reg_rounded,
              color: SafeRouteColors.blue,
              title: 'Student Boarded School Bus',
              spokenText: 'Your child has safely boarded the school bus.',
            ),

            // Template 4: Student Dropped Off
            _buildTemplateCard(
              icon: Icons.home_rounded,
              color: const Color(0xFF8B5CF6),
              title: 'Student Safely Dropped Off',
              spokenText: 'Your child has been safely dropped off at home.',
            ),
            // =========================================================================
            */

            // Template 3: Emergency SOS (Reads full detail)
            _buildTemplateCard(
              icon: Icons.warning_rounded,
              color: SafeRouteColors.error,
              title: 'Urgent SOS / Route Alert (Reads Full Content)',
              spokenText:
                  'Urgent Alert: Bus breakdown near Sector 4. Backup bus dispatched, expected 15 mins delay.',
            ),

            // Template 6: Custom Announcement (Reads title & message)
            _buildTemplateCard(
              icon: Icons.campaign_rounded,
              color: const Color(0xFFF97316),
              title: 'Custom School Announcement (Reads Full Content)',
              spokenText:
                  'School Announcement: Tomorrow will be a half-day due to heavy rain forecast. Buses depart at 12:30 PM.',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateCard({
    required IconData icon,
    required Color color,
    required String title,
    required String spokenText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SafeRouteColors.surfaceVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: SafeRouteColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '"$spokenText"',
                  style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: SafeRouteColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.play_circle_fill_rounded, color: SafeRouteColors.deepNavy, size: 28),
            tooltip: 'Listen to announcement',
            onPressed: () {
              AppVoiceService.instance.speak(spokenText);
            },
          ),
        ],
      ),
    );
  }
}
