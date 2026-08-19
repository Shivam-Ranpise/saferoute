import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/notifications/providers/voice_settings_provider.dart';

const String _prefKeyLanguage = 'sr_selected_language';

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;

  LocaleNotifier(this._ref) : super(const Locale('en', 'IN')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKeyLanguage);
      if (savedCode != null && AppLocalizations.supportedLocales.contains(savedCode)) {
        state = Locale(savedCode, 'IN');
      }
    } catch (_) {}
  }

  Future<void> setLanguage(String languageCode) async {
    if (!AppLocalizations.supportedLocales.contains(languageCode)) return;

    state = Locale(languageCode, 'IN');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLanguage, languageCode);
    } catch (_) {}

    final voiceTtsLang = languageCode == 'hi'
        ? 'hi-IN'
        : languageCode == 'mr'
            ? 'mr-IN'
            : 'en-IN';
    _ref.read(voiceSettingsProvider.notifier).setLanguage(voiceTtsLang);
  }
}

final appLocaleProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final locale = ref.watch(appLocaleProvider);
  return AppLocalizations(locale.languageCode);
});
