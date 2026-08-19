import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
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

  void _confirmEndTrip() {
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
                      Icons.stop_circle_outlined,
                      color: SafeRouteColors.error,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'End Trip?',
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
                'Are you sure you want to finish this trip? Live GPS broadcasting will stop and parents will be notified that the trip has concluded.',
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
                        ref.read(driverActiveTripProvider.notifier).endTrip();
                      },
                      child: const Text(
                        'End Trip',
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
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider);
    final bundleAsync = ref.watch(currentDriverBundleProvider);
    final tripAsync = ref.watch(driverActiveTripProvider);
    final trip = tripAsync.value;

    return Scaffold(
      backgroundColor: SafeRouteColors.deepNavy,
      appBar: AppBar(
        backgroundColor: SafeRouteColors.deepNavy,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SafeRoute Driver',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            if (profile != null)
              Text(
                'Driver: ${profile.name}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
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
                          'Are you sure you want to sign out of SafeRoute Driver?',
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
      body: bundleAsync.when(
        data: (bundle) {
          if (bundle == null || bundle.bus == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_bus_outlined,
                        color: SafeRouteColors.yellow, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'No Bus Assigned',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please contact school operations to assign a vehicle to your driver profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, height: 1.4),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded,
                                  size: 28),
                              label: const Text(
                                'START TRIP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              onPressed: () => ref
                                  .read(driverActiveTripProvider.notifier)
                                  .startTrip(),
                            ),
                          ),
                        ] else ...[
                          // Active Trip Status & Controls
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                          ? 'LIVE GPS BROADCASTING'
                                          : 'GPS PAUSED',
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
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: SafeRouteColors.error,
                                ),
                                icon: const Icon(Icons.warning_rounded,
                                    size: 18),
                                label: const Text(
                                  'SOS Alert',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: _showEmergencyDialog,
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  icon: Icon(
                                    ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ),
                                  label: Text(
                                    ref.watch(driverActiveTripProvider.notifier).isBroadcasting
                                        ? 'Pause GPS'
                                        : 'Resume GPS',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
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
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  icon: const Icon(Icons.stop_rounded),
                                  label: const Text(
                                    'End Trip',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
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
