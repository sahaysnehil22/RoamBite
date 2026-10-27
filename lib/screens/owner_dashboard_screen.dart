import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/food_truck.dart';
import '../services/demo_trucks.dart';
import '../services/supabase_service.dart';
import 'truck_detail_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  static const String _managedTruckId = 'a1111111-aaaa-1111-aaaa-111111111111';

  bool _isShiftActive = false;
  String _truckStatus = 'serving_now'; // 'serving_now' or 'on_the_move'
  bool _isBoostActive = false;
  final String _currentZone = 'Wynwood, Miami, FL';
  Timer? _pingTimer;
  DateTime? _lastPingTime;
  int _secondsUntilNextPing = 120;
  Timer? _countdownTimer;

  late TextEditingController _nameCtrl;
  late TextEditingController _taglineCtrl;
  late TextEditingController _cuisineCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _closesAtCtrl;
  late TextEditingController _profileImgCtrl;

  static const List<String> _truckProfilePresets = [
    'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
    'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
  ];

  @override
  void initState() {
    super.initState();
    final truck = DemoTrucks.getTruckById(_managedTruckId);
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
    _sendLocationPing();
    _secondsUntilNextPing = 120;
    _pingTimer?.cancel();
    _countdownTimer?.cancel();

    _pingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _sendLocationPing();
      setState(() => _secondsUntilNextPing = 120);
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _secondsUntilNextPing > 0) {
        setState(() => _secondsUntilNextPing--);
      }
    });
  }

  void _stopPingSchedule() {
    _pingTimer?.cancel();
    _countdownTimer?.cancel();
    _pingTimer = null;
    _countdownTimer = null;
  }

  Future<void> _sendLocationPing() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await SupabaseService().broadcastOwnerLocation(
        truckId: _managedTruckId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        status: _truckStatus,
      );

      if (mounted) {
        setState(() => _lastPingTime = DateTime.now());
      }
    } catch (e) {
      debugPrint('Location ping: using default GPS ($e)');
      if (mounted) {
        setState(() => _lastPingTime = DateTime.now());
      }
    }
  }

  Future<void> _handleToggleShift(bool active) async {
    if (active) {
      final granted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFFFF5722)),
              SizedBox(width: 8),
              Text('Live Shift Broadcast'),
            ],
          ),
          content: const Text(
            'RoamBite requires high-accuracy foreground location while your shift is active to broadcast your truck\'s pin to hungry customers every 2 minutes.\n\nYour pin automatically expires after 15 minutes of inactivity.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722)),
              child: const Text('Start Shift',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (granted != true) return;

      setState(() => _isShiftActive = true);
      _startPingSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Shift started! Broadcasting live GPS pings every 2 minutes.'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } else {
      setState(() => _isShiftActive = false);
      _stopPingSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Shift ended. Live broadcast stopped.')),
        );
      }
    }
  }

  void _saveTruckProfile() {
    DemoTrucks.updateTruckProfile(
      truckId: _managedTruckId,
      name: _nameCtrl.text.trim(),
      tagline: _taglineCtrl.text.trim(),
      cuisine: _cuisineCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      closesAt: _closesAtCtrl.text.trim(),
      profileImageUrl: _profileImgCtrl.text.trim(),
      status: _truckStatus == 'serving_now'
          ? TruckStatus.servingNow
          : TruckStatus.onTheMove,
    );
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Truck profile & radar image saved! Customers can now see it on Radar & Feed.'),
        backgroundColor: Color(0xFF00C853),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTruck = DemoTrucks.getTruckById(_managedTruckId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Operations & Truck Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Status Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isShiftActive
                      ? const Color(0xFF00C853)
                      : theme.dividerColor,
                  width: _isShiftActive ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isShiftActive
                                  ? const Color(0xFF00C853)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isShiftActive
                                ? 'BROADCASTING LIVE'
                                : 'CURRENTLY OFFLINE',
                            style: TextStyle(
                              color: _isShiftActive
                                  ? const Color(0xFF00C853)
                                  : theme.hintColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isShiftActive,
                        onChanged: _handleToggleShift,
                        activeThumbColor: const Color(0xFF00C853),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFFFF5722), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isShiftActive
                              ? 'Broadcasting in: $_currentZone'
                              : 'Tap switch to go live',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  if (_isShiftActive) ...[
                    const SizedBox(height: 12),
                    Divider(color: theme.dividerColor),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _lastPingTime != null
                              ? 'Last ping: Just now'
                              : 'First ping sent',
                          style:
                              TextStyle(color: theme.hintColor, fontSize: 12),
                        ),
                        Text(
                          'Next ping in: ${_secondsUntilNextPing}s',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
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
                          'Preview Full Truck Profile (Menu & Reviews)'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Truck Profile & Radar Avatar Editor Card
            const Text(
              'EDIT TRUCK PROFILE & RADAR IMAGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF5722),
                            width: 2.5,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            _profileImgCtrl.text,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_shipping,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Radar & Profile Image',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Shown on the live radar scanner and truck profile header.',
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _truckProfilePresets.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, idx) {
                        final url = _truckProfilePresets[idx];
                        final selected = _profileImgCtrl.text == url;
                        return GestureDetector(
                          onTap: () => setState(() => _profileImgCtrl.text = url),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFFF5722)
                                    : Colors.grey.shade300,
                                width: selected ? 2.5 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(url, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _profileImgCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Profile Image URL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Truck Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _taglineCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tagline / Specialty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cuisineCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Cuisine',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _closesAtCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Closes At',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Curb Address',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveTruckProfile,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Save Truck Profile & Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Operating Status Selector (Material icons, no emoji)
            const Text(
              'OPERATING STATUS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _truckStatus = 'serving_now');
                      if (_isShiftActive) _sendLocationPing();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _truckStatus == 'serving_now'
                            ? const Color(0xFF00C853).withValues(alpha: 0.15)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _truckStatus == 'serving_now'
                              ? const Color(0xFF00C853)
                              : theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant,
                            color: _truckStatus == 'serving_now'
                                ? const Color(0xFF00C853)
                                : theme.hintColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Serving Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _truckStatus == 'serving_now'
                                  ? const Color(0xFF00C853)
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _truckStatus = 'on_the_move');
                      if (_isShiftActive) _sendLocationPing();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _truckStatus == 'on_the_move'
                            ? const Color(0xFFFF9100).withValues(alpha: 0.15)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _truckStatus == 'on_the_move'
                              ? const Color(0xFFFF9100)
                              : theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.local_shipping,
                            color: _truckStatus == 'on_the_move'
                                ? const Color(0xFFFF9100)
                                : theme.hintColor,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'On The Move',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _truckStatus == 'on_the_move'
                                  ? const Color(0xFFFF9100)
                                  : theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Boost Pin (Lure-Style Promotion)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.flash_on, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Sponsored Radar Boost (2 Hours)',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Highlight your food truck with a glowing amber beacon on all customer radar scans within 3.0 miles.',
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isBoostActive = !_isBoostActive);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isBoostActive
                              ? 'Radar boost activated for 2 hours!'
                              : 'Radar boost deactivated.'),
                          backgroundColor: Colors.amber[800],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isBoostActive
                          ? 'ACTIVE (1 hr 52 min left)'
                          : 'ACTIVATE BOOST (\$4.99)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
}
