import 'package:flutter_test/flutter_test.dart';
import 'package:saferoute_core/saferoute_core.dart';

void main() {
  group('Phase 13 — Localization (i18n) & Accessibility (a11y) Tests', () {
    test('Supported locales are English, Hindi, and Marathi', () {
      expect(AppLocalizations.supportedLocales, equals(['en', 'hi', 'mr']));
    });

    test('English translations and parameter interpolation', () {
      const en = AppLocalizations('en');
      expect(en.appName, equals('SafeRoute'));
      expect(en.appTagline, equals('Every Child. Every Mile. Safely.'));
      expect(en.tripActive, equals('Trip in Progress'));

      final message = en.translate('bus_nearby_message', {
        'child_name': 'Alice',
        'distance': '450m',
      });
      expect(message, equals("Bus is approx 450m from Alice's stop."));
    });

    test('Hindi translations and parameter interpolation', () {
      const hi = AppLocalizations('hi');
      expect(hi.appName, equals('सेफरूट'));
      expect(hi.appTagline, equals('हर बच्चा। हर मील। सुरक्षित।'));
      expect(hi.tripActive, equals('यात्रा जारी है'));
      expect(hi.boarded, equals('बस में बैठा'));

      final message = hi.translate('bus_nearby_message', {
        'child_name': 'एलिस',
        'distance': '450m',
      });
      expect(message, equals('बस एलिस के स्टॉप से लगभग 450m दूर है।'));
    });

    test('Marathi translations and parameter interpolation', () {
      const mr = AppLocalizations('mr');
      expect(mr.appName, equals('सेफरूट'));
      expect(mr.appTagline, equals('प्रत्येक मूल. प्रत्येक मैल. सुरक्षितपणे.'));
      expect(mr.tripActive, equals('प्रवास सुरू आहे'));
      expect(mr.boarded, equals('बसमध्ये चढले'));

      final message = mr.translate('bus_nearby_message', {
        'child_name': 'एलिस',
        'distance': '450m',
      });
      expect(message, equals('बस एलिस च्या थांब्यापासून सुमारे 450m अंतरावर आहे.'));
    });

    test('Fallback resolution for missing key returns key string', () {
      const en = AppLocalizations('en');
      expect(en.translate('non_existent_key'), equals('non_existent_key'));
    });
  });
}
