import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  bool get isLoading => _isLoading;
  bool get isSignedIn => _isSignedIn;
  UserRole get role => _role;
  bool get isTruckOwner => _role == UserRole.truckOwner;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  String? get email => _email;
  String? get displayName => _displayName;

  AuthProvider() {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSignedIn = prefs.getBool('roambite_signed_in') ?? false;
      final savedRoleStr = prefs.getString('roambite_user_role') ?? 'foodie';
      _userId = prefs.getString('roambite_user_id') ?? 'local_user';
      _displayName = prefs.getString('roambite_display_name') ?? 'RoamBite Member';

      _isSignedIn = savedSignedIn;
      _role = savedRoleStr == 'truck_owner' ? UserRole.truckOwner : UserRole.foodie;

      // Verify with Supabase if configured
      final supaClient = SupabaseService().client;
      if (supaClient != null && supaClient.auth.currentUser != null) {
        final current = supaClient.auth.currentUser!;
        _isSignedIn = true;
        _userId = current.id;
        _phoneNumber = current.phone;
        _email = current.email;
        final serverRole = await SupabaseService().getUserRole(current.id);
        if (serverRole != null) {
          _role = serverRole == 'truck_owner' ? UserRole.truckOwner : UserRole.foodie;
        }
      }
    } catch (e) {
      debugPrint('Auth initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign In with Google
  Future<void> signInWithGoogle(UserRole selectedRole) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (SupabaseConfig.isConfigured) {
        await SupabaseService().signInWithGoogle();
      } else {
        // Fallback for demo when backend credentials are pending
        await _setLocalSession(
          id: 'demo_google_user',
          role: selectedRole,
          name: 'Google User',
        );
      }
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
      // Demo simulated OTP succeeds
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
        final res = await SupabaseService().verifyPhoneOtp(phone: _phoneNumber!, token: token);
        if (res.user != null) {
          _userId = res.user!.id;
          final roleStr = chosenRole == UserRole.truckOwner ? 'truck_owner' : 'foodie';
          await SupabaseService().setProfileRole(
            userId: res.user!.id,
            role: roleStr,
            phone: _phoneNumber,
          );
        }
      }

      await _setLocalSession(
        id: _userId ?? 'phone_user_${DateTime.now().millisecondsSinceEpoch}',
        role: chosenRole,
        name: chosenRole == UserRole.truckOwner ? 'Food Truck Partner' : 'Foodie Explorer',
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

    await _setLocalSession(
      id: chosenRole == UserRole.truckOwner ? 'demo_owner_111' : 'demo_foodie_222',
      role: chosenRole,
      name: chosenRole == UserRole.truckOwner ? 'Taco Trail Partner' : 'Miami Foodie',
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
    await prefs.setString('roambite_user_role', role == UserRole.truckOwner ? 'truck_owner' : 'foodie');
    await prefs.setString('roambite_user_id', id);
    await prefs.setString('roambite_display_name', name);
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

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
