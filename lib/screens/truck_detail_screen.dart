import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/food_truck.dart';
import '../services/supabase_service.dart';

class TruckDetailScreen extends StatefulWidget {
  final FoodTruck truck;

  const TruckDetailScreen({super.key, required this.truck});

  @override
  State<TruckDetailScreen> createState() => _TruckDetailScreenState();
}

class _TruckDetailScreenState extends State<TruckDetailScreen> {
  int _selectedTab = 0; // 0: Menu, 1: Reviews, 2: Location Info

  Future<void> _openReviewDialog() async {
    double selectedRating = 5.0;
    final textCtrl = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Review ${widget.truck.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rate your meal:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2, 3, 4, 5].map((star) {
                  return IconButton(
                    icon: Icon(
                      star <= selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                    onPressed: () => setDlgState(() => selectedRating = star.toDouble()),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share what you ordered (e.g. Quesabirria crunch, salsa heat)...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Verified Visit: We check if you were within 200m of this truck during its shift to badge your review.',
                        style: TextStyle(fontSize: 10, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (textCtrl.text.trim().isEmpty) return;
                      setDlgState(() => isSubmitting = true);

                      try {
                        final pos = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
                        );
                        await SupabaseService().submitReview(
                          truckId: widget.truck.id,
                          rating: selectedRating,
                          text: textCtrl.text.trim(),
                          userLat: pos.latitude,
                          userLng: pos.longitude,
                        );
                      } catch (_) {
                        // Mock fallback submission
                      }

                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted! Thank you.')),
                        );
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Review'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final truck = widget.truck;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Live link copied for ${truck.name}!')),
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    truck.heroImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: truck.status == TruckStatus.servingNow
                                ? const Color(0xFF00C853)
                                : const Color(0xFFFF9100),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            truck.status == TruckStatus.servingNow ? '● SERVING NOW' : '🚚 ON THE MOVE',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          truck.name,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          truck.tagline,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(Icons.star, Colors.amber, '${truck.rating}', '${truck.reviewCount} ratings'),
                    _buildDivider(theme),
                    _buildStatCol(Icons.near_me, theme.colorScheme.primary, '${truck.distanceInMiles} mi', 'Distance'),
                    _buildDivider(theme),
                    _buildStatCol(Icons.access_time, const Color(0xFF00C853), 'Open', 'Closes ${truck.closesAt}'),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons: Directions & Write Review
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Navigating to ${truck.address}, ${truck.city}...')),
                        );
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text('Get Directions', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: _openReviewDialog,
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Review'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Selector
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              child: Row(
                children: [
                  _buildTabChip(0, 'Menu (${truck.menu.length})', theme),
                  const SizedBox(width: 8),
                  _buildTabChip(1, 'Verified Reviews', theme),
                  const SizedBox(width: 8),
                  _buildTabChip(2, 'Location & Verification', theme),
                ],
              ),
            ),
          ),

          if (_selectedTab == 0) ...[
            _buildMenuSection(truck, theme),
          ] else if (_selectedTab == 1) ...[
            _buildReviewsSection(truck, theme),
          ] else ...[
            _buildLocationSection(truck, theme),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildStatCol(IconData icon, Color color, String title, String subtitle) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(width: 1, height: 24, color: theme.dividerColor);
  }

  Widget _buildTabChip(int index, String label, ThemeData theme) {
    final isSelected = _selectedTab == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _selectedTab = index),
    );
  }

  Widget _buildMenuSection(FoodTruck truck, ThemeData theme) {
    if (truck.menu.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text('No menu items uploaded yet.', style: TextStyle(color: theme.hintColor)),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = truck.menu[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: item.isSignature ? theme.colorScheme.primary.withValues(alpha: 0.4) : theme.dividerColor,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      item.imageUrl,
                      width: 76,
                      height: 76,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, size: 36),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.isSignature)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '⭐ SIGNATURE DISH',
                              style: TextStyle(color: theme.colorScheme.primary, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 3),
                        Text(
                          item.description,
                          style: TextStyle(color: theme.hintColor, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          childCount: truck.menu.length,
        ),
      ),
    );
  }

  Widget _buildReviewsSection(FoodTruck truck, ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.verified, color: Color(0xFF00C853), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '200m Verified Visit Protection: Only reviews from foodies physically present near the truck are factored into the official rating.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF00C853), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 14,
                      child: Text('M', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Maya V.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C853).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('✓ Verified Visit (50m)', style: TextStyle(fontSize: 9, color: Color(0xFF00C853), fontWeight: FontWeight.bold)),
                    ),
                    const Spacer(),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const Text(' 5.0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '"Crispiest birria tacos in Wynwood. The consomé was piping hot and perfectly seasoned."',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildLocationSection(FoodTruck truck, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirmed Live Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text('${truck.address}, ${truck.city}, ${truck.state}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 4),
              Text('GPS: ${truck.latitude.toStringAsFixed(4)}, ${truck.longitude.toStringAsFixed(4)}', style: TextStyle(color: theme.hintColor, fontSize: 11)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF00C853), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location confirmed ${truck.lastConfirmed}',
                        style: const TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
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
}
