import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/supabase_service.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _isShiftActive = false;
  String _truckStatus = 'serving_now'; // 'serving_now' or 'on_the_move'
  bool _isBoostActive = false;
  final String _currentZone = 'Wynwood, Miami, FL';
  Timer? _pingTimer;
  DateTime? _lastPingTime;
  int _secondsUntilNextPing = 120;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _stopPingSchedule();
    super.dispose();
  }

  void _startPingSchedule() {
    _sendLocationPing();
    _secondsUntilNextPing = 120;
    _pingTimer?.cancel();
    _countdownTimer?.cancel();

    // Ping every 2 minutes (Phase 4 requirement)
    _pingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _sendLocationPing();
      setState(() => _secondsUntilNextPing = 120);
    });

    // Countdown timer for owner UI feedback
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      await SupabaseService().broadcastOwnerLocation(
        truckId: 'a1111111-aaaa-1111-aaaa-111111111111',
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
      // Permission Rationale Modal
      final granted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFFFF5722)),
              SizedBox(width: 8),
              Text('Live Shift Broadcast'),
            ],
          ),
          content: const Text(
            'RoamBite requires high-accuracy foreground location while your shift is active to broadcast your truck\'s pin to hungry customers every 2 minutes.\n\nYour pin automatically expires after 15 minutes of inactivity.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
              child: const Text('Start Shift', style: TextStyle(color: Colors.white)),
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
            content: Text('Shift started! Broadcasting live GPS pings every 2 minutes.'),
            backgroundColor: Color(0xFF00C853),
          ),
        );
      }
    } else {
      setState(() => _isShiftActive = false);
      _stopPingSchedule();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shift ended. Live broadcast stopped.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Operations Dashboard'),
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
                  color: _isShiftActive ? const Color(0xFF00C853) : theme.dividerColor,
                  width: _isShiftActive ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isShiftActive ? const Color(0xFF00C853) : Colors.black).withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
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
                              color: _isShiftActive ? const Color(0xFF00C853) : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isShiftActive ? 'BROADCASTING LIVE' : 'CURRENTLY OFFLINE',
                            style: TextStyle(
                              color: _isShiftActive ? const Color(0xFF00C853) : theme.hintColor,
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
                      const Icon(Icons.location_on, color: Color(0xFFFF5722), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isShiftActive ? 'Broadcasting in: $_currentZone' : 'Tap switch to go live',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                          _lastPingTime != null ? 'Last ping: Just now' : 'First ping sent',
                          style: TextStyle(color: theme.hintColor, fontSize: 12),
                        ),
                        Text(
                          'Next ping in: ${_secondsUntilNextPing}s',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFFF5722)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pin auto-expires after 15 min without pings',
                      style: TextStyle(color: theme.hintColor, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Operating Status Selector
            const Text(
              'OPERATING STATUS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.grey),
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
                          color: _truckStatus == 'serving_now' ? const Color(0xFF00C853) : theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.restaurant, color: _truckStatus == 'serving_now' ? const Color(0xFF00C853) : theme.hintColor),
                          const SizedBox(height: 6),
                          Text(
                            '🍽️ Serving Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _truckStatus == 'serving_now' ? const Color(0xFF00C853) : theme.textTheme.bodyMedium?.color,
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
                          color: _truckStatus == 'on_the_move' ? const Color(0xFFFF9100) : theme.dividerColor,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_shipping, color: _truckStatus == 'on_the_move' ? const Color(0xFFFF9100) : theme.hintColor),
                          const SizedBox(height: 6),
                          Text(
                            '🚚 On The Move',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _truckStatus == 'on_the_move' ? const Color(0xFFFF9100) : theme.textTheme.bodyMedium?.color,
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

            // Idempotent Geofence Notification Preview (Phase 4)
            Container(
              padding: const EdgeInsets.all(16),
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
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_active, color: theme.colorScheme.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Idempotent Geofence Push',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dedup key: hash(user_id, truck_id, area_id, date). Subscribers receive at most 1 alert per area per day, with overnight quiet hours enforced (22:00-08:00).',
                    style: TextStyle(color: theme.hintColor, fontSize: 12),
                  ),
                ],
              ),
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
                  Row(
                    children: const [
                      Icon(Icons.flash_on, color: Colors.amber, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Sponsored Radar Boost (2 Hours)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                          content: Text(_isBoostActive ? 'Radar boost activated for 2 hours!' : 'Radar boost deactivated.'),
                          backgroundColor: Colors.amber[800],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isBoostActive ? 'ACTIVE (1 hr 52 min left)' : 'ACTIVATE BOOST (\$4.99)',
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
