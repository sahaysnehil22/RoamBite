import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/food_truck.dart';
import '../providers/auth_provider.dart';
import '../services/demo_trucks.dart';
import '../services/supabase_service.dart';

class TruckDetailScreen extends StatefulWidget {
  final FoodTruck truck;

  const TruckDetailScreen({super.key, required this.truck});

  @override
  State<TruckDetailScreen> createState() => _TruckDetailScreenState();
}

class _TruckDetailScreenState extends State<TruckDetailScreen> {
  final List<String> _cartItems = [];
  late FoodTruck _truck;

  static const List<Map<String, String>> _reviewMediaPresets = [
    {
      'label': 'Quesabirria Tacos & Consomé',
      'url':
          'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Double Smash Burger & Fries',
      'url':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Nitro Cold Brew & Churros',
      'url':
          'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=600&q=80',
    },
    {
      'label': 'Stuffed Venezuelan Arepa',
      'url':
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _truck = DemoTrucks.getTruckById(widget.truck.id).copyWith(
      distanceInMiles: widget.truck.distanceInMiles,
    );
  }

  void _addToCart(String dishName) {
    setState(() => _cartItems.add(dishName));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Added "$dishName" to your order! (${_cartItems.length} items)'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFFFF5722),
        action: SnackBarAction(
          label: 'View Order',
          textColor: Colors.white,
          onPressed: _openFullMenuSheet,
        ),
      ),
    );
  }

  void _openVideoPreview(VideoReview review) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    review.thumbnailUrl,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(height: 280, color: Colors.grey[900]),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    review.isVideo ? Icons.play_arrow : Icons.photo_camera,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      review.isVideo
                          ? 'VIDEO REEL • ${review.duration}'
                          : 'PHOTO REVIEW',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(review.userAvatar),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              review.timeAgo,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${review.rating}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (review.mediaCaption.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      review.mediaCaption,
                      style: const TextStyle(
                        color: Color(0xFFFF8A65),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '"${review.quote}"',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullMenuSheet() {
    final theme = Theme.of(context);
    final truck = _truck;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetContext, scrollCtrl) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${truck.name} — Full Menu',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${truck.menu.length} dishes with photos available right now',
                              style: TextStyle(
                                  fontSize: 12, color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: truck.menu.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final item = truck.menu[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl,
                              width: 84,
                              height: 84,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 84,
                                height: 84,
                                color: Colors.grey[200],
                                child: const Icon(Icons.fastfood,
                                    color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.isSignature)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    margin: const EdgeInsets.only(bottom: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5722)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.star,
                                            color: Color(0xFFFF5722), size: 11),
                                        SizedBox(width: 3),
                                        Text(
                                          'SIGNATURE DISH',
                                          style: TextStyle(
                                            color: Color(0xFFFF5722),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Text(item.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14)),
                                const SizedBox(height: 3),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                      color: theme.hintColor, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        Navigator.pop(ctx);
                                        _addToCart(item.name);
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5722),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Text(
                                          '+ Add',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Modal allowing a Foodie to drop a review with Rating + Text + Photo or Video
  Future<void> _openReviewDialog() async {
    double selectedRating = 5.0;
    final textCtrl = TextEditingController();
    final captionCtrl = TextEditingController();
    final customUrlCtrl = TextEditingController();
    bool isVideoMedia = true;
    int selectedPresetIdx = 0;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Drop a Review for ${_truck.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1. Rate your experience:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [1, 2, 3, 4, 5].map((star) {
                    return IconButton(
                      icon: Icon(
                        star <= selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 28,
                      ),
                      onPressed: () =>
                          setDlgState(() => selectedRating = star.toDouble()),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                const Text('2. Attach Photo or Video:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.videocam, size: 16),
                        label: const Text('Video Reel'),
                        selected: isVideoMedia,
                        onSelected: (_) =>
                            setDlgState(() => isVideoMedia = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        avatar: const Icon(Icons.photo_camera, size: 16),
                        label: const Text('Dish Photo'),
                        selected: !isVideoMedia,
                        onSelected: (_) =>
                            setDlgState(() => isVideoMedia = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _reviewMediaPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, idx) {
                      final preset = _reviewMediaPresets[idx];
                      final isSelected = selectedPresetIdx == idx;
                      return GestureDetector(
                        onTap: () =>
                            setDlgState(() => selectedPresetIdx = idx),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF5722)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              preset['url']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: customUrlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Or paste custom photo/video URL (optional)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: captionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dish / Media Caption',
                    hintText: 'e.g. Crispy Quesabirria Dip!',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: textCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Your Review *',
                    hintText:
                        'Share what you ordered, taste, and window wait time...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      setDlgState(() => isSubmitting = true);
                      final auth = context.read<AuthProvider>();
                      final chosenMediaUrl =
                          customUrlCtrl.text.trim().isNotEmpty
                              ? customUrlCtrl.text.trim()
                              : _reviewMediaPresets[selectedPresetIdx]['url']!;
                      final chosenCaption = captionCtrl.text.trim().isNotEmpty
                          ? captionCtrl.text.trim()
                          : _reviewMediaPresets[selectedPresetIdx]['label']!;
                      final comment = textCtrl.text.trim().isNotEmpty
                          ? textCtrl.text.trim()
                          : 'Freshly prepared right at the truck window!';

                      final newRev = VideoReview(
                        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
                        userName: auth.displayName ?? 'Snehil Sahay',
                        userAvatar: (auth.avatarUrl != null &&
                                auth.avatarUrl!.isNotEmpty)
                            ? auth.avatarUrl!
                            : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
                        rating: selectedRating,
                        quote: comment,
                        thumbnailUrl: chosenMediaUrl,
                        videoUrl: isVideoMedia ? chosenMediaUrl : '',
                        timeAgo: 'Just now',
                        isVideo: isVideoMedia,
                        mediaCaption: chosenCaption,
                        duration: isVideoMedia ? '0:14' : 'PHOTO',
                      );

                      DemoTrucks.addReviewToTruck(_truck.id, newRev);

                      try {
                        final pos = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(
                              accuracy: LocationAccuracy.medium),
                        );
                        await SupabaseService().submitReview(
                          truckId: _truck.id,
                          rating: selectedRating,
                          text: comment,
                          userLat: pos.latitude,
                          userLng: pos.longitude,
                        );
                      } catch (_) {}

                      if (mounted) {
                        setState(() {
                          _truck = DemoTrucks.getTruckById(_truck.id).copyWith(
                            distanceInMiles: widget.truck.distanceInMiles,
                          );
                        });
                      }
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Your review with media has been posted!'),
                            backgroundColor: Color(0xFF00C853),
                          ),
                        );
                      }
                    },
              child: const Text(
                'Post Review',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final truck = _truck;
    final dishes = truck.menu;
    final reviews = truck.videoReviews;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // 1. HERO APP BAR WITH TRUCK PROFILE IMAGE
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.black,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.black, size: 18),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: InkWell(
                    onTap: _openReviewDialog,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5722),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review,
                              color: Colors.white, size: 15),
                          SizedBox(width: 4),
                          Text(
                            'Drop Review',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    truck.heroImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[800]),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFFFF5722), width: 2.5),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              truck.effectiveProfileImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.local_shipping,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                truck.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${truck.cuisine} • ',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12.5),
                                  ),
                                  Text(
                                    '${truck.rating} ',
                                    style: const TextStyle(
                                      color: Color(0xFFFFC107),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(Icons.star,
                                      color: Color(0xFFFFC107), size: 14),
                                  Text(
                                    ' (${reviews.length} reviews)',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (truck.isNearAndFast)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.bolt,
                                          color: Color(0xFF00E676), size: 15),
                                      Text(
                                        'Near & Fast • ${truck.prepTimeWalkMins} • ${truck.address}',
                                        style: const TextStyle(
                                          color: Color(0xFF00E676),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                ],
              ),
            ),
          ),

          // 2. FULL MENU WITH DISH IMAGES & VIDEO/PHOTO REVIEWS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Full Truck Menu (${dishes.length} Dishes)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: _openFullMenuSheet,
                        child: const Text('Expand Menu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Dish List with Dish Name & Dish Image
                  ...dishes.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.imageUrl,
                              width: 78,
                              height: 78,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 78,
                                height: 78,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.fastfood),
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
                                      Icons.circle,
                                      size: 10,
                                      color: item.isVegetarian
                                          ? const Color(0xFF1E8E3E)
                                          : const Color(0xFFD93829),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                      color: theme.hintColor, fontSize: 11.5),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '\$${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        color: Color(0xFFFF5722),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _addToCart(item.name),
                                      borderRadius: BorderRadius.circular(14),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFF5722),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: const Text(
                                          '+ Add',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.5,
                                          ),
                                        ),
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
                  }),

                  const SizedBox(height: 20),

                  // Video & Photo Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Video & Photo Reviews (${reviews.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _openReviewDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                        ),
                        icon: const Icon(Icons.add_a_photo,
                            color: Colors.white, size: 15),
                        label: const Text(
                          'Drop Review',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Video & Photo Reels
                  SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final rev = reviews[index];
                        return InkWell(
                          onTap: () => _openVideoPreview(rev),
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 162,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.network(
                                    rev.thumbnailUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Container(color: Colors.grey[900]),
                                  ),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.55),
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.88),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    right: 10,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: rev.isVideo
                                                ? const Color(0xFFFF5722)
                                                : Colors.black87,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            rev.isVideo
                                                ? 'VIDEO ${rev.duration}'
                                                : 'PHOTO',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              '${rev.rating}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Icon(Icons.star,
                                                color: Colors.amber, size: 12),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (rev.isVideo)
                                    Center(
                                      child: Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.35),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white54,
                                              width: 1.5),
                                        ),
                                        child: const Icon(Icons.play_arrow,
                                            color: Colors.white, size: 26),
                                      ),
                                    ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    right: 10,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 10,
                                              backgroundImage: NetworkImage(
                                                  rev.userAvatar),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                rev.userName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '"${rev.quote}"',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
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
}
