import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/mock_food_trucks.dart';
import '../models/food_truck.dart';
import '../services/location_service.dart';
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
  double _scanRadiusMiles = 1.0;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerScan() {
    setState(() => _isScanning = true);
    _pulseController.reset();
    _pulseController.repeat();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter trucks within selected radius
    final nearbyTrucks = kMockFoodTrucks.where((truck) {
      return truck.distanceInMiles <= _scanRadiusMiles;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      body: SafeArea(
        child: Stack(
          children: [
            // Radar Proximity Canvas
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.width),
                    painter: RadarPulsePainter(
                      animationValue: _pulseController.value,
                      primaryColor: const Color(0xFFFF6B00),
                      accentColor: const Color(0xFFFFB800),
                    ),
                  );
                },
              ),
            ),

            // Pinned Food Trucks on the Radar (Pokémon GO map markers)
            ..._buildTruckPins(nearbyTrucks),

            // Top Header & Zomato/Blinkit Location Bar
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  _buildLocationHeader(),
                  const SizedBox(height: 12),
                  _buildRadiusSelector(),
                ],
              ),
            ),

            // Scan Trigger Button (Pokémon GO Radar Scanner)
            Positioned(
              right: 20,
              bottom: 240,
              child: FloatingActionButton.extended(
                onPressed: _triggerScan,
                backgroundColor: const Color(0xFFFF6B00),
                elevation: 6,
                icon: const Icon(Icons.radar, color: Colors.white),
                label: Text(
                  _isScanning ? 'SCANNING...' : 'SCAN AREA',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

            // Bottom Drawer: "Nearby Trucks Scanned"
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomScannedDrawer(nearbyTrucks),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161A24).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Color(0xFFFF6B00), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: widget.onOpenLocationPicker,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.currentLocation.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF6B00), size: 18),
                    ],
                  ),
                  Text(
                    widget.currentLocation.formattedAddress,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onOpenLocationPicker,
            icon: const Icon(Icons.my_location, color: Colors.white70, size: 20),
            tooltip: 'Detect GPS',
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector() {
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
                if (selected) setState(() => _scanRadiusMiles = r);
              },
              backgroundColor: const Color(0xFF161A24),
              selectedColor: const Color(0xFFFF6B00),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? const Color(0xFFFF6B00) : Colors.white12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<Widget> _buildTruckPins(List<FoodTruck> trucks) {
    final center = MediaQuery.of(context).size.width / 2;
    final maxRadius = center * 0.78;

    return trucks.asMap().entries.map((entry) {
      final index = entry.key;
      final truck = entry.value;

      // Calculate pseudo-polar position relative to user center
      final angle = (index * (2 * math.pi / (trucks.isEmpty ? 1 : trucks.length))) + 0.35;
      final distanceRatio = (truck.distanceInMiles / _scanRadiusMiles).clamp(0.2, 0.9);
      final r = maxRadius * distanceRatio;

      final dx = center + (r * math.cos(angle)) - 28;
      final dy = (MediaQuery.of(context).size.height * 0.42) + (r * math.sin(angle)) - 28;

      return Positioned(
        left: dx,
        top: dy,
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: truck.isSponsored ? const Color(0xFFFFB800) : const Color(0xFF1E2330),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: truck.isSponsored ? Colors.amberAccent : const Color(0xFFFF6B00),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (truck.isSponsored) ...[
                      const Icon(Icons.flash_on, color: Colors.black, size: 10),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      '${truck.distanceInMiles} mi',
                      style: TextStyle(
                        color: truck.isSponsored ? Colors.black : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              // Pin Icon with Pulsing Border
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF14171F),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: truck.status == TruckStatus.servingNow
                        ? const Color(0xFF00E676)
                        : const Color(0xFFFF9100),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (truck.status == TruckStatus.servingNow
                              ? const Color(0xFF00E676)
                              : const Color(0xFFFF9100))
                          .withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _getCuisineEmoji(truck.cuisine),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Truck name
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  truck.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildBottomScannedDrawer(List<FoodTruck> trucks) {
    return Container(
      height: 220,
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF121620),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.radar, color: Color(0xFFFF6B00), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Nearby Trucks Scanned (${trucks.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIVE NOW',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: trucks.length,
              itemBuilder: (context, index) {
                final truck = trucks[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
                    );
                  },
                  child: Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F2C),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            truck.heroImageUrl,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 76,
                              height: 76,
                              color: Colors.white12,
                              child: const Icon(Icons.fastfood, color: Colors.white54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                truck.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                truck.cuisine,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${truck.rating}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${truck.distanceInMiles} mi',
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B00),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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

  String _getCuisineEmoji(String cuisine) {
    if (cuisine.contains('Taco') || cuisine.contains('Mexican')) return '🌮';
    if (cuisine.contains('Burger')) return '🍔';
    if (cuisine.contains('Coffee') || cuisine.contains('Cafe')) return '☕';
    if (cuisine.contains('Latin') || cuisine.contains('Arepa')) return '🫓';
    return '🚚';
  }
}
