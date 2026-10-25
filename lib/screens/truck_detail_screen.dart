import 'package:flutter/material.dart';
import '../models/food_truck.dart';

class TruckDetailScreen extends StatefulWidget {
  final FoodTruck truck;

  const TruckDetailScreen({super.key, required this.truck});

  @override
  State<TruckDetailScreen> createState() => _TruckDetailScreenState();
}

class _TruckDetailScreenState extends State<TruckDetailScreen> {
  int _selectedTab = 0; // 0: Menu, 1: Video Reviews, 2: About

  @override
  Widget build(BuildContext context) {
    final truck = widget.truck;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: const Color(0xFF141722),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Sharing live pin for ${truck.name}...')),
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
                    errorBuilder: (_, __, ___) => Container(color: Colors.white10),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          const Color(0xFF0D1017),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: truck.status == TruckStatus.servingNow
                                ? const Color(0xFF00E676)
                                : const Color(0xFFFF9100),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            truck.status == TruckStatus.servingNow ? '🟢 SERVING NOW' : '🚚 ON THE MOVE',
                            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          truck.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          truck.tagline,
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Stats Bar (DoorDash/Zomato pattern)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF161A24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(Icons.star, const Color(0xFFFFB800), '${truck.rating}', '${truck.reviewCount} reviews'),
                    _buildDivider(),
                    _buildStatItem(Icons.near_me, const Color(0xFFFF6B00), '${truck.distanceInMiles} mi', '3 min drive'),
                    _buildDivider(),
                    _buildStatItem(Icons.access_time, const Color(0xFF00E676), 'Open', 'Until ${truck.closesAt}'),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons: Get Directions & Share
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening navigation to ${truck.address}, ${truck.city}...')),
                        );
                      },
                      icon: const Icon(Icons.directions, color: Colors.white),
                      label: const Text('Get Directions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to your favorite trucks!')),
                      );
                    },
                    icon: const Icon(Icons.favorite_border, color: Colors.white),
                    label: const Text('Save', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Selector: Menu | Video Reviews | Live Location
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
              child: Row(
                children: [
                  _buildTabChip(0, '📋 Full Menu'),
                  const SizedBox(width: 8),
                  _buildTabChip(1, '🎥 Video Reviews (${truck.videoReviews.length})'),
                  const SizedBox(width: 8),
                  _buildTabChip(2, '📍 Location Info'),
                ],
              ),
            ),
          ),

          // Content Based on Tab
          if (_selectedTab == 0) ...[
            _buildMenuSection(truck),
          ] else if (_selectedTab == 1) ...[
            _buildVideoReviewsSection(truck),
          ] else ...[
            _buildLocationInfoSection(truck),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color color, String title, String subtitle) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 28, color: Colors.white12);
  }

  Widget _buildTabChip(int index, String label) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF6B00) : const Color(0xFF161A24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B00) : Colors.white12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(FoodTruck truck) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = truck.menu[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161A24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item.isSignature ? const Color(0xFFFF6B00).withOpacity(0.4) : Colors.white10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      item.imageUrl,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 84,
                        height: 84,
                        color: Colors.white10,
                        child: const Icon(Icons.fastfood, color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.isSignature) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withOpacity(0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '⭐ SIGNATURE DISH',
                              style: TextStyle(color: Color(0xFFFF6B00), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          item.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${item.price.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildVideoReviewsSection(FoodTruck truck) {
    if (truck.videoReviews.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.videocam_outlined, size: 48, color: Colors.white24),
                const SizedBox(height: 12),
                const Text('No video reviews yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Be the first to record a video bite at this truck!', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Upload 15s Video Review'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B00)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.65,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final review = truck.videoReviews[index];
            return GestureDetector(
              onTap: () => _showVideoPreviewDialog(review),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161A24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      review.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.white12),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.85),
                          ],
                        ),
                      ),
                    ),
                    // Play icon in center
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                      ),
                    ),
                    // Review text & user
                    Positioned(
                      bottom: 10,
                      left: 10,
                      right: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundImage: NetworkImage(review.userAvatar),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  review.userName,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.star, color: Color(0xFFFFB800), size: 12),
                              Text('${review.rating}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '"${review.quote}"',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: truck.videoReviews.length,
        ),
      ),
    );
  }

  Widget _buildLocationInfoSection(FoodTruck truck) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161A24),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Confirmed Live Location', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text('${truck.address}, ${truck.city}, ${truck.state}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text('GPS Coordinates: ${truck.latitude.toStringAsFixed(4)}, ${truck.longitude.toStringAsFixed(4)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF00E676), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location verified by food truck owner ${truck.lastConfirmed}',
                        style: const TextStyle(color: Color(0xFF00E676), fontSize: 12, fontWeight: FontWeight.w600),
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

  void _showVideoPreviewDialog(VideoReview review) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: 460,
            decoration: BoxDecoration(
              color: const Color(0xFF141722),
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(review.thumbnailUrl, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black54, Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Playing Community Clip',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.quote,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
