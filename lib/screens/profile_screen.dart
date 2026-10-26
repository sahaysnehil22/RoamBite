import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';

// Slice 3: Profile screen for the signed-in user.
// Shows the display name and contact details from AuthProvider, an
// Appearance section backed by the existing ThemeProvider, and the
// existing sign-out flow. No new persistence mechanism is introduced.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String? displayName) {
    final parts = (displayName ?? '').trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final displayName = auth.displayName ?? 'RoamBite Member';
    final email = auth.email;
    final phone = auth.phoneNumber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    _initials(displayName),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (auth.isTruckOwner ? const Color(0xFF00C853) : theme.colorScheme.primary).withValues(alpha: 0.15),
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
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email, size: 16, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(email, style: TextStyle(color: theme.hintColor, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
                if (phone != null && phone.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone, size: 16, color: theme.hintColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(phone, style: TextStyle(color: theme.hintColor, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
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
                  title: const Text('Light', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Always use the light theme', style: TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.light_mode, color: Color(0xFFFF5722)),
                  value: ThemeMode.light,
                  groupValue: themeProvider.themeMode,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                RadioListTile<ThemeMode>(
                  title: const Text('Dark', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Always use the dark theme', style: TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.dark_mode, color: Color(0xFFFF5722)),
                  value: ThemeMode.dark,
                  groupValue: themeProvider.themeMode,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (mode) {
                    if (mode != null) themeProvider.setThemeMode(mode);
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),
                RadioListTile<ThemeMode>(
                  title: const Text('System', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Follow the device theme', style: TextStyle(fontSize: 12)),
                  secondary: const Icon(Icons.settings_suggest, color: Color(0xFFFF5722)),
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
          Center(
            child: Text(
              'RoamBite v1.1.0+2 - US Food Truck Network',
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
