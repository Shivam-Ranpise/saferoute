import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saferoute_core/saferoute_core.dart';

class AppNotificationHelper {
  static final FlutterLocalNotificationsPlugin _localNotifs =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static final Set<String> _seenDeliveryIds = {};
  static final DateTime _appLaunchTime = DateTime.now();
  static bool _dialogShowing = false;

  /// Registers FCM Token with Supabase and sets up auto-refresh
  static Future<void> registerDevicePushToken(String profileId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      AppLogger.info('FCM Authorization status: ${settings.authorizationStatus}', context: 'AppNotificationHelper');

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        AppLogger.info('Registering FCM Token with Supabase for profileId: $profileId', context: 'AppNotificationHelper');
        await NotificationRepository().registerDeviceToken(
          profileId: profileId,
          fcmToken: token,
          platform: DevicePlatform.android,
        );
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.isNotEmpty) {
          await NotificationRepository().registerDeviceToken(
            profileId: profileId,
            fcmToken: newToken,
            platform: DevicePlatform.android,
          );
        }
      });
    } catch (e) {
      AppLogger.warning('Failed to register FCM token: $e', context: 'AppNotificationHelper');
    }
  }

  /// Unregisters FCM Token on logout
  static Future<void> unregisterDevicePushToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await NotificationRepository().unregisterDeviceToken(token);
      }
    } catch (e) {
      AppLogger.warning('Failed to unregister FCM token: $e', context: 'AppNotificationHelper');
    }
  }

  static Future<void> init() async {
    if (_initialized) return;

    try {
      AppLogger.info('Initializing AppNotificationHelper & Notification Channels (v2)...', context: 'AppNotificationHelper');

      // 1. Request Android 13+ Notification Permission via permission_handler
      final permStatus = await Permission.notification.request();
      AppLogger.info('Permission.notification.request() status: $permStatus', context: 'AppNotificationHelper');

      // 2. Initialize Local Notifications Plugin
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifs.initialize(initSettings);

      // 3. Create High Importance Android Notification Channel (Enables Heads-Up Floating Banners)
      const androidChannel = AndroidNotificationChannel(
        'saferoute_emergency_alerts_v2',
        'SafeRoute Push Notifications',
        description: 'High-priority floating banners and system notifications for SafeRoute alerts',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      final androidPlugin = _localNotifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(androidChannel);
        final pluginPerm = await androidPlugin.requestNotificationsPermission();
        AppLogger.info('AndroidFlutterLocalNotificationsPlugin permission granted: $pluginPerm', context: 'AppNotificationHelper');
      }

      _initialized = true;
      AppLogger.info('AppNotificationHelper initialized successfully', context: 'AppNotificationHelper');
    } catch (e) {
      AppLogger.warning('Failed to initialize local notifications: $e', context: 'AppNotificationHelper');
    }
  }

  /// Ensures notification permission is granted on ANY Android version (9 to 15+).
  static Future<void> ensureNotificationPermission(BuildContext context) async {
    await init();

    try {
      var status = await Permission.notification.status;
      AppLogger.info('ensureNotificationPermission check -> status: $status', context: 'AppNotificationHelper');
      if (!status.isGranted) {
        status = await Permission.notification.request();
        AppLogger.info('Permission re-request result: $status', context: 'AppNotificationHelper');
      }

      final androidPlugin = _localNotifs.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted == false) {
          status = PermissionStatus.denied;
        }
      }

      if (!status.isGranted && context.mounted && !_dialogShowing) {
        AppLogger.info('Permission not granted. Presenting mandatory setting dialog...', context: 'AppNotificationHelper');
        _dialogShowing = true;
        await _showMandatoryPermissionDialog(context);
        _dialogShowing = false;
      }
    } catch (e) {
      AppLogger.warning('Error checking notification permission: $e', context: 'AppNotificationHelper');
    }
  }

  static Future<void> _showMandatoryPermissionDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFF2563EB),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Allow Notifications',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'SafeRoute requires notification permissions to send live bus arrival alerts, safety updates, and emergency notices.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.settings_suggest_rounded, size: 20),
                  label: const Text(
                    'Enable Notifications',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    await openAppSettings();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Displays an Android Floating Heads-Up System Tray Push Notification
  static Future<void> showSystemNotification({
    required String deliveryId,
    required String title,
    required String message,
    DateTime? createdAt,
  }) async {
    // If notification was created BEFORE app was launched, mark as seen and do not pop up historical items
    if (createdAt != null && createdAt.isBefore(_appLaunchTime.subtract(const Duration(seconds: 10)))) {
      _seenDeliveryIds.add(deliveryId);
      return;
    }

    if (_seenDeliveryIds.contains(deliveryId)) {
      AppLogger.info('Notification deliveryId $deliveryId already popped up. Skipping duplicate.', context: 'AppNotificationHelper');
      return;
    }
    _seenDeliveryIds.add(deliveryId);

    AppLogger.info('🚨 TRIGGERING LIVE FLOATING HEADS-UP BANNER POPUP: [$title] -> "$message"', context: 'AppNotificationHelper');
    await init();
    try {
      const androidDetails = AndroidNotificationDetails(
        'saferoute_emergency_alerts_v2',
        'SafeRoute Push Notifications',
        channelDescription: 'System tray notifications for SafeRoute safety alerts and announcements',
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'SafeRoute Emergency Notification',
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        styleInformation: BigTextStyleInformation(''),
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      const notificationId = 1001; // Single clean notification tray slot
      await _localNotifs.show(
        notificationId,
        title,
        message,
        notificationDetails,
      );
      AppLogger.info('SUCCESS: Local floating system banner popped up for deliveryId: $deliveryId', context: 'AppNotificationHelper');
    } catch (e) {
      AppLogger.warning('Failed to show system tray notification: $e', context: 'AppNotificationHelper');
    }
  }

  /// Displays an In-App Center Card Modal Popup when the app is active in foreground
  static Future<void> showInAppCenterPopup(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onDismiss,
    VoidCallback? onDelete,
  }) async {
    if (!context.mounted) return;

    AppLogger.info('💬 POPPING UP IN-APP CENTER DIALOG MODAL: [$title]', context: 'AppNotificationHelper');

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        backgroundColor: const Color(0xFF0F172A), // Dark Navy
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Color(0xFFF59E0B), // Golden Yellow
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (onDelete != null) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      tooltip: 'Delete Notification',
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        onDelete();
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        onDismiss?.call();
                      },
                      child: const Text(
                        'OK / Dismiss',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
