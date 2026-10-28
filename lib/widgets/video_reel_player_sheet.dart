import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/food_truck.dart';

/// Opens a full-screen interactive Video Reel Player for a truck's reviews.
Future<void> showVideoReelPlayer(
  BuildContext context, {
  required FoodTruck truck,
  required List<VideoReview> reviews,
  int initialIndex = 0,
}) async {
  if (reviews.isEmpty) return;
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (ctx) => _VideoReelPlayerDialog(
      truck: truck,
      reviews: reviews,
      initialIndex: initialIndex,
    ),
  );
}

class _VideoReelPlayerDialog extends StatefulWidget {
  final FoodTruck truck;
  final List<VideoReview> reviews;
  final int initialIndex;

  const _VideoReelPlayerDialog({
    required this.truck,
    required this.reviews,
    required this.initialIndex,
  });

  @override
  State<_VideoReelPlayerDialog> createState() => _VideoReelPlayerDialogState();
}

class _VideoReelPlayerDialogState extends State<_VideoReelPlayerDialog>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _playbackController;
  late int _currentIndex;
  bool _isPlaying = true;
  bool _isMuted = false;
  final Set<String> _likedReviewIds = {};
  final Map<String, int> _likeCounts = {};

  // Generated multi-frame food scenes per review for continuous video reel motion
  static const List<String> _generatedSceneFrames = [
    'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1624371414361-e670edf4898d?auto=format&fit=crop&w=900&q=80',
    'https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?auto=format&fit=crop&w=900&q=80',
  ];

  static const List<String> _sceneSubtitles = [
    'Freshly plated right off the truck flat-top grill',
    'Close-up texture, melted cheese pull & house salsa',
    'Served piping hot at the Wynwood food truck window',
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.reviews.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    for (var i = 0; i < widget.reviews.length; i++) {
      final rev = widget.reviews[i];
      _likeCounts[rev.id] = 42 + (i * 19);
    }
    _playbackController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          // Auto-advance to next video reel
          if (_currentIndex < widget.reviews.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
            );
          } else {
            _playbackController.forward(from: 0);
          }
        }
      });
    _playbackController.forward();
  }

  @override
  void dispose() {
    _playbackController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _playbackController.forward();
      } else {
        _playbackController.stop();
      }
    });
  }

  List<String> _framesForReview(VideoReview review, int index) {
    final primary = review.thumbnailUrl.isNotEmpty
        ? review.thumbnailUrl
        : widget.truck.heroImageUrl;
    final second = widget.truck.menu.isNotEmpty
        ? widget.truck.menu[index % widget.truck.menu.length].imageUrl
        : _generatedSceneFrames[index % _generatedSceneFrames.length];
    final third =
        _generatedSceneFrames[(index + 2) % _generatedSceneFrames.length];
    return [primary, second, third];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            // Vertical / Horizontal PageView of Video Reels
            PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: widget.reviews.length,
              onPageChanged: (idx) {
                setState(() {
                  _currentIndex = idx;
                  _isPlaying = true;
                });
                _playbackController.forward(from: 0);
              },
              itemBuilder: (ctx, index) {
                final review = widget.reviews[index];
                final frames = _framesForReview(review, index);
                final isLiked = _likedReviewIds.contains(review.id);
                final likes = _likeCounts[review.id] ?? 48;

                return GestureDetector(
                  onTap: _togglePlayPause,
                  child: AnimatedBuilder(
                    animation: _playbackController,
                    builder: (context, _) {
                      final progress = _playbackController.value;
                      // Switch between 3 generated camera angles across the 15s reel
                      final sceneIdx = (progress * 3).floor().clamp(0, 2);
                      final localT = (progress * 3) - sceneIdx;
                      final scale = 1.04 + (0.10 * localT);
                      final panX =
                          (sceneIdx.isEven ? 1 : -1) * (12.0 * (localT - 0.5));

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // Animated Ken-Burns Multi-Scene Video Frame
                          ClipRect(
                            child: Transform.translate(
                              offset: Offset(panX, 0),
                              child: Transform.scale(
                                scale: scale,
                                child: Image.network(
                                  frames[sceneIdx],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1E1E1E),
                                    child: const Center(
                                      child: Icon(Icons.restaurant,
                                          color: Colors.white54, size: 64),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Live Sizzling / Steam Particle Overlay
                          CustomPaint(
                            painter: _ReelSteamOverlayPainter(
                                progress: progress),
                          ),
                          // Top & Bottom Cinema Gradients
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.65),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.88),
                                ],
                                stops: const [0.0, 0.22, 0.58, 1.0],
                              ),
                            ),
                          ),
                          // Center Play/Pause indicator when paused
                          if (!_isPlaying)
                            Center(
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white54, width: 2),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 46,
                                ),
                              ),
                            ),
                          // Live Audio / Scene Caption Pill
                          Positioned(
                            left: 16,
                            right: 84,
                            bottom: 195,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isMuted
                                        ? Icons.volume_off
                                        : Icons.graphic_eq,
                                    color: const Color(0xFFFF5722),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Scene ${sceneIdx + 1}/3: ${_sceneSubtitles[sceneIdx]}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right-side Vertical Action Rail (Like, Audio, Next, Share)
                          Positioned(
                            right: 14,
                            bottom: 110,
                            child: Column(
                              children: [
                                _buildRailButton(
                                  icon: isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  iconColor: isLiked
                                      ? const Color(0xFFFF5722)
                                      : Colors.white,
                                  label: '$likes',
                                  onTap: () {
                                    setState(() {
                                      if (isLiked) {
                                        _likedReviewIds.remove(review.id);
                                        _likeCounts[review.id] = likes - 1;
                                      } else {
                                        _likedReviewIds.add(review.id);
                                        _likeCounts[review.id] = likes + 1;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildRailButton(
                                  icon: _isMuted
                                      ? Icons.volume_off
                                      : Icons.volume_up,
                                  label: _isMuted ? 'Muted' : 'Sound',
                                  onTap: () =>
                                      setState(() => _isMuted = !_isMuted),
                                ),
                                const SizedBox(height: 16),
                                _buildRailButton(
                                  icon: Icons.share_outlined,
                                  label: 'Share',
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Copied video reel link for ${widget.truck.name}!'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                if (widget.reviews.length > 1)
                                  _buildRailButton(
                                    icon: Icons.skip_next_rounded,
                                    label: 'Next Reel',
                                    onTap: () {
                                      final next = (_currentIndex + 1) %
                                          widget.reviews.length;
                                      _pageController.animateToPage(
                                        next,
                                        duration:
                                            const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                          // Bottom Reviewer Details & Scrubber
                          Positioned(
                            left: 16,
                            right: 16,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundImage:
                                          NetworkImage(review.userAvatar),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                review.userName,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF00C853),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.verified,
                                                        color: Colors.white,
                                                        size: 11),
                                                    SizedBox(width: 3),
                                                    Text(
                                                      'VERIFIED VISIT',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            '${review.timeAgo} • ${review.mediaCaption.isNotEmpty ? review.mediaCaption : widget.truck.name}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF5722),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: Colors.white, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${review.rating}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '"${review.quote}"',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Interactive Progress Scrubber Bar
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(
                                        overlayRadius: 12),
                                    activeTrackColor: const Color(0xFFFF5722),
                                    inactiveTrackColor: Colors.white30,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: progress,
                                    onChanged: (val) {
                                      _playbackController.value = val;
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '0:${(progress * 15).round().toString().padLeft(2, '0')} / ${review.duration}',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11),
                                    ),
                                    Text(
                                      'Reel ${index + 1} of ${widget.reviews.length} • Swipe up/down for more',
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 11),
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
                );
              },
            ),
            // Top Header Bar with Segmented Story Progress Bars & Close Button
            Positioned(
              top: 10,
              left: 14,
              right: 14,
              child: Column(
                children: [
                  // Story-style segmented progress bars
                  AnimatedBuilder(
                    animation: _playbackController,
                    builder: (context, _) {
                      return Row(
                        children: List.generate(widget.reviews.length, (i) {
                          final val = i < _currentIndex
                              ? 1.0
                              : i == _currentIndex
                                  ? _playbackController.value
                                  : 0.0;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              height: 3.5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: val,
                                  backgroundColor: Colors.white30,
                                  valueColor: const AlwaysStoppedAnimation(
                                      Color(0xFFFF5722)),
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.slow_motion_video,
                                color: Color(0xFFFF5722), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${widget.truck.name} • Video Reels',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.black54),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
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

  Widget _buildRailButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelSteamOverlayPainter extends CustomPainter {
  final double progress;
  _ReelSteamOverlayPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 14; i++) {
      final phase = (progress * 2.5 + (i * 0.17)) % 1.0;
      final x = (size.width * 0.15) +
          ((i * 47) % (size.width * 0.70)) +
          math.sin(phase * math.pi * 2) * 14;
      final y = size.height * (0.78 - (phase * 0.45));
      final alpha = (1.0 - phase) * 0.18;
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), 6 + (phase * 14), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReelSteamOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
