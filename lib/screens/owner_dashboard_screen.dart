import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/food_truck.dart';
import '../services/demo_trucks.dart';
import '../services/supabase_service.dart';
import '../widgets/media_picker_sheet.dart';
import 'menu_editor_screen.dart';
import 'truck_detail_screen.dart';
import 'visitor_stats_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  String _managedTruckId = 'a1111111-aaaa-1111-aaaa-111111111111';

  bool _isShiftActive = true;
  String _truckStatus = 'serving_now'; // 'serving_now' or 'on_the_move'
  bool _isBoostActive = false;
  final String _currentZone = 'Wynwood, Miami, FL';
  Timer? _pingTimer;
  DateTime? _lastPingTime = DateTime.now();
  int _secondsUntilNextPing = 120;
  Timer? _countdownTimer;

  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _cuisineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _closesAtCtrl;
  late TextEditingController _profileImgCtrl;
  String _photoSourceLabel = 'Current Radar Profile Image';

  @override
  void initState() {
    super.initState();
    _loadManagedTruckFields(_managedTruckId);
    _startPingSchedule();
  }

  void _loadManagedTruckFields(String truckId) {
    final truck = DemoTrucks.getTruckById(truckId);
    _nameCtrl = TextEditingController(text: truck.name);
    _taglineCtrl = TextEditingController(text: truck.tagline);
    _cuisineCtrl = TextEditingController(text: truck.cuisine);
    _addressCtrl = TextEditingController(text: truck.address);
    _closesAtCtrl = TextEditingController(text: truck.closesAt);
    _profileImgCtrl = TextEditingController(text: truck.effectiveProfileImage);
  }

  @override
  void dispose() {
    _stopPingSchedule();
    _nameCtrl.dispose();
    _taglineCtrl.dispose();
    _cuisineCtrl.dispose();
    _addressCtrl.dispose();
    _closesAtCtrl.dispose();
    _profileImgCtrl.dispose();
    super.dispose();
  }

  void _startPingSchedule() {
    _stopPingSchedule();
    _sendLocationPing();
    _pingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _sendLocationPing();
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isShiftActive) {
        setState(() {
          if (_secondsUntilNextPing > 0) {
            _secondsUntilNextPing--;
          } else {
            _secondsUntilNextPing = 120;
          }
        });
      }
    });
  }

  void _stopPingSchedule() {
    _pingTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> _sendLocationPing() async {
    double lat = 25.7997;
    double lng = -80.1986;

    try {
      final pos = await Geolocator.getCurrentPosition();
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {}

    await SupabaseService().broadcastOwnerLocation(
      truckId: _managedTruckId,
      latitude: lat,
      longitude: lng,
      status: _truckStatus,
    );

    if (mounted) {
      setState(() {
        _lastPingTime = DateTime.now();
        _secondsUntilNextPing = 120;
      });
    }
  }

  Future<void> _pickTruckImageFromCameraOrGallery() async {
    final picked = await showRoamBiteMediaPicker(
      context,
      title: 'Upload Truck Profile & Radar Photo',
      allowVideo: false,
    );
    if (picked != null && mounted) {
      setState(() {
        _profileImgCtrl.text = picked.url;
        _photoSourceLabel = picked.sourceLabel;
      });
    }
  }

  Future<void> _saveTruckProfile() async {
    await SupabaseService().updateTruckProfileInDb(
      truckId: _managedTruckId,
      name: _nameCtrl.text.trim(),
      tagline: _taglineCtrl.text.trim(),
      cuisine: _cuisineCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      closesAt: _closesAtCtrl.text.trim(),
      profileImageUrl: _profileImgCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Color(0xFF00C853),
        content: Text(
          'Truck profile & Radar avatar updated! Visible on Radar & Explore.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTruck = DemoTrucks.getTruckById(_managedTruckId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Truck Partner Operations'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isShiftActive
                  ? const Color(0xFF00C853).withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    _isShiftActive ? const Color(0xFF00C853) : Colors.grey,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 10,
                  color: _isShiftActive
                      ? const Color(0xFF00C853)
                      : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  _isShiftActive ? 'BROADCASTING LIVE' : 'OFF SHIFT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _isShiftActive
                        ? const Color(0xFF00C853)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Live Shift & Radar Broadcast Control Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isShiftActive
                    ? const Color(0xFF00C853)
                    : theme.dividerColor,
                width: _isShiftActive ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickTruckImageFromCameraOrGallery,
                      child: Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFFF5722),
                                width: 2.5,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                _profileImgCtrl.text.isNotEmpty
                                    ? _profileImgCtrl.text
                                    : currentTruck.effectiveProfileImage,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.local_shipping,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5722),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentTruck.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'Active Zone: $_currentZone',
                            style: TextStyle(
                                color: theme.hintColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isShiftActive,
                      activeThumbColor: const Color(0xFF00C853),
                      onChanged: (val) {
                        setState(() => _isShiftActive = val);
                        if (val) {
                          _startPingSchedule();
                        } else {
                          _stopPingSchedule();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusChoice(
                        label: 'Serving Now',
                        value: 'serving_now',
                        icon: Icons.storefront,
                        activeColor: const Color(0xFF00C853),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatusChoice(
                        label: 'On The Move',
                        value: 'on_the_move',
                        icon: Icons.local_shipping,
                        activeColor: const Color(0xFFFF9100),
                      ),
                    ),
                  ],
                ),
                if (_isShiftActive) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Next GPS Radar Ping in ${_secondsUntilNextPing}s',
                        style: TextStyle(color: theme.hintColor, fontSize: 12),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          _sendLocationPing();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Live GPS coordinates pinged to Radar!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.my_location, size: 15),
                        label: const Text('Ping GPS Now',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. Quick Operations Buttons: Dish Menu Editor, Visitor Analytics, Full Preview
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MenuEditorScreen(truckId: _managedTruckId),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.add_a_photo, size: 18),
                  label: Text(
                    'Menu & Dish Photos (${currentTruck.menu.length})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xFFFF5722)),
                    foregroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TruckDetailScreen(truck: currentTruck),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text(
                    'Preview Customer View',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Edit Truck Profile & Upload Image from Gallery / Camera
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge_outlined, color: Color(0xFFFF5722)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Edit Truck Profile & Radar Scanner Image',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload a photo from your Gallery or capture with Camera. This photo appears on the Radar scanner & truck header.',
                  style: TextStyle(color: theme.hintColor, fontSize: 12),
                ),
                const SizedBox(height: 14),
                // Camera / Gallery Upload Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5722).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            const Color(0xFFFF5722).withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _profileImgCtrl.text,
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 72,
                            height: 72,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.local_shipping),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Truck Profile & Radar Pin Photo',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              _photoSourceLabel,
                              style: TextStyle(
                                  color: theme.hintColor, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5722),
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _pickTruckImageFromCameraOrGallery,
                              icon: const Icon(Icons.add_a_photo, size: 15),
                              label: const Text(
                                'Upload from Gallery / Camera',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Truck Name',
                    prefixIcon: const Icon(Icons.storefront_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _taglineCtrl,
                  decoration: InputDecoration(
                    labelText: 'Truck Tagline / Specialty',
                    prefixIcon: const Icon(Icons.auto_awesome_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cuisineCtrl,
                        decoration: InputDecoration(
                          labelText: 'Cuisine Category',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _closesAtCtrl,
                        decoration: InputDecoration(
                          labelText: 'Closes At',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Current Street Address',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5722),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _saveTruckProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Save Truck Profile & Radar Photo',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. Promoted Placement Boost + Live Analytics Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary:
                      const Icon(Icons.bolt, color: Colors.amber, size: 28),
                  title: const Text(
                    'Featured Zomato-Style Upper Hero Boost',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Highlight your truck in the upper hero banner for nearby foodies',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isBoostActive,
                  activeThumbColor: Colors.amber,
                  onChanged: (val) {
                    setState(() => _isBoostActive = val);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val
                            ? 'Hero Banner Boost activated for ${currentTruck.name}!'
                            : 'Hero Banner Boost paused.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.analytics_outlined,
                      color: Color(0xFFFF5722)),
                  title: const Text(
                    'View Live Foot-Traffic & Radar Stats',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'See how many foodies scanned your truck & tapped Google Maps',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const VisitorStatsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildStatusChoice({
    required String label,
    required String value,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _truckStatus == value;
    return GestureDetector(
      onTap: () {
        setState(() => _truckStatus = value);
        DemoTrucks.updateTruckProfile(
          truckId: _managedTruckId,
          status: value == 'serving_now'
              ? TruckStatus.servingNow
              : TruckStatus.onTheMove,
        );
        if (_isShiftActive) _sendLocationPing();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade400,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
