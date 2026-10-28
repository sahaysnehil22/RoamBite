import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/food_truck.dart';
import '../providers/auth_provider.dart';
import '../services/demo_trucks.dart';
import '../services/supabase_service.dart';
import '../widgets/google_maps_directions_sheet.dart';
import '../widgets/media_picker_sheet.dart';
import '../widgets/video_reel_player_sheet.dart';

class TruckDetailScreen extends StatefulWidget {
  final FoodTruck truck;

  const TruckDetailScreen({super.key, required this.truck});

  @override
  State<TruckDetailScreen> createState() => _TruckDetailScreenState();
}

class _TruckDetailScreenState extends State<TruckDetailScreen> {
  final List<String> _cartItems = [];
  late FoodTruck _truck;
  bool _vegOnlyMenu = false;
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _truck = DemoTrucks.getTruckById(widget.truck.id).copyWith(
      distanceInMiles: widget.truck.distanceInMiles,
    );
    _isSaved = DemoTrucks.isTruckSaved(_truck.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.vegMode) {
        setState(() => _vegOnlyMenu = true);
      }
    });
  }

  void _addToCart(String dishName) {
    setState(() => _cartItems.add(dishName));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Added "$dishName" to your walk-up list (${_cartItems.length} items)'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFFF5722),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Directions',
          textColor: Colors.white,
          onPressed: () => openGoogleMapsDirections(context, truck: _truck),
        ),
      ),
    );
  }

  void _openVideoReel(VideoReview clickedReview) {
    final idx =
        _truck.videoReviews.indexWhere((r) => r.id == clickedReview.id);
    showVideoReelPlayer(
      context,
      truck: _truck,
      reviews: _truck.videoReviews,
      initialIndex: idx < 0 ? 0 : idx,
    );
  }

  Future<void> _openWriteReviewModal() async {
    final auth = context.read<AuthProvider>();
    double selectedRating = 5.0;
    final commentCtrl = TextEditingController();
    final captionCtrl = TextEditingController();
    bool isVideoReview = true;
    String attachedMediaUrl = _truck.menu.isNotEmpty
        ? _truck.menu.first.imageUrl
        : _truck.heroImageUrl;
    String attachedMediaSource = 'Default Truck Dish';
    String attachedDuration = '0:15';
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final theme = Theme.of(ctx);
            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Drop a Review & Video Reel',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                _truck.name,
                                style: TextStyle(
                                    color: theme.hintColor, fontSize: 13),
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
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to Rate',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starVal = index + 1.0;
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            selectedRating >= starVal
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () =>
                              setModalState(() => selectedRating = starVal),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    // Camera / Gallery Upload Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              const Color(0xFFFF5722).withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Image.network(
                                      attachedMediaUrl,
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.fastfood),
                                      ),
                                    ),
                                    if (isVideoReview)
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.play_arrow,
                                            color: Colors.white, size: 18),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isVideoReview
                                          ? 'Video Reel ($attachedDuration)'
                                          : 'Food Photo Attached',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      attachedMediaSource,
                                      style: TextStyle(
                                          color: theme.hintColor, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        foregroundColor:
                                            const Color(0xFFFF5722),
                                        side: const BorderSide(
                                            color: Color(0xFFFF5722)),
                                      ),
                                      onPressed: () async {
                                        final picked =
                                            await showRoamBiteMediaPicker(
                                          ctx,
                                          title:
                                              'Upload Review Photo or Video Reel',
                                          allowVideo: true,
                                          defaultToVideo: isVideoReview,
                                        );
                                        if (picked != null) {
                                          setModalState(() {
                                            attachedMediaUrl = picked.url;
                                            isVideoReview = picked.isVideo;
                                            attachedMediaSource =
                                                picked.sourceLabel;
                                            attachedDuration = picked.duration;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.add_a_photo,
                                          size: 15),
                                      label: const Text(
                                        'Camera / Gallery',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: captionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Dish Ordered (e.g. Crispy Quesabirria)',
                        prefixIcon:
                            const Icon(Icons.restaurant_menu, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'How was the food, portion size, and wait time?',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (commentCtrl.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Please write a short review comment.')),
                                  );
                                  return;
                                }
                                setModalState(() => isSubmitting = true);
                                final newRev = VideoReview(
                                  id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                                  userName: auth.displayName ?? 'Snehil Sahay',
                                  userAvatar: (auth.avatarUrl != null &&
                                          auth.avatarUrl!.isNotEmpty)
                                      ? auth.avatarUrl!
                                      : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                                  rating: selectedRating,
                                  quote: commentCtrl.text.trim(),
                                  thumbnailUrl: attachedMediaUrl,
                                  videoUrl: isVideoReview
                                      ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
                                      : '',
                                  timeAgo: 'Just now',
                                  isVideo: isVideoReview,
                                  mediaCaption: captionCtrl.text.trim().isEmpty
                                      ? 'Verified Order'
                                      : captionCtrl.text.trim(),
                                  duration: attachedDuration,
                                );

                                DemoTrucks.addReviewToTruck(_truck.id, newRev);

                                if (SupabaseConfig.isConfigured &&
                                    auth.isAuthenticated) {
                                  try {
                                    double uLat = _truck.latitude;
                                    double uLng = _truck.longitude;
                                    try {
                                      final pos =
                                          await Geolocator.getCurrentPosition();
                                      uLat = pos.latitude;
                                      uLng = pos.longitude;
                                    } catch (_) {}
                                    await SupabaseService().submitReview(
                                      truckId: _truck.id,
                                      rating: selectedRating,
                                      text: commentCtrl.text.trim(),
                                      userLat: uLat,
                                      userLng: uLng,
                                      reviewerName: newRev.userName,
                                      reviewerAvatarUrl: newRev.userAvatar,
                                      mediaUrl: attachedMediaUrl,
                                      videoUrl: newRev.videoUrl,
                                      isVideo: isVideoReview,
                                      mediaCaption: newRev.mediaCaption,
                                      duration: attachedDuration,
                                    );
                                  } catch (_) {}
                                }

                                if (mounted) {
                                  setState(() {
                                    _truck = DemoTrucks.getTruckById(_truck.id)
                                        .copyWith(
                                      distanceInMiles: _truck.distanceInMiles,
                                    );
                                  });
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF00C853),
                                      content: Text(
                                        isVideoReview
                                            ? 'Video reel review posted to ${_truck.name}!'
                                            : 'Photo review posted to ${_truck.name}!',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          isSubmitting ? 'Posting...' : 'Post Verified Review',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
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
    final displayedMenu = _vegOnlyMenu
        ? _truck.menu.where((m) => m.isVegetarian).toList()
        : _truck.menu;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero App Bar with Truck Profile Image, Save, Share & Directions
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            actions: [
              IconButton(
                tooltip: _isSaved ? 'Saved' : 'Save Truck',
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                onPressed: () {
                  final nowSaved = DemoTrucks.toggleSavedTruck(_truck.id);
                  setState(() => _isSaved = nowSaved);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(nowSaved
                          ? 'Saved ${_truck.name} to your Favorites!'
                          : 'Removed ${_truck.name} from Favorites.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: _isSaved ? const Color(0xFFFF5722) : Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Share Truck',
                style: IconButton.styleFrom(backgroundColor: Colors.black45),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text:
                        'Check out ${_truck.name} (${_truck.address}, ${_truck.city}) on RoamBite!',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('Copied share link for ${_truck.name}!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _truck.heroImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[800]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              _truck.effectiveProfileImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xFFFF5722),
                                child: const Icon(Icons.local_shipping,
                                    color: Colors.white),
                              ),
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
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _truck.status ==
                                              TruckStatus.servingNow
                                          ? const Color(0xFF00C853)
                                          : const Color(0xFFFF9100),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _truck.status == TruckStatus.servingNow
                                          ? 'SERVING NOW'
                                          : 'ON THE MOVE',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (_truck.isNearAndFast)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.bolt,
                                              color: Color(0xFF00C853),
                                              size: 13),
                                          Text(
                                            'Near & Fast • ${_truck.prepTimeWalkMins}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _truck.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${_truck.cuisine} • ${_truck.priceRange} • ${_truck.address}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Buttons Row: Google Maps Directions, Watch Reels, Drop Review
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => openGoogleMapsDirections(
                            context,
                            truck: _truck,
                          ),
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text(
                            'Google Maps',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Color(0xFFFF5722)),
                            foregroundColor: const Color(0xFFFF5722),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            if (_truck.videoReviews.isNotEmpty) {
                              showVideoReelPlayer(
                                context,
                                truck: _truck,
                                reviews: _truck.videoReviews,
                              );
                            }
                          },
                          icon: const Icon(Icons.play_circle_fill, size: 18),
                          label: Text(
                            'Watch Reels (${_truck.videoReviews.length})',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _openWriteReviewModal,
                          icon: const Icon(Icons.rate_review, size: 17),
                          label: const Text(
                            'Drop Review',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Live GPS Location Card (Tappable to open Google Maps)
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        openGoogleMapsDirections(context, truck: _truck),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.location_on,
                                color: Color(0xFF1A73E8)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_truck.address}, ${_truck.city}, ${_truck.state}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                Text(
                                  '${_truck.distanceInMiles} mi away • Verified ${_truck.lastConfirmed} • Open until ${_truck.closesAt}',
                                  style: TextStyle(
                                      color: theme.hintColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new,
                              size: 18, color: Color(0xFF1A73E8)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Full Menu Header + Veg Only Filter Switch
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Full Truck Menu (${displayedMenu.length} Dishes)',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      FilterChip(
                        avatar: const Icon(
                          Icons.eco,
                          size: 15,
                          color: Color(0xFF00C853),
                        ),
                        label: const Text(
                          'Veg Only',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        selected: _vegOnlyMenu,
                        selectedColor:
                            const Color(0xFF00C853).withValues(alpha: 0.2),
                        onSelected: (val) =>
                            setState(() => _vegOnlyMenu = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (displayedMenu.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.eco_outlined,
                              color: Color(0xFF00C853)),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'No vegetarian-only items in this filter.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _vegOnlyMenu = false),
                            child: const Text('Show All Dishes'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...displayedMenu
                        .map((item) => _buildDishCard(item, theme)),

                  const SizedBox(height: 24),

                  // Video & Photo Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video Reels & Reviews (${_truck.videoReviews.length})',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Tap any video reel to watch in full-screen player',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 12),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _openWriteReviewModal,
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: const Text('Add Reel / Review'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 235,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _truck.videoReviews.length,
                      itemBuilder: (context, index) {
                        final rev = _truck.videoReviews[index];
                        return _buildVideoReviewCard(rev, theme);
                      },
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishCard(MenuItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              item.imageUrl,
              width: 88,
              height: 88,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 88,
                height: 88,
                color: Colors.grey.shade200,
                child: const Icon(Icons.fastfood, color: Color(0xFFFF5722)),
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
                    Icon(
                      Icons.crop_square_sharp,
                      size: 15,
                      color: item.isVegetarian
                          ? const Color(0xFF00C853)
                          : const Color(0xFFD32F2F),
                    ),
                    const SizedBox(width: 4),
                    if (item.isSignature)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF5722).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BESTSELLER',
                          style: TextStyle(
                            color: Color(0xFFFF5722),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFFF5722),
                        side: const BorderSide(color: Color(0xFFFF5722)),
                      ),
                      onPressed: () => _addToCart(item.name),
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text(
                        'ADD',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12),
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

  Widget _buildVideoReviewCard(VideoReview review, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openVideoReel(review),
      child: Container(
        width: 175,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              review.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey.shade800),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            // Top badge: VIDEO REEL + Duration
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5722),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          review.isVideo ? Icons.videocam : Icons.photo_camera,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          review.isVideo ? 'REEL ${review.duration}' : 'PHOTO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 11),
                        const SizedBox(width: 2),
                        Text(
                          '${review.rating}',
                          style: const TextStyle(
                            color: Colors.white,
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
            // Center Play Button
            Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.90),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            // Bottom Quote & Reviewer
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${review.quote}"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
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
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
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
}
