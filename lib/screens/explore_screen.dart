import 'package:flutter/material.dart';
import '../data/mock_food_trucks.dart';
import '../models/food_truck.dart';
import '../services/location_service.dart';
import 'truck_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  final UserLocation currentLocation;
  final VoidCallback onOpenLocationPicker;

  const ExploreScreen({
    super.key,
    required this.currentLocation,
    required this.onOpenLocationPicker,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _selectedCategory = 'All';
  bool _onlyOpenNow = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    '🌮 Tacos',
    '🍔 Burgers',
    '☕ Coffee & Sweet',
    '🫓 Latin',
    '⭐ Top Rated',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.toLowerCase();

    final filteredTrucks = kMockFoodTrucks.where((truck) {
      if (_onlyOpenNow && truck.status != TruckStatus.servingNow) return false;
      if (_selectedCategory == '🌮 Tacos' && !truck.cuisine.contains('Taco')) return false;
      if (_selectedCategory == '🍔 Burgers' && !truck.cuisine.contains('Burger')) return false;
      if (_selectedCategory == '☕ Coffee & Sweet' && !truck.cuisine.contains('Coffee')) return false;
      if (_selectedCategory == '🫓 Latin' && !truck.cuisine.contains('Latin')) return false;
      if (_selectedCategory == '⭐ Top Rated' && truck.rating < 4.9) return false;

      if (query.isNotEmpty) {
        final matchesName = truck.name.toLowerCase().contains(query);
        final matchesCuisine = truck.cuisine.toLowerCase().contains(query);
        final matchesMenu = truck.menu.any((m) => m.name.toLowerCase().contains(query));
        return matchesName || matchesCuisine || matchesMenu;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      body: SafeArea(
        child: Column(
          children: [
            // Top Zomato/Blinkit Location Header
            _buildTopBar(),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search food trucks, dishes, or cuisines...',
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFFF6B00)),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF191E2B),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Category Chips
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      backgroundColor: const Color(0xFF191E2B),
                      selectedColor: const Color(0xFFFF6B00),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFFFF6B00) : Colors.white12,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Regional Filter Pills
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${widget.currentLocation.city}, ${widget.currentLocation.state} (${filteredTrucks.length} Trucks)',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  FilterChip(
                    label: const Text('Serving Now'),
                    selected: _onlyOpenNow,
                    onSelected: (val) => setState(() => _onlyOpenNow = val),
                    backgroundColor: const Color(0xFF191E2B),
                    selectedColor: const Color(0xFF00E676).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _onlyOpenNow ? const Color(0xFF00E676) : Colors.white60,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide(
                      color: _onlyOpenNow ? const Color(0xFF00E676) : Colors.white12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Truck Cards List (DoorDash / Zomato style)
            Expanded(
              child: filteredTrucks.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredTrucks.length,
                      itemBuilder: (context, index) {
                        final truck = filteredTrucks[index];
                        return _buildDoorDashCard(truck);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: widget.onOpenLocationPicker,
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.currentLocation.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF6B00), size: 18),
                          ],
                        ),
                        Text(
                          widget.currentLocation.formattedAddress,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
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
          IconButton(
            onPressed: widget.onOpenLocationPicker,
            icon: const Icon(Icons.my_location, color: Colors.white70),
            tooltip: 'Detect GPS',
          ),
        ],
      ),
    );
  }

  Widget _buildDoorDashCard(FoodTruck truck) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161A24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image with Badges
            Stack(
              children: [
                Image.network(
                  truck.heroImageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 180,
                    color: Colors.white12,
                    child: const Center(child: Icon(Icons.fastfood, size: 48, color: Colors.white24)),
                  ),
                ),
                // Gradient Shadow
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Live Status Badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: truck.status == TruckStatus.servingNow
                          ? const Color(0xFF00E676)
                          : const Color(0xFFFF9100),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          truck.status == TruckStatus.servingNow ? Icons.check_circle : Icons.navigation,
                          size: 13,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          truck.status == TruckStatus.servingNow ? 'SERVING NOW' : 'ON THE MOVE',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Verified Time badge
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📍 ${truck.lastConfirmed}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                // Distance badge
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${truck.distanceInMiles} mi away',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          truck.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFB800).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${truck.rating}',
                              style: const TextStyle(
                                color: Color(0xFFFFB800),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              ' (${truck.reviewCount})',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${truck.cuisine} • ${truck.priceRange} • Open until ${truck.closesAt}',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 10),

                  // Signature Dish Banner
                  if (truck.menu.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2332),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.thumb_up_alt_outlined, color: Color(0xFFFF6B00), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Best Dish: ${truck.menu.firstWhere((m) => m.isSignature, orElse: () => truck.menu.first).name} (\$${truck.menu.first.price.toStringAsFixed(2)})',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 56, color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            'No food trucks found matching filter',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try widening your radius or clearing search query',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
                _onlyOpenNow = false;
                _searchController.clear();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
            ),
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}
