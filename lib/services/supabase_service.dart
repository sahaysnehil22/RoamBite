import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_truck.dart';
import 'demo_trucks.dart';
import 'location_service.dart';

class SupabaseConfig {
  static const String url =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String sentryDsn =
      String.fromEnvironment('SENTRY_DSN', defaultValue: '');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

class AlertRadiusConfig {
  final bool enabled;
  final double radiusMiles;
  final bool quietHoursEnabled;

  const AlertRadiusConfig({
    this.enabled = true,
    this.radiusMiles = 2.0,
    this.quietHoursEnabled = true,
  });
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
  static const String _kSavedTruckIdsKey = 'roambite_saved_truck_ids';
  static const String _kAlertEnabledKey = 'roambite_alert_enabled';
  static const String _kAlertRadiusMilesKey = 'roambite_alert_radius_miles';
  static const String _kQuietHoursEnabledKey = 'roambite_quiet_hours_enabled';

  /// Initialize Supabase if configured via --dart-define
  static Future<void> initialize() async {
    if (SupabaseConfig.isConfigured) {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
    }
  }

  // --- AUTH & ROLES ---

  /// Sign in with Phone number (sends OTP)
  Future<void> signInWithPhone(String phone) async {
    final c = client;
    if (c == null) {
      throw Exception(
          'Backend is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    await c.auth.signInWithOtp(phone: phone);
  }

  /// Verify Phone OTP
  Future<AuthResponse> verifyPhoneOtp(
      {required String phone, required String token}) async {
    final c = client;
    if (c == null) {
      throw Exception(
          'Backend is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    return await c.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  /// Sign in with Google (OAuth)
  Future<bool> signInWithGoogle() async {
    final c = client;
    if (c == null) {
      throw Exception(
          'Backend is not configured. Provide SUPABASE_URL and SUPABASE_ANON_KEY.');
    }
    return await c.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb
          ? 'https://roambite-app-sahay-snehils-projects.vercel.app/'
          : 'com.roambite.roambite://login-callback',
    );
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
      final res = await c
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
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

  /// Fetch user profile fields (role, display_name, avatar_url) from profiles
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final c = client;
    if (c == null) return null;
    try {
      final res = await c
          .from('profiles')
          .select('role, display_name, phone, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return res;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Set or create profile with role and optional avatar_url
  Future<void> setProfileRole({
    required String userId,
    required String role,
    String? phone,
    String? displayName,
    String? avatarUrl,
  }) async {
    final c = client;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('roambite_user_role', role);

    if (c != null) {
      final payload = <String, dynamic>{
        'id': userId,
        'role': role,
        'phone': phone,
        'display_name': displayName ?? 'RoamBite Member',
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (avatarUrl != null) {
        payload['avatar_url'] = avatarUrl;
      }
      await c.from('profiles').upsert(payload);
    }
  }

  // --- SUPABASE STORAGE ('roambite-media' BUCKET) ---

  /// Upload a picked photo or video file to the public 'roambite-media' bucket
  /// under paths: reviews/<user_id>/..., avatars/<user_id>/..., or trucks/<truck_id>/...
  /// Returns the public URL for storing in database columns.
  Future<String> uploadMediaToBucket({
    required String storageFolder,
    required Uint8List bytes,
    required String fileName,
    bool isVideo = false,
  }) async {
    final c = client;
    if (c == null) {
      throw Exception(
          'Backend is not configured. Please sign in with a live backend or paste a Custom URL.');
    }

    final cleanFolder =
        storageFolder.replaceAll(RegExp(r'^/+|/+$'), '').trim();
    final safeFileName = fileName.trim().isEmpty
        ? (isVideo ? 'video.mp4' : 'photo.jpg')
        : fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final objectPath = '$cleanFolder/${timestamp}_$safeFileName';

    final lower = safeFileName.toLowerCase();
    String contentType;
    if (lower.endsWith('.png')) {
      contentType = 'image/png';
    } else if (lower.endsWith('.webp')) {
      contentType = 'image/webp';
    } else if (lower.endsWith('.gif')) {
      contentType = 'image/gif';
    } else if (lower.endsWith('.mp4')) {
      contentType = 'video/mp4';
    } else if (lower.endsWith('.mov')) {
      contentType = 'video/quicktime';
    } else if (lower.endsWith('.webm')) {
      contentType = 'video/webm';
    } else {
      contentType = isVideo ? 'video/mp4' : 'image/jpeg';
    }

    await c.storage.from('roambite-media').uploadBinary(
          objectPath,
          bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return c.storage.from('roambite-media').getPublicUrl(objectPath);
  }

  // --- ALERT RADIUS GEOFENCE SYSTEM ---

  Future<AlertRadiusConfig> loadAlertRadiusSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return AlertRadiusConfig(
      enabled: prefs.getBool(_kAlertEnabledKey) ?? true,
      radiusMiles: prefs.getDouble(_kAlertRadiusMilesKey) ?? 2.0,
      quietHoursEnabled: prefs.getBool(_kQuietHoursEnabledKey) ?? true,
    );
  }

  Future<void> saveAlertRadiusSettings({
    required bool enabled,
    required double radiusMiles,
    required bool quietHoursEnabled,
    double? userLat,
    double? userLng,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAlertEnabledKey, enabled);
    await prefs.setDouble(_kAlertRadiusMilesKey, radiusMiles);
    await prefs.setBool(_kQuietHoursEnabledKey, quietHoursEnabled);

    final c = client;
    if (c != null && c.auth.currentUser != null && userLat != null && userLng != null) {
      try {
        await c.rpc('upsert_user_alert_radius', params: {
          'p_latitude': userLat,
          'p_longitude': userLng,
          'p_radius_miles': radiusMiles,
          'p_notify_enabled': enabled,
          'p_quiet_hours_enabled': quietHoursEnabled,
        });
      } catch (e) {
        debugPrint('Supabase upsert_user_alert_radius fallback: $e');
      }
    }
  }

  // --- TRUCKS & LIVE DISCOVERY ---

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
        final response = await c
            .from('trucks')
            .select('''
              id, name, tagline, cuisine, signature_dish, price_range, address, city, state, hero_image_url, profile_image_url, prep_time_walk_mins, is_sponsored,
              truck_locations!inner (
                latitude, longitude, is_live, live_until, status, recorded_at
              ),
              menus (
                items, menu_version
              ),
              reviews (
                id, rating, text, verified_visit, created_at, reviewer_name, reviewer_avatar_url, media_url, video_url, is_video, media_caption, duration, profiles(display_name)
              )
            ''')
            .eq('truck_locations.is_live', true)
            .gt('truck_locations.live_until', nowIso)
            .order('recorded_at',
                referencedTable: 'truck_locations', ascending: false);

        final trucks = <FoodTruck>[];
        for (final row in (response as List<dynamic>)) {
          final locs = row['truck_locations'] as List<dynamic>?;
          if (locs == null || locs.isEmpty) continue;
          final latestLoc = locs.first;

          final truckLat = (latestLoc['latitude'] as num).toDouble();
          final truckLng = (latestLoc['longitude'] as num).toDouble();
          final distance = LocationService.calculateDistanceInMiles(
              userLat, userLng, truckLat, truckLng);

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
                isVegetarian: m['isVegetarian'] == true,
              ));
            }
          }

          double avgRating = 5.0;
          final reviewsData = row['reviews'] as List<dynamic>? ?? [];
          final parsedReviews = <VideoReview>[];
          if (reviewsData.isNotEmpty) {
            final sum = reviewsData.fold<double>(
                0.0, (acc, r) => acc + ((r['rating'] as num?)?.toDouble() ?? 0.0));
            avgRating =
                double.parse((sum / reviewsData.length).toStringAsFixed(1));

            for (final r in reviewsData) {
              final prof = r['profiles'] as Map<String, dynamic>?;
              final revName = (r['reviewer_name'] as String?)?.isNotEmpty == true
                  ? r['reviewer_name'] as String
                  : (prof?['display_name'] as String? ?? 'RoamBite Foodie');
              parsedReviews.add(
                VideoReview(
                  id: r['id']?.toString() ?? 'rev',
                  userName: revName,
                  userAvatar: (r['reviewer_avatar_url'] as String?)?.isNotEmpty == true
                      ? r['reviewer_avatar_url'] as String
                      : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
                  rating: (r['rating'] as num?)?.toDouble() ?? 5.0,
                  quote: r['text'] as String? ?? '',
                  thumbnailUrl: (r['media_url'] as String?)?.isNotEmpty == true
                      ? r['media_url'] as String
                      : (row['hero_image_url'] as String? ?? ''),
                  videoUrl: r['video_url'] as String? ?? '',
                  timeAgo: 'Verified Visit',
                  isVideo: r['is_video'] == true,
                  mediaCaption: r['media_caption'] as String? ?? '',
                  duration: r['duration'] as String? ?? '0:15',
                ),
              );
            }
          }

          final statusStr = latestLoc['status'] as String? ?? 'serving_now';
          final truckStatus = statusStr == 'serving_now'
              ? TruckStatus.servingNow
              : TruckStatus.onTheMove;

          final recordedAt =
              DateTime.tryParse(latestLoc['recorded_at'] ?? '') ??
                  DateTime.now();
          final minutesAgo = DateTime.now().difference(recordedAt).inMinutes;
          final lastConfirmed =
              minutesAgo <= 1 ? 'Just now' : '$minutesAgo mins ago';

          trucks.add(FoodTruck(
            id: row['id'] as String,
            name: row['name'] as String,
            tagline: row['tagline'] as String? ?? '',
            cuisine: row['cuisine'] as String? ?? '',
            rating: avgRating,
            reviewCount: reviewsData.length,
            priceRange: row['price_range'] as String? ?? r'$',
            latitude: truckLat,
            longitude: truckLng,
            address: row['address'] as String? ?? '',
            city: row['city'] as String? ?? '',
            state: row['state'] as String? ?? '',
            status: truckStatus,
            lastConfirmed: lastConfirmed,
            closesAt: '11:00 PM',
            prepTimeWalkMins:
                row['prep_time_walk_mins'] as String? ?? '6-10 mins',
            heroImageUrl: row['hero_image_url'] as String? ??
                'https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?auto=format&fit=crop&w=1200&q=80',
            profileImageUrl: row['profile_image_url'] as String? ??
                row['hero_image_url'] as String? ??
                '',
            menu: menuList,
            videoReviews: parsedReviews,
            isSponsored: row['is_sponsored'] == true,
            distanceInMiles: double.parse(distance.toStringAsFixed(1)),
          ));
        }

        if (trucks.isNotEmpty) {
          await _cacheTrucks(trucks);
          return trucks;
        }
      } catch (e) {
        debugPrint(
            'Supabase fetchLiveTrucks failed ($e), falling back to session/demo...');
      }
    }

    return DemoTrucks.forLocation(userLat: userLat, userLng: userLng);
  }

  /// Broadcast live location (Owner Go Live ping every 2 min, expires in 15 min)
  Future<void> broadcastOwnerLocation({
    required String truckId,
    required double latitude,
    required double longitude,
    required String status, // 'serving_now' or 'on_the_move'
  }) async {
    DemoTrucks.updateTruckProfile(
      truckId: truckId,
      status: status == 'serving_now'
          ? TruckStatus.servingNow
          : TruckStatus.onTheMove,
    );

    final c = client;
    if (c == null) return;

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

    try {
      await c.functions.invoke(
        'send-truck-alerts',
        body: {
          'truck_id': truckId,
          'latitude': latitude,
          'longitude': longitude,
          'recorded_at': now.toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('send-truck-alerts edge function skip: $e');
    }
  }

  // --- FAVOURITES (saved_trucks) & LIVE PROMOTIONS (promotions) ---

  /// Load saved truck IDs from `saved_trucks` for the signed-in user, or from
  /// local state / SharedPreferences in demo mode.
  Future<Set<String>> fetchSavedTruckIds() async {
    final c = client;
    final user = c?.auth.currentUser;
    if (c != null && user != null) {
      try {
        final rows = await c
            .from('saved_trucks')
            .select('truck_id')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        final ids = <String>{};
        for (final row in (rows as List<dynamic>)) {
          final id = row['truck_id']?.toString();
          if (id != null && id.isNotEmpty) {
            ids.add(id);
          }
        }
        DemoTrucks.setSavedTruckIds(ids);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(_kSavedTruckIdsKey, ids.toList());
        return ids;
      } catch (e) {
        debugPrint('Supabase fetchSavedTruckIds fallback: $e');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_kSavedTruckIdsKey);
      if (stored != null) {
        DemoTrucks.setSavedTruckIds(stored);
      }
    } catch (_) {}
    return DemoTrucks.savedTruckIds;
  }

  /// Toggle saved state for [truckId]. Inserts/deletes in `saved_trucks` when
  /// signed in to Supabase, and updates local state in demo mode.
  Future<bool> toggleSavedTruck(String truckId) async {
    final nowSaved = DemoTrucks.toggleSavedTruck(truckId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _kSavedTruckIdsKey, DemoTrucks.savedTruckIds.toList());
    } catch (_) {}

    final c = client;
    final user = c?.auth.currentUser;
    if (c != null && user != null) {
      try {
        if (nowSaved) {
          await c.from('saved_trucks').upsert(
            {
              'user_id': user.id,
              'truck_id': truckId,
            },
            onConflict: 'user_id,truck_id',
          );
        } else {
          await c
              .from('saved_trucks')
              .delete()
              .eq('user_id', user.id)
              .eq('truck_id', truckId);
        }
      } catch (e) {
        debugPrint('Supabase toggleSavedTruck fallback: $e');
      }
    }
    return nowSaved;
  }

  /// Return the list of saved [FoodTruck] objects for the current user.
  Future<List<FoodTruck>> fetchSavedTrucks({
    double? userLat,
    double? userLng,
  }) async {
    final savedIds = await fetchSavedTruckIds();
    if (savedIds.isEmpty) return [];

    final lat = userLat ?? DemoTrucks.miamiHub.latitude;
    final lng = userLng ?? DemoTrucks.miamiHub.longitude;
    final liveOrDemo = await fetchLiveTrucks(userLat: lat, userLng: lng);
    final byId = <String, FoodTruck>{
      for (final t in DemoTrucks.forLocation(userLat: lat, userLng: lng))
        t.id: t,
      for (final t in liveOrDemo) t.id: t,
    };

    final result = <FoodTruck>[];
    for (final id in savedIds) {
      final match = byId[id];
      if (match != null) {
        result.add(match);
      }
    }
    return result;
  }

  static int _parseHexColor(String? hexStr, int fallback) {
    if (hexStr == null || hexStr.trim().isEmpty) return fallback;
    final cleaned = hexStr.trim().replaceAll('#', '').replaceAll('0x', '');
    final withAlpha = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return int.tryParse(withAlpha, radix: 16) ?? fallback;
  }

  /// Fetch active promotions from `promotions` (is_active = true, order by sort_order).
  /// Falls back to `DemoTrucks.heroPromotions` when the table is empty or unreachable.
  Future<List<PromoBanner>> fetchActivePromotions() async {
    final c = client;
    if (c != null) {
      try {
        final rows = await c
            .from('promotions')
            .select(
                'id, truck_id, tag, headline_top, headline_bottom, subtext, cta_text, image_url, primary_color_hex, secondary_color_hex, is_active, sort_order, created_at')
            .eq('is_active', true)
            .order('sort_order', ascending: true);

        final promos = <PromoBanner>[];
        for (final row in (rows as List<dynamic>)) {
          promos.add(
            PromoBanner(
              id: row['id']?.toString() ?? 'promo',
              truckId: row['truck_id']?.toString() ?? '',
              badgeText: row['tag'] as String? ?? '',
              headlineTop: row['headline_top'] as String? ?? '',
              headlineMain: row['headline_bottom'] as String? ?? '',
              subheadline: row['subtext'] as String? ?? '',
              ctaText: row['cta_text'] as String? ?? 'Explore',
              imageUrl: row['image_url'] as String? ?? '',
              primaryColorHex: _parseHexColor(
                  row['primary_color_hex'] as String?, 0xFFD93829),
              secondaryColorHex: _parseHexColor(
                  row['secondary_color_hex'] as String?, 0xFFB71C1C),
            ),
          );
        }
        if (promos.isNotEmpty) {
          return promos;
        }
      } catch (e) {
        debugPrint('Supabase fetchActivePromotions fallback: $e');
      }
    }
    return DemoTrucks.heroPromotions;
  }

  // --- PUSH NOTIFICATIONS (FCM TOKEN) ---

  /// Store the device FCM token on `profiles.fcm_token` for the signed-in user.
  Future<void> saveFcmToken(String token) async {
    if (token.trim().isEmpty) return;
    final c = client;
    final user = c?.auth.currentUser;
    if (c == null || user == null) return;
    try {
      await c.from('profiles').update({
        'fcm_token': token.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Supabase saveFcmToken warning: $e');
    }
  }

  /// Resolve a single [FoodTruck] by ID for push notification deep-links.
  Future<FoodTruck?> fetchTruckById(String truckId) async {
    final cleanId = truckId.trim();
    if (cleanId.isEmpty) return null;
    try {
      final trucks = await fetchLiveTrucks(
        userLat: DemoTrucks.miamiHub.latitude,
        userLng: DemoTrucks.miamiHub.longitude,
      );
      for (final t in trucks) {
        if (t.id == cleanId) return t;
      }
    } catch (_) {}
    for (final t in DemoTrucks.miamiHubTrucks) {
      if (t.id == cleanId) return t;
    }
    return DemoTrucks.getTruckById(cleanId);
  }

  /// Update Truck Profile & Radar Avatar in both Demo session and Supabase
  Future<void> updateTruckProfileInDb({
    required String truckId,
    required String name,
    required String tagline,
    required String cuisine,
    required String address,
    required String closesAt,
    required String profileImageUrl,
  }) async {
    DemoTrucks.updateTruckProfile(
      truckId: truckId,
      name: name,
      tagline: tagline,
      cuisine: cuisine,
      address: address,
      closesAt: closesAt,
      profileImageUrl: profileImageUrl,
    );

    final c = client;
    if (c != null) {
      try {
        await c.from('trucks').update({
          'name': name,
          'tagline': tagline,
          'cuisine': cuisine,
          'address': address,
          'profile_image_url': profileImageUrl,
          'hero_image_url': profileImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', truckId);
      } catch (e) {
        debugPrint('Supabase updateTruckProfileInDb fallback: $e');
      }
    }
  }

  /// Sync Truck Menu (with dish images & vegetarian flags) to Supabase menus table
  Future<void> syncTruckMenuToDb({
    required String truckId,
    required List<MenuItem> items,
    required int menuVersion,
  }) async {
    final c = client;
    if (c == null) return;
    try {
      final jsonItems = items
          .map((m) => {
                'id': m.id,
                'name': m.name,
                'description': m.description,
                'price': m.price,
                'imageUrl': m.imageUrl,
                'isSignature': m.isSignature,
                'isVegetarian': m.isVegetarian,
              })
          .toList();
      await c.from('menus').upsert({
        'truck_id': truckId,
        'items': jsonItems,
        'menu_version': menuVersion,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'truck_id');
    } catch (e) {
      debugPrint('Supabase syncTruckMenuToDb fallback: $e');
    }
  }

  /// Submit review (supports text, star rating, and camera/gallery photo or video reel)
  Future<void> submitReview({
    required String truckId,
    required double rating,
    required String text,
    required double userLat,
    required double userLng,
    String reviewerName = 'Snehil Sahay',
    String reviewerAvatarUrl =
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    String mediaUrl = '',
    String videoUrl = '',
    bool isVideo = false,
    String mediaCaption = '',
    String duration = '0:15',
  }) async {
    final c = client;
    if (c == null) return;
    final user = c.auth.currentUser;
    if (user == null) return;

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
      'reviewer_name': reviewerName,
      'reviewer_avatar_url': reviewerAvatarUrl,
      'media_url': mediaUrl,
      'video_url': videoUrl,
      'is_video': isVideo,
      'media_caption': mediaCaption,
      'duration': duration,
    });
  }

  Future<void> _cacheTrucks(List<FoodTruck> trucks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listMap = trucks
          .map((t) => {
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
                'status': t.status == TruckStatus.servingNow
                    ? 'serving_now'
                    : 'on_the_move',
                'lastConfirmed': t.lastConfirmed,
                'heroImageUrl': t.heroImageUrl,
                'profileImageUrl': t.profileImageUrl,
                'isSponsored': t.isSponsored,
              })
          .toList();
      await prefs.setString(_kOfflineTrucksCacheKey, jsonEncode(listMap));
    } catch (e) {
      debugPrint('Failed to cache trucks: $e');
    }
  }
}
