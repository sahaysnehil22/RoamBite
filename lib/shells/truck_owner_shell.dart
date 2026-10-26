import 'package:flutter/material.dart';
import '../screens/menu_editor_screen.dart';
import '../screens/owner_dashboard_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/visitor_stats_screen.dart';
import '../services/location_service.dart';
import '../widgets/location_picker_sheet.dart';

class TruckOwnerShell extends StatefulWidget {
  const TruckOwnerShell({super.key});

  @override
  State<TruckOwnerShell> createState() => _TruckOwnerShellState();
}

class _TruckOwnerShellState extends State<TruckOwnerShell> {
  int _currentIndex = 0;
  UserLocation _currentLocation = UserLocation.defaultMiami;

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

  @override
  Widget build(BuildContext context) {
    final screens = [
      const OwnerDashboardScreen(),
      const MenuEditorScreen(),
      const VisitorStatsScreen(),
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Shift Ops',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
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
