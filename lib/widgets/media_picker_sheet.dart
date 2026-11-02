import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';

class PickedMediaResult {
  final String url;
  final bool isVideo;
  final String sourceLabel; // 'Camera Photo', 'Gallery Photo', 'Custom URL', etc.
  final String duration;

  const PickedMediaResult({
    required this.url,
    required this.isVideo,
    required this.sourceLabel,
    this.duration = '0:15',
  });
}

/// Shows an interactive Camera / Gallery / Custom URL media picker bottom sheet.
/// Picks a real photo or video via [ImagePicker] (`ImageSource.camera` /
/// `ImageSource.gallery`), uploads it to the `roambite-media` Supabase Storage
/// bucket under [storageFolder] (`reviews/<user_id>`, `avatars/<user_id>`,
/// `trucks/<truck_id>`), and returns the public URL.
Future<PickedMediaResult?> showRoamBiteMediaPicker(
  BuildContext context, {
  required String title,
  String storageFolder = 'uploads/general',
  bool allowVideo = false,
  bool defaultToVideo = false,
}) async {
  return showModalBottomSheet<PickedMediaResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _RoamBiteMediaPickerSheet(
      title: title,
      storageFolder: storageFolder,
      allowVideo: allowVideo,
      defaultToVideo: defaultToVideo,
    ),
  );
}

class _RoamBiteMediaPickerSheet extends StatefulWidget {
  final String title;
  final String storageFolder;
  final bool allowVideo;
  final bool defaultToVideo;

  const _RoamBiteMediaPickerSheet({
    required this.title,
    required this.storageFolder,
    required this.allowVideo,
    required this.defaultToVideo,
  });

  @override
  State<_RoamBiteMediaPickerSheet> createState() =>
      _RoamBiteMediaPickerSheetState();
}

class _RoamBiteMediaPickerSheetState extends State<_RoamBiteMediaPickerSheet> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _customUrlCtrl = TextEditingController();
  late bool _isVideoMode;
  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _isVideoMode = widget.allowVideo && widget.defaultToVideo;
  }

  @override
  void dispose() {
    _customUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    if (_isUploading) return;
    setState(() {
      _errorMessage = null;
    });

    XFile? pickedFile;
    try {
      if (_isVideoMode) {
        pickedFile = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30),
        );
      } else {
        pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      final code = e.code.toLowerCase();
      final msg = (e.message ?? '').toLowerCase();
      if (code.contains('denied') ||
          code.contains('access') ||
          code.contains('permission') ||
          msg.contains('denied') ||
          msg.contains('permission')) {
        setState(() {
          _errorMessage =
              'Camera or photo access was denied. Please enable permission in your device settings or use a Custom URL below.';
        });
      } else {
        setState(() {
          _errorMessage =
              'Could not open ${source == ImageSource.camera ? 'camera' : 'gallery'}: ${e.message ?? e.code}';
        });
      }
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'} on this device. You can paste a Custom URL below.';
      });
      return;
    }

    // User canceled the native picker
    if (pickedFile == null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final rawName = pickedFile.name.isNotEmpty
          ? pickedFile.name
          : (_isVideoMode ? 'capture.mp4' : 'capture.jpg');

      final publicUrl = await SupabaseService().uploadMediaToBucket(
        storageFolder: widget.storageFolder,
        bytes: bytes,
        fileName: rawName,
        isVideo: _isVideoMode,
      );

      if (!mounted) return;
      final label = source == ImageSource.camera
          ? (_isVideoMode ? 'Camera Video' : 'Camera Photo')
          : (_isVideoMode ? 'Gallery Video' : 'Gallery Photo');

      Navigator.pop(
        context,
        PickedMediaResult(
          url: publicUrl,
          isVideo: _isVideoMode,
          sourceLabel: label,
          duration: '0:15',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _errorMessage =
            'Upload failed. Please check your connection and sign-in status, or use a Custom URL below.';
      });
    }
  }

  void _submitCustomUrl() {
    final text = _customUrlCtrl.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid image or video URL.';
      });
      return;
    }
    final uri = Uri.tryParse(text);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      setState(() {
        _errorMessage = 'Please enter a valid http:// or https:// URL.';
      });
      return;
    }
    Navigator.pop(
      context,
      PickedMediaResult(
        url: text,
        isVideo: _isVideoMode,
        sourceLabel: 'Custom URL',
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
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed:
                      _isUploading ? null : () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (widget.allowVideo) ...[
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: const Text('Photo Mode'),
                      selected: !_isVideoMode,
                      onSelected: _isUploading
                          ? null
                          : (_) => setState(() => _isVideoMode = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ChoiceChip(
                      avatar: const Icon(Icons.videocam_outlined, size: 16),
                      label: const Text('Video Reel Mode'),
                      selected: _isVideoMode,
                      onSelected: _isUploading
                          ? null
                          : (_) => setState(() => _isVideoMode = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade700, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_isUploading) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFFF5722)),
                    SizedBox(height: 14),
                    Text(
                      'Uploading to RoamBite Storage...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Option 1: Open Camera (ImageSource.camera)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pickAndUpload(ImageSource.camera),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFFF5722).withValues(alpha: 0.35),
                    ),
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
                                  ? 'Open Camera to Record Video'
                                  : 'Open Camera to Take Photo',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _isVideoMode
                                  ? 'Record a video clip with your device camera'
                                  : 'Take a photo directly with your device camera',
                              style: TextStyle(
                                  color: theme.hintColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFFFF5722)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Option 2: Upload from Gallery (ImageSource.gallery)
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _pickAndUpload(ImageSource.gallery),
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
                          color:
                              const Color(0xFF1E88E5).withValues(alpha: 0.12),
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
                                  ? 'Upload Video from Gallery'
                                  : 'Upload Photo from Gallery',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Choose an existing file from your photo library',
                              style: TextStyle(
                                  color: theme.hintColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Option 3: Custom URL option
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
                      onSubmitted: (_) => _submitCustomUrl(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _submitCustomUrl,
                    child: const Text('Use URL'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
