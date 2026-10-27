import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_truck.dart';
import 'location_service.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? get client {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static const String _kOfflineTrucksCacheKey = 'roambite_cached_trucks_json';

  /// Initialize Supabase if configured via --dart-define
  static Future<void> initialize() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
    }
  }

  // --- AUTH & ROLES (Phase 2) ---

  /// Sign in with Phone number (sends OTP)
  Future<void> signInWithPhone(String phone) async {
    final c = client;
    if (c == null) throw Exception('Backend is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.');
    await c.auth.signInWithOtp(phone: phone);
  }

  /// Verify Phone OTP
  Future<AuthResponse> verifyPhoneOtp({required String phone, required String token}) async {
    final c = client;
    if (c == null) throw Exception('Backend is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.');
    return await c.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Sign in with Google (OAuth)
  Future<bool> signInWithGoogle() async {
    final c = client;
    if (c == null) throw Exception('Backend is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.');
    return await c.auth.signInWithOAuth(OAuthProvider.google, redirectTo: kIsWeb ? 'https://roambite-app-sahay-snehils-projects.vercel.app/' : 'com.roambite.roambite://login-callback');
  }

  /// Sign out
  Future<void> signOut() async {
    final c = client;
    if (c != null) {
      await c.auth.signOut();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('roambite_user_role');
  }

  /// Current user profile role ('foodie' or 'truck_owner')
  Future<String?> getUserRole(String userId) async {
    final c = client;
    if (c == null) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('roambite_user_role') ?? 'foodie';
    }

    try {
      final res = await c.from('profiles').select('role').eq('id', userId).maybeSingle();
      if (res != null && res['role'] != null) {
        final role = res['role'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('roambite_user_role', role);
        return role;
      }
    } catch (e) {
      debugPrint('Error fetching role: $e');
    }
    return 'foodie';
  }

  /// Set or create profile with role
  Future<void> setProfileRole({
    required String userId,
    required String role,
    String? phone,
    String? displayName,
  }) async {
    final c = client;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roambite_user_role', role);

    if (c != null) {
      await c.from('profiles').upsert({
        'id': userId,
        'role': role,
        'phone': phone,
        'display_name': displayName ?? 'RoamBite Member',
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // --- TRUCKS & LIVE DISCOVERY (Phase 3 & Phase 4) ---

  /// Fetch live food trucks around coordinates with offline cache fallback
  Future<List<FoodTruck>> fetchLiveTrucks({
    required double userLat,
    required double userLng,
    double radiusMiles = 5.0,
  }) async {
    final c = client;

    if (c != null) {
      try {
        final nowIso = DateTime.now().toIso8601String();
        // Query trucks with valid active unexpired location
        final response = await c
            .from('trucks')
            .select('''
              id, name, tagline, cuisine, signature_dish, price_range, address, city, state, hero_image_url, is_sponsored,
              truck_locations!inner (
                latitude, longitude, is_live, live_until, status, recorded_at
              ),
              menus (
                items, menu_version
              ),
              reviews (
                id, rating, text, verified_visit, created_at, profiles(display_name)
              )
            ''')
            .eq('truck_locations.is_live', true)
            .gt('truck_locations.live_until', nowIso)
            .order('recorded_at', referencedTable: 'truck_locations', ascending: false);

        final trucks = <FoodTruck>[];
        for (final row in (response as List<dynamic>)) {
          final locs = row['truck_locations'] as List<dynamic>?;
          if (locs == null || locs.isEmpty) continue;
          final latestLoc = locs.first;

          final truckLat = (latestLoc['latitude'] as num).toDouble();
          final truckLng = (latestLoc['longitude'] as num).toDouble();
          final distance = LocationService.calculateDistanceInMiles(userLat, userLng, truckLat, truckLng);

          // Menu items parse
          final menuList = <MenuItem>[];
          final menusData = row['menus'] as List<dynamic>?;
          if (menusData != null && menusData.isNotEmpty) {
            final rawItems = menusData.first['items'] as List<dynamic>? ?? [];
            for (final m in rawItems) {
              menuList.add(MenuItem(
                id: m['id'] ?? 'item',
                name: m['name'] ?? '',
                description: m['description'] ?? '',
                price: (m['price'] as num?)?.toDouble() ?? 0.0,
                imageUrl: m['imageUrl'] ?? '',
                isSignature: m['isSignature'] == true,
              ));
            }
          }

          // Calculate average rating
          double avgRating = 5.0;
          final reviewsData = row['reviews'] as List<dynamic>? ?? [];
          if (reviewsData.isNotEmpty) {
            final sum = reviewsData.fold<double>(0.0, (acc, r) => acc + ((r['rating'] as num?)?.toDouble() ?? 0.0));
            avgRating = double.parse((sum / reviewsData.length).toStringAsFixed(1));
          }

          final statusStr = latestLoc['status'] as String? ?? 'serving_now';
          final truckStatus = statusStr == 'serving_now' ? TruckStatus.servingNow : TruckStatus.onTheMove;

          final recordedAt = DateTime.tryParse(latestLoc['recorded_at'] ?? '') ?? DateTime.now();
          final minutesAgo = DateTime.now().difference(recordedAt).inMinutes;
          final lastConfirmed = minutesAgo <= 1 ? 'Just now' : '$minutesAgo mins ago';

          trucks.add(FoodTruck(
            id: row['id'] as String,
            name: row['name'] as String,
            tagline: row['tagline'] as String? ?? '',
            cuisine: row['cuisine'] as String? ?? '',
            rating: avgRating,
            reviewCount: reviewsData.length,
            priceRange: row['price_range'] as String? ?? '\$',
            latitude: truckLat,
            longitude: truckLng,
            address: row['address'] as String? ?? '',
            city: row['city'] as String? ?? '',
            state: row['state'] as String? ?? '',
            status: truckStatus,
            lastConfirmed: lastConfirmed,
            closesAt: '11:00 PM',
            heroImageUrl: row['hero_image_url'] as String? ?? 'https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?auto=format&fit=crop&w=1200&q=80',
            menu: menuList,
            videoReviews: const [],
            isSponsored: row['is_sponsored'] == true,
            distanceInMiles: double.parse(distance.toStringAsFixed(1)),
          ));
        }

        // Cache for offline resilience
        await _cacheTrucks(trucks);
        return trucks;
      } catch (e) {
        debugPrint('Supabase fetchLiveTrucks failed ($e), attempting offline cache...');
      }
    }

    // Offline cache fallback
    return await _getCachedTrucks(userLat, userLng);
  }

  /// Broadcast live location (Owner Go Live ping every 2 min, expires in 15 min)
  Future<void> broadcastOwnerLocation({
    required String truckId,
    required double latitude,
    required double longitude,
    required String status, // 'serving_now' or 'on_the_move'
  }) async {
    final c = client;
    if (c == null) throw Exception('Backend is not configured.');

    final now = DateTime.now();
    final liveUntil = now.add(const Duration(minutes: 15));

    await c.from('truck_locations').insert({
      'truck_id': truckId,
      'latitude': latitude,
      'longitude': longitude,
      'geog': 'POINT($longitude $latitude)',
      'recorded_at': now.toIso8601String(),
      'live_until': liveUntil.toIso8601String(),
      'is_live': true,
      'status': status,
    });
  }

  /// Submit review with 200m verified visit check
  Future<void> submitReview({
    required String truckId,
    required double rating,
    required String text,
    required double userLat,
    required double userLng,
  }) async {
    final c = client;
    if (c == null) throw Exception('Backend is not configured.');
    final user = c.auth.currentUser;
    if (user == null) throw Exception('Must be signed in to review.');

    // Check verified visit via RPC
    bool isVerified = false;
    try {
      final res = await c.rpc('check_is_verified_visit', params: {
        'p_truck_id': truckId,
        'p_user_lat': userLat,
        'p_user_lng': userLng,
      });
      isVerified = res == true;
    } catch (_) {}

    await c.from('reviews').insert({
      'user_id': user.id,
      'truck_id': truckId,
      'rating': rating,
      'text': text,
      'verified_visit': isVerified,
    });
  }

  // --- OFFLINE CACHE HELPERS ---

  Future<void> _cacheTrucks(List<FoodTruck> trucks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = trucks.map((t) => {
        'id': t.id,
        'name': t.name,
        'tagline': t.tagline,
        'cuisine': t.cuisine,
        'rating': t.rating,
        'reviewCount': t.reviewCount,
        'priceRange': t.priceRange,
        'latitude': t.latitude,
        'longitude': t.longitude,
        'address': t.address,
        'city': t.city,
        'state': t.state,
        'status': t.status == TruckStatus.servingNow ? 'serving_now' : 'on_the_move',
        'lastConfirmed': t.lastConfirmed,
        'heroImageUrl': t.heroImageUrl,
        'isSponsored': t.isSponsored,
      }).toList();
      await prefs.setString(_kOfflineTrucksCacheKey, jsonEncode(listMap));
    } catch (e) {
      debugPrint('Failed to cache trucks: $e');
    }
  }

  Future<List<FoodTruck>> _getCachedTrucks(double userLat, double userLng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_kOfflineTrucksCacheKey);
      if (str != null) {
        final list = jsonDecode(str) as List<dynamic>;
        if (list.isNotEmpty) {
          return list.map((m) {
            final lat = (m['latitude'] as num).toDouble();
            final lng = (m['longitude'] as num).toDouble();
            final dist = LocationService.calculateDistanceInMiles(userLat, userLng, lat, lng);
            return FoodTruck(
              id: m['id'],
              name: m['name'],
              tagline: m['tagline'] ?? '',
              cuisine: m['cuisine'] ?? '',
              rating: (m['rating'] as num?)?.toDouble() ?? 5.0,
              reviewCount: (m['reviewCount'] as num?)?.toInt() ?? 0,
              priceRange: m['priceRange'] ?? '\$',
              latitude: lat,
              longitude: lng,
              address: m['address'] ?? '',
              city: m['city'] ?? '',
              state: m['state'] ?? '',
              status: m['status'] == 'serving_now' ? TruckStatus.servingNow : TruckStatus.onTheMove,
              lastConfirmed: m['lastConfirmed'] ?? 'Cached',
              closesAt: '11:00 PM',
              heroImageUrl: m['heroImageUrl'] ?? '',
              menu: const [],
              videoReviews: const [],
              isSponsored: m['isSponsored'] == true,
              distanceInMiles: double.parse(dist.toStringAsFixed(1)),
            );
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Error reading cached trucks: $e');
    }
    return _defaultDemoTrucks(userLat, userLng);
  }

  static List<FoodTruck> _defaultDemoTrucks(double userLat, double userLng) {
    return [
      FoodTruck(
        id: 'a1111111-aaaa-1111-aaaa-111111111111',
        name: 'Taco Trail',
        tagline: 'Authentic Jalisco street tacos & melted birria',
        cuisine: 'Mexican • Tacos',
        rating: 4.9,
        reviewCount: 841,
        priceRange: '\$',
        latitude: userLat + 0.003,
        longitude: userLng + 0.003,
        address: '2407 NW 2nd Ave',
        city: 'Miami',
        state: 'FL',
        status: TruckStatus.servingNow,
        lastConfirmed: 'Just now',
        closesAt: '11:00 PM',
        heroImageUrl: 'https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?auto=format&fit=crop&w=1200&q=80',
        isSponsored: true,
        distanceInMiles: 0.4,
        menu: const [
          MenuItem(
            id: 'm1',
            name: 'Crispy Quesabirria Tacos',
            description: 'Birria, Cheese, Consomé',
            price: 12.99,
            imageUrl: 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
            isSignature: true,
          ),
          MenuItem(
            id: 'm2',
            name: 'Spicy Al Pastor',
            description: 'Pineapple, Cilantro, Salsa',
            price: 10.50,
            imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
            isSignature: true,
          ),
          MenuItem(
            id: 'm3',
            name: 'Chorizo Queso Fries',
            description: 'Loaded spicy fries with queso fresco',
            price: 9.75,
            imageUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=600&q=80',
            isSignature: true,
          ),
          MenuItem(
            id: 'm4',
            name: 'Horchata',
            description: 'Traditional sweetened rice milk with cinnamon',
            price: 4.50,
            imageUrl: 'https://images.unsplash.com/photo-1556881286-fc6915169721?auto=format&fit=crop&w=600&q=80',
            isSignature: false,
          ),
        ],
        videoReviews: const [
          VideoReview(
            id: 'v1',
            userName: 'Maya V',
            userAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
            rating: 4.8,
            quote: 'Crispiest Birria in Wynwood! 😍',
            thumbnailUrl: 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
            videoUrl: '',
            timeAgo: '2h ago',
          ),
          VideoReview(
            id: 'v2',
            userName: 'Alex_C',
            userAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
            rating: 4.9,
            quote: 'Absolute Must-Try!',
            thumbnailUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
            videoUrl: '',
            timeAgo: '4h ago',
          ),
          VideoReview(
            id: 'v3',
            userName: 'FoodieJess',
            userAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
            rating: 5.0,
            quote: 'Incredible flavor! The Al Pastor is amazing.',
            thumbnailUrl: 'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=600&q=80',
            videoUrl: '',
            timeAgo: '1d ago',
          ),
        ],
      ),
      FoodTruck(
        id: 'a2222222-aaaa-2222-aaaa-222222222222',
        name: 'Burger Bus Co.',
        tagline: 'Double smash burgers with butter-toasted brioche',
        cuisine: 'American • Burgers',
        rating: 4.8,
        reviewCount: 620,
        priceRange: '\$\$',
        latitude: userLat - 0.004,
        longitude: userLng + 0.002,
        address: '2600 NW Miami Ct',
        city: 'Miami',
        state: 'FL',
        status: TruckStatus.servingNow,
        lastConfirmed: '5 mins ago',
        closesAt: '10:00 PM',
        heroImageUrl: 'https://images.unsplash.com/photo-1525164286253-04e68b9d94c6?auto=format&fit=crop&w=1200&q=80',
        isSponsored: false,
        distanceInMiles: 0.6,
        menu: const [
          MenuItem(
            id: 'bm1',
            name: 'The Wynwood Double Smash',
            description: 'Double Angus beef patties, American cheese, special sauce',
            price: 13.50,
            imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
            isSignature: true,
          ),
          MenuItem(
            id: 'bm2',
            name: 'Truffle Parmesan Fries',
            description: 'Crispy skin-on fries tossed in white truffle oil',
            price: 7.00,
            imageUrl: 'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
            isSignature: true,
          ),
        ],
        videoReviews: const [],
      ),
    ];
  }
}

