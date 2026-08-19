/// SafeRoute Localization Dictionary
/// Supports English (`en`), Hindi (`hi`), and Marathi (`mr`).
class AppLocalizations {
  final String localeCode;

  const AppLocalizations(this.localeCode);

  static const supportedLocales = ['en', 'hi', 'mr'];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'SafeRoute',
      'app_tagline': 'Every Child. Every Mile. Safely.',
      'login_title': 'Sign In',
      'login_subtitle': 'Enter your registered institutional credentials',
      'email_label': 'Email Address',
      'password_label': 'Password',
      'sign_in_button': 'Sign In',
      'parent_home_title': 'Child Live Tracking',
      'bus_nearby_title': 'Bus Arriving Soon! 🚌',
      'bus_nearby_message': 'Bus is approx {distance} from {child_name}\'s stop.',
      'trip_active': 'Trip in Progress',
      'trip_idle': 'Bus in Depot',
      'trip_completed': 'Trip Completed',
      'boarded': 'Boarded',
      'dropped': 'Dropped Off',
      'pending': 'Pending',
      'absent': 'Absent',
      'driver_dashboard': 'Driver Live Console',
      'start_trip': 'Start Route',
      'pause_gps': 'Pause GPS',
      'resume_gps': 'Resume GPS',
      'end_trip': 'End Route',
      'emergency_sos': 'Emergency SOS Alert',
      'manifest_title': 'Student Roll Call',
      'admin_fleet_overview': 'Fleet Command Center',
      'admin_buses': 'Fleet Buses',
      'admin_drivers': 'Drivers Registry',
      'admin_students': 'Student Roster',
      'admin_settings': 'School Settings',
      'offline_sync_banner': 'Offline mode — Buffering telemetry locally',
    },
    'hi': {
      'app_name': 'सेफरूट',
      'app_tagline': 'हर बच्चा। हर मील। सुरक्षित।',
      'login_title': 'साइन इन करें',
      'login_subtitle': 'अपना पंजीकृत ईमेल और पासवर्ड दर्ज करें',
      'email_label': 'ईमेल पता',
      'password_label': 'पासवर्ड',
      'sign_in_button': 'साइन इन करें',
      'parent_home_title': 'लाइव बस ट्रैकिंग',
      'bus_nearby_title': 'बस जल्द ही आ रही है! 🚌',
      'bus_nearby_message': 'बस {child_name} के स्टॉप से लगभग {distance} दूर है।',
      'trip_active': 'यात्रा जारी है',
      'trip_idle': 'बस डिपो में है',
      'trip_completed': 'यात्रा समाप्त हुई',
      'boarded': 'बस में बैठा',
      'dropped': 'उतार दिया गया',
      'pending': 'प्रतीक्षारत',
      'absent': 'अनुपस्थित',
      'driver_dashboard': 'ड्राइवर लाइव कंसोल',
      'start_trip': 'यात्रा शुरू करें',
      'pause_gps': 'जीपीएस रोकें',
      'resume_gps': 'जीपीएस पुनः चालू करें',
      'end_trip': 'यात्रा समाप्त करें',
      'emergency_sos': 'आपातकालीन एसओएस चेतावनी',
      'manifest_title': 'छात्र उपस्थिति सूची',
      'admin_fleet_overview': 'फ्लीट कमांड सेंटर',
      'admin_buses': 'स्कूल बसें',
      'admin_drivers': 'ड्राइवर सूची',
      'admin_students': 'छात्र सूची',
      'admin_settings': 'स्कूल सेटिंग्स',
      'offline_sync_banner': 'ऑफ़लाइन मोड — डेटा स्थानीय रूप से सहेजा जा रहा है',
    },
    'mr': {
      'app_name': 'सेफरूट',
      'app_tagline': 'प्रत्येक मूल. प्रत्येक मैल. सुरक्षितपणे.',
      'login_title': 'साइन इन करा',
      'login_subtitle': 'आपला नोंदणीकृत ईमेल आणि पासवर्ड प्रविष्ट करा',
      'email_label': 'ईमेल पत्ता',
      'password_label': 'पासवर्ड',
      'sign_in_button': 'साइन इन करा',
      'parent_home_title': 'थेट बस ट्रॅकिंग',
      'bus_nearby_title': 'बस लवकरच पोहोचत आहे! 🚌',
      'bus_nearby_message': 'बस {child_name} च्या थांब्यापासून सुमारे {distance} अंतरावर आहे.',
      'trip_active': 'प्रवास सुरू आहे',
      'trip_idle': 'बस डेपोमध्ये आहे',
      'trip_completed': 'प्रवास पूर्ण झाला',
      'boarded': 'बसमध्ये चढले',
      'dropped': 'सोडण्यात आले',
      'pending': 'प्रलंबित',
      'absent': 'अनुपस्थित',
      'driver_dashboard': 'चालक लाइव्ह कन्सोल',
      'start_trip': 'प्रवास सुरू करा',
      'pause_gps': 'जीपीएस थांबवा',
      'resume_gps': 'जीपीएस पुन्हा सुरू करा',
      'end_trip': 'प्रवास समाप्त करा',
      'emergency_sos': 'आपत्कालीन एसओएस अलर्ट',
      'manifest_title': 'विद्यार्थी हजेरी यादी',
      'admin_fleet_overview': 'फ्लीट नियंत्रण केंद्र',
      'admin_buses': 'शाळा बसेस',
      'admin_drivers': 'चालक यादी',
      'admin_students': 'विद्यार्थी यादी',
      'admin_settings': 'शाळा सेटिंग्ज',
      'offline_sync_banner': 'ऑफलाइन मोड — डेटा स्थानिक पातळीवर जतन केला जात आहे',
    },
  };

  /// Translates a key with optional dynamic variable interpolation
  String translate(String key, [Map<String, String>? params]) {
    final languageDict = _localizedValues[localeCode] ?? _localizedValues['en']!;
    var value = languageDict[key] ?? _localizedValues['en']![key] ?? key;

    if (params != null) {
      params.forEach((paramKey, paramVal) {
        value = value.replaceAll('{$paramKey}', paramVal);
      });
    }

    return value;
  }

  // Convenience getters
  String get appName => translate('app_name');
  String get appTagline => translate('app_tagline');
  String get tripActive => translate('trip_active');
  String get tripIdle => translate('trip_idle');
  String get tripCompleted => translate('trip_completed');
  String get boarded => translate('boarded');
  String get dropped => translate('dropped');
  String get pending => translate('pending');
  String get absent => translate('absent');
  String get startTrip => translate('start_trip');
  String get endTrip => translate('end_trip');
  String get emergencySos => translate('emergency_sos');
}
