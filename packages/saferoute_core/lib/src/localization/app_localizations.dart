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
      'login_subtitle': 'Enter your username, mobile number, or email.',
      'identifier_label': 'Username, Mobile or Email',
      'identifier_hint': 'e.g. parent or +919876543210',
      'identifier_error': 'Please enter your username, mobile, or email',
      'password_label': 'Password',
      'password_error': 'Please enter your password',
      'sign_in_button': 'Sign In',
      'welcome_user': 'Welcome, {name}',
      'parent_home_title': 'Live Bus Tracking',
      'child_tracking': 'Child Live Tracking',
      'bus_status': 'Bus Status',
      'live_track': 'Live Track',
      'notifications': 'Notifications',
      'location': 'Location',
      'settings': 'Settings',
      'set_location': 'Set Location',
      'edit_stop': 'Edit Stop',
      'set_stop': 'Set Stop',
      'no_children_title': 'No Children Linked Yet',
      'no_children_subtitle': 'Please contact your school administrator to register and link your child to your account.',
      'check_again': 'Check Again',
      'retry': 'Retry',
      'bus_in_depot': 'Bus in Depot',
      'bus_on_the_way': 'Bus On The Way',
      'bus_approaching': 'Approaching Stop',
      'bus_arrived': 'Arrived at Stop',
      'safe_at_school': 'Safe at School',
      'bus_nearby_title': 'Bus Arriving Soon! 🚌',
      'bus_nearby_message': 'Bus is approx {distance} from {child_name}\'s stop.',
      'trip_active': 'Trip in Progress',
      'trip_idle': 'Bus in Depot',
      'trip_completed': 'Trip Completed',
      'trip_paused': 'GPS Paused',
      'boarded': 'Boarded',
      'dropped': 'Dropped Off',
      'pending': 'Pending',
      'absent': 'Absent',
      'morning_pickup': 'Morning Pickup',
      'afternoon_drop': 'Afternoon Drop-off',
      'driver_dashboard': 'Driver Live Console',
      'start_trip': 'Start Route',
      'pause_gps': 'Pause GPS',
      'resume_gps': 'Resume GPS',
      'end_trip': 'End Route',
      'emergency_sos': 'Emergency SOS Alert',
      'report_delay': 'Report Delay',
      'manifest_title': 'Student Roll Call',
      'settings_title': 'App Settings',
      'notification_preferences': 'Notification Preferences',
      'delivery_channels': 'Delivery Channels',
      'push_notifications': 'In-App Push Notifications',
      'push_subtitle': 'Instant alerts on your device',
      'whatsapp_messages': 'WhatsApp Messages',
      'whatsapp_subtitle': 'Updates sent directly to your WhatsApp',
      'sms_messages': 'SMS Text Messages',
      'sms_subtitle': 'Standard SMS message alerts',
      'voice_settings_title': 'Voice & Speech Alerts',
      'voice_settings_subtitle': 'Custom spoken announcements when bus arrives',
      'language_title': 'App Language / भाषा',
      'language_subtitle': 'Choose your preferred language for the application',
      'save_button': 'Save Preferences',
      'logout_button': 'Sign Out',
      'sign_out_dialog_title': 'Sign Out',
      'sign_out_dialog_msg': 'Are you sure you want to sign out of SafeRoute?',
      'cancel_button': 'Cancel',
      'try_again': 'Try Again',
      'invalid_credentials_title': 'Invalid Credentials',
      'invalid_credentials_msg': 'The username, mobile number or password you entered is incorrect. Please check your credentials and try again.',
      'voice_controls_title': 'Voice Controls & Speech Rate',
      'speech_speed': 'Speech Speed:',
      'voice_volume': 'Voice Volume:',
      'test_play_voice': 'Test Play Voice Sample',
      'announcement_templates': 'Spoken Announcement Templates',
      'spoken_voice_alerts': 'Spoken Voice Alerts',
      'voice_enabled_desc': 'Speaks bus arrival & school updates out loud',
      'voice_disabled_desc': 'Voice announcements are disabled',
      'slow': 'Slow',
      'normal': 'Normal',
      'fast': 'Fast',
      'driver_appbar_title': 'SafeRoute Driver',
      'driver_prefix': 'Driver: {name}',
      'no_bus_assigned': 'No Bus Assigned',
      'no_bus_assigned_desc': 'Please contact school operations to assign a vehicle to your driver profile.',
      'live_gps_broadcasting': 'LIVE GPS BROADCASTING',
      'gps_paused': 'GPS PAUSED',
      'delay_button': 'Delay',
      'sos_button': 'SOS Alert',
      'report_delay_title': 'Report Bus Delay',
      'emergency_sos_title': 'Emergency SOS Alert',
      'delay_dialog_subtitle': 'Notify parents instantly about delay timing:',
      'sos_dialog_subtitle': 'Select emergency type to immediately alert parents and school admins:',
      'alert_reason_label': 'Alert Reason / Category:',
      'recipient_target_label': 'Send Alert To:',
      'all_parents_broadcast': 'All Parents (Broadcast)',
      'specific_parent': 'Specific Student\'s Parent',
      'select_student_label': 'Select Student / Stop:',
      'custom_reason_label': 'Type Custom Reason / Title *',
      'custom_reason_hint': 'e.g. Tree fallen on road / Route diversion',
      'delay_duration_label': 'Select Delay Duration (Quick Pick):',
      'additional_details_label': 'Additional Details (Optional)',
      'additional_details_hint_delay': 'e.g. Heavy traffic near Sony Signal, moving slowly',
      'additional_details_hint_sos': 'e.g. Flat tire on 80ft Road, waiting for mechanic',
      'send_delay_btn': 'Send Delay Notice',
      'broadcast_sos_btn': 'Broadcast SOS',
      'end_trip_dialog_title': 'End Trip?',
      'end_trip_dialog_msg': 'Are you sure you want to finish this trip? Live GPS broadcasting will stop and parents will be notified that the trip has concluded.',
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
      'login_subtitle': 'अपना उपयोगकर्ता नाम, मोबाइल नंबर या ईमेल दर्ज करें।',
      'identifier_label': 'उपयोगकर्ता नाम, मोबाइल या ईमेल',
      'identifier_hint': 'उदा. parent या +919876543210',
      'identifier_error': 'कृपया अपना उपयोगकर्ता नाम, मोबाइल या ईमेल दर्ज करें',
      'password_label': 'पासवर्ड',
      'password_error': 'कृपया अपना पासवर्ड दर्ज करें',
      'sign_in_button': 'साइन इन करें',
      'welcome_user': 'स्वागत है, {name}',
      'parent_home_title': 'लाइव बस ट्रैकिंग',
      'child_tracking': 'बच्चे की लाइव ट्रैकिंग',
      'bus_status': 'बस की स्थिति',
      'live_track': 'लाइव ट्रैक',
      'notifications': 'सूचनाएं',
      'location': 'स्टॉप स्थान',
      'settings': 'सेटिंग्स',
      'set_location': 'स्थान सेट करें',
      'edit_stop': 'स्टॉप बदलें',
      'set_stop': 'स्टॉप सेट करें',
      'no_children_title': 'कोई बच्चा लिंक नहीं है',
      'no_children_subtitle': 'कृपया अपने बच्चे को अपने खाते से जोड़ने के लिए स्कूल प्रशासक से संपर्क करें।',
      'check_again': 'पुनः जांचें',
      'retry': 'पुनः प्रयास करें',
      'bus_in_depot': 'बस डिपो में है',
      'bus_on_the_way': 'बस रास्ते में है',
      'bus_approaching': 'स्टॉप के पास पहुंच रही है',
      'bus_arrived': 'स्टॉप पर पहुंच गई',
      'safe_at_school': 'स्कूल सुरक्षित पहुंच गए',
      'bus_nearby_title': 'बस जल्द ही आ रही है! 🚌',
      'bus_nearby_message': 'बस {child_name} के स्टॉप से लगभग {distance} दूर है।',
      'trip_active': 'यात्रा जारी है',
      'trip_idle': 'बस डिपो में है',
      'trip_completed': 'यात्रा समाप्त हुई',
      'trip_paused': 'जीपीएस रुका हुआ है',
      'boarded': 'बस में बैठा',
      'dropped': 'उतार दिया गया',
      'pending': 'प्रतीक्षारत',
      'absent': 'अनुपस्थित',
      'morning_pickup': 'सुबह पिकअप',
      'afternoon_drop': 'दोपहर ड्रॉप-ऑफ',
      'driver_dashboard': 'ड्राइवर लाइव कंसोल',
      'start_trip': 'यात्रा शुरू करें',
      'pause_gps': 'जीपीएस रोकें',
      'resume_gps': 'जीपीएस पुनः चालू करें',
      'end_trip': 'यात्रा समाप्त करें',
      'emergency_sos': 'आपातकालीन एसओएस चेतावनी',
      'report_delay': 'देरी की सूचना दें',
      'manifest_title': 'छात्र उपस्थिति सूची',
      'settings_title': 'ऐप सेटिंग्स',
      'notification_preferences': 'सूचना प्राथमिकताएं',
      'delivery_channels': 'सूचना के माध्यम',
      'push_notifications': 'ऐप पुश सूचनाएं',
      'push_subtitle': 'आपके डिवाइस पर तुरंत अलर्ट',
      'whatsapp_messages': 'व्हाट्सएप संदेश',
      'whatsapp_subtitle': 'सीधे आपके व्हाट्सएप पर अपडेट',
      'sms_messages': 'एसएमएस टेक्स्ट संदेश',
      'sms_subtitle': 'मानक एसएमएस संदेश अलर्ट',
      'voice_settings_title': 'आवाज और भाषण अलर्ट',
      'voice_settings_subtitle': 'बस आने पर बोलकर सुनाई जाने वाली सूचनाएं',
      'language_title': 'ऐप की भाषा (Language)',
      'language_subtitle': 'एप्लिकेशन के लिए अपनी पसंदीदा भाषा चुनें',
      'save_button': 'सेटिंग्स सुरक्षित करें',
      'logout_button': 'लॉग आउट',
      'sign_out_dialog_title': 'लॉग आउट करें',
      'sign_out_dialog_msg': 'क्या आप वाकई सेफरूट से लॉग आउट करना चाहते हैं?',
      'cancel_button': 'रद्द करें',
      'try_again': 'पुनः प्रयास करें',
      'invalid_credentials_title': 'अमान्य विवरण',
      'invalid_credentials_msg': 'दर्ज किया गया उपयोगकर्ता नाम, मोबाइल नंबर या पासवर्ड गलत है। कृपया जांचें और पुनः प्रयास करें।',
      'voice_controls_title': 'आवाज नियंत्रण और बोलने की गति',
      'speech_speed': 'बोलने की गति:',
      'voice_volume': 'आवाज की तीव्रता:',
      'test_play_voice': 'परीक्षण आवाज बजाएं',
      'announcement_templates': 'घोषणा टेम्पलेट',
      'spoken_voice_alerts': 'बोलकर सुनाई जाने वाली आवाज सूचनाएं',
      'voice_enabled_desc': 'बस आने और स्कूल अपडेट को बोलकर सुनाता है',
      'voice_disabled_desc': 'आवाज घोषणाएं अक्षम हैं',
      'slow': 'धीमा',
      'normal': 'सामान्य',
      'fast': 'तेज',
      'driver_appbar_title': 'सेफरूट ड्राइवर',
      'driver_prefix': 'ड्राइवर: {name}',
      'no_bus_assigned': 'कोई बस आवंटित नहीं है',
      'no_bus_assigned_desc': 'कृपया अपने ड्राइवर प्रोफ़ाइल में वाहन असाइन करने के लिए स्कूल प्रशासन से संपर्क करें।',
      'live_gps_broadcasting': 'लाइव जीपीएस चालू है',
      'gps_paused': 'जीपीएस रुका हुआ है',
      'delay_button': 'देरी',
      'sos_button': 'एसओएस अलर्ट',
      'report_delay_title': 'बस में देरी की सूचना दें',
      'emergency_sos_title': 'आपातकालीन एसओएस चेतावनी',
      'delay_dialog_subtitle': 'अभिभावकों को तुरंत बस में देरी की सूचना दें:',
      'sos_dialog_subtitle': 'अभिभावकों और स्कूल प्रशासन को तुरंत अलर्ट करने के लिए आपातकाल प्रकार चुनें:',
      'alert_reason_label': 'अलर्ट का कारण / श्रेणी:',
      'recipient_target_label': 'अलर्ट किसे भेजें:',
      'all_parents_broadcast': 'सभी अभिभावक (प्रसारण)',
      'specific_parent': 'विशिष्ट छात्र के अभिभावक',
      'select_student_label': 'छात्र / स्टॉप चुनें:',
      'custom_reason_label': 'कस्टम कारण / शीर्षक लिखें *',
      'custom_reason_hint': 'उदा. सड़क पर पेड़ गिर गया / मार्ग परिवर्तन',
      'delay_duration_label': 'देरी का समय चुनें:',
      'additional_details_label': 'अतिरिक्त विवरण (वैकल्पिक)',
      'additional_details_hint_delay': 'उदा. सिग्नल पर भारी ट्रैफिक, धीरे चल रही है',
      'additional_details_hint_sos': 'उदा. टायर पंक्चर हो गया, मैकेनिक का इंतजार है',
      'send_delay_btn': 'देरी की सूचना भेजें',
      'broadcast_sos_btn': 'एसओएस भेजें',
      'end_trip_dialog_title': 'यात्रा समाप्त करें?',
      'end_trip_dialog_msg': 'क्या आप वाकई यह यात्रा समाप्त करना चाहते हैं? लाइव जीपीएस रुक जाएगा और अभिभावकों को सूचित कर दिया जाएगा।',
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
      'login_subtitle': 'आपला वापरकर्ता नाव, मोबाईल क्रमांक किंवा ईमेल प्रविष्ट करा.',
      'identifier_label': 'वापरकर्ता नाव, मोबाईल किंवा ईमेल',
      'identifier_hint': 'उदा. parent किंवा +919876543210',
      'identifier_error': 'कृपया आपले वापरकर्ता नाव, मोबाईल किंवा ईमेल प्रविष्ट करा',
      'password_label': 'पासवर्ड',
      'password_error': 'कृपया आपला पासवर्ड प्रविष्ट करा',
      'sign_in_button': 'साइन इन करा',
      'welcome_user': 'स्वागत आहे, {name}',
      'parent_home_title': 'थेट बस ट्रॅकिंग',
      'child_tracking': 'विद्यार्थी थेट ट्रॅकिंग',
      'bus_status': 'बसची स्थिती',
      'live_track': 'थेट ट्रॅकिंग',
      'notifications': 'सूचना',
      'location': 'थांबा स्थान',
      'settings': 'सेटिंग्ज',
      'set_location': 'स्थान सेट करा',
      'edit_stop': 'थांबा बदला',
      'set_stop': 'थांबा सेट करा',
      'no_children_title': 'कोणतेही मूल लिंक केलेले नाही',
      'no_children_subtitle': 'कृपया आपल्या पाल्याला खात्याशी लिंक करण्यासाठी शाळा प्रशासकाशी संपर्क साधा.',
      'check_again': 'पुन्हा तपासा',
      'retry': 'पुन्हा प्रयत्न करा',
      'bus_in_depot': 'बस डेपोमध्ये आहे',
      'bus_on_the_way': 'बस मार्गावर आहे',
      'bus_approaching': 'थांब्याजवळ पोहोचत आहे',
      'bus_arrived': 'थांब्यावर पोहोचली',
      'safe_at_school': 'शाळेत सुरक्षित पोहोचले',
      'bus_nearby_title': 'बस लवकरच पोहोचत आहे! 🚌',
      'bus_nearby_message': 'बस {child_name} च्या थांब्यापासून सुमारे {distance} अंतरावर आहे.',
      'trip_active': 'प्रवास सुरू आहे',
      'trip_idle': 'बस डेपोमध्ये आहे',
      'trip_completed': 'प्रवास पूर्ण झाला',
      'trip_paused': 'जीपीएस थांबवले आहे',
      'boarded': 'बसमध्ये चढले',
      'dropped': 'सोडण्यात आले',
      'pending': 'प्रलंबित',
      'absent': 'अनुपस्थित',
      'morning_pickup': 'सकाळची पिकअप',
      'afternoon_drop': 'दुपारची ड्रॉप-ऑफ',
      'driver_dashboard': 'चालक लाइव्ह कन्सोल',
      'start_trip': 'प्रवास सुरू करा',
      'pause_gps': 'जीपीएस थांबवा',
      'resume_gps': 'जीपीएस पुन्हा सुरू करा',
      'end_trip': 'प्रवास समाप्त करा',
      'emergency_sos': 'आपत्कालीन एसओएस अलर्ट',
      'report_delay': 'उशीर कळवा',
      'manifest_title': 'विद्यार्थी हजेरी यादी',
      'settings_title': 'अ‍ॅप सेटिंग्ज',
      'notification_preferences': 'सूचना पसंती',
      'delivery_channels': 'सूचना मार्ग',
      'push_notifications': 'अ‍ॅप पुश सूचना',
      'push_subtitle': 'आपल्या डिव्हाइसवर त्वरित सूचना',
      'whatsapp_messages': 'व्हॉट्सअ‍ॅप संदेश',
      'whatsapp_subtitle': 'थेट आपल्या व्हॉट्सअ‍ॅपवर अपडेट',
      'sms_messages': 'एसएमएस संदेश',
      'sms_subtitle': 'नेहमीचे एसएमएस संदेश अलर्ट',
      'voice_settings_title': 'आवाज आणि उच्चार अलर्ट',
      'voice_settings_subtitle': 'बस आल्यावर ऐकू येणाऱ्या सूचना',
      'language_title': 'अ‍ॅपची भाषा (Language)',
      'language_subtitle': 'अनुप्रयोगासाठी आपली पसंतीची भाषा निवडा',
      'save_button': 'पसंती जतन करा',
      'logout_button': 'लॉग आऊट',
      'sign_out_dialog_title': 'लॉग आऊट करा',
      'sign_out_dialog_msg': 'तुम्हाला खात्री आहे की तुम्ही सेफरूटमधून लॉग आऊट करू इच्छिता?',
      'cancel_button': 'रद्द करा',
      'try_again': 'पुन्हा प्रयत्न करा',
      'invalid_credentials_title': 'अवैध तपशील',
      'invalid_credentials_msg': 'प्रविष्ट केलेले वापरकर्ता नाव, मोबाईल क्रमांक किंवा पासवर्ड चुकीचा आहे. कृपया तपासा आणि पुन्हा प्रयत्न करा.',
      'voice_controls_title': 'आवाज नियंत्रण आणि बोलण्याचा वेग',
      'speech_speed': 'बोलण्याचा वेग:',
      'voice_volume': 'आवाजाची पातळी:',
      'test_play_voice': 'चाचणी आवाज प्ले करा',
      'announcement_templates': 'घोषणा टेम्पलेट्स',
      'spoken_voice_alerts': 'ऐकू येणाऱ्या आवाज सूचना',
      'voice_enabled_desc': 'बस आल्यावर आणि शाळेचे अपडेट बोलून सांगते',
      'voice_disabled_desc': 'आवाज घोषणा अक्षम आहेत',
      'slow': 'हळू',
      'normal': 'सामान्य',
      'fast': 'जलद',
      'driver_appbar_title': 'सेफरूट चालक',
      'driver_prefix': 'चालक: {name}',
      'no_bus_assigned': 'कोणतीही बस नेमलेली नाही',
      'no_bus_assigned_desc': 'कृपया आपल्या चालक प्रोफाईलमध्ये वाहन जोडण्यासाठी शाळा प्रशासनाशी संपर्क साधा.',
      'live_gps_broadcasting': 'थेट जीपीएस सुरू आहे',
      'gps_paused': 'जीपीएस थांबवले आहे',
      'delay_button': 'उशीर',
      'sos_button': 'एसओएस अलर्ट',
      'report_delay_title': 'बसला झालेल्या उशीराची माहिती द्या',
      'emergency_sos_title': 'आपत्कालीन एसओएस अलर्ट',
      'delay_dialog_subtitle': 'पालकांना त्वरित बस उशीराची माहिती द्या:',
      'sos_dialog_subtitle': 'पालक आणि शाळा प्रशासनाला त्वरित अलर्ट करण्यासाठी आपत्कालीन प्रकार निवडा:',
      'alert_reason_label': 'अलर्टचे कारण / प्रकार:',
      'recipient_target_label': 'अलर्ट कोणाला पाठवायचे:',
      'all_parents_broadcast': 'सर्व पालक (प्रसारण)',
      'specific_parent': 'विशिष्ट विद्यार्थ्याचे पालक',
      'select_student_label': 'विद्यार्थी / थांबा निवडा:',
      'custom_reason_label': 'स्वतःचे कारण / शीर्षक लिहा *',
      'custom_reason_hint': 'उदा. रस्त्यावर झाड पडले / मार्ग बदल',
      'delay_duration_label': 'उशीराची वेळ निवडा:',
      'additional_details_label': 'अधिक तपशील (ऐच्छिक)',
      'additional_details_hint_delay': 'उदा. सिग्नलजवळ प्रचंड ट्रॅफिक, हळू चालली आहे',
      'additional_details_hint_sos': 'उदा. टायर पंक्चर झाला, मेकॅनिकची वाट पाहत आहे',
      'send_delay_btn': 'उशीराची सूचना पाठवा',
      'broadcast_sos_btn': 'एसओएस पाठवा',
      'end_trip_dialog_title': 'प्रवास समाप्त करायचा?',
      'end_trip_dialog_msg': 'तुम्हाला खात्री आहे की तुम्ही हा प्रवास समाप्त करू इच्छिता? थेट जीपीएस थांबेल आणि पालकांना प्रवास पूर्ण झाल्याची माहिती दिली जाईल.',
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
  String get loginTitle => translate('login_title');
  String get loginSubtitle => translate('login_subtitle');
  String get identifierLabel => translate('identifier_label');
  String get identifierHint => translate('identifier_hint');
  String get identifierError => translate('identifier_error');
  String get passwordLabel => translate('password_label');
  String get passwordError => translate('password_error');
  String get signInButton => translate('sign_in_button');
  String welcome(String name) => translate('welcome_user', {'name': name});
  String get parentHomeTitle => translate('parent_home_title');
  String get childTracking => translate('child_tracking');
  String get busStatus => translate('bus_status');
  String get liveTrack => translate('live_track');
  String get notifications => translate('notifications');
  String get location => translate('location');
  String get settings => translate('settings');
  String get setLocation => translate('set_location');
  String get editStop => translate('edit_stop');
  String get setStop => translate('set_stop');
  String get noChildrenTitle => translate('no_children_title');
  String get noChildrenSubtitle => translate('no_children_subtitle');
  String get checkAgain => translate('check_again');
  String get retry => translate('retry');
  String get busInDepot => translate('bus_in_depot');
  String get busOnTheWay => translate('bus_on_the_way');
  String get busApproaching => translate('bus_approaching');
  String get busArrived => translate('bus_arrived');
  String get safeAtSchool => translate('safe_at_school');
  String get tripActive => translate('trip_active');
  String get tripIdle => translate('trip_idle');
  String get tripCompleted => translate('trip_completed');
  String get tripPaused => translate('trip_paused');
  String get boarded => translate('boarded');
  String get dropped => translate('dropped');
  String get pending => translate('pending');
  String get absent => translate('absent');
  String get morningPickup => translate('morning_pickup');
  String get afternoonDrop => translate('afternoon_drop');
  String get driverDashboard => translate('driver_dashboard');
  String get startTrip => translate('start_trip');
  String get pauseGps => translate('pause_gps');
  String get resumeGps => translate('resume_gps');
  String get endTrip => translate('end_trip');
  String get emergencySos => translate('emergency_sos');
  String get reportDelay => translate('report_delay');
  String get manifestTitle => translate('manifest_title');
  String get settingsTitle => translate('settings_title');
  String get notificationPreferences => translate('notification_preferences');
  String get deliveryChannels => translate('delivery_channels');
  String get pushNotifications => translate('push_notifications');
  String get pushSubtitle => translate('push_subtitle');
  String get whatsappMessages => translate('whatsapp_messages');
  String get whatsappSubtitle => translate('whatsapp_subtitle');
  String get smsMessages => translate('sms_messages');
  String get smsSubtitle => translate('sms_subtitle');
  String get voiceSettingsTitle => translate('voice_settings_title');
  String get voiceSettingsSubtitle => translate('voice_settings_subtitle');
  String get languageTitle => translate('language_title');
  String get languageSubtitle => translate('language_subtitle');
  String get saveButton => translate('save_button');
  String get logoutButton => translate('logout_button');
  String get signOutDialogTitle => translate('sign_out_dialog_title');
  String get signOutDialogMsg => translate('sign_out_dialog_msg');
  String get cancelButton => translate('cancel_button');
  String get tryAgain => translate('try_again');
  String get invalidCredentialsTitle => translate('invalid_credentials_title');
  String get invalidCredentialsMsg => translate('invalid_credentials_msg');
  String get voiceControlsTitle => translate('voice_controls_title');
  String get speechSpeed => translate('speech_speed');
  String get voiceVolume => translate('voice_volume');
  String get testPlayVoice => translate('test_play_voice');
  String get announcementTemplates => translate('announcement_templates');
  String get spokenVoiceAlerts => translate('spoken_voice_alerts');
  String get voiceEnabledDesc => translate('voice_enabled_desc');
  String get voiceDisabledDesc => translate('voice_disabled_desc');
  String get slow => translate('slow');
  String get normal => translate('normal');
  String get fast => translate('fast');
  String get driverAppbarTitle => translate('driver_appbar_title');
  String driverPrefix(String name) => translate('driver_prefix', {'name': name});
  String get noBusAssigned => translate('no_bus_assigned');
  String get noBusAssignedDesc => translate('no_bus_assigned_desc');
  String get liveGpsBroadcasting => translate('live_gps_broadcasting');
  String get gpsPaused => translate('gps_paused');
  String get delayButton => translate('delay_button');
  String get sosButton => translate('sos_button');
  String get reportDelayTitle => translate('report_delay_title');
  String get emergencySosTitle => translate('emergency_sos_title');
  String get delayDialogSubtitle => translate('delay_dialog_subtitle');
  String get sosDialogSubtitle => translate('sos_dialog_subtitle');
  String get alertReasonLabel => translate('alert_reason_label');
  String get recipientTargetLabel => translate('recipient_target_label');
  String get allParentsBroadcast => translate('all_parents_broadcast');
  String get specificParent => translate('specific_parent');
  String get selectStudentLabel => translate('select_student_label');
  String get customReasonLabel => translate('custom_reason_label');
  String get customReasonHint => translate('custom_reason_hint');
  String get delayDurationLabel => translate('delay_duration_label');
  String get additionalDetailsLabel => translate('additional_details_label');
  String get additionalDetailsHintDelay => translate('additional_details_hint_delay');
  String get additionalDetailsHintSos => translate('additional_details_hint_sos');
  String get sendDelayBtn => translate('send_delay_btn');
  String get broadcastSosBtn => translate('broadcast_sos_btn');
  String get endTripDialogTitle => translate('end_trip_dialog_title');
  String get endTripDialogMsg => translate('end_trip_dialog_msg');
}
