import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  final String label;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String city;
  final String state;
  final bool isGpsDetected;

  const UserLocation({
    required this.label,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.state,
    this.isGpsDetected = false,
  });

  static const defaultMiami = UserLocation(
    label: 'Wynwood Art District',
    formattedAddress: '2407 NW 2nd Ave, Wynwood, Miami, FL 33127',
    latitude: 25.7997,
    longitude: -80.1986,
    city: 'Miami',
    state: 'FL',
  );

  static const List<UserLocation> kUsFoodTruckHubs = [
    UserLocation(
      label: 'Wynwood Arts District',
      formattedAddress: '2407 NW 2nd Ave, Miami, FL 33127',
      latitude: 25.7997,
      longitude: -80.1986,
      city: 'Miami',
      state: 'FL',
    ),
    UserLocation(
      label: 'Brickell Financial Center',
      formattedAddress: '701 S Miami Ave, Miami, FL 33130',
      latitude: 25.7667,
      longitude: -80.1920,
      city: 'Miami',
      state: 'FL',
    ),
    UserLocation(
      label: 'South Congress Food Park',
      formattedAddress: '1503 S Congress Ave, Austin, TX 78704',
      latitude: 30.2501,
      longitude: -97.7499,
      city: 'Austin',
      state: 'TX',
    ),
    UserLocation(
      label: 'Venice Beach Boardwalk',
      formattedAddress: '1800 Ocean Front Walk, Venice, CA 90291',
      latitude: 33.9850,
      longitude: -118.4695,
      city: 'Los Angeles',
      state: 'CA',
    ),
    UserLocation(
      label: 'Downtown Food Pods',
      formattedAddress: '920 SW 9th Ave, Portland, OR 97205',
      latitude: 45.5190,
      longitude: -122.6820,
      city: 'Portland',
      state: 'OR',
    ),
  ];
}

// Slice 4: typed location failures, so the UI can explain what went wrong
// instead of showing a bare exception, and can offer the right next step.
enum LocationFailureReason {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class LocationFailure implements Exception {
  final LocationFailureReason reason;
  final String message;

  const LocationFailure(this.reason, this.message);

  // Device location settings fix a disabled service and a permanently
  // denied permission (via app settings); a plain denial can be retried.
  bool get canOpenSettings =>
      reason == LocationFailureReason.serviceDisabled ||
      reason == LocationFailureReason.permissionDeniedForever;

  @override
  String toString() => message;
}

// Slice 4: the result of a GPS attempt. A failure never arrives on its
// own: it may still carry a last-known location the user can fall back to.
class LocationResult {
  final UserLocation? location;
  final LocationFailure? failure;
  final bool usedLastKnown;

  const LocationResult({this.location, this.failure, this.usedLastKnown = false});

  bool get isSuccess => location != null;
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Slice 4: the supported service area is the US, where the seed trucks
  // live. Coordinates outside it must show the service-area gate, never a
  // blank list. The boxes cover the contiguous US plus Hawaii and Alaska.
  static bool isInServiceArea(UserLocation location) =>
      isInServiceAreaLatLng(location.latitude, location.longitude);

  static bool isInServiceAreaLatLng(double latitude, double longitude) {
    final inContiguousUs = latitude >= 24.5 &&
        latitude <= 49.4 &&
        longitude >= -125.0 &&
        longitude <= -66.4;
    final inHawaii = latitude >= 18.9 &&
        latitude <= 28.4 &&
        longitude >= -178.0 &&
        longitude <= -154.0;
    final inAlaska = latitude >= 51.0 &&
        latitude <= 71.4 &&
        longitude >= -180.0 &&
        longitude <= -129.0;
    return inContiguousUs || inHawaii || inAlaska;
  }

  // Slice 4: radius filtering is only meaningful once the service-area
  // gate has passed; the dashboard applies this radius after that check.
  static const double kServiceRadiusMiles = 5.0;

  /// Requests foreground GPS permission and returns exact US coordinates & address (Zomato/Blinkit pattern)
  Future<UserLocation> getCurrentGpsLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(
        LocationFailureReason.serviceDisabled,
        'Location services are turned off on your device. Turn on GPS to detect your location.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationFailure(
          LocationFailureReason.permissionDenied,
          'Location permission was denied. Allow location access to detect your location, or choose a location manually.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureReason.permissionDeniedForever,
        'Location permission is permanently denied. Open settings to allow location access, or choose a location manually.',
      );
    }

    // High accuracy single-shot query
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    try {
      // Reverse geocode to US address
      final placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final street = place.street ?? '';
        final locality = place.locality ?? place.subLocality ?? 'Current Area';
        final state = place.administrativeArea ?? 'US';
        final postalCode = place.postalCode ?? '';

        final parts = [street, locality, state, postalCode]
            .where((e) => e.isNotEmpty)
            .toList();
        final formatted = parts.join(', ');

        return UserLocation(
          label: locality.isNotEmpty ? locality : 'Detected Location',
          formattedAddress: formatted.isNotEmpty ? formatted : 'US Location',
          latitude: position.latitude,
          longitude: position.longitude,
          city: locality,
          state: state,
          isGpsDetected: true,
        );
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }

    return UserLocation(
      label: 'Current Location',
      formattedAddress: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
      latitude: position.latitude,
      longitude: position.longitude,
      city: 'Local Area',
      state: 'US',
      isGpsDetected: true,
    );
  }

  /// Slice 4: GPS with a graceful fallback. A failure is returned, not
  /// thrown away: callers show its message, offer device settings, and
  /// offer the last-known location (or the manual picker) as a fallback.
  /// Nothing here fails silently and nothing returns a blank result.
  Future<LocationResult> getCurrentGpsLocationWithFallback() async {
    try {
      return LocationResult(location: await getCurrentGpsLocation());
    } on LocationFailure catch (failure) {
      final lastKnown = await getLastKnownLocation();
      if (lastKnown != null) {
        return LocationResult(location: lastKnown, failure: failure, usedLastKnown: true);
      }
      return LocationResult(failure: failure);
    } catch (e) {
      final failure = LocationFailure(
        LocationFailureReason.unavailable,
        'Location is unavailable right now. Check GPS and try again, or choose a location manually.',
      );
      debugPrint('GPS error: $e');
      final lastKnown = await getLastKnownLocation();
      if (lastKnown != null) {
        return LocationResult(location: lastKnown, failure: failure, usedLastKnown: true);
      }
      return LocationResult(failure: failure);
    }
  }

  /// Last known device position, if any. Used only as an explicit
  /// fallback after a GPS failure, never as a silent substitute.
  Future<UserLocation?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position == null) return null;
      return UserLocation(
        label: 'Last known location',
        formattedAddress: 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
        latitude: position.latitude,
        longitude: position.longitude,
        city: 'Last known area',
        state: 'US',
      );
    } catch (_) {
      return null;
    }
  }

  /// Opens device location settings (for a disabled service) or app
  /// settings (for a permanently denied permission).
  Future<void> openSettingsForFailure(LocationFailure failure) async {
    if (failure.reason == LocationFailureReason.permissionDeniedForever) {
      await Geolocator.openAppSettings();
    } else {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Calculates distance in miles between user and food truck
  static double calculateDistanceInMiles(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusMiles = 3958.8;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
