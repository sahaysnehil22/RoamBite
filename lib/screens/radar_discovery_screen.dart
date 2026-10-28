import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/food_truck.dart';
import '../services/demo_trucks.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import '../widgets/google_maps_directions_sheet.dart';
import '../widgets/radar_painter.dart';
import 'truck_detail_screen.dart';

class RadarDiscoveryScreen extends StatefulWidget {
  final UserLocation currentLocation;
  final VoidCallback onOpenLocationPicker;

  const RadarDiscoveryScreen({
    super.key,
    required this.currentLocation,
    required this.onOpenLocationPicker,
  });

  @override
  State<RadarDiscoveryScreen> createState() => _RadarDiscoveryScreenState();
}

class _RadarDiscoveryScreenState extends State<RadarDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final MapController _mapController = MapController();

  bool _showGoogleMapView = true; // Default to interactive Map + Radar toggle
  double _scanRadiusMiles = 2.5;
  bool _alertEnabled = true;
  double _alertRadiusMiles = 1.0;
  bool _quietHoursEnabled = true;
  bool _isScanning = false;
  List<FoodTruck> _trucks = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _loadAlertSettings();
    _loadTrucks();
  }

  Future<void> _loadAlertSettings() async {
    final cfg = await SupabaseService().loadAlertRadiusSettings();
    if (!mounted) return;
    setState(() {
      _alertEnabled = cfg.enabled;
      _alertRadiusMiles = cfg.radiusMiles;
      _quietHoursEnabled = cfg.quietHoursEnabled;
    });
  }

  @override
  void didUpdateWidget(covariant RadarDiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation.latitude != widget.currentLocation.latitude ||
        oldWidget.currentLocation.longitude !=
            widget.currentLocation.longitude) {
      _loadTrucks();
    }
  }

  Future<void> _loadTrucks() async {
    setState(() => _isScanning = true);
    if (!SupabaseConfig.isConfigured) {
      final demo = DemoTrucks.forLocation(
        userLat: widget.currentLocation.latitude,
        userLng: widget.currentLocation.longitude,
      );
      if (mounted) {
        setState(() {
          _trucks = demo;
          _isScanning = false;
        });
      }
      return;
    }
    final results = await SupabaseService().fetchLiveTrucks(
      userLat: widget.currentLocation.latitude,
      userLng: widget.currentLocation.longitude,
      radiusMiles: _scanRadiusMiles,
    );
    if (mounted) {
      setState(() {
        _trucks = results.isEmpty
            ? DemoTrucks.forLocation(
                userLat: widget.currentLocation.latitude,
                userLng: widget.currentLocation.longitude,
              )
            : results;
        _isScanning = false;
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerScan() {
    _pulseController.reset();
    _pulseController.repeat();
    _loadTrucks();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Scanning $_scanRadiusMiles mi radius around ${widget.currentLocation.label}...',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openTruckProfile(FoodTruck truck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
    );
    if (mounted) {
      _loadTrucks();
    }
  }

  Future<void> _openAlertRadiusSheet(List<FoodTruck> alertTrucks) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            final currentMatches = _trucks
                .where((t) => t.distanceInMiles <= _alertRadiusMiles)
                .toList();

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF5722).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_active,
                            color: Color(0xFFFF5722)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Proximity Alert Radius Geofence',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 17),
                            ),
                            Text(
                              'Get notified when live food trucks enter your alert zone',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Enable Live Truck Arrival Alerts',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      _alertEnabled
                          ? 'Active within ${_alertRadiusMiles.toStringAsFixed(1)} mi of ${widget.currentLocation.label}'
                          : 'Arrival notifications paused',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: _alertEnabled,
                    activeThumbColor: const Color(0xFFFF5722),
                    onChanged: (val) {
                      setModalState(() => _alertEnabled = val);
                      setState(() => _alertEnabled = val);
                      SupabaseService().saveAlertRadiusSettings(
                        enabled: _alertEnabled,
                        radiusMiles: _alertRadiusMiles,
                        quietHoursEnabled: _quietHoursEnabled,
                        userLat: widget.currentLocation.latitude,
                        userLng: widget.currentLocation.longitude,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select Alert Radius Distance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [0.5, 1.0, 2.0, 5.0].map((r) {
                      final selected = _alertRadiusMiles == r;
                      return ChoiceChip(
                        label: Text('$r mi alert'),
                        selected: selected,
                        selectedColor: const Color(0xFFFF5722),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : null,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setModalState(() => _alertRadiusMiles = r);
                          setState(() => _alertRadiusMiles = r);
                          SupabaseService().saveAlertRadiusSettings(
                            enabled: _alertEnabled,
                            radiusMiles: _alertRadiusMiles,
                            quietHoursEnabled: _quietHoursEnabled,
                            userLat: widget.currentLocation.latitude,
                            userLng: widget.currentLocation.longitude,
                          );
                        },
                      );
                    }).toList(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Quiet Hours (10:00 PM – 8:00 AM)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    subtitle: const Text(
                      'Mute arrival pushes overnight',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _quietHoursEnabled,
                    activeThumbColor: const Color(0xFFFF5722),
                    onChanged: (val) {
                      setModalState(() => _quietHoursEnabled = val);
                      setState(() => _quietHoursEnabled = val);
                      SupabaseService().saveAlertRadiusSettings(
                        enabled: _alertEnabled,
                        radiusMiles: _alertRadiusMiles,
                        quietHoursEnabled: _quietHoursEnabled,
                        userLat: widget.currentLocation.latitude,
                        userLng: widget.currentLocation.longitude,
                      );
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    'Trucks Currently Inside Alert Zone (${currentMatches.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (currentMatches.isEmpty)
                    const Text(
                      'No trucks currently inside this alert radius. Increase radius to catch more trucks.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    ...currentMatches.take(3).map(
                          (t) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(t.effectiveProfileImage),
                            ),
                            title: Text(
                              t.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              '${t.distanceInMiles} mi away • ${t.address}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: TextButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                openGoogleMapsDirections(
                                  context,
                                  truck: t,
                                  userLat: widget.currentLocation.latitude,
                                  userLng: widget.currentLocation.longitude,
                                );
                              },
                              icon: const Icon(Icons.directions, size: 16),
                              label: const Text('Directions'),
                            ),
                          ),
                        ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final firstName = currentMatches.isNotEmpty
                            ? currentMatches.first.name
                            : 'Taco Trail Express';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF00C853),
                            content: Text(
                              'Arrival Alert Active: $firstName is serving within $_alertRadiusMiles mi of your location!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_active),
                      label: const Text(
                        'Save Alert Radius & Test Live Notification',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nearbyTrucks =
        _trucks.where((t) => t.distanceInMiles <= _scanRadiusMiles).toList();
    final alertTrucks =
        _trucks.where((t) => t.distanceInMiles <= _alertRadiusMiles).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background View: Interactive Google Map OR Radar Pulse Canvas
            if (_showGoogleMapView)
              _buildInteractiveMap(nearbyTrucks, theme)
            else
              Stack(
                children: [
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(MediaQuery.of(context).size.width,
                              MediaQuery.of(context).size.width),
                          painter: RadarPulsePainter(
                            animationValue: _pulseController.value,
                            primaryColor: theme.colorScheme.primary,
                            accentColor: Colors.amber,
                          ),
                        );
                      },
                    ),
                  ),
                  ..._buildRadarTruckPins(nearbyTrucks, theme),
                ],
              ),

            // Top Header: Location Bar, Map/Radar Switcher, Scan Radius & Alert Radius
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _buildLocationAndModeHeader(theme, alertTrucks),
                  const SizedBox(height: 8),
                  _buildRadiusAndAlertBar(theme, alertTrucks),
                ],
              ),
            ),

            // Floating Action Buttons: Re-center & Scan Area
            Positioned(
              right: 16,
              bottom: 235,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_showGoogleMapView)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FloatingActionButton.small(
                        heroTag: 'recenter_map_btn',
                        backgroundColor: theme.colorScheme.surface,
                        onPressed: () {
                          _mapController.move(
                            LatLng(widget.currentLocation.latitude,
                                widget.currentLocation.longitude),
                            14.4,
                          );
                        },
                        child: Icon(Icons.my_location,
                            color: theme.colorScheme.primary),
                      ),
                    ),
                  FloatingActionButton.extended(
                    heroTag: 'scan_area_btn',
                    onPressed: _triggerScan,
                    backgroundColor: theme.colorScheme.primary,
                    icon: const Icon(Icons.radar, color: Colors.white),
                    label: Text(
                      _isScanning ? 'SCANNING...' : 'SCAN AREA',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Drawer: Scanned Trucks with Google Maps Directions & Full Profile buttons
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomScannedDrawer(nearbyTrucks, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveMap(List<FoodTruck> nearbyTrucks, ThemeData theme) {
    final userCenter = LatLng(
      widget.currentLocation.latitude,
      widget.currentLocation.longitude,
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: userCenter,
        initialZoom: 14.3,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.roambite.roambite',
        ),
        CircleLayer(
          circles: [
            // Scan Radius Circle (meters)
            CircleMarker(
              point: userCenter,
              radius: _scanRadiusMiles * 1609.34,
              useRadiusInMeter: true,
              color: const Color(0xFFFF5722).withValues(alpha: 0.10),
              borderColor: const Color(0xFFFF5722),
              borderStrokeWidth: 2,
            ),
            // Alert Radius Geofence Circle (if enabled)
            if (_alertEnabled)
              CircleMarker(
                point: userCenter,
                radius: _alertRadiusMiles * 1609.34,
                useRadiusInMeter: true,
                color: const Color(0xFF00C853).withValues(alpha: 0.08),
                borderColor: const Color(0xFF00C853),
                borderStrokeWidth: 2,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            // User Live Position Pin
            Marker(
              point: userCenter,
              width: 44,
              height: 44,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A73E8),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6),
                  ],
                ),
                child: const Icon(Icons.person_pin_circle,
                    color: Colors.white, size: 22),
              ),
            ),
            // Food Truck Profile Avatar Pins
            ...nearbyTrucks.map((truck) {
              return Marker(
                point: LatLng(truck.latitude, truck.longitude),
                width: 96,
                height: 86,
                child: GestureDetector(
                  onTap: () => _openTruckProfile(truck),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: truck.status == TruckStatus.servingNow
                                ? const Color(0xFF00C853)
                                : const Color(0xFFFF5722),
                            width: 3,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 6),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            truck.effectiveProfileImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_shipping,
                              color: Color(0xFFFF5722),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          truck.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationAndModeHeader(
      ThemeData theme, List<FoodTruck> alertTrucks) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: InkWell(
              onTap: widget.onOpenLocationPicker,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.currentLocation.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                  Text(
                    'Scan: $_scanRadiusMiles mi • Alert: ${_alertEnabled ? "${_alertRadiusMiles}mi ON" : "OFF"}',
                    style: TextStyle(color: theme.hintColor, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          // Map vs Radar Pulse Toggle
          SegmentedButton<bool>(
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            segments: const [
              ButtonSegment<bool>(
                value: true,
                icon: Icon(Icons.map_outlined, size: 15),
                label: Text('Map', style: TextStyle(fontSize: 11)),
              ),
              ButtonSegment<bool>(
                value: false,
                icon: Icon(Icons.radar, size: 15),
                label: Text('Radar', style: TextStyle(fontSize: 11)),
              ),
            ],
            selected: {_showGoogleMapView},
            onSelectionChanged: (s) =>
                setState(() => _showGoogleMapView = s.first),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusAndAlertBar(ThemeData theme, List<FoodTruck> alertTrucks) {
    final radii = [0.5, 1.0, 2.5, 5.0];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Alert Radius Geofence Button
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              backgroundColor: _alertEnabled
                  ? const Color(0xFF00C853).withValues(alpha: 0.15)
                  : theme.colorScheme.surface,
              side: BorderSide(
                color: _alertEnabled
                    ? const Color(0xFF00C853)
                    : theme.dividerColor,
              ),
              avatar: Icon(
                _alertEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off_outlined,
                size: 16,
                color: _alertEnabled
                    ? const Color(0xFF00C853)
                    : theme.hintColor,
              ),
              label: Text(
                _alertEnabled
                    ? 'Alert: $_alertRadiusMiles mi (${alertTrucks.length})'
                    : 'Set Alert Radius',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: _alertEnabled ? const Color(0xFF008E3B) : null,
                ),
              ),
              onPressed: () => _openAlertRadiusSheet(alertTrucks),
            ),
          ),
          // Scan Radius Chips
          ...radii.map((r) {
            final isSelected = _scanRadiusMiles == r;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('$r mi scan'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _scanRadiusMiles = r);
                    _loadTrucks();
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildRadarTruckPins(List<FoodTruck> trucks, ThemeData theme) {
    final center = MediaQuery.of(context).size.width / 2;
    final maxRadius = center * 0.74;

    return trucks.asMap().entries.map((entry) {
      final index = entry.key;
      final truck = entry.value;

      final angle =
          (index * (2 * math.pi / (trucks.isEmpty ? 1 : trucks.length))) + 0.35;
      final distanceRatio =
          (truck.distanceInMiles / _scanRadiusMiles).clamp(0.22, 0.85);
      final r = maxRadius * distanceRatio;

      final dx = center + (r * math.cos(angle)) - 34;
      final dy =
          (MediaQuery.of(context).size.height * 0.42) + (r * math.sin(angle)) - 34;

      return Positioned(
        left: dx,
        top: dy,
        child: GestureDetector(
          onTap: () => _openTruckProfile(truck),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: truck.isSponsored
                      ? Colors.amber
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: truck.isSponsored
                        ? Colors.amberAccent
                        : theme.colorScheme.primary,
                  ),
                ),
                child: Text(
                  '${truck.distanceInMiles} mi',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: truck.isSponsored
                        ? Colors.black
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: truck.status == TruckStatus.servingNow
                        ? const Color(0xFF00C853)
                        : const Color(0xFFFF9100),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (truck.status == TruckStatus.servingNow
                              ? const Color(0xFF00C853)
                              : const Color(0xFFFF9100))
                          .withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    truck.effectiveProfileImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.local_shipping,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  truck.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomScannedDrawer(List<FoodTruck> trucks, ThemeData theme) {
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.radar,
                        color: theme.colorScheme.primary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Trucks in $_scanRadiusMiles mi (${trucks.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _openAlertRadiusSheet(trucks),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active,
                            color: Color(0xFF00C853), size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _alertEnabled
                              ? 'ALERT ${_alertRadiusMiles}MI ON'
                              : 'ALERTS OFF',
                          style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: trucks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No trucks detected within $_scanRadiusMiles miles.',
                          style:
                              TextStyle(color: theme.hintColor, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _scanRadiusMiles = 5.0);
                            _loadTrucks();
                          },
                          child: const Text('Expand scan radius to 5.0 mi'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trucks.length,
                    itemBuilder: (context, index) {
                      final truck = trucks[index];
                      return Container(
                        width: 285,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _openTruckProfile(truck),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      truck.effectiveProfileImage,
                                      width: 62,
                                      height: 62,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.fastfood, size: 32),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          truck.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${truck.menu.length} Dishes • ${truck.videoReviews.length} Video Reels',
                                          style: TextStyle(
                                              color: theme.hintColor,
                                              fontSize: 11),
                                          maxLines: 1,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 13),
                                            const SizedBox(width: 3),
                                            Text('${truck.rating}',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11)),
                                            const Spacer(),
                                            Text(
                                              '${truck.distanceInMiles} mi',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                    onPressed: () => openGoogleMapsDirections(
                                      context,
                                      truck: truck,
                                      userLat: widget.currentLocation.latitude,
                                      userLng: widget.currentLocation.longitude,
                                    ),
                                    icon: const Icon(Icons.directions,
                                        size: 14, color: Color(0xFF1A73E8)),
                                    label: const Text(
                                      'Google Maps',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                    ),
                                    onPressed: () => _openTruckProfile(truck),
                                    icon: const Icon(Icons.restaurant_menu,
                                        size: 14),
                                    label: const Text(
                                      'Full Profile',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
