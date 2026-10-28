import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_truck.dart';
import '../providers/auth_provider.dart';
import '../services/demo_trucks.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import '../widgets/google_maps_directions_sheet.dart';
import '../widgets/service_area_gate.dart';
import 'profile_screen.dart';
import 'truck_detail_screen.dart';

// Zomato-style foodie dashboard with full-bleed animated upper promotion section,
// Near & Fast filter & truck card badges, circular dish categories, and Miami Demo Hub banner.
class HomeDashboardScreen extends StatefulWidget {
  final UserLocation currentLocation;
  final VoidCallback onOpenLocationPicker;
  final VoidCallback onSwitchToRadar;
  final VoidCallback? onBrowseMiamiDemo;

  const HomeDashboardScreen({
    super.key,
    required this.currentLocation,
    required this.onOpenLocationPicker,
    required this.onSwitchToRadar,
    this.onBrowseMiamiDemo,
  });

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final PageController _promoController = PageController();
  late AnimationController _soothingAnimController;
  Timer? _autoSlideTimer;

  List<FoodTruck> _trucks = [];
  bool _isLoading = true;
  bool _isDemoFallback = false;
  String _selectedCuisine = 'All';
  bool _nearAndFastOnly = false;
  bool _openNowOnly = false;
  bool _nearMeOnly = false;
  bool _topRatedOnly = false;
  bool _vegOnly = false;
  bool _under12Only = false;
  String _sortBy = 'rating'; // 'rating', 'distance', 'price'
  int _promoIndex = 0;

  static const double _nearMeMiles = 2.0;
  static const double _topRatedThreshold = 4.5;

