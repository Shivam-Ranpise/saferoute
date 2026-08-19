import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../../notifications/providers/notification_providers.dart';
import '../../notifications/providers/voice_settings_provider.dart';
import '../../notifications/services/app_notification_service.dart';
import '../../notifications/services/app_voice_service.dart';
import '../providers/parent_providers.dart';
import 'widgets/bus_map_view.dart';
import 'widgets/child_selector_bar.dart';
import 'widgets/trip_hud_sheet.dart';

class ParentHomeScreen extends ConsumerStatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  ConsumerState<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends ConsumerState<ParentHomeScreen> {
  bool _promptedForStop = false;
  final Set<String> _seenNotificationIds = {};
  bool _initialNotificationsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppNotificationHelper.ensureNotificationPermission(context);
    });
  }

  void _checkFirstTimeStop(List<Child> children) {
    if (_promptedForStop || children.isEmpty) return;
    final unconfiguredChild = children.cast<Child?>().firstWhere(
          (c) => c != null && !c.hasPickupLocation,
          orElse: () => null,
        );

    if (unconfiguredChild != null) {
      _promptedForStop = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (dialogCtx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: SafeRouteColors.blue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pin_drop_rounded,
                          color: SafeRouteColors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Set Pickup Location',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: SafeRouteColors.deepNavy,
                              ),
                            ),
                            Text(
                              'For ${unconfiguredChild.name}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome to SafeRoute! To enable live bus tracking and arrival alerts, please set your child\'s pickup location on the map.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: Text(
                            'Later',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeRouteColors.deepNavy,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(
                            Icons.my_location_rounded,
                            size: 16,
                            color: SafeRouteColors.yellow,
                          ),
                          label: const Text(
                            'Set Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            context.push('/parent/pickup-location/${unconfiguredChild.id}');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<NotificationItem>>>(parentNotificationsProvider, (previous, next) {
      next.whenData((items) {
        if (!_initialNotificationsLoaded) {
          _initialNotificationsLoaded = true;
          _seenNotificationIds.addAll(items.map((i) => i.id));
          return;
        }

        for (final item in items) {
          if (!_seenNotificationIds.contains(item.id)) {
            _seenNotificationIds.add(item.id);

            // 1. Play System Notification Sound & Tray Banner
            AppNotificationHelper.showSystemNotification(
              deliveryId: item.id,
              title: item.title,
              message: item.message,
              createdAt: item.createdAt,
            );

            // 2. Speak voice announcement if enabled
            final voiceSettings = ref.read(voiceSettingsProvider);
            if (voiceSettings.enabled) {
              final spoken = AppVoiceService.instance.generateSpokenSentence(
                title: item.title,
                message: item.message,
              );
              AppVoiceService.instance.speak(spoken);
            }

            // 3. Show In-App Center Popup Modal
            AppNotificationHelper.showInAppCenterPopup(
              context,
              title: item.title,
              message: item.message,
              onDismiss: () {
                ref.read(readNotificationIdsProvider.notifier).update(
                      (state) => {...state, item.id},
                    );
                ref.read(notificationRepositoryProvider).markAsRead(item.id);
              },
              onDelete: () {
                ref.read(clearedNotificationIdsProvider.notifier).update(
                      (state) => {...state, item.id},
                    );
                ref.read(readNotificationIdsProvider.notifier).update(
                      (state) => {...state, item.id},
                    );
              },
            );
          }
        }
      });
    });

    final profile = ref.watch(currentProfileProvider);
    final childrenAsync = ref.watch(parentChildrenStreamProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: SafeRouteColors.deepNavy,
      appBar: AppBar(
        backgroundColor: SafeRouteColors.deepNavy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SafeRoute',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (profile != null)
              Text(
                'Welcome, ${profile.name}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.translate_rounded, color: Colors.white),
            tooltip: 'Language / भाषा',
            onSelected: (code) {
              ref.read(appLocaleProvider.notifier).setLanguage(code);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'en', child: Text('🇬🇧 English')),
              PopupMenuItem(value: 'hi', child: Text('🇮🇳 हिंदी (Hindi)')),
              PopupMenuItem(value: 'mr', child: Text('🇮🇳 मराठी (Marathi)')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.record_voice_over_rounded, color: Colors.white),
            tooltip: 'Voice Alerts (TTS)',
            onPressed: () => context.push('/parent/voice-settings'),
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded, color: Colors.white),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: SafeRouteColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Notifications',
            onPressed: () => context.push('/parent/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.edit_location_alt_rounded, color: SafeRouteColors.yellow),
            tooltip: 'Edit Child Stop',
            onPressed: () {
              final child = ref.read(selectedChildProvider);
              if (child != null) {
                context.push('/parent/pickup-location/${child.id}');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  backgroundColor: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: SafeRouteColors.error.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: SafeRouteColors.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: SafeRouteColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Are you sure you want to sign out of SafeRoute?',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: SafeRouteColors.error,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  ref.read(authProvider.notifier).signOut();
                                },
                                child: const Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
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
            },
          ),
        ],
      ),
      body: childrenAsync.when(
        data: (children) {
          _checkFirstTimeStop(children);

          if (children.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.child_care_rounded,
                        color: SafeRouteColors.yellow, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'No Children Linked Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please contact your school administrator to register and link your child to your account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check Again'),
                      onPressed: () =>
                          ref.refresh(parentChildrenStreamProvider),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Column(
            children: [
              // Multi-child selection bar
              ChildSelectorBar(),

              // Live Map & HUD View
              Expanded(
                child: Stack(
                  children: [
                    // OpenStreetMap Live View
                    Positioned.fill(
                      child: BusMapView(),
                    ),

                    // Floating Bottom HUD Sheet
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: TripHudSheet(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SafeRouteColors.yellow),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    color: SafeRouteColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load children: $err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(parentChildrenStreamProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
