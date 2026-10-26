import 'package:flutter/material.dart';
import '../screens/explore_screen.dart';
import '../screens/home_dashboard_screen.dart';
import '../screens/radar_discovery_screen.dart';
import '../screens/settings_screen.dart';
import '../services/location_service.dart';
import '../widgets/location_picker_sheet.dart';

class FoodieShell extends StatefulWidget {
  const FoodieShell({super.key});

  @override
  State<FoodieShell> createState() => _FoodieShellState();
}

class _FoodieShellState extends State<FoodieShell> {
  // Phase 1: Cold start lands on Home (Index 0), NEVER on radar/scan
  int _currentIndex = 0;
  UserLocation _currentLocation = UserLocation.defaultMiami; // Slice 4: demo logins land on the Miami hub.

  void _openLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPickerSheet(
        currentLocation: _currentLocation,
        onLocationSelected: (loc) {
          setState(() => _currentLocation = loc);
        },
      ),
    );
  }

  void _switchToRadarTab() {
    setState(() => _currentIndex = 2); } void _browseMiamiDemo() { setState(() { _currentLocation = UserLocation.defaultMiami; _currentIndex = 0; }); // Radar is Tab Index 2
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        currentLocation: _currentLocation,
        onOpenLocationPicker: _openLocationPicker,
        onSwitchToRadar: _switchToRadarTab, onBrowseMiamiDemo: _browseMiamiDemo,
      ),
      ExploreScreen(
        currentLocation: _currentLocation,
        onOpenLocationPicker: _openLocationPicker,
      ),
      RadarDiscoveryScreen(
        currentLocation: _currentLocation,
        onOpenLocationPicker: _openLocationPicker,
      ),
      SettingsScreen(
        currentLocation: _currentLocation,
        onOpenLocationPicker: _openLocationPicker,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.radar_outlined),
            selectedIcon: Icon(Icons.radar),
            label: 'Radar',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
