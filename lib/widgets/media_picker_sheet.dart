import 'dart:async';
import 'package:flutter/material.dart';

class PickedMediaResult {
  final String url;
  final bool isVideo;
  final String sourceLabel; // 'Camera Capture' or 'Photo Gallery' or 'Custom URL'
  final String duration;

  const PickedMediaResult({
    required this.url,
    required this.isVideo,
    required this.sourceLabel,
    this.duration = '0:15',
  });
}

/// Shows an interactive "Upload from Gallery or Capture from Camera" bottom sheet.
/// Used across:
/// - Foodie "Drop a Review" (photo or video reel upload)
/// - Truck Owner Menu Editor (dish photo upload)
/// - Truck Owner Dashboard (truck profile & radar avatar upload)
/// - Foodie "Your Profile" (user avatar upload)
Future<PickedMediaResult?> showRoamBiteMediaPicker(
  BuildContext context, {
  required String title,
  bool allowVideo = false,
  bool defaultToVideo = false,
}) async {
  return showModalBottomSheet<PickedMediaResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RoamBiteMediaPickerSheet(
      title: title,
      allowVideo: allowVideo,
      defaultToVideo: defaultToVideo,
    ),
  );
}

class _RoamBiteMediaPickerSheet extends StatefulWidget {
  final String title;
  final bool allowVideo;
  final bool defaultToVideo;

  const _RoamBiteMediaPickerSheet({
    required this.title,
    required this.allowVideo,
    required this.defaultToVideo,
  });

  @override
  State<_RoamBiteMediaPickerSheet> createState() =>
      _RoamBiteMediaPickerSheetState();
}

class _RoamBiteMediaPickerSheetState extends State<_RoamBiteMediaPickerSheet> {
  // 0 = Action Chooser (Camera vs Gallery), 1 = Live Camera Viewfinder, 2 = Gallery Grid
  int _step = 0;
  late bool _isVideoMode;
  bool _flashOn = false;
  bool _frontCamera = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  int _cameraPreviewIndex = 0;
  final TextEditingController _customUrlCtrl = TextEditingController();

  static const List<Map<String, String>> _cameraDishShots = [
    {
      'label': 'Fresh Sizzling Quesabirria Plate',
      'url':
          'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=900&q=80',
      'duration': '0:16',
    },
    {
      'label': 'Double Smash Burger off the Grill',
      'url':
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=900&q=80',
      'duration': '0:19',
    },
    {
      'label': 'Caramelized Cinnamon Sugar Churros',
      'url':
          'https://images.unsplash.com/photo-1624371414361-e670edf4898d?auto=format&fit=crop&w=900&q=80',
      'duration': '0:14',
    },
    {
      'label': 'Stuffed Reina Pepiada Arepa',
      'url':
          'https://images.unsplash.com/photo-1599974579688-8dbdd335c77f?auto=format&fit=crop&w=900&q=80',
      'duration': '0:18',
    },
    {
      'label': 'Food Truck Serving Window Live',
      'url':
          'https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?auto=format&fit=crop&w=900&q=80',
      'duration': '0:21',
    },
  ];

