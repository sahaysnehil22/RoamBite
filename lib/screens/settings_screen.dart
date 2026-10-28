import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final UserLocation currentLocation;
  final VoidCallback onOpenLocationPicker;

  const SettingsScreen({
    super.key,
    required this.currentLocation,
    required this.onOpenLocationPicker,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _areaAlertsEnabled = true;
  double _alertRadiusMiles = 2.0;
  bool _quietHoursEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadAlertSettings();
  }

  Future<void> _loadAlertSettings() async {
    final cfg = await SupabaseService().loadAlertRadiusSettings();
    if (!mounted) return;
    setState(() {
      _areaAlertsEnabled = cfg.enabled;
      _alertRadiusMiles =
          [0.5, 1.0, 2.0, 5.0].contains(cfg.radiusMiles) ? cfg.radiusMiles : 2.0;
      _quietHoursEnabled = cfg.quietHoursEnabled;
    });
  }

  Future<void> _saveAlertSettings() async {
    await SupabaseService().saveAlertRadiusSettings(
      enabled: _areaAlertsEnabled,
      radiusMiles: _alertRadiusMiles,
      quietHoursEnabled: _quietHoursEnabled,
      userLat: widget.currentLocation.latitude,
      userLng: widget.currentLocation.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Account Profile Card - taps through to the Profile screen.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    backgroundImage: (auth.avatarUrl != null &&
                            auth.avatarUrl!.isNotEmpty)
                        ? NetworkImage(auth.avatarUrl!)
                        : null,
                    child: (auth.avatarUrl == null || auth.avatarUrl!.isEmpty)
                        ? Icon(
                            auth.isTruckOwner
                                ? Icons.local_shipping
                                : Icons.restaurant,
                            color: Colors.white,
                            size: 26,
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.displayName ?? 'RoamBite Member',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (auth.isTruckOwner
                                    ? const Color(0xFF00C853)
                                    : theme.colorScheme.primary)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            auth.isTruckOwner
                                ? 'TRUCK OWNER / PARTNER'
                                : 'FOODIE EXPLORER',
                            style: TextStyle(
                              color: auth.isTruckOwner
                                  ? const Color(0xFF00C853)
                                  : theme.colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // APPEARANCE SECTION (Light / Dark / System, persisted by ThemeProvider)
          _buildSectionHeader('APPEARANCE'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: const Text('Light',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Always use the light theme',
                      style: TextStyle(fontSize: 12)),
                  secondary:
                      const Icon(Icons.light_mode, color: Color(0xFFFF5722)),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Always use the dark theme',
                      style: TextStyle(fontSize: 12)),
                  secondary:
                      const Icon(Icons.dark_mode, color: Color(0xFFFF5722)),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                RadioListTile<ThemeMode>(
                  title: const Text('System',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Follow the device theme',
                      style: TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.settings_suggest,
                      color: Color(0xFFFF5722)),
                  value: ThemeMode.system,
                  groupValue: themeProvider.themeMode,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // NOTIFICATIONS & GEOFENCING PREFERENCES
          _buildSectionHeader('ARRIVAL ALERTS & PROXIMITY GEOFENCE'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active,
                      color: Color(0xFFFF5722)),
                  title: const Text('Area Arrival Alerts',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text(
                      'Notify when trucks enter your alert radius',
                      style: TextStyle(fontSize: 12)),
                  value: _areaAlertsEnabled,
                  onChanged: (val) {
                    setState(() => _areaAlertsEnabled = val);
                    _saveAlertSettings();
                  },
                  activeThumbColor: theme.colorScheme.primary,
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.radar, color: Color(0xFFFFB300)),
                  title: const Text('Alert Radius',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                      'Within ${_alertRadiusMiles.toStringAsFixed(1)} miles of your location',
                      style: const TextStyle(fontSize: 12)),
                  trailing: DropdownButton<double>(
                    value: _alertRadiusMiles,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 0.5, child: Text('0.5 mi')),
                      DropdownMenuItem(value: 1.0, child: Text('1.0 mi')),
                      DropdownMenuItem(value: 2.0, child: Text('2.0 mi')),
                      DropdownMenuItem(value: 5.0, child: Text('5.0 mi')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _alertRadiusMiles = val);
                        _saveAlertSettings();
                      }
                    },
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                SwitchListTile(
                  secondary:
                      const Icon(Icons.bedtime, color: Colors.indigoAccent),
                  title: const Text('Quiet Hours (10 PM - 8 AM)',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Suppress arrival pushes overnight',
                      style: TextStyle(fontSize: 12)),
                  value: _quietHoursEnabled,
                  onChanged: (val) {
                    setState(() => _quietHoursEnabled = val);
                    _saveAlertSettings();
                  },
                  activeThumbColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // DIETARY & ROLE PREFERENCES
          _buildSectionHeader('DIETARY & ROLE'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary:
                      const Icon(Icons.eco, color: Color(0xFF00C853)),
                  title: const Text('Veg Mode',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text(
                      'Filter food trucks & menus for vegetarian dishes',
                      style: TextStyle(fontSize: 12)),
                  value: auth.vegMode,
                  onChanged: (val) => auth.setVegMode(val),
                  activeThumbColor: const Color(0xFF00C853),
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.swap_horiz,
                      color: Color(0xFFFF5722)),
                  title: Text(
                    auth.isTruckOwner
                        ? 'Switch to Foodie Explorer View'
                        : 'Switch to Truck Owner Dashboard',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Toggle between customer discovery and truck operations',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    auth.selectRole(
                        auth.isTruckOwner ? 'foodie' : 'truck_owner');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // LOCATION SETTINGS
          _buildSectionHeader('LOCATION'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListTile(
              leading:
                  const Icon(Icons.location_on, color: Color(0xFFFF5722)),
              title: const Text('Active US Hub',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                '${widget.currentLocation.label} (${widget.currentLocation.city}, ${widget.currentLocation.state})',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onOpenLocationPicker,
            ),
          ),
          const SizedBox(height: 20),
          // SESSION & LOGOUT
          _buildSectionHeader('ACCOUNT'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text('Sign Out',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              subtitle: const Text('Log out of this session',
                  style: TextStyle(fontSize: 12)),
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text(
                        'Are you sure you want to sign out of RoamBite?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent),
                        child: const Text('Sign Out',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authProvider.signOut();
                }
              },
            ),
          ),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'RoamBite v1.2.0+3 - US Food Truck Network',
              style: TextStyle(color: theme.hintColor, fontSize: 11),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Colors.grey,
        ),
      ),
    );
  }
}
