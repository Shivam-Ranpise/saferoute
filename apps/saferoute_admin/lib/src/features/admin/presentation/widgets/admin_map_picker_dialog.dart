import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../theme/admin_theme.dart';

class LocationPickResult {
  final double latitude;
  final double longitude;
  final String address;

  const LocationPickResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class AdminMapPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final String title;

  const AdminMapPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    this.title = 'Select School Destination Location',
  });

  @override
  State<AdminMapPickerDialog> createState() => _AdminMapPickerDialogState();
}

class _AdminMapPickerDialogState extends State<AdminMapPickerDialog> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  late LatLng _currentCenter;
  late LatLng _selectedPoint;
  String _address = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLatitude ?? 16.6974; // Default to Ichalkaranji / current context
    final lng = widget.initialLongitude ?? 74.4565;
    _selectedPoint = LatLng(lat, lng);
    _currentCenter = _selectedPoint;
    _address = widget.initialAddress ?? '';
    _searchController.text = _address;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().length < 3) return;

    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'SafeRouteAdmin/1.0',
      });

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _searchResults = data.cast<Map<String, dynamic>>();
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (_) {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = double.tryParse(result['lat'] as String? ?? '');
    final lon = double.tryParse(result['lon'] as String? ?? '');
    final displayName = result['display_name'] as String? ?? '';

    if (lat != null && lon != null) {
      final point = LatLng(lat, lon);
      setState(() {
        _selectedPoint = point;
        _currentCenter = point;
        _address = displayName;
        _searchController.text = displayName;
        _searchResults.clear();
      });
      _mapController.move(point, 16.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 850,
        height: 620,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // ── Modal Header ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: AdminColors.deepNavy,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminColors.yellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: AdminColors.deepNavy, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Search address or click on the map to place the school marker',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search Bar & Autocomplete ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search school address, landmark, or street name...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded),
                                    onPressed: () =>
                                        _searchAddress(_searchController.text),
                                  ),
                          ),
                          onSubmitted: _searchAddress,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.deepNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.search_rounded, size: 18),
                        label: const Text('Search'),
                        onPressed: () => _searchAddress(_searchController.text),
                      ),
                    ],
                  ),

                  // Search Results Dropdown List
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: AdminColors.border),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final item = _searchResults[idx];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_rounded,
                                color: AdminColors.safetyGreen, size: 18),
                            title: Text(
                              item['display_name'] as String? ?? '',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectSearchResult(item),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ── Interactive Map View ──
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _currentCenter,
                      initialZoom: 15.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _selectedPoint = point;
                          _address =
                              'Lat: ${point.latitude.toStringAsFixed(5)}, Lon: ${point.longitude.toStringAsFixed(5)}';
                          _searchController.text = _address;
                          _searchResults.clear();
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.saferoute.admin',
                      ),

                      // Geofence Circle (200m)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _selectedPoint,
                            radius: 200,
                            useRadiusInMeter: true,
                            color: AdminColors.deepNavy.withValues(alpha: 0.15),
                            borderColor: AdminColors.deepNavy,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),

                      // Destination School Marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedPoint,
                            width: 50,
                            height: 50,
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: AdminColors.error,
                                  size: 40,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Info Badge on Bottom Left
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pin_drop_rounded,
                              size: 16, color: AdminColors.safetyGreen),
                          const SizedBox(width: 6),
                          Text(
                            'Coordinates: ${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
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

            // ── Modal Actions ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: AdminColors.surface,
                border: Border(top: BorderSide(color: AdminColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _address.isNotEmpty
                          ? 'Selected: $_address'
                          : 'Click anywhere on the map to set location point',
                      style: const TextStyle(
                          fontSize: 12, color: AdminColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.safetyGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Confirm Location',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        LocationPickResult(
                          latitude: _selectedPoint.latitude,
                          longitude: _selectedPoint.longitude,
                          address: _searchController.text.trim().isNotEmpty
                              ? _searchController.text.trim()
                              : 'Lat: ${_selectedPoint.latitude.toStringAsFixed(4)}, Lon: ${_selectedPoint.longitude.toStringAsFixed(4)}',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
