import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/parent_providers.dart';

class TripHudSheet extends ConsumerWidget {
  const TripHudSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final telemetry = ref.watch(busTelemetryProvider);
    final busAsync = ref.watch(selectedChildBusProvider);
    final driverAsync = ref.watch(selectedChildDriverProfileProvider);
    final loc = ref.watch(appLocalizationsProvider);

    if (child == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: SafeRouteColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Center(
          child: Text(
            loc.noChildrenTitle,
            style: const TextStyle(color: SafeRouteColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final bus = busAsync.value;
    final driver = driverAsync.value;

    return Container(
      decoration: const BoxDecoration(
        color: SafeRouteColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SafeRouteColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Status & Proximity Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Proximity / Trip Status Badge
                  _buildStatusBadge(telemetry, loc),

                  // Configure Pickup Location Button
                  TextButton.icon(
                    onPressed: () {
                      context.push('/parent/pickup-location/${child.id}');
                    },
                    icon: const Icon(Icons.edit_location_alt, size: 16),
                    label: Text(
                      child.hasPickupLocation ? loc.editStop : loc.setStop,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: SafeRouteColors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Distance & ETA Metric Display
              if (telemetry.hasOngoingTrip) ...[
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SafeRouteColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Distance to Stop',
                              style: TextStyle(
                                color: SafeRouteColors.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              telemetry.formattedDistance,
                              style: const TextStyle(
                                color: SafeRouteColors.deepNavy,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SafeRouteColors.blueBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Arrival',
                              style: TextStyle(
                                color: SafeRouteColors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              telemetry.estimatedMinutes != null
                                  ? '~${telemetry.estimatedMinutes} mins'
                                  : '--',
                              style: const TextStyle(
                                color: SafeRouteColors.blue,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Bus & Driver Details Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: SafeRouteColors.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: SafeRouteColors.navyMid,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: SafeRouteColors.yellow,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus != null
                                ? 'Bus ${bus.busNumber}'
                                : 'Bus Not Assigned',
                            style: const TextStyle(
                              color: SafeRouteColors.deepNavy,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            driver != null
                                ? 'Driver: ${driver.name}'
                                : 'No driver assigned',
                            style: const TextStyle(
                              color: SafeRouteColors.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (driver != null && driver.phone != null)
                      IconButton.filled(
                        icon: const Icon(Icons.phone, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: SafeRouteColors.safetyGreen,
                          foregroundColor: SafeRouteColors.white,
                        ),
                        onPressed: () {
                          // Quick call driver action
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling Driver: ${driver.phone}'),
                              backgroundColor: SafeRouteColors.deepNavy,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: SafeRouteColors.deepNavy,
                  side: const BorderSide(color: SafeRouteColors.outline),
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.pin_drop_rounded,
                    color: SafeRouteColors.blue, size: 18),
                label: Text(
                  child.hasPickupLocation
                      ? '${loc.editStop}: ${child.pickupName ?? "Designated Stop"}'
                      : '📍 ${loc.setStop} (${child.name})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () {
                  context.push('/parent/pickup-location/${child.id}');
                },
              ),

              if (!child.hasPickupLocation) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: SafeRouteColors.warningLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SafeRouteColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: SafeRouteColors.warning, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Set your child\'s pickup location to receive accurate distance & arrival notifications.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BusTelemetryState telemetry, AppLocalizations loc) {
    if (!telemetry.hasOngoingTrip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: SafeRouteColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 4,
              backgroundColor: SafeRouteColors.disabled,
            ),
            const SizedBox(width: 6),
            Text(
              loc.busInDepot,
              style: const TextStyle(
                color: SafeRouteColors.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    String label;
    Color color;

    switch (telemetry.proximityState) {
      case ProximityState.locked:
        label = loc.busArrived;
        color = SafeRouteColors.safetyGreen;
        break;
      case ProximityState.enteredRadius:
      case ProximityState.notified:
        label = loc.busApproaching;
        color = SafeRouteColors.safetyGreen;
        break;
      case ProximityState.approaching:
        label = loc.busApproaching;
        color = SafeRouteColors.orange;
        break;
      case ProximityState.outside:
        label = loc.busOnTheWay;
        color = SafeRouteColors.blue;
        break;
    }

    if (telemetry.isStale) {
      label = 'GPS Signal Weak';
      color = SafeRouteColors.statusStale;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
