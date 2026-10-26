import 'package:flutter/material.dart';

import '../services/location_service.dart';

// Slice 4: illustrated empty state shown when the user's location is
// outside the supported service area (the US). It never shows a blank
// list: it explains the situation and offers the two next steps.
class ServiceAreaGate extends StatelessWidget {
  final UserLocation location;
  final VoidCallback onBrowseMiamiDemo;
  final VoidCallback onChangeLocation;

  const ServiceAreaGate({
    super.key,
    required this.location,
    required this.onBrowseMiamiDemo,
    required this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orange = theme.colorScheme.primary;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Zomato/Blinkit-style illustration: a truck in a soft orange disc.
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.location_off_outlined, size: 88, color: orange),
                Positioned(
                  bottom: 42,
                  child: Icon(Icons.local_shipping_outlined, size: 40, color: orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            "RoamBite isn't available in your area yet",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'We currently serve the United States, where our food trucks live. '
            'Your location is ${location.formattedAddress}. '
            'Browse the Miami demo to explore RoamBite, or pick a location inside the service area.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface.withOpacity(0.7), height: 1.45),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBrowseMiamiDemo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Browse Miami demo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onChangeLocation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Change location'),
            ),
          ),
        ],
      ),
    );
  }
}
