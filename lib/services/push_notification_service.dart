import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/truck_detail_screen.dart';
import '../theme/app_theme.dart';
import 'supabase_service.dart';

/// Global navigator key used to open [TruckDetailScreen] when a user taps a
/// push notification in the foreground, background, or cold start.
final GlobalKey<NavigatorState> roamBiteNavigatorKey =
    GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Runs safely as no-op when google-services.json is not yet provided.
  }
}

class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  bool _isFirebaseReady = false;
  String? _cachedToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;

  bool get isFirebaseReady => _isFirebaseReady;

  /// Initializes Firebase and FCM when `google-services.json` is present.
  /// If `google-services.json` has not been provided yet, catches the
  /// initialization error and returns cleanly so the app runs as today.
  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isFirebaseReady = true;
    } catch (e) {
      _isFirebaseReady = false;
      debugPrint(
        'FCM inactive (google-services.json not configured yet): $e',
      );
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          _cachedToken = token;
          await SupabaseService().saveFcmToken(token);
        }
      }

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = messaging.onTokenRefresh.listen((newToken) async {
        _cachedToken = newToken;
        await SupabaseService().saveFcmToken(newToken);
      });

      // Cold-start tap handling
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openTruckFromMessage(initialMessage);
        });
      }

      // Background -> foreground tap handling
      _onMessageOpenedSub?.cancel();
      _onMessageOpenedSub =
          FirebaseMessaging.onMessageOpenedApp.listen(_openTruckFromMessage);

      // Foreground arrival banner with tap action to open TruckDetailScreen
      _onMessageSub?.cancel();
      _onMessageSub =
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      debugPrint('FCM setup warning: $e');
    }
  }

  /// Syncs the device FCM token to `profiles.fcm_token` once a user signs in.
  Future<void> syncTokenForCurrentUser() async {
    if (!_isFirebaseReady) return;
    try {
      final token = _cachedToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        await SupabaseService().saveFcmToken(token);
      }
    } catch (e) {
      debugPrint('FCM token sync skipped: $e');
    }
  }

  String? _extractTruckId(RemoteMessage message) {
    final data = message.data;
    final raw = data['truck_id'] ?? data['truckId'];
    final id = raw?.toString().trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final navContext = roamBiteNavigatorKey.currentContext;
    if (navContext == null) return;
    final messenger = ScaffoldMessenger.maybeOf(navContext);
    if (messenger == null) return;

    final title = message.notification?.title ??
        message.data['title']?.toString() ??
        'Food truck nearby';
    final body = message.notification?.body ??
        message.data['body']?.toString() ??
        'Tap View to open the truck menu and live status.';
    final truckId = _extractTruckId(message);

    messenger.showSnackBar(
      SnackBar(
        content: Text('$title — $body'),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: truckId != null
            ? SnackBarAction(
                label: 'View',
                textColor: AppTheme.primaryOrange,
                onPressed: () => _openTruckById(truckId),
              )
            : null,
      ),
    );
  }

  Future<void> _openTruckFromMessage(RemoteMessage message) async {
    final truckId = _extractTruckId(message);
    if (truckId == null) return;
    await _openTruckById(truckId);
  }

  Future<void> _openTruckById(String truckId) async {
    final truck = await SupabaseService().fetchTruckById(truckId);
    if (truck == null) return;
    final nav = roamBiteNavigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => TruckDetailScreen(truck: truck),
      ),
    );
  }
}
