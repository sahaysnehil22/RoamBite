import 'package:flutter/material.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _isShiftActive = true;
  String _truckStatus = 'Serving now'; // 'Serving now' or 'On the move'
  bool _isBoostActive = false;
  final String _currentZone = 'Wynwood, Miami, FL';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141722),
        elevation: 0,
        title: const Text(
          'Owner Dashboard: Taco Trail',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Status Hero Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isShiftActive
                      ? [const Color(0xFF1B2B1F), const Color(0xFF121B15)]
                      : [const Color(0xFF2B1B1B), const Color(0xFF1B1212)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isShiftActive ? const Color(0xFF00E676).withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
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
                              color: _isShiftActive ? const Color(0xFF00E676) : Colors.redAccent,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isShiftActive ? 'LIVE LOCATION BROADCASTING' : 'OFFLINE',
                            style: TextStyle(
                              color: _isShiftActive ? const Color(0xFF00E676) : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isShiftActive,
                        onChanged: (val) {
                          setState(() => _isShiftActive = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(val ? 'Shift started! You are now live.' : 'Shift ended. Broadcast stopped.')),
                          );
                        },
                        activeColor: const Color(0xFF00E676),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFFF6B00), size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isShiftActive ? 'Active in: $_currentZone' : 'No active zone broadcast',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Operating Status Selector
            const Text(
              'TRUCK STATUS',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _truckStatus = 'Serving now'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _truckStatus == 'Serving now' ? const Color(0xFF00E676).withOpacity(0.18) : const Color(0xFF161A24),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _truckStatus == 'Serving now' ? const Color(0xFF00E676) : Colors.white12,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.restaurant, color: _truckStatus == 'Serving now' ? const Color(0xFF00E676) : Colors.white54),
                          const SizedBox(height: 6),
                          Text(
                            '🍽️ Serving Now',
                            style: TextStyle(
                              color: _truckStatus == 'Serving now' ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
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
                    onTap: () => setState(() => _truckStatus = 'On the move'),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _truckStatus == 'On the move' ? const Color(0xFFFF9100).withOpacity(0.18) : const Color(0xFF161A24),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _truckStatus == 'On the move' ? const Color(0xFFFF9100) : Colors.white12,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.local_shipping, color: _truckStatus == 'On the move' ? const Color(0xFFFF9100) : Colors.white54),
                          const SizedBox(height: 6),
                          Text(
                            '🚚 On The Move',
                            style: TextStyle(
                              color: _truckStatus == 'On the move' ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Area-Entry Notification Status (Simulated Push Engine)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161A24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B00).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_active, color: Color(0xFFFF6B00), size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Area-Entry Geofence Alert',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'When your truck crosses the Wynwood boundary, 1,420 subscribers receive a push notification:',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2433),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_read, color: Color(0xFF00E676), size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '"Taco Trail entered Wynwood! Fresh birria is serving now."',
                            style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pokémon GO Lure-Style Sponsored Pin
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2A2012), Color(0xFF1B160E)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB800).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFFFFB800), size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Boost Pin (Lure Promotion)',
                        style: TextStyle(color: Color(0xFFFFB800), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Promote your truck with a glowing amber beacon on nearby radar scans for 2 hours to attract more foot traffic.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isBoostActive = !_isBoostActive);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isBoostActive ? 'Boost pin activated for 2 hours!' : 'Boost pin deactivated.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB800),
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      _isBoostActive ? 'ACTIVE (1 hr 45 min left)' : 'ACTIVATE BOOST (\$4.99)',
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
