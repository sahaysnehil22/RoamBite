import 'profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/food_truck.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import 'truck_detail_screen.dart';

// Slice 2: Zomato-style foodie dashboard.
// The data flow is unchanged: trucks come from SupabaseService.fetchLiveTrucks.
// Promotions reuse the trucks' existing isSponsored flag; when no truck is
// sponsored, a single generic RoamBite card is shown instead of invented offers.
// "Near me" means within 2 miles and "Top rated" means a rating of 4.5 or more.
class HomeDashboardScreen extends StatefulWidget {
  final UserLocation currentLocation;
  final VoidCallback onOpenLocationPicker;
  final VoidCallback onSwitchToRadar;

  const HomeDashboardScreen({
    super.key,
    required this.currentLocation,
    required this.onOpenLocationPicker,
    required this.onSwitchToRadar,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PageController _promoController = PageController();
  List<FoodTruck> _trucks = [];
  bool _isLoading = true;
  String _selectedCuisine = 'All';
  bool _openNowOnly = false;
  bool _nearMeOnly = false;
  bool _topRatedOnly = false;
  int _promoIndex = 0;

  static const double _nearMeMiles = 2.0;
  static const double _topRatedThreshold = 4.5;

  @override
  void initState() {
    super.initState();
    _loadTrucks();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation.latitude != widget.currentLocation.latitude ||
        oldWidget.currentLocation.longitude != widget.currentLocation.longitude) {
      _loadTrucks();
    }
  }

  Future<void> _loadTrucks() async {
    if (!mounted) return;
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
    _promoController.dispose();
    super.dispose();
  }

  bool _isOpen(FoodTruck truck) => truck.status != TruckStatus.closed;

  String _statusLabel(FoodTruck truck) {
    switch (truck.status) {
      case TruckStatus.servingNow:
        return 'LIVE';
      case TruckStatus.onTheMove:
        return 'ON THE MOVE';
      case TruckStatus.closed:
        return 'CLOSED';
    }
  }

  Color _statusColor(FoodTruck truck) {
    switch (truck.status) {
      case TruckStatus.servingNow:
        return const Color(0xFF00C853);
      case TruckStatus.onTheMove:
        return const Color(0xFFFF6D00);
      case TruckStatus.closed:
        return Colors.grey;
    }
  }

  void _openTruckDetail(FoodTruck truck) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchController.text.toLowerCase();

    final filtered = _trucks.where((t) {
      if (_selectedCuisine != 'All' && !t.cuisine.toLowerCase().contains(_selectedCuisine.toLowerCase())) {
        return false;
      }
      if (_openNowOnly && !_isOpen(t)) {
        return false;
      }
      if (_nearMeOnly && t.distanceInMiles > _nearMeMiles) {
        return false;
      }
      if (_topRatedOnly && t.rating < _topRatedThreshold) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = t.name.toLowerCase().contains(query);
        final matchesCuisine = t.cuisine.toLowerCase().contains(query);
        final matchesDish = t.menu.any((m) => m.name.toLowerCase().contains(query));
        return matchesName || matchesCuisine || matchesDish;
      }
      return true;
    }).toList();

