import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
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
  LatLng? _deviceLocation;
  bool _autoFollow = true;

  @override
  void initState() {
    super.initState();
    _fetchDeviceLocation();
  }

  Future<void> _fetchDeviceLocation() async {
    try {
      final hasPermission = await Geolocator.checkPermission();
      if (hasPermission == LocationPermission.always ||
          hasPermission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        if (mounted) {
          setState(() {
            _deviceLocation = LatLng(pos.latitude, pos.longitude);
          });
          _mapController.move(_deviceLocation!, 16.0);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(driverActiveTripProvider);
    final studentsAsync = ref.watch(driverStudentsProvider);
    final trip = tripAsync.value;

    final LatLng livePoint = (trip != null && trip.hasLocation)
        ? LatLng(trip.currentLatitude!, trip.currentLongitude!)
        : (_deviceLocation ?? const LatLng(16.7050, 74.2433));

    final students = studentsAsync.value ?? [];

    // Auto-follow driver live position on map
    if (_autoFollow && trip != null && trip.hasLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapController.move(livePoint, _mapController.camera.zoom);
        }
      });
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: livePoint,
            initialZoom: 16.0,
            maxZoom: AppConfig.mapMaxZoom,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                setState(() => _autoFollow = false);
              }
            },
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

                // Live Driver Location Marker with Pulsing Halo
                Marker(
                  point: livePoint,
                  width: 58,
                  height: 58,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer halo circle
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SafeRouteColors.blue.withValues(alpha: 0.2),
                        ),
                      ),
                      // Inner Bus Icon
                      Transform.rotate(
                        angle: (trip?.currentHeading ?? 0) * (math.pi / 180),
                        child: Container(
                          width: 44,
                          height: 44,
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
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Re-center My Location Floating Button
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'driver_center_gps',
                backgroundColor: _autoFollow ? SafeRouteColors.deepNavy : Colors.white,
                foregroundColor: _autoFollow ? Colors.white : SafeRouteColors.deepNavy,
                onPressed: () {
                  setState(() => _autoFollow = true);
                  _mapController.move(livePoint, 16.5);
                },
                tooltip: 'My Live Location',
                child: const Icon(Icons.my_location, size: 20),
              ),
            ],
          ),
        ),

        // Live Speed Indicator
        if (trip != null && trip.isOngoing)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SafeRouteColors.deepNavy.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, color: SafeRouteColors.yellow, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${(trip.currentSpeed ?? 0).toStringAsFixed(0)} km/h',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
