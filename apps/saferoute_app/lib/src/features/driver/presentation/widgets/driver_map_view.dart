import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/driver_providers.dart';

class DriverMapView extends ConsumerStatefulWidget {
  const DriverMapView({super.key});

  @override
  ConsumerState<DriverMapView> createState() => _DriverMapViewState();
}

class _DriverMapViewState extends ConsumerState<DriverMapView> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(driverActiveTripProvider);
    final studentsAsync = ref.watch(driverStudentsProvider);
    final trip = tripAsync.value;

    final busPoint = (trip != null && trip.hasLocation)
        ? LatLng(trip.currentLatitude!, trip.currentLongitude!)
        : const LatLng(12.9716, 77.5946);

    final students = studentsAsync.value ?? [];

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: busPoint,
        initialZoom: 15.0,
        maxZoom: AppConfig.mapMaxZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: AppConfig.mapTileUrl,
          userAgentPackageName: 'io.saferoute.app',
          maxZoom: AppConfig.mapMaxZoom,
        ),

        // Pickup Stop Markers
        MarkerLayer(
          markers: [
            // Student Pickup Points
            ...students
                .where((s) => s.hasPickupLocation)
                .map(
                  (s) => Marker(
                    point: LatLng(s.pickupLatitude!, s.pickupLongitude!),
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: SafeRouteColors.blue,
                      size: 32,
                    ),
                  ),
                ),

            // Live Bus Marker
            if (trip != null && trip.hasLocation)
              Marker(
                point: busPoint,
                width: 50,
                height: 50,
                child: Transform.rotate(
                  angle: (trip.currentHeading ?? 0) * (math.pi / 180),
                  child: Container(
                    decoration: BoxDecoration(
                      color: SafeRouteColors.yellow,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: SafeRouteColors.deepNavy,
                        width: 2.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: SafeRouteColors.deepNavy,
                      size: 26,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
