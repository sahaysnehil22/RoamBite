import 'package:flutter/material.dart';
import '../models/food_truck.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
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
  List<FoodTruck> _trucks = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'All',
    '🌮 Tacos',
    '🍔 Burgers',
    '☕ Coffee & Sweet',
    '🫓 Latin',
    '⭐ Top Rated',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrucks();
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation.latitude != widget.currentLocation.latitude ||
        oldWidget.currentLocation.longitude != widget.currentLocation.longitude) {
      _loadTrucks();
    }
  }

  Future<void> _loadTrucks() async {
    setState(() => _isLoading = true);
    final results = await SupabaseService().fetchLiveTrucks(
      userLat: widget.currentLocation.latitude,
      userLng: widget.currentLocation.longitude,
    );
    if (mounted) {
      setState(() {
        _trucks = results;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchController.text.toLowerCase();

    final filteredTrucks = _trucks.where((truck) {
      if (_onlyOpenNow && truck.status != TruckStatus.servingNow) return false;
      if (_selectedCategory == '🌮 Tacos' && !truck.cuisine.toLowerCase().contains('taco')) return false;
      if (_selectedCategory == '🍔 Burgers' && !truck.cuisine.toLowerCase().contains('burger')) return false;
      if (_selectedCategory == '☕ Coffee & Sweet' && !truck.cuisine.toLowerCase().contains('coffee')) return false;
      if (_selectedCategory == '🫓 Latin' && !truck.cuisine.toLowerCase().contains('latin') && !truck.cuisine.toLowerCase().contains('arepa')) return false;
      if (_selectedCategory == '⭐ Top Rated' && truck.rating < 4.8) return false;

      if (query.isNotEmpty) {
        final matchesName = truck.name.toLowerCase().contains(query);
        final matchesCuisine = truck.cuisine.toLowerCase().contains(query);
        final matchesMenu = truck.menu.any((m) => m.name.toLowerCase().contains(query));
        return matchesName || matchesCuisine || matchesMenu;
      }
      return true;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: widget.onOpenLocationPicker,
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      widget.currentLocation.label,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, size: 16),
                                  ],
                                ),
                                Text(
                                  widget.currentLocation.formattedAddress,
                                  style: TextStyle(color: theme.hintColor, fontSize: 11),
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
                    icon: const Icon(Icons.my_location, size: 20),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search cuisine, dishes, trucks...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.dividerColor)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Count & Filter Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${widget.currentLocation.city}, ${widget.currentLocation.state} (${filteredTrucks.length} Trucks)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const Spacer(),
                  FilterChip(
                    label: const Text('Live Now'),
                    selected: _onlyOpenNow,
                    onSelected: (v) => setState(() => _onlyOpenNow = v),
                    selectedColor: const Color(0xFF00C853).withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Truck Cards List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTrucks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: Colors.grey),
                              const SizedBox(height: 10),
                              const Text('No food trucks found matching filter', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Try clearing filters or switching location', style: TextStyle(color: theme.hintColor, fontSize: 12)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadTrucks,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: filteredTrucks.length,
                            itemBuilder: (context, index) {
                              final truck = filteredTrucks[index];
                              return _buildTruckCard(truck, theme);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTruckCard(FoodTruck truck, ThemeData theme) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Image.network(
                  truck.heroImageUrl,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(height: 170, color: Colors.grey[300]),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: truck.status == TruckStatus.servingNow
                          ? const Color(0xFF00C853)
                          : const Color(0xFFFF9100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      truck.status == TruckStatus.servingNow ? '🟢 SERVING NOW' : '🚚 ON THE MOVE',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${truck.rating}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${truck.cuisine} • ${truck.priceRange} • ${truck.city}',
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                  if (truck.menu.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.restaurant, color: theme.colorScheme.primary, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Featured: ${truck.menu.first.name} (\$${truck.menu.first.price.toStringAsFixed(2)})',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
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
}
