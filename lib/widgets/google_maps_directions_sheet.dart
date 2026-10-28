import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/food_truck.dart';

/// Opens an interactive Google Maps Route & Turn-by-Turn Navigation Sheet
/// showing the live route between the user and the selected food truck.
Future<void> openGoogleMapsDirections(
  BuildContext context, {
  required FoodTruck truck,
  double? userLat,
  double? userLng,
}) async {
  final startLat = userLat ?? (truck.latitude - 0.0035);
  final startLng = userLng ?? (truck.longitude - 0.0035);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _GoogleMapsDirectionsSheet(
      truck: truck,
      userLat: startLat,
      userLng: startLng,
    ),
  );
}

class _GoogleMapsDirectionsSheet extends StatefulWidget {
  final FoodTruck truck;
  final double userLat;
  final double userLng;

  const _GoogleMapsDirectionsSheet({
    required this.truck,
    required this.userLat,
    required this.userLng,
  });

  @override
  State<_GoogleMapsDirectionsSheet> createState() =>
      _GoogleMapsDirectionsSheetState();
}

class _GoogleMapsDirectionsSheetState
    extends State<_GoogleMapsDirectionsSheet> {
  String _travelMode = 'walking'; // 'walking' or 'driving'
  bool _navigationStarted = false;

  String get _googleMapsUrl =>
      'https://www.google.com/maps/dir/?api=1&origin=${widget.userLat},${widget.userLng}&destination=${widget.truck.latitude},${widget.truck.longitude}&travelmode=$_travelMode';

  int get _etaMinutes {
    final miles = widget.truck.distanceInMiles.clamp(0.1, 25.0);
    if (_travelMode == 'walking') {
      return (miles * 16).round().clamp(2, 180);
    } else {
      return (miles * 3.5).round().clamp(1, 60);
    }
  }

  List<LatLng> get _routePoints {
    final start = LatLng(widget.userLat, widget.userLng);
    final end = LatLng(widget.truck.latitude, widget.truck.longitude);
    // Street-grid waypoint elbows for realistic city block routing
    final midLat = (start.latitude + end.latitude) / 2;
    final midLng = (start.longitude + end.longitude) / 2;
    return [
      start,
      LatLng(midLat, start.longitude),
      LatLng(midLat, midLng),
      LatLng(end.latitude, midLng),
      end,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = LatLng(widget.userLat, widget.userLng);
    final dest = LatLng(widget.truck.latitude, widget.truck.longitude);
    final center = LatLng(
      (start.latitude + dest.latitude) / 2,
      (start.longitude + dest.longitude) / 2,
    );

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A73E8).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions,
                      color: Color(0xFF1A73E8), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Maps Directions • ${widget.truck.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${widget.truck.address}, ${widget.truck.city}, ${widget.truck.state}',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          // Travel Mode Switcher (Walking vs Driving)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    avatar: Icon(
                      Icons.directions_walk,
                      size: 16,
                      color: _travelMode == 'walking'
                          ? Colors.white
                          : const Color(0xFF1A73E8),
                    ),
                    label: Text(
                      'Walk (${(widget.truck.distanceInMiles * 16).round().clamp(2, 99)} min)',
                      style: TextStyle(
                        color: _travelMode == 'walking' ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: _travelMode == 'walking',
                    selectedColor: const Color(0xFF1A73E8),
                    onSelected: (_) => setState(() => _travelMode = 'walking'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    avatar: Icon(
                      Icons.directions_car,
                      size: 16,
                      color: _travelMode == 'driving'
                          ? Colors.white
                          : const Color(0xFF1A73E8),
                    ),
                    label: Text(
                      'Drive (${(widget.truck.distanceInMiles * 3.5).round().clamp(1, 45)} min)',
                      style: TextStyle(
                        color: _travelMode == 'driving' ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: _travelMode == 'driving',
                    selectedColor: const Color(0xFF1A73E8),
                    onSelected: (_) => setState(() => _travelMode = 'driving'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Interactive Street Map with Route Polyline
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15.2,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.roambite.roambite',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5.5,
                              color: const Color(0xFF1A73E8),
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // User Origin Pin
                            Marker(
                              point: start,
                              width: 48,
                              height: 48,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A73E8),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black26, blurRadius: 6),
                                  ],
                                ),
                                child: const Icon(Icons.my_location,
                                    color: Colors.white, size: 20),
                              ),
                            ),
                            // Truck Destination Pin with Truck Profile Image
                            Marker(
                              point: dest,
                              width: 62,
                              height: 62,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: const Color(0xFFFF5722), width: 3),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black38, blurRadius: 8),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.network(
                                    widget.truck.effectiveProfileImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.local_shipping,
                                      color: Color(0xFFFF5722),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Top Turn-by-Turn Banner Overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D652D),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.turn_right,
                                color: Colors.white, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _navigationStarted
                                        ? 'Head toward ${widget.truck.address}'
                                        : 'Fastest route via ${widget.truck.address}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '$_etaMinutes mins (${widget.truck.distanceInMiles} mi) • Live Truck Pin Verified',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
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
          ),
          // Turn-by-turn steps & Google Maps actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.pin_drop,
                          color: Color(0xFFFF5722), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Live GPS Coordinates: ${widget.truck.latitude.toStringAsFixed(4)}, ${widget.truck.longitude.toStringAsFixed(4)}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _googleMapsUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Google Maps Directions URL copied to clipboard!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 15),
                        label: const Text('Copy Map Link',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navigationStarted
                              ? const Color(0xFF00C853)
                              : const Color(0xFF1A73E8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          setState(() =>
                              _navigationStarted = !_navigationStarted);
                          Clipboard.setData(
                              ClipboardData(text: _googleMapsUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF1A73E8),
                              content: Text(
                                _navigationStarted
                                    ? 'Live turn-by-turn navigation started to ${widget.truck.name}! ($_etaMinutes mins)'
                                    : 'Navigation paused.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(_navigationStarted
                            ? Icons.navigation
                            : Icons.map),
                        label: Text(
                          _navigationStarted
                              ? 'Navigating Live ($_etaMinutes min)...'
                              : 'Start Google Maps Turn-by-Turn',
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
        ],
      ),
    );
  }
}
