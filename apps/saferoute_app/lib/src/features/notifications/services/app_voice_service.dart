import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:saferoute_core/saferoute_core.dart';

class AppVoiceService {
  AppVoiceService._();
  static final AppVoiceService instance = AppVoiceService._();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> initialize({
    double volume = 1.0,
    double rate = 0.5,
    double pitch = 1.0,
    String language = 'en-IN',
  }) async {
    try {
      if (Platform.isIOS) {
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }

      // Check language availability with automatic fallback
      try {
        final isAvailable = await _tts.isLanguageAvailable(language);
        if (isAvailable == true || isAvailable == 1) {
          await _tts.setLanguage(language);
        } else {
          await _tts.setLanguage('en-US');
        }
      } catch (_) {
        await _tts.setLanguage('en-US');
      }

      await _tts.setVolume(volume.clamp(0.0, 1.0));
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
      await _tts.setPitch(pitch.clamp(0.5, 2.0));

      if (Platform.isAndroid) {
        await _tts.setQueueMode(1); // Immediate flush & speak
      }

      _isInitialized = true;
      AppLogger.info('AppVoiceService initialized successfully', context: 'VoiceTTS');
    } catch (e) {
      AppLogger.error('Failed to initialize AppVoiceService', error: e, context: 'VoiceTTS');
    }
  }

  Future<void> updateSettings({
    required double volume,
    required double rate,
    required double pitch,
    required String language,
  }) async {
    try {
      try {
        final isAvailable = await _tts.isLanguageAvailable(language);
        if (isAvailable == true || isAvailable == 1) {
          await _tts.setLanguage(language);
        } else {
          await _tts.setLanguage('en-US');
        }
      } catch (_) {
        await _tts.setLanguage('en-US');
      }

      await _tts.setVolume(volume.clamp(0.0, 1.0));
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
      await _tts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (e) {
      AppLogger.error('Failed to update TTS settings', error: e, context: 'VoiceTTS');
    }
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      if (!_isInitialized) {
        await initialize();
      }
      AppLogger.info('Speaking TTS: "$text"', context: 'VoiceTTS');
      await _tts.stop();
      final result = await _tts.speak(text.trim());
      AppLogger.info('TTS speak result: $result', context: 'VoiceTTS');
    } catch (e) {
      AppLogger.error('TTS speech error', error: e, context: 'VoiceTTS');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Generates a natural spoken announcement based on the notification title & message
  String generateSpokenSentence({
    required String title,
    required String message,
    NotificationEventType? eventType,
  }) {
    final cleanTitle = title.trim();
    final cleanMsg = message.trim();
    final lowerTitle = cleanTitle.toLowerCase();
    final lowerMsg = cleanMsg.toLowerCase();

    // Helper to format announcements and alerts without duplicate words
    String formatWithPrefix(String prefix, String title, String msg) {
      final tLower = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

      // Check if title is just a generic category name
      final isGenericTitle = tLower.isEmpty ||
          tLower == 'schoolannouncement' ||
          tLower == 'announcement' ||
          tLower == 'notice' ||
          tLower == 'urgentalert' ||
          tLower == 'alert' ||
          tLower == 'emergency' ||
          tLower == 'emergencynotice' ||
          tLower == 'notification' ||
          tLower == 'customalert' ||
          tLower == 'saferoute';

      if (isGenericTitle) {
        return msg.isNotEmpty ? '$prefix: $msg' : '$prefix: $title';
      }

      // If title already includes the prefix
      if (title.toLowerCase().contains(prefix.toLowerCase())) {
        return msg.isNotEmpty ? '$title. $msg' : title;
      }

      if (title.isNotEmpty && msg.isNotEmpty && !msg.toLowerCase().contains(title.toLowerCase())) {
        return '$prefix: $title. $msg';
      }

      return '$prefix: ${msg.isNotEmpty ? msg : title}';
    }

    // 1. Emergency SOS / Critical Delays
    if (lowerTitle.contains('emergency') ||
        lowerTitle.contains('sos') ||
        lowerTitle.contains('critical') ||
        lowerTitle.contains('accident') ||
        lowerTitle.contains('breakdown') ||
        lowerTitle.contains('delay') ||
        lowerMsg.contains('sos') ||
        lowerMsg.contains('emergency') ||
        lowerMsg.contains('delay')) {
      return formatWithPrefix('Urgent Alert', cleanTitle, cleanMsg);
    }

    // 2. Bus Approaching / Nearby
    if (lowerTitle.contains('approach') || lowerTitle.contains('nearby') || lowerMsg.contains('approaching')) {
      return 'Attention: Your child\'s school bus is approaching your stop. Please be ready!';
    }

    // 3. Bus Arrived at Stop
    if (lowerTitle.contains('arrived') || lowerMsg.contains('has arrived')) {
      return 'Attention: Your child\'s school bus has arrived at your designated stop!';
    }

    // 4. School Reached / Trip Completed
    if (lowerTitle.contains('reached school') || lowerTitle.contains('school arrival') || lowerMsg.contains('reached school')) {
      return 'Good news! Your child has safely reached the school.';
    }

    // 5. Student Boarded
    if (lowerTitle.contains('boarded') || lowerMsg.contains('boarded')) {
      return 'Your child has safely boarded the school bus.';
    }

    // 6. Student Dropped
    if (lowerTitle.contains('dropped') || lowerMsg.contains('dropped off')) {
      return 'Your child has been safely dropped off.';
    }

    // 7. Custom School Announcement / Notice from Admin
    return formatWithPrefix('School Announcement', cleanTitle, cleanMsg);
  }
}
