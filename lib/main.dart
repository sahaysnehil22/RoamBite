import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/explore_screen.dart';
import 'screens/owner_dashboard_screen.dart';
import 'screens/radar_discovery_screen.dart';
import 'services/location_service.dart';
import 'widgets/location_picker_sheet.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const RoamBiteApp());
}

class RoamBiteApp extends StatelessWidget {
  const RoamBiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoamBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1017),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFFFFB800),
          surface: Color(0xFF141722),
        ),
        useMaterial3: true,
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  UserLocation _currentLocation = UserLocation.defaultMiami;

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        currentLocation: _currentLocation,
        onLocationSelected: (location) {
          setState(() => _currentLocation = location);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location updated to ${location.label} (${location.city}, ${location.state})'),
              backgroundColor: const Color(0xFFFF6B00),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      RadarDiscoveryScreen(
        currentLocation: _currentLocation,
        onOpenLocationPicker: _openLocationPicker,
      ),
      ExploreScreen(
        currentLocation: _currentLocation,
        onOpenLocationPicker: _openLocationPicker,
      ),
      const OwnerDashboardScreen(),
      _buildProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12151F),
          border: const Border(top: BorderSide(color: Colors.white10, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.transparent,
          indicatorColor: const Color(0xFFFF6B00).withOpacity(0.2),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.radar_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.radar, color: Color(0xFFFF6B00)),
              label: 'Radar',
            ),
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.storefront, color: Color(0xFFFF6B00)),
              label: 'Explore',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined, color: Colors.white54),
              selectedIcon: Icon(Icons.local_shipping, color: Color(0xFFFF6B00)),
              label: 'Truck Mode',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.white54),
              selectedIcon: Icon(Icons.person, color: Color(0xFFFF6B00)),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1017),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141722),
        elevation: 0,
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFFF6B00),
                child: Text('RB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RoamBite Foodie', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 2),
                  Text('Active in ${_currentLocation.label}', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text('APP PREFERENCES', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          _buildSettingsTile(
            Icons.location_on_outlined,
            'Selected Location',
            '${_currentLocation.label} (${_currentLocation.city}, ${_currentLocation.state})',
            onTap: _openLocationPicker,
          ),
          _buildSettingsTile(
            Icons.notifications_active_outlined,
            'Area-Entry Alerts',
            'Get notified when food trucks enter your area',
            isSwitch: true,
          ),
          _buildSettingsTile(
            Icons.flag_outlined,
            'Region Scope',
            'United States (US Only)',
          ),
          _buildSettingsTile(
            Icons.straighten_outlined,
            'Distance Units',
            'Miles (mi)',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isSwitch = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Material(
        color: const Color(0xFF161A24),
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFFFF6B00)),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          trailing: isSwitch
              ? Switch(value: true, onChanged: (_) {}, activeColor: const Color(0xFFFF6B00))
              : const Icon(Icons.chevron_right, color: Colors.white24),
          onTap: onTap,
        ),
      ),
    );
  }
}