  @override
  void initState() {
    super.initState();
    _soothingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat(reverse: true);

    _autoSlideTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
      if (!mounted || !_promoController.hasClients) return;
      final total = DemoTrucks.heroPromotions.length;
      if (total <= 1) return;
      final next = (_promoIndex + 1) % total;
      _promoController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });

    _loadTrucks();
  }

  @override
  void didUpdateWidget(covariant HomeDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLocation.latitude != widget.currentLocation.latitude ||
        oldWidget.currentLocation.longitude !=
            widget.currentLocation.longitude) {
      _loadTrucks();
    }
  }

  Future<void> _loadTrucks() async {
    if (!mounted) return;
    // US-only service-area gate FIRST, radius filter only AFTER gate passes
    if (!LocationService.isInServiceArea(widget.currentLocation)) {
      if (mounted) {
        setState(() {
          _trucks = [];
          _isLoading = false;
          _isDemoFallback = false;
        });
      }
      return;
    }
    if (!SupabaseConfig.isConfigured) {
      if (mounted) {
        setState(() {
          _trucks = DemoTrucks.forLocation(
            userLat: widget.currentLocation.latitude,
            userLng: widget.currentLocation.longitude,
          );
          _isLoading = false;
          _isDemoFallback = true;
        });
      }
      return;
    }
    setState(() => _isLoading = true);
    final results = await SupabaseService().fetchLiveTrucks(
      userLat: widget.currentLocation.latitude,
      userLng: widget.currentLocation.longitude,
    );
    if (mounted) {
      setState(() {
        _trucks = results.isEmpty
            ? DemoTrucks.forLocation(
                userLat: widget.currentLocation.latitude,
                userLng: widget.currentLocation.longitude,
              )
            : results
                .where(
                    (t) => t.distanceInMiles <= LocationService.kServiceRadiusMiles)
                .toList();
        _isDemoFallback = results.isEmpty;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _soothingAnimController.dispose();
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

  Future<void> _openTruckDetail(FoodTruck truck) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TruckDetailScreen(truck: truck)),
    );
    if (mounted) {
      _loadTrucks();
    }
  }

  void _openPromoTruck(PromoBanner promo) {
    final match = _trucks.where((t) => t.id == promo.truckId).toList();
    if (match.isNotEmpty) {
      _openTruckDetail(match.first);
    } else if (_trucks.isNotEmpty) {
      _openTruckDetail(_trucks.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!LocationService.isInServiceArea(widget.currentLocation)) {
      return Scaffold(
        body: SafeArea(
          child: ServiceAreaGate(
            location: widget.currentLocation,
            onBrowseMiamiDemo: widget.onBrowseMiamiDemo ?? () {},
            onChangeLocation: widget.onOpenLocationPicker,
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final query = _searchController.text.toLowerCase();

    final filtered = _trucks.where((t) {
      if (_selectedCuisine != 'All' &&
          !t.cuisine.toLowerCase().contains(_selectedCuisine.toLowerCase())) {
        return false;
      }
      if (_nearAndFastOnly && !t.isNearAndFast) {
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
      if ((_vegOnly || auth.vegMode) && !t.menu.any((m) => m.isVegetarian)) {
        return false;
      }
      if (_under12Only && !t.menu.any((m) => m.price <= 12.0)) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = t.name.toLowerCase().contains(query);
        final matchesCuisine = t.cuisine.toLowerCase().contains(query);
        final matchesDish =
            t.menu.any((m) => m.name.toLowerCase().contains(query));
        return matchesName || matchesCuisine || matchesDish;
      }
      return true;
    }).toList();

    final liveTrucks =
        filtered.where((t) => t.status == TruckStatus.servingNow).toList();
    final recommended = [...filtered]..sort((a, b) {
        if (_sortBy == 'distance') {
          return a.distanceInMiles.compareTo(b.distanceInMiles);
        }
        if (_sortBy == 'price') {
          return a.priceRange.length.compareTo(b.priceRange.length);
        }
        return b.rating.compareTo(a.rating);
      });

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadTrucks,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Zomato-Style Full-Bleed Animated Upper Section
              SliverToBoxAdapter(
                child: _buildZomatoUpperHeroSection(theme, auth, query),
              ),

              // 2. Miami Demo Hub Banner (always shown when demo hub is active)
              if (_isDemoFallback)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'MIAMI DEMO HUB • Showing 4 seed food trucks in Wynwood, Miami.',
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
                ),

              // 3. Circular Plated Category Strip (Zomato Style)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 6),
                  child: _buildCircularCategoryStrip(theme),
                ),
              ),

              // 4. Filter Pills Row (Filters modal, Near & Fast, Pure Veg, Open now, Near me, Top rated, Under $12)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          avatar: const Icon(Icons.tune, size: 16),
                          label: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Filters',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_drop_down, size: 18),
                            ],
                          ),
                          onPressed: () => _openFiltersSheet(auth),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: const Icon(
                            Icons.bolt,
                            color: Color(0xFF00C853),
                            size: 18,
                          ),
                          label: const Text(
                            'Near & Fast',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          selected: _nearAndFastOnly,
                          selectedColor:
                              const Color(0xFF00C853).withValues(alpha: 0.16),
                          onSelected: (selected) =>
                              setState(() => _nearAndFastOnly = selected),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: const Icon(
                            Icons.eco,
                            color: Color(0xFF00C853),
                            size: 16,
                          ),
                          label: const Text(
                            'Pure Veg / Options',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          selected: _vegOnly || auth.vegMode,
                          selectedColor:
                              const Color(0xFF00C853).withValues(alpha: 0.16),
                          onSelected: (selected) {
                            setState(() => _vegOnly = selected);
                            auth.setVegMode(selected);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Meals Under \$12'),
                          selected: _under12Only,
                          onSelected: (selected) =>
                              setState(() => _under12Only = selected),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Open now'),
                          selected: _openNowOnly,
                          onSelected: (selected) =>
                              setState(() => _openNowOnly = selected),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Near me'),
                          selected: _nearMeOnly,
                          onSelected: (selected) =>
                              setState(() => _nearMeOnly = selected),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: const Text('Top rated 4.5+'),
                          selected: _topRatedOnly,
                          onSelected: (selected) =>
                              setState(() => _topRatedOnly = selected),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. Proximity Radar Callout Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: InkWell(
                    onTap: widget.onSwitchToRadar,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.radar,
                                color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Proximity Radar Scan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  'Tap truck profiles pulsing live around you right now',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios,
                              color: Colors.white70, size: 15),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // 6. Live & Serving Right Now Section
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
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6),
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
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 215,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : liveTrucks.isEmpty
                          ? _buildEmptySection(
                              'No food trucks currently live in this radius.')
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: liveTrucks.length,
                              itemBuilder: (context, index) {
                                final truck = liveTrucks[index];
                                return _buildLiveTruckCard(truck, theme);
                              },
                            ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 7. Recommended For You Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'RECOMMENDED FOR YOU',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              if (_isLoading)
                const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()))
              else if (recommended.isEmpty)
                SliverToBoxAdapter(
                    child:
                        _buildEmptySection('No trucks found matching query.'))
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

  /// Full-bleed Zomato-style upper section covering location bar, profile "S" button,
  /// search bar, VEG MODE switch, and auto-advancing animated promotions.
  Widget _buildZomatoUpperHeroSection(
      ThemeData theme, AuthProvider auth, String query) {
    final promos = DemoTrucks.heroPromotions;
    final currentPromo = promos[_promoIndex % promos.length];
    final primaryBg = Color(currentPromo.primaryColorHex);
    final secondaryBg = Color(currentPromo.secondaryColorHex);
    final userInitial = (auth.displayName ?? 'Snehil').trim().isNotEmpty
        ? (auth.displayName ?? 'Snehil').trim()[0].toUpperCase()
        : 'S';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBg, secondaryBg],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Stack(
        children: [
          // Soothing repeating starburst background animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _soothingAnimController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _HeroStarburstPainter(
                    progress: _soothingAnimController.value,
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                // Row 1: Location Header + GOLD Badge + Circular "S" Profile Button
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: widget.onOpenLocationPicker,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 18, color: Colors.white),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.currentLocation.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: Colors.white, size: 18),
                              ],
                            ),
                            Text(
                              widget.currentLocation.formattedAddress,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _openGoldPerksModal,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF3C4), Color(0xFFFFD54F)],
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          'GOLD',
                          style: TextStyle(
                            color: Color(0xFF5D4037),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFD2E3FC),
                        backgroundImage: (auth.avatarUrl != null &&
                                auth.avatarUrl!.isNotEmpty)
                            ? NetworkImage(auth.avatarUrl!)
                            : null,
                        child: (auth.avatarUrl == null ||
                                auth.avatarUrl!.isEmpty)
                            ? Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Color(0xFF174EA6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 2: White Search Bar + VEG MODE Toggle
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search "quesabirria" or "smash burger"',
                            hintStyle: const TextStyle(
                                color: Colors.black45, fontSize: 13),
                            prefixIcon: const Icon(Icons.search,
                                color: Color(0xFFE23744)),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.clear,
                                        color: Colors.black54, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _openVoiceSearchSheet,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic_none_rounded,
                          color: Color(0xFFE23744),
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'VEG\nMODE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 8.5,
                            height: 1.0,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          child: Switch(
                            value: _vegOnly || auth.vegMode,
                            activeThumbColor: const Color(0xFF00C853),
                            onChanged: (val) {
                              setState(() => _vegOnly = val);
                              auth.setVegMode(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Row 3: Auto-Advancing Animated Promotions Carousel
                SizedBox(
                  height: 162,
                  child: PageView.builder(
                    controller: _promoController,
                    onPageChanged: (idx) => setState(() => _promoIndex = idx),
                    itemCount: promos.length,
                    itemBuilder: (context, idx) {
                      final promo = promos[idx];
                      final accentColor = Color(promo.accentColorHex);
                      return GestureDetector(
                        onTap: () => _openPromoTruck(promo),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.28),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      promo.badgeText,
                                      style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 9.5,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    promo.headlineTop,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 21,
                                      fontStyle: FontStyle.italic,
                                      height: 1.05,
                                    ),
                                  ),
                                  Text(
                                    promo.headlineMain,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 23,
                                      fontStyle: FontStyle.italic,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    promo.subheadline,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF141416),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          promo.ctaText,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: AnimatedBuilder(
                                animation: _soothingAnimController,
                                builder: (context, child) {
                                  final dy = math.sin(
                                          _soothingAnimController.value *
                                              math.pi) *
                                      6.0;
                                  final scale = 0.96 +
                                      (0.06 * _soothingAnimController.value);
                                  return Transform.translate(
                                    offset: Offset(0, -dy),
                                    child: Transform.scale(
                                      scale: scale,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Center(
                                  child: Container(
                                    width: 118,
                                    height: 118,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: accentColor,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        promo.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.white24,
                                          child: const Icon(
                                            Icons.restaurant,
                                            color: Colors.white,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Dots Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(promos.length, (idx) {
                    final active = idx == (_promoIndex % promos.length);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : Colors.white38,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularCategoryStrip(ThemeData theme) {
    final categories = [
      (
        label: 'All',
        query: 'All',
        img:
            'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=300&q=80'
      ),
      (
        label: 'Tacos',
        query: 'Tacos',
        img:
            'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=300&q=80'
      ),
      (
        label: 'Burgers',
        query: 'Burgers',
        img:
            'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=300&q=80'
      ),
      (
        label: 'Coffee',
        query: 'Coffee',
        img:
            'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=300&q=80'
      ),
      (
        label: 'Arepas',
        query: 'Venezuelan',
        img:
            'https://images.unsplash.com/photo-1613514785940-daed07799d9b?auto=format&fit=crop&w=300&q=80'
      ),
    ];

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
        itemBuilder: (context, idx) {
          final item = categories[idx];
          final selected = _selectedCuisine == item.query;
          return GestureDetector(
            onTap: () => setState(() => _selectedCuisine = item.query),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      item.img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        child: Icon(Icons.restaurant,
                            color: theme.colorScheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 26,
                  height: 2.5,
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveTruckCard(FoodTruck truck, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openTruckDetail(truck),
      child: Container(
        width: 245,
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
                  height: 112,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 112,
                    color: Colors.grey[300],
                    child: const Icon(Icons.local_shipping),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8E3E),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.white, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          '${truck.rating}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${truck.distanceInMiles} mi',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
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
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  if (truck.isNearAndFast)
                    Row(
                      children: [
                        const Icon(Icons.bolt,
                            color: Color(0xFF00C853), size: 15),
                        const SizedBox(width: 2),
                        Text(
                          'Near & Fast • ${truck.prepTimeWalkMins}',
                          style: const TextStyle(
                            color: Color(0xFF00C853),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${truck.cuisine} • ${truck.prepTimeWalkMins}',
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
                  truck.effectiveProfileImage,
                  width: 82,
                  height: 82,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 82,
                    height: 82,
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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8E3E),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                '${truck.rating}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (truck.isNearAndFast)
                      Row(
                        children: [
                          const Icon(Icons.bolt,
                              color: Color(0xFF00C853), size: 15),
                          const SizedBox(width: 2),
                          Text(
                            'Near & Fast • ${truck.prepTimeWalkMins} • ${truck.distanceInMiles} mi',
                            style: const TextStyle(
                              color: Color(0xFF00C853),
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '${truck.cuisine} • ${truck.distanceInMiles} mi away • ${truck.priceRange}',
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
                        _buildTagChip('${truck.menu.length} Dishes'),
                        _buildTagChip('${truck.videoReviews.length} Video Reels'),
                        if (truck.isSponsored) _buildTagChip('Sponsored'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: const Color(0xFF1A73E8),
                            side: const BorderSide(color: Color(0xFF1A73E8)),
                          ),
                          onPressed: () => openGoogleMapsDirections(
                            context,
                            truck: truck,
                            userLat: widget.currentLocation.latitude,
                            userLng: widget.currentLocation.longitude,
                          ),
                          icon: const Icon(Icons.directions, size: 15),
                          label: const Text(
                            'Google Maps',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _openTruckDetail(truck),
                          icon: const Icon(Icons.restaurant_menu, size: 15),
                          label: const Text(
                            'Menu & Reels',
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  void _openFiltersSheet(AuthProvider auth) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters & Sort',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _nearAndFastOnly = false;
                            _openNowOnly = false;
                            _nearMeOnly = false;
                            _topRatedOnly = false;
                            _vegOnly = false;
                            _under12Only = false;
                            _selectedCuisine = 'All';
                            _sortBy = 'rating';
                          });
                          setState(() {});
                          auth.setVegMode(false);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sort Trucks By',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Rating: High to Low'),
                        selected: _sortBy == 'rating',
                        onSelected: (_) {
                          setModalState(() => _sortBy = 'rating');
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Nearest First'),
                        selected: _sortBy == 'distance',
                        onSelected: (_) {
                          setModalState(() => _sortBy = 'distance');
                          setState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Price: Low to High'),
                        selected: _sortBy == 'price',
                        onSelected: (_) {
                          setModalState(() => _sortBy = 'price');
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Near & Fast (Under 1.0 mi • 6-10 mins)'),
                    value: _nearAndFastOnly,
                    activeColor: const Color(0xFF00C853),
                    onChanged: (v) {
                      setModalState(() => _nearAndFastOnly = v ?? false);
                      setState(() {});
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Veg Mode (Vegetarian Dish Options)'),
                    value: _vegOnly || auth.vegMode,
                    activeColor: const Color(0xFF00C853),
                    onChanged: (v) {
                      final val = v ?? false;
                      setModalState(() => _vegOnly = val);
                      setState(() {});
                      auth.setVegMode(val);
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Meals Under \$12'),
                    value: _under12Only,
                    activeColor: const Color(0xFFFF5722),
                    onChanged: (v) {
                      setModalState(() => _under12Only = v ?? false);
                      setState(() {});
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Serving Right Now'),
                    value: _openNowOnly,
                    activeColor: const Color(0xFFFF5722),
                    onChanged: (v) {
                      setModalState(() => _openNowOnly = v ?? false);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Apply Filters',
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

  void _openVoiceSearchSheet() {
    final samples = [
      'Quesabirria',
      'Smash Burger',
      'Churros',
      'Arepa',
      'Elote',
      'Truffle Fries',
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFE23744).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Color(0xFFE23744), size: 32),
              ),
              const SizedBox(height: 12),
              const Text(
                'Voice & Instant Dish Search',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap any dish below or speak to filter live food trucks',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: samples.map((q) {
                  return ActionChip(
                    avatar: const Icon(Icons.search, size: 15),
                    label: Text(q),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _searchController.text = q;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _openGoldPerksModal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1714),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD54F),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium,
                        color: Colors.black, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'RoamBite GOLD VIP Perks',
                      style: TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                '• Priority Walk-Up Window Queue at Partner Food Trucks\n'
                '• Extra 15% OFF Combo Plates at Sponsored Wynwood Trucks\n'
                '• Instant VIP Radar Arrival Alerts Before General Public',
                style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('RoamBite GOLD VIP benefits active!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text(
                    'Active Gold Member • Apply Perks',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        style: const TextStyle(
            color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
        child: Text(message,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    );
  }
}

class _HeroStarburstPainter extends CustomPainter {
  final double progress;

  _HeroStarburstPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.72, size.height * 0.62);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    const rayCount = 10;
    final baseAngle = progress * math.pi * 0.25;
    final radius = size.width * 0.85;

    for (var i = 0; i < rayCount; i++) {
      final a1 = baseAngle + (i * 2 * math.pi / rayCount);
      final a2 = a1 + (math.pi / (rayCount * 1.8));
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + radius * math.cos(a1),
          center.dy + radius * math.sin(a1),
        )
        ..lineTo(
          center.dx + radius * math.cos(a2),
          center.dy + radius * math.sin(a2),
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HeroStarburstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