  static const List<Map<String, String>> _galleryItems = [
    {
      'label': 'Birria Dip & Consome',
      'url':
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80',
      'duration': '0:15',
    },
    {
      'label': 'Loaded Truffle Fries',
      'url':
          'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=800&q=80',
      'duration': '0:12',
    },
    {
      'label': 'Grilled Street Elote',
      'url':
          'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80',
      'duration': '0:17',
    },
    {
      'label': 'Cold Brew Horchata Latte',
      'url':
          'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=800&q=80',
      'duration': '0:14',
    },
    {
      'label': 'Crispy Sweet Plantains',
      'url':
          'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?auto=format&fit=crop&w=800&q=80',
      'duration': '0:16',
    },
    {
      'label': 'Wynwood Food Truck Night',
      'url':
          'https://images.unsplash.com/photo-1525164286253-04e68b9d94c6?auto=format&fit=crop&w=800&q=80',
      'duration': '0:22',
    },
    {
      'label': 'Chef Plating Tacos',
      'url':
          'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?auto=format&fit=crop&w=800&q=80',
      'duration': '0:19',
    },
    {
      'label': 'Foodie Portrait Avatar',
      'url':
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=600&q=80',
      'duration': '0:10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _isVideoMode = widget.allowVideo && widget.defaultToVideo;
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _customUrlCtrl.dispose();
    super.dispose();
  }

  void _handleCameraCapture() {
    final shot = _cameraDishShots[_cameraPreviewIndex % _cameraDishShots.length];
    if (_isVideoMode) {
      if (!_isRecording) {
        setState(() {
          _isRecording = true;
          _recordSeconds = 1;
        });
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;
          setState(() => _recordSeconds++);
          if (_recordSeconds >= 15) {
            _finishRecording(shot);
          }
        });
      } else {
        _finishRecording(shot);
      }
    } else {
      Navigator.pop(
        context,
        PickedMediaResult(
          url: shot['url']!,
          isVideo: false,
          sourceLabel: 'Camera Photo (${shot['label']})',
        ),
      );
    }
  }

  void _finishRecording(Map<String, String> shot) {
    _recordTimer?.cancel();
    final secs = _recordSeconds.clamp(3, 59).toString().padLeft(2, '0');
    Navigator.pop(
      context,
      PickedMediaResult(
        url: shot['url']!,
        isVideo: true,
        sourceLabel: 'Camera Video Reel (${shot['label']})',
        duration: '0:$secs',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              children: [
                if (_step != 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      _recordTimer?.cancel();
                      setState(() {
                        _isRecording = false;
                        _step = 0;
                      });
                    },
                  ),
                Expanded(
                  child: Text(
                    _step == 0
                        ? widget.title
                        : _step == 1
                            ? (_isVideoMode
                                ? 'Camera • Record Video Reel'
                                : 'Camera • Capture Photo')
                            : 'Choose from Device Gallery',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_step == 0) _buildChooserView(theme),
            if (_step == 1) _buildCameraViewfinder(theme),
            if (_step == 2) _buildGalleryPicker(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildChooserView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.allowVideo) ...[
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  avatar: const Icon(Icons.photo_camera_outlined, size: 16),
                  label: const Text('Photo Mode'),
                  selected: !_isVideoMode,
                  onSelected: (_) => setState(() => _isVideoMode = false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  avatar: const Icon(Icons.videocam_outlined, size: 16),
                  label: const Text('Video Reel Mode'),
                  selected: _isVideoMode,
                  onSelected: (_) => setState(() => _isVideoMode = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        // Option 1: Open Camera
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _step = 1),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFF5722).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFFF5722).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5722),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isVideoMode ? Icons.videocam : Icons.camera_alt,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isVideoMode
                            ? 'Open Camera to Record Video Reel'
                            : 'Open Camera to Take Photo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isVideoMode
                            ? 'Capture a live 15s food truck video review with camera'
                            : 'Snap a fresh photo directly from your camera',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFFF5722)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Option 2: Upload from Gallery
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _step = 2),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isVideoMode
                            ? 'Upload Video or Photo from Gallery'
                            : 'Upload Photo from Gallery',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select from your device camera roll & saved food shots',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCameraViewfinder(ThemeData theme) {
    final currentShot =
        _cameraDishShots[_cameraPreviewIndex % _cameraDishShots.length];
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Image.network(
                currentShot['url']!,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isRecording
                          ? Colors.redAccent
                          : Colors.white.withValues(alpha: 0.4),
                      width: _isRecording ? 3 : 1.5,
                    ),
                  ),
                ),
              ),
              // Camera HUD Overlay
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.circle,
                            size: 10,
                            color: _isRecording
                                ? Colors.redAccent
                                : const Color(0xFF00C853),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isRecording
                                ? 'REC 00:${_recordSeconds.toString().padLeft(2, '0')}'
                                : (_frontCamera ? 'FRONT LENS' : 'HD REAR LENS'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                          onPressed: () =>
                              setState(() => _flashOn = !_flashOn),
                          icon: Icon(
                            _flashOn ? Icons.flash_on : Icons.flash_off,
                            color: _flashOn ? Colors.amber : Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                              backgroundColor: Colors.black54),
                          onPressed: () => setState(() {
                            _frontCamera = !_frontCamera;
                            _cameraPreviewIndex++;
                          }),
                          icon: const Icon(
                            Icons.cameraswitch_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Scene selector pill
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentShot['label']!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () =>
                          setState(() => _cameraPreviewIndex++),
                      icon: const Icon(Icons.refresh, size: 14),
                      label: const Text('Switch Angle',
                          style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _step = 2),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gallery'),
            ),
            GestureDetector(
              onTap: _handleCameraCapture,
              child: Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isVideoMode
                        ? Colors.redAccent
                        : const Color(0xFFFF5722),
                    width: 4,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isVideoMode
                        ? Colors.redAccent
                        : const Color(0xFFFF5722),
                    shape: _isRecording ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius:
                        _isRecording ? BorderRadius.circular(8) : null,
                  ),
                  child: Icon(
                    _isVideoMode
                        ? (_isRecording ? Icons.stop : Icons.videocam)
                        : Icons.camera_alt,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
            if (widget.allowVideo)
              TextButton.icon(
                onPressed: () =>
                    setState(() => _isVideoMode = !_isVideoMode),
                icon: Icon(
                    _isVideoMode ? Icons.camera_alt : Icons.videocam_outlined),
                label: Text(_isVideoMode ? 'Photo' : 'Video'),
              )
            else
              const SizedBox(width: 72),
          ],
        ),
      ],
    );
  }

  Widget _buildGalleryPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Photos & Video Clips on Device',
          style: TextStyle(
            color: theme.hintColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _galleryItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (ctx, i) {
            final item = _galleryItems[i];
            return GestureDetector(
              onTap: () {
                Navigator.pop(
                  context,
                  PickedMediaResult(
                    url: item['url']!,
                    isVideo: _isVideoMode,
                    sourceLabel: 'Gallery (${item['label']})',
                    duration: item['duration'] ?? '0:15',
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(item['url']!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 5),
                        color: Colors.black.withValues(alpha: 0.65),
                        child: Row(
                          children: [
                            Icon(
                              _isVideoMode
                                  ? Icons.play_circle_fill
                                  : Icons.photo,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item['label']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customUrlCtrl,
                decoration: InputDecoration(
                  hintText: 'Or paste custom image/video URL...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5722),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final text = _customUrlCtrl.text.trim();
                if (text.isNotEmpty) {
                  Navigator.pop(
                    context,
                    PickedMediaResult(
                      url: text,
                      isVideo: _isVideoMode,
                      sourceLabel: 'Custom URL',
                    ),
                  );
                }
              },
              child: const Text('Use URL'),
            ),
          ],
        ),
      ],
    );
  }
}
