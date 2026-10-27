import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/food_truck.dart';
import '../services/demo_trucks.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
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
  double _scanRadiusMiles = 2.5;
  bool _isScanning = false;
  List<FoodTruck> _trucks = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _loadTrucks();
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
  }

  Future<void> _openTruckProfile(FoodTruck truck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
    );
    if (mounted) {
      _loadTrucks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nearbyTrucks =
        _trucks.where((t) => t.distanceInMiles <= _scanRadiusMiles).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Radar Canvas
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

            // Food Truck Profile Avatar Pins on Radar
            ..._buildTruckPins(nearbyTrucks, theme),

            // Top Header: Location Bar & Radius Selector
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _buildLocationHeader(theme),
                  const SizedBox(height: 10),
                  _buildRadiusSelector(theme),
                ],
              ),
            ),

            // Scan Trigger Button
            Positioned(
              right: 16,
              bottom: 230,
              child: FloatingActionButton.extended(
                onPressed: _triggerScan,
                backgroundColor: theme.colorScheme.primary,
                icon: const Icon(Icons.radar, color: Colors.white),
                label: Text(
                  _isScanning ? 'SCANNING...' : 'SCAN AREA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white),
                ),
              ),
            ),

            // Bottom Drawer: Scanned Trucks
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

  Widget _buildLocationHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: widget.onOpenLocationPicker,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.currentLocation.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const Icon(Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                  Text(
                    'Tap any truck profile on radar for full menu & video reviews',
                    style: TextStyle(color: theme.hintColor, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onOpenLocationPicker,
            icon: const Icon(Icons.my_location, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector(ThemeData theme) {
    final radii = [0.5, 1.0, 2.5, 5.0];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: radii.map((r) {
          final isSelected = _scanRadiusMiles == r;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$r mi radius'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _scanRadiusMiles = r);
                  _loadTrucks();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTruckPins(List<FoodTruck> trucks, ThemeData theme) {
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
      height: 210,
      padding: const EdgeInsets.only(top: 14, bottom: 8),
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
                      'Nearby Truck Profiles (${trucks.length})',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C853).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Color(0xFF00C853), size: 8),
                      SizedBox(width: 4),
                      Text(
                        'LIVE NOW',
                        style: TextStyle(
                          color: Color(0xFF00C853),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: trucks.isEmpty
                ? Center(
                    child: Text(
                      'No trucks detected in this range.',
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: trucks.length,
                    itemBuilder: (context, index) {
                      final truck = trucks[index];
                      return GestureDetector(
                        onTap: () => _openTruckProfile(truck),
                        child: Container(
                          width: 256,
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  truck.effectiveProfileImage,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.fastfood, size: 36),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                                      '${truck.menu.length} Dishes • ${truck.videoReviews.length} Reviews',
                                      style: TextStyle(
                                          color: theme.hintColor, fontSize: 11),
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
                                            color: theme.colorScheme.primary,
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
