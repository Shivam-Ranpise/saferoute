import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:saferoute_core/saferoute_core.dart';
import '../../../theme/app_theme.dart';
import '../providers/parent_providers.dart';

class SetPickupLocationScreen extends ConsumerStatefulWidget {
  final String childId;

  const SetPickupLocationScreen({
    super.key,
    required this.childId,
  });

  @override
  ConsumerState<SetPickupLocationScreen> createState() =>
      _SetPickupLocationScreenState();
}

class _SetPickupLocationScreenState
    extends ConsumerState<SetPickupLocationScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _stopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  LatLng? _selectedPoint;
  int _notificationDistance = 500;
  bool _isSaving = false;
  bool _isLocating = false;
  bool _initialized = false;

  @override
  void dispose() {
    _stopNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initFromChild(Child? child) {
    if (_initialized || child == null) return;
    _initialized = true;

    if (child.pickupLatitude != null && child.pickupLongitude != null) {
      _selectedPoint = LatLng(child.pickupLatitude!, child.pickupLongitude!);
    } else {
      // Prompt GPS location automatically if no pickup set
      _detectCurrentLocation();
    }

    _stopNameController.text = child.pickupName ?? '';
    _addressController.text = child.pickupAddress ?? '';
    _notificationDistance = child.notificationDistanceMeters;
  }

  Future<void> _detectCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 8),
        );

        final point = LatLng(position.latitude, position.longitude);
        setState(() {
          _selectedPoint = point;
          _isLocating = false;
        });

        _mapController.move(point, 16.0);
        return;
      }
    } catch (e) {
      AppLogger.error('Failed to get GPS location', error: e);
    }

    if (_selectedPoint == null) {
      setState(() {
        _selectedPoint = const LatLng(16.7050, 74.2433); // Kolhapur default
        _isLocating = false;
      });
    }
  }

  Future<void> _saveLocation() async {
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap the map to choose a pickup location.'),
          backgroundColor: SafeRouteColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(parentRepositoryProvider);
      await repo.updateChildPickupLocation(
        childId: widget.childId,
        latitude: _selectedPoint!.latitude,
        longitude: _selectedPoint!.longitude,
        pickupName: _stopNameController.text.trim().isEmpty
            ? null
            : _stopNameController.text.trim(),
        pickupAddress: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        notificationDistanceMeters: _notificationDistance,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup location updated successfully!'),
            backgroundColor: SafeRouteColors.safetyGreen,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update pickup location: $e'),
            backgroundColor: SafeRouteColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(parentChildrenStreamProvider).value ?? [];
    final child = children.firstWhere(
      (c) => c.id == widget.childId,
      orElse: () => Child(
        id: widget.childId,
        organizationId: '',
        parentId: '',
        name: 'Child',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    _initFromChild(child);

    final initialCenter = _selectedPoint ?? const LatLng(16.7050, 74.2433);

    return Scaffold(
      appBar: AppBar(
        title: Text('Set Stop for ${child.name}'),
        backgroundColor: SafeRouteColors.deepNavy,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveLocation,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: SafeRouteColors.yellow,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: SafeRouteColors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Map View for selecting location
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 15.0,
                    maxZoom: AppConfig.mapMaxZoom,
                    onTap: (tapPosition, point) {
                      setState(() {
                        _selectedPoint = point;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: AppConfig.mapTileUrl,
                      userAgentPackageName: 'io.saferoute.app',
                    ),
                    if (_selectedPoint != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedPoint!,
                            radius: _notificationDistance.toDouble(),
                            useRadiusInMeter: true,
                            color: SafeRouteColors.blue.withValues(alpha: 0.15),
                            borderColor: SafeRouteColors.blue,
                            borderStrokeWidth: 2.0,
                          ),
                        ],
                      ),
                    if (_selectedPoint != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint!,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              color: SafeRouteColors.error,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: SafeRouteColors.deepNavy.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.touch_app,
                            color: SafeRouteColors.yellow, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tap on map to place your child pickup point',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'my_location_btn',
                    backgroundColor: SafeRouteColors.deepNavy,
                    foregroundColor: SafeRouteColors.yellow,
                    tooltip: 'Find My Current Location',
                    onPressed: _isLocating ? null : _detectCurrentLocation,
                    child: _isLocating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: SafeRouteColors.yellow,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Configuration Card
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Stop Name Text Field
                TextField(
                  controller: _stopNameController,
                  decoration: const InputDecoration(
                    labelText: 'Stop Name (e.g. Apartment Gate)',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Notification Distance Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Alert Distance',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${_notificationDistance}m before arrival',
                      style: const TextStyle(
                        color: SafeRouteColors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: AppConfig.notificationDistanceOptions.map((dist) {
                    final isSelected = _notificationDistance == dist;
                    return ChoiceChip(
                      label: Text('${dist}m'),
                      selected: isSelected,
                      selectedColor: SafeRouteColors.blue,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? SafeRouteColors.white
                            : SafeRouteColors.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _notificationDistance = dist;
                          });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Save Button
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveLocation,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Stop Location'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
