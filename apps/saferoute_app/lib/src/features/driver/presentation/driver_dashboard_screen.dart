import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../theme/app_theme.dart';
import '../../notifications/services/app_notification_service.dart';
import '../providers/driver_providers.dart';
import 'widgets/driver_map_view.dart';
import 'widgets/emergency_dialog.dart';

class DriverDashboardScreen extends ConsumerStatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  ConsumerState<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends ConsumerState<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppNotificationHelper.ensureNotificationPermission(context);
    });
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (context) => const EmergencyDialog(),
    );
  }

  void _showDelayDialog() {
    showDialog(
      context: context,
      builder: (context) => const EmergencyDialog(isDelayMode: true),
    );
  }

  /// Checks GPS permission & location services before starting a trip.
  /// If disabled, opens Android's system location settings dialog.
  Future<void> _startTripWithGpsCheck() async {
    // 1. Check if location services are enabled at the OS level
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      // Show a dialog explaining why location is needed, then open settings
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.location_off_rounded, color: Colors.orange, size: 26),
              SizedBox(width: 10),
              Text('Location Required', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'GPS location must be enabled to start a trip.\n\n'
            'Parents track the bus in real-time through your device location. '
            'Please turn on Location Services to continue.',
            style: TextStyle(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeRouteColors.safetyGreen,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Enable GPS', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        ),
      );
      // After the user returns from settings, re-check
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; // Still off — abort
    }

    // 2. Check / request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. Cannot start trip.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.gps_off_rounded, color: Colors.red, size: 26),
              SizedBox(width: 10),
              Text('Permission Blocked', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Location permission is permanently denied.\n\n'
            'Please go to App Settings → Permissions → Location and set it to "Allow while using the app".',
            style: TextStyle(fontSize: 13.5, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SafeRouteColors.deepNavy,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.app_settings_alt_rounded, size: 18),
              label: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await Geolocator.openAppSettings();
              },
            ),
          ],
        ),
      );
      return;
    }

    // 3. All checks passed — start the trip
    if (!mounted) return;
    await ref.read(driverActiveTripProvider.notifier).startTrip();
  }

  void _confirmEndTrip() {
    final loc = ref.read(appLocalizationsProvider);
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
                      color: SafeRouteColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.stop_circle_outlined,
                      color: SafeRouteColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    loc.endTripDialogTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: SafeRouteColors.deepNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                loc.endTripDialogMsg,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: Text(
                        loc.cancelButton,
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
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ref.read(driverActiveTripProvider.notifier).endTrip();
                      },
                      child: Text(
                        loc.endTrip,
                        style: const TextStyle(
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
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final bundleAsync = ref.watch(currentDriverBundleProvider);
    final tripAsync = ref.watch(driverActiveTripProvider);
    final trip = tripAsync.value;
    final loc = ref.watch(appLocalizationsProvider);
    final currentLocale = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: SafeRouteColors.deepNavy,
      appBar: AppBar(
        backgroundColor: SafeRouteColors.deepNavy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.driverAppbarTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (profile != null)
              Text(
                loc.driverPrefix(profile.name),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          // Language Switcher Dropdown
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language_rounded, size: 16, color: SafeRouteColors.yellow),
                  const SizedBox(width: 4),
                  Text(
                    currentLocale.languageCode == 'mr'
                        ? 'मराठी'
                        : (currentLocale.languageCode == 'hi' ? 'हिंदी' : 'EN'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (langCode) {
              ref.read(appLocaleProvider.notifier).setLanguage(langCode);
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇬🇧 English'),
                    if (currentLocale.languageCode == 'en')
                      const Spacer(),
                    if (currentLocale.languageCode == 'en')
                      const Icon(Icons.check, color: SafeRouteColors.deepNavy, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hi',
                child: Row(
                  children: [
                    const Text('🇮🇳 हिंदी (Hindi)'),
                    if (currentLocale.languageCode == 'hi')
                      const Spacer(),
                    if (currentLocale.languageCode == 'hi')
                      const Icon(Icons.check, color: SafeRouteColors.deepNavy, size: 18),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'mr',
                child: Row(
                  children: [
                    const Text('🇮🇳 मराठी (Marathi)'),
                    if (currentLocale.languageCode == 'mr')
                      const Spacer(),
                    if (currentLocale.languageCode == 'mr')
                      const Icon(Icons.check, color: SafeRouteColors.deepNavy, size: 18),
                  ],
                ),
              ),
            ],
          ),

          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: loc.logoutButton,
            onPressed: () {
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
                            Text(
                              loc.signOutDialogTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: SafeRouteColors.deepNavy,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          loc.signOutDialogMsg,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(dialogCtx),
                                child: Text(
                                  loc.cancelButton,
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
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogCtx);
                                  ref.read(authProvider.notifier).signOut();
                                },
                                child: Text(
                                  loc.logoutButton,
                                  style: const TextStyle(
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
      body: bundleAsync.when(
        data: (bundle) {
          if (bundle == null || bundle.bus == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_bus_outlined,
                        color: SafeRouteColors.yellow, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      loc.noBusAssigned,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.noBusAssignedDesc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          final bus = bundle.bus!;

          return Column(
            children: [
              // Assigned Bus Info Bar
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                color: SafeRouteColors.navyMid,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.directions_bus,
                            color: SafeRouteColors.yellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Bus ${bus.busNumber}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      bus.registrationNumber ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Split View: OSM Live Map
              const Expanded(
                child: DriverMapView(),
              ),

              // Bottom Trip Controls Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: SafeRouteColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trip == null || !trip.isOngoing) ...[
                      // Start Trip Action
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: SafeRouteColors.safetyGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 28),
                          label: Text(
                            loc.startTrip.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          onPressed: _startTripWithGpsCheck,
                        ),
                      ),
                    ] else ...[
                      // Active Trip Status & Controls
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                  ? SafeRouteColors.safetyGreen.withValues(alpha: 0.2)
                                  : SafeRouteColors.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 4,
                                  backgroundColor: ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                      ? SafeRouteColors.safetyGreen
                                      : SafeRouteColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                      ? loc.liveGpsBroadcasting
                                      : loc.gpsPaused,
                                  style: TextStyle(
                                    color: ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                        ? SafeRouteColors.safetyGreen
                                        : SafeRouteColors.warning,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.timer_outlined, size: 15),
                                label: Text(
                                  loc.delayButton,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                ),
                                onPressed: _showDelayDialog,
                              ),
                              const SizedBox(width: 4),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: SafeRouteColors.error,
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.warning_rounded, size: 15),
                                label: Text(
                                  loc.sosButton,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                                ),
                                onPressed: _showEmergencyDialog,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          // Pause / Resume Toggle
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: Icon(
                                ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                    ? loc.pauseGps
                                    : loc.resumeGps,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                ref
                                    .read(driverActiveTripProvider.notifier)
                                    .toggleGpsBroadcasting();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          // End Trip Button
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: SafeRouteColors.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(Icons.stop_rounded),
                              label: Text(
                                loc.endTrip,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: _confirmEndTrip,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: SafeRouteColors.yellow),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load driver info: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
