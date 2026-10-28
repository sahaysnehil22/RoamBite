import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/media_picker_sheet.dart';

// Zomato-style Profile Overview & "Your Profile" Editor screen.
// Preserves ThemeProvider (Light/Dark/System) and AuthProvider sign-out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _firstInitial(String? displayName) {
    final trimmed = (displayName ?? '').trim();
    if (trimmed.isEmpty) return 'S';
    return trimmed[0].toUpperCase();
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final displayName = auth.displayName ?? 'Snehil Sahay';
    final firstName = displayName.trim().split(RegExp(r'\s+')).first;
    final avatarUrl = auth.avatarUrl;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF5F6FB)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          // Top Zomato-Style Profile Card + Gold Bar
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFD2E3FC),
                        backgroundImage:
                            (avatarUrl != null && avatarUrl.isNotEmpty)
                                ? NetworkImage(avatarUrl)
                                : null,
                        child: (avatarUrl == null || avatarUrl.isEmpty)
                            ? Text(
                                _firstInitial(displayName),
                                style: const TextStyle(
                                  color: Color(0xFF174EA6),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 28,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Edit profile',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Dark Gold Membership Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  color: const Color(0xFF141416),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3A2E18),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          color: Color(0xFFE5B869),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          auth.isTruckOwner
                              ? 'RoamBite Partner • Verified Truck Owner'
                              : 'RoamBite Gold Member • Zero Wait Perks',
                          style: const TextStyle(
                            color: Color(0xFFE5B869),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFE5B869),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Quick Wallet & Perks Row
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined,
                            size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RoamBite Credits',
                              style: TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              r'$0',
                              style: TextStyle(
                                color: Color(0xFF00C853),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_offer_outlined, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Your coupons',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Your Preferences Card
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Your preferences',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  secondary: const Icon(
                    Icons.eco,
                    color: Color(0xFF1E8E3E),
                  ),
                  title: const Text(
                    'Veg Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    auth.vegMode ? 'Showing vegetarian options' : 'Off',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  value: auth.vegMode,
                  activeThumbColor: const Color(0xFF1E8E3E),
                  onChanged: (val) => auth.setVegMode(val),
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading: Icon(
                    Icons.palette_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    'Appearance',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _themeLabel(themeProvider.themeMode),
                        style: TextStyle(color: theme.hintColor, fontSize: 13),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right, color: theme.hintColor),
                    ],
                  ),
                  onTap: () => _showAppearanceSheet(context, themeProvider),
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    'Edit personal details',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  trailing: Icon(Icons.chevron_right, color: theme.hintColor),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Street Truck Discovery Section
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Food truck discovery',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.rate_review_outlined),
                  title: const Text(
                    'Your truck reviews & videos',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  trailing: Icon(Icons.chevron_right, color: theme.hintColor),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading: const Icon(Icons.bookmark_border),
                  title: const Text(
                    'Your collections',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  trailing: Icon(Icons.chevron_right, color: theme.hintColor),
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Divider(height: 1, color: theme.dividerColor),
                ListTile(
                  leading:
                      const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Log out of this session',
                    style: TextStyle(fontSize: 12),
                  ),
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
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await authProvider.signOut();
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
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

  void _showAppearanceSheet(
      BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Appearance',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Light'),
                secondary:
                    const Icon(Icons.light_mode, color: Color(0xFFFF5722)),
                value: ThemeMode.light,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  if (mode != null) themeProvider.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark'),
                secondary:
                    const Icon(Icons.dark_mode, color: Color(0xFFFF5722)),
                value: ThemeMode.dark,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  if (mode != null) themeProvider.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System'),
                secondary: const Icon(Icons.settings_suggest,
                    color: Color(0xFFFF5722)),
                value: ThemeMode.system,
                groupValue: themeProvider.themeMode,
                onChanged: (mode) {
                  if (mode != null) themeProvider.setThemeMode(mode);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Zomato-style "Your Profile" editor screen matching the user's screenshot:
/// Top circular avatar with edit badge, Name, Mobile, Email, Date of birth,
/// Anniversary, Gender dropdown, and "Update profile" button.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _anniversaryCtrl;
  String _selectedGender = 'Male';
  String _avatarUrl = '';

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nameCtrl = TextEditingController(text: auth.displayName ?? 'Snehil Sahay');
    _mobileCtrl =
        TextEditingController(text: auth.phoneNumber ?? '7543917249');
    _emailCtrl = TextEditingController(
        text: auth.email ?? 'snehil.sahay@roambite.com');
    _dobCtrl = TextEditingController(text: auth.dateOfBirth ?? '');
    _anniversaryCtrl = TextEditingController(text: auth.anniversary ?? '');
    _selectedGender =
        ['Male', 'Female', 'Other', 'Prefer not to say']
                .contains(auth.gender)
            ? auth.gender!
            : 'Male';
    _avatarUrl = auth.avatarUrl ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _anniversaryCtrl.dispose();
    super.dispose();
  }

  String _firstInitial(String text) {
    final t = text.trim();
    if (t.isEmpty) return 'S';
    return t[0].toUpperCase();
  }

  Future<void> _openAvatarPickerSheet() async {
    final picked = await showRoamBiteMediaPicker(
      context,
      title: 'Upload Profile Photo (Camera or Gallery)',
      allowVideo: false,
    );
    if (picked != null && mounted) {
      setState(() => _avatarUrl = picked.url);
    }
  }

  Future<void> _saveProfile() async {
    await context.read<AuthProvider>().updateUserProfile(
          displayName: _nameCtrl.text,
          phoneNumber: _mobileCtrl.text,
          email: _emailCtrl.text,
          dateOfBirth: _dobCtrl.text,
          anniversary: _anniversaryCtrl.text,
          gender: _selectedGender,
          avatarUrl: _avatarUrl,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.light
          ? const Color(0xFFF5F6FB)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Your Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 52),
                    padding: const EdgeInsets.fromLTRB(16, 68, 16, 24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Name Field
                        TextField(
                          controller: _nameCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Name',
                            suffixIcon: _nameCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel, size: 18),
                                    onPressed: () =>
                                        setState(() => _nameCtrl.clear()),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Mobile Field
                        TextField(
                          controller: _mobileCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Mobile',
                            suffixIcon: TextButton(
                              onPressed: () {},
                              child: Text(
                                'CHANGE',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            suffixIcon: TextButton(
                              onPressed: () {},
                              child: Text(
                                'CHANGE',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date of birth Field
                        TextField(
                          controller: _dobCtrl,
                          decoration: InputDecoration(
                            labelText: 'Date of birth',
                            hintText: 'DD/MM/YYYY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Anniversary Field
                        TextField(
                          controller: _anniversaryCtrl,
                          decoration: InputDecoration(
                            labelText: 'Anniversary',
                            hintText: 'DD/MM/YYYY',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gender Dropdown
                        DropdownButtonFormField<String>(
                          initialValue: _selectedGender,
                          decoration: InputDecoration(
                            labelText: 'Gender',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Male', child: Text('Male')),
                            DropdownMenuItem(
                                value: 'Female', child: Text('Female')),
                            DropdownMenuItem(
                                value: 'Other', child: Text('Other')),
                            DropdownMenuItem(
                              value: 'Prefer not to say',
                              child: Text('Prefer not to say'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedGender = val);
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Top Overlapping Circular Avatar + Edit Badge
                  Positioned(
                    top: 0,
                    child: GestureDetector(
                      onTap: _openAvatarPickerSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 48,
                              backgroundColor: const Color(0xFFD2E3FC),
                              backgroundImage: _avatarUrl.isNotEmpty
                                  ? NetworkImage(_avatarUrl)
                                  : null,
                              child: _avatarUrl.isEmpty
                                  ? Text(
                                      _firstInitial(_nameCtrl.text),
                                      style: const TextStyle(
                                        color: Color(0xFF174EA6),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 38,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom "Update profile" Button Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surface,
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveProfile,
                  child: const Text(
                    'Update profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
