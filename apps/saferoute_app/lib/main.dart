import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferoute_core/saferoute_core.dart';
import 'src/features/notifications/services/app_notification_service.dart';
import 'src/providers/locale_provider.dart';
import 'src/router/app_router.dart';
import 'src/theme/app_theme.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final notif = message.notification;
    if (notif != null) {
      await AppNotificationHelper.showSystemNotification(
        deliveryId: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: notif.title ?? 'SafeRoute Alert',
        message: notif.body ?? '',
      );
    }
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on phones (allow landscape on tablets)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Initialize Supabase (anon key only — service role is NEVER here)
  await SupabaseService.initialize();

  // Initialize Firebase (for FCM push notifications)
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        AppNotificationHelper.showSystemNotification(
          deliveryId: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: notif.title ?? 'SafeRoute Alert',
          message: notif.body ?? '',
        );
      }
    });
  } catch (e) {
    AppLogger.warning('Firebase messaging setup skipped (running in dev/fallback mode): $e');
  }

  // Initialize Local Notifications & setup Android notification channel
  await AppNotificationHelper.init();

  runApp(
    const ProviderScope(
      child: SafeRouteApp(),
    ),
  );
}

class SafeRouteApp extends ConsumerWidget {
  const SafeRouteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SafeRoute',
      debugShowCheckedModeBanner: false,
      theme: SafeRouteTheme.lightTheme,
      routerConfig: router,

      // Multi-Language Support (English, Hindi, Marathi)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'IN'),
        Locale('hi', 'IN'),
        Locale('mr', 'IN'),
      ],
      locale: ref.watch(appLocaleProvider),

      // Accessibility
      builder: (context, child) {
        return MediaQuery(
          // Prevent text scaling from breaking layouts
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.3),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
