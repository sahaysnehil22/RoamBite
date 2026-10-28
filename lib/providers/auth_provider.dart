import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

enum UserRole { foodie, truckOwner }

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSignedIn = false;
  UserRole _role = UserRole.foodie;
  String? _userId;
  String? _phoneNumber;
  String? _email;
  String? _displayName;
  String? _dateOfBirth;
  String? _anniversary;
  String? _gender;
  String? _avatarUrl;
  bool _vegMode = false;
  UserRole? _pendingGoogleRole;
  StreamSubscription<AuthState>? _authSubscription;
  StreamSubscription<Uri>? _linkSubscription;
  final AppLinks _appLinks = AppLinks();

  bool get isLoading => _isLoading;
  bool get isSignedIn => _isSignedIn;
  bool get isAuthenticated => _isSignedIn;

  UserRole get role => _role;
  bool get isTruckOwner => _role == UserRole.truckOwner;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  String? get email => _email;
  String? get displayName => _displayName;
  String? get dateOfBirth => _dateOfBirth;
  String? get anniversary => _anniversary;
  String? get gender => _gender;
  String? get avatarUrl => _avatarUrl;
  bool get vegMode => _vegMode;

  AuthProvider() {
    _listenToAuthChanges();
    _listenToDeepLinks();
    _checkInitialAuth();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  /// Listen for Supabase auth events so a Google sign-in that completes in
  /// the browser lands in the app without an app restart.
  void _listenToAuthChanges() {
    try {
      final client = SupabaseService().client;
      if (client == null) return;
      _authSubscription = client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn ||
            data.event == AuthChangeEvent.tokenRefreshed) {
          final user = data.session?.user;
          if (user != null) {
            await _applySupabaseUser(user);
          }
        } else if (data.event == AuthChangeEvent.signedOut) {
          _isSignedIn = false;
          _isLoading = false;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Auth state listener error: $e');
    }
  }

  /// Listen for the OAuth return link, both while the app is running and
  /// as the initial link when the app is (re)launched from the browser.
  void _listenToDeepLinks() {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleLoginCallback,
      onError: (Object e) => debugPrint('Deep link error: $e'),
    );
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleLoginCallback(uri);
    }).catchError((Object e) {
      debugPrint('Initial link error: $e');
    });
  }

  /// Handle com.roambite.roambite://login-callback: exchange a PKCE code
  /// when one is present, otherwise re-check/refresh the Supabase session,
  /// then apply the signed-in user in the same session.
  Future<void> _handleLoginCallback(Uri uri) async {
    if (uri.scheme != 'com.roambite.roambite' ||
        uri.host != 'login-callback') {
      return;
    }
    final client = SupabaseService().client;
    if (client == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        try {
          final exchanged = await client.auth.exchangeCodeForSession(code);
          final exchangedUser = exchanged.session?.user;
          if (exchangedUser != null) {
            await _applySupabaseUser(exchangedUser);
            return;
          }
        } catch (e) {
          debugPrint(
              'OAuth code exchange failed, falling back to session check: $e');
        }
      }
      var user = client.auth.currentUser;
      if (user == null) {
        try {
          final refreshed = await client.auth.refreshSession();
          user = refreshed.session?.user ?? client.auth.currentUser;
        } catch (_) {
          user = client.auth.currentUser;
        }
      }
      if (user != null) {
        await _applySupabaseUser(user);
      }
    } catch (e) {
      debugPrint('Login callback handling error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Apply a Supabase user to this provider, persisting the session the
  /// same way the startup check does, and persisting the role the user
  /// picked for a Google sign-in.
  Future<void> _applySupabaseUser(User user) async {
    _isSignedIn = true;
    _userId = user.id;
    _phoneNumber = user.phone ?? _phoneNumber;
    _email = user.email ?? _email;
    var role = _role;
    final serverRole = await SupabaseService().getUserRole(user.id);
    if (serverRole != null) {
      role = serverRole == 'truck_owner' ? UserRole.truckOwner : UserRole.foodie;
    }
    final metadata = user.userMetadata;
    final metadataName = metadata == null
        ? null
        : (metadata['full_name'] ?? metadata['name']);
    final name = metadataName is String && metadataName.isNotEmpty
        ? metadataName
        : (_displayName ?? 'RoamBite Member');
    final pendingRole = _pendingGoogleRole;
    if (pendingRole != null) {
      role = pendingRole;
      _pendingGoogleRole = null;
      final roleStr = role == UserRole.truckOwner ? 'truck_owner' : 'foodie';
      try {
        await SupabaseService().setProfileRole(
          userId: user.id,
          role: roleStr,
          displayName: name,
        );
      } catch (e) {
        debugPrint('Persisting Google role failed: $e');
      }
    }
    await _setLocalSession(id: user.id, role: role, name: name);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _checkInitialAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSignedIn = prefs.getBool('roambite_signed_in') ?? false;
      final savedRoleStr = prefs.getString('roambite_user_role') ?? 'foodie';
      _userId = prefs.getString('roambite_user_id') ?? 'local_user';
      _displayName =
          prefs.getString('roambite_display_name') ?? 'Snehil Sahay';
      _phoneNumber = prefs.getString('roambite_phone_number') ?? '7543917249';
      _email = prefs.getString('roambite_email') ?? 'snehil.sahay@roambite.com';
      _dateOfBirth = prefs.getString('roambite_dob') ?? '';
      _anniversary = prefs.getString('roambite_anniversary') ?? '';
      _gender = prefs.getString('roambite_gender') ?? 'Male';
      _avatarUrl = prefs.getString('roambite_avatar_url');
      _vegMode = prefs.getBool('roambite_veg_mode') ?? false;

      _isSignedIn = savedSignedIn;
      _role =
          savedRoleStr == 'truck_owner' ? UserRole.truckOwner : UserRole.foodie;

      // Verify with Supabase if configured
      final supaClient = SupabaseService().client;
      if (supaClient != null && supaClient.auth.currentUser != null) {
        final current = supaClient.auth.currentUser!;
        _isSignedIn = true;
        _userId = current.id;
        _phoneNumber = current.phone ?? _phoneNumber;
        _email = current.email ?? _email;
        final serverRole = await SupabaseService().getUserRole(current.id);
        if (serverRole != null) {
          _role = serverRole == 'truck_owner'
              ? UserRole.truckOwner
              : UserRole.foodie;
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile fields (Name, Mobile, Email, DOB, Anniversary, Gender, Avatar)
  Future<void> updateUserProfile({
    required String displayName,
    String? phoneNumber,
    String? email,
    String? dateOfBirth,
    String? anniversary,
    String? gender,
    String? avatarUrl,
  }) async {
    _displayName = displayName.trim().isNotEmpty
        ? displayName.trim()
        : (_displayName ?? 'RoamBite Member');
    if (phoneNumber != null) _phoneNumber = phoneNumber.trim();
    if (email != null) _email = email.trim();
    if (dateOfBirth != null) _dateOfBirth = dateOfBirth.trim();
    if (anniversary != null) _anniversary = anniversary.trim();
    if (gender != null) _gender = gender.trim();
    if (avatarUrl != null) _avatarUrl = avatarUrl.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roambite_display_name', _displayName!);
    if (_phoneNumber != null) {
      await prefs.setString('roambite_phone_number', _phoneNumber!);
    }
    if (_email != null) {
      await prefs.setString('roambite_email', _email!);
    }
    if (_dateOfBirth != null) {
      await prefs.setString('roambite_dob', _dateOfBirth!);
    }
    if (_anniversary != null) {
      await prefs.setString('roambite_anniversary', _anniversary!);
    }
    if (_gender != null) {
      await prefs.setString('roambite_gender', _gender!);
    }
    if (_avatarUrl != null) {
      await prefs.setString('roambite_avatar_url', _avatarUrl!);
    }

    if (SupabaseConfig.isConfigured && _userId != null) {
      try {
        await SupabaseService().setProfileRole(
          userId: _userId!,
          role: _role == UserRole.truckOwner ? 'truck_owner' : 'foodie',
          displayName: _displayName,
          phone: _phoneNumber,
        );
      } catch (e) {
        debugPrint('Profile sync warning: $e');
      }
    }
    notifyListeners();
  }

  Future<void> setVegMode(bool enabled) async {
    _vegMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('roambite_veg_mode', enabled);
    notifyListeners();
  }

  Future<void> selectRole(String role) async {
    _role = role == 'truck_owner' ? UserRole.truckOwner : UserRole.foodie;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roambite_user_role', _role == UserRole.truckOwner ? 'truck_owner' : 'foodie');
    notifyListeners();
  }
  

  /// Sign In with Google
  Future<void> signInWithGoogle(UserRole selectedRole) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        _pendingGoogleRole = selectedRole;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'roambite_user_role',
            selectedRole == UserRole.truckOwner ? 'truck_owner' : 'foodie');
        await SupabaseService().signInWithGoogle();
      } else {
        await _setLocalSession(
          id: 'demo_google_user',
          role: selectedRole,
          name: 'Snehil Sahay',
        );
      }
    } catch (e) {
      _pendingGoogleRole = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Request Phone OTP
  Future<void> requestPhoneOtp(String phone) async {
    _isLoading = true;
    _phoneNumber = phone;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        await SupabaseService().signInWithPhone(phone);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verify Phone OTP & assign chosen role
  Future<void> verifyOtpAndLogin({
    required String token,
    required UserRole chosenRole,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured && _phoneNumber != null) {
        final res = await SupabaseService()
            .verifyPhoneOtp(phone: _phoneNumber!, token: token);
        if (res.user != null) {
          _userId = res.user!.id;
          final roleStr =
              chosenRole == UserRole.truckOwner ? 'truck_owner' : 'foodie';
          await SupabaseService().setProfileRole(
            userId: res.user!.id,
            role: roleStr,
            phone: _phoneNumber,
          );
        }
      }

      _pendingGoogleRole = null;
      await _setLocalSession(
        id: _userId ?? 'phone_user_${DateTime.now().millisecondsSinceEpoch}',
        role: chosenRole,
        name: chosenRole == UserRole.truckOwner
            ? 'Food Truck Partner'
            : 'Snehil Sahay',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick Demo / Guest Login for development & testability
  Future<void> demoLogin(UserRole chosenRole) async {
    _isLoading = true;
    notifyListeners();

    _pendingGoogleRole = null;
    await _setLocalSession(
      id: chosenRole == UserRole.truckOwner
          ? 'demo_owner_111'
          : 'demo_foodie_222',
      role: chosenRole,
      name: chosenRole == UserRole.truckOwner
          ? 'Taco Trail Partner'
          : 'Snehil Sahay',
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _setLocalSession({
    required String id,
    required UserRole role,
    required String name,
  }) async {
    _isSignedIn = true;
    _userId = id;
    _role = role;
    _displayName = name;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('roambite_signed_in', true);
    await prefs.setString('roambite_user_role',
        role == UserRole.truckOwner ? 'truck_owner' : 'foodie');
    await prefs.setString('roambite_user_id', id);
    await prefs.setString('roambite_display_name', name);
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    _pendingGoogleRole = null;
    await SupabaseService().signOut();
    _isSignedIn = false;
    _userId = null;
    _phoneNumber = null;
    _email = null;
    _displayName = null;
    _role = UserRole.foodie;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('roambite_signed_in', false);
    await prefs.remove('roambite_user_id');
    await prefs.remove('roambite_user_role');
    await prefs.remove('roambite_display_name');

    _isLoading = false;
    notifyListeners();
  }
}
