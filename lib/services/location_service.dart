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

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Requests foreground GPS permission and returns exact US coordinates & address (Zomato/Blinkit pattern)
  Future<UserLocation> getCurrentGpsLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled on your device. Please enable GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
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
