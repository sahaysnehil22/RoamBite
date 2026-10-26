import 'package:flutter/material.dart';
import '../services/location_service.dart';

class LocationPickerSheet extends StatefulWidget {
  final UserLocation currentLocation;
  final ValueChanged<UserLocation> onLocationSelected;

  const LocationPickerSheet({
    super.key,
    required this.currentLocation,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  bool _isDetectingGps = false;
  String? _errorMessage; LocationFailure? _locationFailure; UserLocation? _lastKnownLocation;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _handleGpsDetect() async {
    setState(() {
      _isDetectingGps = true;
      _errorMessage = null; _locationFailure = null; _lastKnownLocation = null;
    });

    try {
      final result = await LocationService().getCurrentGpsLocationWithFallback(); if (!mounted) return; if (result.location != null && !result.usedLastKnown) { widget.onLocationSelected(result.location!); Navigator.of(context).pop(); return; } setState(() { _isDetectingGps = false; _errorMessage = result.failure?.message ?? 'Location is unavailable right now.'; _locationFailure = result.failure; _lastKnownLocation = result.usedLastKnown ? result.location : null; }); return;
      if (!mounted) return;
      // GPS fallback is handled above.
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetectingGps = false;
        _errorMessage = e.toString().replaceAll('Exception: ', ''); _locationFailure = e is LocationFailure ? e : null; _lastKnownLocation = null;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Icon(Icons.location_on, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Select Your Location',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '🇺🇸 US Only',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // "Use Current Location" GPS button
          InkWell(
            onTap: _isDetectingGps ? null : _handleGpsDetect,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  if (_isDetectingGps)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  else
                    Icon(Icons.my_location, color: theme.colorScheme.primary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDetectingGps ? 'Detecting Precise GPS...' : 'Use Current Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Detects exact US address on-demand with zero battery drain',
                          style: TextStyle(color: theme.hintColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.hintColor),
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12), ), if (_locationFailure != null && _locationFailure!.canOpenSettings) TextButton(onPressed: () { final failure = _locationFailure; if (failure != null) { LocationService().openSettingsForFailure(failure); } }, child: const Text('Open location settings')), if (_lastKnownLocation != null) TextButton(onPressed: () { final lastKnown = _lastKnownLocation; if (lastKnown != null) { widget.onLocationSelected(lastKnown); Navigator.of(context).pop(); } }, child: const Text('Use last known location')), const Text('Or pick a location from the list below.', style: TextStyle(color: Colors.redAccent, fontSize: 12)
            ),
          ],

          const SizedBox(height: 16),

          // Search input
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search city, street or ZIP code...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'POPULAR US FOOD TRUCK HUBS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 8),

          ...UserLocation.kUsFoodTruckHubs.map((hub) {
            final isSelected = widget.currentLocation.label == hub.label;
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: ListTile(
                dense: true,
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.storefront_outlined,
                  color: isSelected ? theme.colorScheme.primary : theme.hintColor,
                  size: 20,
                ),
                title: Text(
                  hub.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  hub.formattedAddress,
                  style: TextStyle(color: theme.hintColor, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${hub.city}, ${hub.state}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  widget.onLocationSelected(hub);
                  Navigator.of(context).pop();
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
