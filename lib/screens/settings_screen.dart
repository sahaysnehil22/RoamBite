import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/location_service.dart';

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
  double _alertRadiusMiles = 5.0;
  bool _quietHoursEnabled = true;

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
          // Account Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    auth.isTruckOwner ? '🚚' : '🍔',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.displayName ?? 'RoamBite Member',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (auth.isTruckOwner ? const Color(0xFF00C853) : theme.colorScheme.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          auth.isTruckOwner ? 'TRUCK OWNER / PARTNER' : 'FOODIE EXPLORER',
                          style: TextStyle(
                            color: auth.isTruckOwner ? const Color(0xFF00C853) : theme.colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // APPEARANCE SECTION (Phase 5: Light default, Dark toggleable)
          _buildSectionHeader('APPEARANCE'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: SwitchListTile(
              secondary: Icon(
                themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                color: theme.colorScheme.primary,
              ),
              title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(
                themeProvider.isDarkMode ? 'Dark theme active' : 'Light theme active (Default)',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
              activeThumbColor: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 20),

          // NOTIFICATIONS & GEOFENCING PREFERENCES (Phase 4)
          _buildSectionHeader('ARRIVAL ALERTS & NOTIFICATIONS'),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_active, color: Color(0xFFFF5722)),
                  title: const Text('Area Arrival Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Notify when trucks enter your neighborhood', style: TextStyle(fontSize: 12)),
                  value: _areaAlertsEnabled,
                  onChanged: (val) => setState(() => _areaAlertsEnabled = val),
                  activeThumbColor: theme.colorScheme.primary,
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.radar, color: Color(0xFFFFB300)),
                  title: const Text('Alert Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Within ${_alertRadiusMiles.toStringAsFixed(1)} miles of your location', style: const TextStyle(fontSize: 12)),
                  trailing: DropdownButton<double>(
                    value: _alertRadiusMiles,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 1.0, child: Text('1 mi')),
                      DropdownMenuItem(value: 3.0, child: Text('3 mi')),
                      DropdownMenuItem(value: 5.0, child: Text('5 mi')),
                      DropdownMenuItem(value: 10.0, child: Text('10 mi')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _alertRadiusMiles = val);
                    },
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                SwitchListTile(
                  secondary: const Icon(Icons.bedtime, color: Colors.indigoAccent),
                  title: const Text('Quiet Hours (10 PM – 8 AM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Suppress arrival pushes overnight', style: TextStyle(fontSize: 12)),
                  value: _quietHoursEnabled,
                  onChanged: (val) => setState(() => _quietHoursEnabled = val),
                  activeThumbColor: theme.colorScheme.primary,
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
              leading: const Icon(Icons.location_on, color: Color(0xFFFF5722)),
              title: const Text('Active US Hub', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
              title: const Text('Sign Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Log out of this session', style: TextStyle(fontSize: 12)),
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out of RoamBite?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
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

          // Version info
          Center(
            child: Text(
              'RoamBite v1.1.0+2 • US Food Truck Network',
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
