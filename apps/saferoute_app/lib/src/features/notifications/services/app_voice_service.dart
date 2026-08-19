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
    if (_isInitialized) return;

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

      await _tts.setLanguage(language);
      await _tts.setVolume(volume.clamp(0.0, 1.0));
      await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
      await _tts.setPitch(pitch.clamp(0.5, 2.0));

      await _tts.awaitSpeakCompletion(true);
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
      await _tts.setLanguage(language);
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
      await _tts.stop();
      await _tts.speak(text.trim());
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

    // 1. Emergency SOS / Critical Delays: Read full detailed message content so parents know the exact situation!
    if (lowerTitle.contains('emergency') ||
        lowerTitle.contains('sos') ||
        lowerTitle.contains('critical') ||
        lowerTitle.contains('accident') ||
        lowerTitle.contains('breakdown') ||
        lowerTitle.contains('delay') ||
        lowerMsg.contains('sos') ||
        lowerMsg.contains('emergency') ||
        lowerMsg.contains('delay')) {
      if (cleanTitle.isNotEmpty && cleanMsg.isNotEmpty && !cleanMsg.toLowerCase().contains(cleanTitle.toLowerCase())) {
        return 'Urgent Alert: $cleanTitle. $cleanMsg';
      } else {
        return 'Urgent Alert: ${cleanMsg.isNotEmpty ? cleanMsg : cleanTitle}';
      }
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

    // 7. Custom School Announcement / Notice from Admin: Read exact notice title & content
    if (cleanTitle.isNotEmpty && cleanMsg.isNotEmpty && !cleanMsg.toLowerCase().contains(cleanTitle.toLowerCase())) {
      return 'School Announcement: $cleanTitle. $cleanMsg';
    } else if (cleanMsg.isNotEmpty) {
      return 'School Announcement: $cleanMsg';
    } else {
      return 'School Announcement: $cleanTitle';
    }
  }
}