    final liveTrucks = filtered.where((t) => t.status == TruckStatus.servingNow).toList();
    final recommended = [...filtered]..sort((a, b) => b.rating.compareTo(a.rating));
    final sponsored = _trucks.where((t) => t.isSponsored).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTrucks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Top location bar: current location name with a Change affordance.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/images/roambite_logo_white.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.local_shipping, size: 28),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: widget.onOpenLocationPicker,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 14, color: theme.colorScheme.primary),
                                  const SizedBox(width: 2),
                                  Flexible(
                                    child: Text(
                                      widget.currentLocation.label,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                      ),
                      TextButton(
                        onPressed: widget.onOpenLocationPicker,
                        child: const Text('Change'),
                      ),
                      IconButton(
                        onPressed: widget.onOpenLocationPicker,
                        icon: const Icon(Icons.my_location, size: 20),
                        tooltip: 'Use GPS Location',
                      ),
                      IconButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())), icon: const Icon(Icons.account_circle, size: 28), tooltip: 'Profile', color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),

              // Search bar: filters the shown truck list by name (and cuisine/dish).
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search tacos, burgers, coffee...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: theme.dividerColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Sponsored promo banner carousel at the top.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _buildPromoCarousel(theme, sponsored),
                ),
              ),

              // Radar Banner Callout
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: widget.onSwitchToRadar,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            const Color(0xFFFF8A65),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.radar, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Proximity Radar Scan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Discover trucks pulsing live around you right now',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Cuisine Filter Pills
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['All', 'Tacos', 'Burgers', 'Coffee', 'Arepas', 'BBQ'].map((cat) {
                      final isSelected = _selectedCuisine == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedCuisine = cat);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Working filter chips: these actually filter the truck list above.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Open now'),
                          selected: _openNowOnly,
                          onSelected: (selected) => setState(() => _openNowOnly = selected),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Near me'),
                          selected: _nearMeOnly,
                          onSelected: (selected) => setState(() => _nearMeOnly = selected),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Top rated'),
                          selected: _topRatedOnly,
                          onSelected: (selected) => setState(() => _topRatedOnly = selected),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Live & Serving Right Now Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C853),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'SERVING RIGHT NOW',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                      ),
                      const Spacer(),
                      Text(
                        '${liveTrucks.length} Active',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              // Horizontal Live Trucks Carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : liveTrucks.isEmpty
                          ? _buildEmptySection('No food trucks currently live in this radius.')
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: liveTrucks.length,
                              itemBuilder: (context, index) {
                                final truck = liveTrucks[index];
                                return _buildLiveTruckCard(truck, theme);
                              },
                            ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // Recommended Truck Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'RECOMMENDED FOR YOU',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.6),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              // Recommended List
              if (_isLoading)
                const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
              else if (recommended.isEmpty)
                SliverToBoxAdapter(child: _buildEmptySection('No trucks found matching query.'))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final truck = recommended[index];
                        return _buildRecommendedCard(truck, theme);
                      },
                      childCount: recommended.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCarousel(ThemeData theme, List<FoodTruck> sponsored) {
    if (_isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (sponsored.isEmpty) {
      return _buildGenericPromoCard(theme);
    }
    final promoIndex = sponsored.isEmpty ? 0 : _promoIndex % sponsored.length;
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _promoController,
            onPageChanged: (index) => setState(() => _promoIndex = index),
            itemCount: sponsored.length,
            itemBuilder: (context, index) {
              final truck = sponsored[index];
              return _buildSponsoredPromoCard(truck, theme);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(sponsored.length, (index) {
            final isActive = index == promoIndex;
            return Container(
              width: isActive ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isActive ? theme.colorScheme.primary : theme.dividerColor,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildSponsoredPromoCard(FoodTruck truck, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openTruckDetail(truck),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: theme.colorScheme.primary,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                truck.heroImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: theme.colorScheme.primary,
                  child: const Icon(Icons.local_shipping, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'SPONSORED',
                      style: TextStyle(color: theme.colorScheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    truck.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${truck.cuisine} \u2022 ${truck.distanceInMiles} mi away',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericPromoCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      height: 160,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            const Color(0xFFFF8A65),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fresh trucks near you',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 4),
                Text(
                  'Find live food trucks, menus and opening times in one place.',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTruckCard(FoodTruck truck, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openTruckDetail(truck),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
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
                  height: 110,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 110,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_shipping),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${truck.distanceInMiles} mi',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    truck.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${truck.rating}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          truck.cuisine,
                          style: TextStyle(color: theme.hintColor, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
  }

  Widget _buildRecommendedCard(FoodTruck truck, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openTruckDetail(truck),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  truck.heroImageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_shipping),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            truck.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8E3E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '${truck.rating}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${truck.cuisine} \u2022 ${truck.distanceInMiles} mi away \u2022 ${truck.priceRange}',
                      style: TextStyle(color: theme.hintColor, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (truck.tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        truck.tagline,
                        style: TextStyle(color: theme.hintColor, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildStatusBadge(truck),
                        _buildTagChip(truck.cuisine),
                        _buildTagChip(truck.priceRange),
                        if (truck.isSponsored) _buildTagChip('Sponsored'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(FoodTruck truck) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _statusColor(truck),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _statusLabel(truck),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(label, style: const TextStyle(fontSize: 10)),
    );
  }

  Widget _buildEmptySection(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}
