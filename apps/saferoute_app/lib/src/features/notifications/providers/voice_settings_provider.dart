import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_voice_service.dart';

class VoiceSettings {
  final bool enabled;
  final double volume;
  final double speechRate;
  final double pitch;
  final String language;

  const VoiceSettings({
    this.enabled = true,
    this.volume = 1.0,
    this.speechRate = 0.5,
    this.pitch = 1.0,
    this.language = 'en-IN',
  });

  VoiceSettings copyWith({
    bool? enabled,
    double? volume,
    double? speechRate,
    double? pitch,
    String? language,
  }) {
    return VoiceSettings(
      enabled: enabled ?? this.enabled,
      volume: volume ?? this.volume,
      speechRate: speechRate ?? this.speechRate,
      pitch: pitch ?? this.pitch,
      language: language ?? this.language,
    );
  }
}

class VoiceSettingsNotifier extends StateNotifier<VoiceSettings> {
  VoiceSettingsNotifier() : super(const VoiceSettings()) {
    _loadFromPrefs();
  }

  static const _keyEnabled = 'voice_alerts_enabled';
  static const _keyVolume = 'voice_alerts_volume';
  static const _keyRate = 'voice_alerts_rate';
  static const _keyPitch = 'voice_alerts_pitch';
  static const _keyLang = 'voice_alerts_lang';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_keyEnabled) ?? true;
      final volume = prefs.getDouble(_keyVolume) ?? 1.0;
      final rate = prefs.getDouble(_keyRate) ?? 0.5;
      final pitch = prefs.getDouble(_keyPitch) ?? 1.0;
      final lang = prefs.getString(_keyLang) ?? 'en-IN';

      state = VoiceSettings(
        enabled: enabled,
        volume: volume,
        speechRate: rate,
        pitch: pitch,
        language: lang,
      );

      await AppVoiceService.instance.initialize(
        volume: volume,
        rate: rate,
        pitch: pitch,
        language: lang,
      );
    } catch (_) {}
  }

  Future<void> setEnabled(bool val) async {
    state = state.copyWith(enabled: val);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, val);
  }

  Future<void> setVolume(double val) async {
    state = state.copyWith(volume: val);
    await AppVoiceService.instance.updateSettings(
      volume: val,
      rate: state.speechRate,
      pitch: state.pitch,
      language: state.language,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, val);
  }

  Future<void> setSpeechRate(double val) async {
    state = state.copyWith(speechRate: val);
    await AppVoiceService.instance.updateSettings(
      volume: state.volume,
      rate: val,
      pitch: state.pitch,
      language: state.language,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRate, val);
  }

  Future<void> setLanguage(String lang) async {
    state = state.copyWith(language: lang);
    await AppVoiceService.instance.updateSettings(
      volume: state.volume,
      rate: state.speechRate,
      pitch: state.pitch,
      language: lang,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLang, lang);
  }
}

final voiceSettingsProvider =
    StateNotifierProvider<VoiceSettingsNotifier, VoiceSettings>((ref) {
  return VoiceSettingsNotifier();
});
