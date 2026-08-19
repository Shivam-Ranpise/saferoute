import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../../theme/app_theme.dart';
import '../../providers/parent_providers.dart';

class BusMapView extends ConsumerStatefulWidget {
  const BusMapView({super.key});

  @override
  ConsumerState<BusMapView> createState() => _BusMapViewState();
}

class _BusMapViewState extends ConsumerState<BusMapView> {
  final MapController _mapController = MapController();
  bool _hasInitialCentered = false;

  void _fitBounds(LatLng busPoint, LatLng pickupPoint) {
    final bounds = LatLngBounds.fromPoints([busPoint, pickupPoint]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(
          top: 80,
          bottom: 220,
          left: 50,
          right: 50,
        ),
      ),
    );
  }

  void _centerOnBus(LatLng busPoint) {
    _mapController.move(busPoint, 16.0);
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(selectedChildProvider);
    final telemetry = ref.watch(busTelemetryProvider);

    // Fallback default coordinates (Kolhapur, Maharashtra) if neither is set
    const defaultCenter = LatLng(16.7050, 74.2433);

    LatLng? pickupPoint;
    if (child != null && child.hasPickupLocation) {
      pickupPoint = LatLng(child.pickupLatitude!, child.pickupLongitude!);
    }

    LatLng? busPoint;
    if (telemetry.trip != null && telemetry.trip!.hasLocation) {
      busPoint = LatLng(
        telemetry.trip!.currentLatitude!,
        telemetry.trip!.currentLongitude!,
      );
    }

    final initialCenter = busPoint ?? pickupPoint ?? defaultCenter;

    // Auto-fit on first load once coordinates are available
    if (!_hasInitialCentered && busPoint != null && pickupPoint != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _fitBounds(busPoint!, pickupPoint!);
          _hasInitialCentered = true;
        }
      });
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15.0,
            maxZoom: AppConfig.mapMaxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // OpenStreetMap Tile Layer
            TileLayer(
              urlTemplate: AppConfig.mapTileUrl,
              userAgentPackageName: 'io.saferoute.app',
              maxZoom: AppConfig.mapMaxZoom,
            ),

            // Geofence Circle around Child Pickup Location
            if (pickupPoint != null && child != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: pickupPoint,
                    radius: child.notificationDistanceMeters.toDouble(),
                    useRadiusInMeter: true,
                    color: SafeRouteColors.blue.withValues(alpha: 0.12),
                    borderColor: SafeRouteColors.blue,
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),

            // Markers Layer (Pickup Pin & Live Bus)
            MarkerLayer(
              markers: [
                // Child Pickup Pin
                if (pickupPoint != null && child != null)
                  Marker(
                    point: pickupPoint,
                    width: 60,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: SafeRouteColors.deepNavy,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ],
                          ),
                          child: Text(
                            child.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.location_pin,
                          color: SafeRouteColors.blue,
                          size: 36,
                        ),
                      ],
                    ),
                  ),

                // Live Bus Marker with Heading Rotation
                if (busPoint != null && telemetry.trip != null)
                  Marker(
                    point: busPoint,
                    width: 54,
                    height: 54,
                    child: Transform.rotate(
                      angle: (telemetry.trip!.currentHeading ?? 0) * (math.pi / 180),
                      child: Container(
                        decoration: BoxDecoration(
                          color: telemetry.isStale
                              ? SafeRouteColors.statusStale
                              : SafeRouteColors.yellow,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black38,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: SafeRouteColors.deepNavy,
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: SafeRouteColors.deepNavy,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Floating Map Controls (Fit Bounds, Center on Bus)
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              if (busPoint != null)
                FloatingActionButton.small(
                  heroTag: 'center_bus',
                  backgroundColor: SafeRouteColors.white,
                  foregroundColor: SafeRouteColors.deepNavy,
                  onPressed: () => _centerOnBus(busPoint!),
                  tooltip: 'Center on Bus',
                  child: const Icon(Icons.directions_bus, size: 20),
                ),
              if (busPoint != null && pickupPoint != null) ...[
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'fit_bounds',
                  backgroundColor: SafeRouteColors.white,
                  foregroundColor: SafeRouteColors.deepNavy,
                  onPressed: () => _fitBounds(busPoint!, pickupPoint!),
                  tooltip: 'Show Both',
                  child: const Icon(Icons.crop_free, size: 20),
                ),
              ],
            ],
          ),
        ),

        // Stale Telemetry Warning Banner
        if (telemetry.isStale && telemetry.hasOngoingTrip)
          Positioned(
            top: 16,
            left: 16,
            right: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: SafeRouteColors.statusStale,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bus GPS paused or connection slow (>5m ago)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
