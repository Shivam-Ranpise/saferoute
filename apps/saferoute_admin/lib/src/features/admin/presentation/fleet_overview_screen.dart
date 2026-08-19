import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/admin_theme.dart';
import '../providers/admin_providers.dart';

class FleetOverviewScreen extends ConsumerStatefulWidget {
  const FleetOverviewScreen({super.key});

  @override
  ConsumerState<FleetOverviewScreen> createState() => _FleetOverviewScreenState();
}

class _FleetOverviewScreenState extends ConsumerState<FleetOverviewScreen> {
  final MapController _mapController = MapController();
  ActiveTripFleetBundle? _selectedTrip;

  // Default fallback center to Kolhapur, Maharashtra
  static const LatLng _kolhapurCenter = LatLng(16.7050, 74.2433);

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(organizationStatsProvider);
    final activeTripsAsync = ref.watch(fleetLiveTripsStreamProvider);
    final orgAsync = ref.watch(currentOrganizationProvider);

    final org = orgAsync.value;
    final hasOrgLocation = org != null && org.latitude != null && org.longitude != null;
    final centerPos = hasOrgLocation
        ? LatLng(org.latitude!, org.longitude!)
        : _kolhapurCenter;

    return Scaffold(
      backgroundColor: AdminColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fleet Overview & Live Tracking',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Real-time GPS telemetry and active school bus routes',
                        style: TextStyle(
                          fontSize: 13,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh Metrics',
                  onPressed: () {
                    ref.invalidate(organizationStatsProvider);
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // KPI Stat Cards Row
            statsAsync.when(
              data: (stats) => Row(
                children: [
                  _buildStatCard(
                    title: 'Active Trips',
                    value: '${stats.activeTripsCount}',
                    subtitle: 'of ${stats.totalBuses} buses on road',
                    icon: Icons.directions_bus_rounded,
                    color: AdminColors.safetyGreen,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Total Buses',
                    value: '${stats.totalBuses}',
                    subtitle: '${stats.activeBuses} registered active',
                    icon: Icons.airport_shuttle_rounded,
                    color: AdminColors.blue,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Drivers',
                    value: '${stats.totalDrivers}',
                    subtitle: 'Verified crew members',
                    icon: Icons.badge_rounded,
                    color: AdminColors.yellow,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    title: 'Students Registered',
                    value: '${stats.totalStudents}',
                    subtitle: 'Across all active routes',
                    icon: Icons.people_alt_rounded,
                    color: AdminColors.deepNavy,
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Live Map & Active Trips Split Layout
            Expanded(
              child: activeTripsAsync.when(
                data: (bundles) {
                  final activeMarkers = bundles
                      .where((b) =>
                          b.trip.currentLatitude != null &&
                          b.trip.currentLongitude != null)
                      .map((b) {
                    final lat = b.trip.currentLatitude!;
                    final lon = b.trip.currentLongitude!;
                    final isSelected = _selectedTrip?.trip.id == b.trip.id;

                    return Marker(
                      point: LatLng(lat, lon),
                      width: 110,
                      height: 60,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedTrip = b);
                        },
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AdminColors.yellow
                                    : AdminColors.deepNavy,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                b.bus?.busNumber ?? 'Bus',
                                style: TextStyle(
                                  color: isSelected
                                      ? AdminColors.deepNavy
                                      : Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.directions_bus_rounded,
                              color: AdminColors.yellow,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList();

                  // Combine bus markers with school destination marker
                  final allMarkers = List<Marker>.from(activeMarkers);
                  if (hasOrgLocation) {
                    allMarkers.add(
                      Marker(
                        point: LatLng(org.latitude!, org.longitude!),
                        width: 140,
                        height: 70,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AdminColors.deepNavy,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AdminColors.yellow, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.school_rounded,
                                      color: AdminColors.yellow, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    org.name.isNotEmpty ? org.name : 'School Destination',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.location_on_rounded,
                              color: AdminColors.error,
                              size: 32,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── FLEET MAP (Zero Google APIs - OpenStreetMap) ─────
                      Expanded(
                        flex: 3,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: centerPos,
                                  initialZoom: 13.0,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.saferoute.admin',
                                  ),
                                  if (hasOrgLocation)
                                    CircleLayer(
                                      circles: [
                                        CircleMarker(
                                          point: LatLng(
                                              org.latitude!, org.longitude!),
                                          radius: org.geofenceRadiusMeters
                                              .toDouble(),
                                          useRadiusInMeter: true,
                                          color: AdminColors.yellow
                                              .withValues(alpha: 0.15),
                                          borderColor: AdminColors.yellow,
                                          borderStrokeWidth: 2,
                                        ),
                                      ],
                                    ),
                                  MarkerLayer(markers: allMarkers),
                                ],
                              ),

                              // Map Floating Controls
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 4,
                                        backgroundColor: AdminColors.safetyGreen,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${bundles.length} Live Buses',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AdminColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // ─── ACTIVE TRIPS TABLE ─────────────────────────────
                      Expanded(
                        flex: 2,
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Active Routes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AdminColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Live Status',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AdminColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Expanded(
                                  child: bundles.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No active trips on road right now.',
                                            style: TextStyle(
                                                color: AdminColors
                                                    .textSecondary),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: bundles.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final b = bundles[index];
                                            final isSelected =
                                                _selectedTrip?.trip.id ==
                                                    b.trip.id;

                                            return ListTile(
                                              selected: isSelected,
                                              selectedTileColor: AdminColors
                                                  .blueLight
                                                  .withValues(alpha: 0.5),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              leading: const CircleAvatar(
                                                backgroundColor:
                                                    AdminColors.deepNavy,
                                                foregroundColor:
                                                    AdminColors.yellow,
                                                child: Icon(
                                                    Icons
                                                        .directions_bus_rounded,
                                                    size: 18),
                                              ),
                                              title: Text(
                                                b.bus?.busNumber ??
                                                    'Bus Route',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              subtitle: Text(
                                                'Driver: ${b.driverName ?? 'Assigned'}${b.trip.currentSpeed != null ? ' • ${b.trip.currentSpeed!.toStringAsFixed(0)} km/h' : ''}',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                              trailing: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: AdminColors
                                                      .safetyGreen
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'EN ROUTE',
                                                  style: TextStyle(
                                                    color: AdminColors
                                                        .safetyGreen,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              onTap: () {
                                                setState(() => _selectedTrip = b);
                                                if (b.trip.currentLatitude != null &&
                                                    b.trip.currentLongitude !=
                                                        null) {
                                                  _mapController.move(
                                                    LatLng(
                                                        b.trip.currentLatitude!,
                                                        b.trip.currentLongitude!),
                                                    14.0,
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AdminColors.yellow),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load active fleet: $e'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AdminColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AdminColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AdminColors.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
