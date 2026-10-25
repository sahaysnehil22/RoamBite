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
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();

  Future<void> _handleGpsDetect() async {
    setState(() {
      _isDetectingGps = true;
      _errorMessage = null;
    });

    try {
      final detected = await LocationService().getCurrentGpsLocation();
      if (!mounted) return;
      widget.onLocationSelected(detected);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetectingGps = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
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
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF14171F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: Color(0xFFFF6B00), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Select Your Location',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '🇺🇸 US Only',
                  style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Zomato/Blinkit Style: "Use Current Location" button
          InkWell(
            onTap: _isDetectingGps ? null : _handleGpsDetect,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF6B00).withOpacity(0.2),
                    const Color(0xFFFFB800).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  if (_isDetectingGps)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFFFF6B00),
                      ),
                    )
                  else
                    const Icon(Icons.my_location, color: Color(0xFFFF6B00), size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isDetectingGps ? 'Querying High-Accuracy GPS...' : 'Use Current Location',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Detects exact US address on-demand with zero battery drain',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white38),
                ],
              ),
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ],

          const SizedBox(height: 18),

          // US Address Search bar
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search US city, street or ZIP code...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E2330),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),

          // Popular US Food Truck Hubs
          const Text(
            'POPULAR US FOOD TRUCK HUBS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          ...UserLocation.kUsFoodTruckHubs.map((hub) {
            final isSelected = widget.currentLocation.label == hub.label;
            return InkWell(
              onTap: () {
                widget.onLocationSelected(hub);
                Navigator.of(context).pop();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF242C3F) : const Color(0xFF191E2B),
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? Border.all(color: const Color(0xFFFF6B00), width: 1.2) : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.storefront_outlined,
                      color: isSelected ? const Color(0xFFFF6B00) : Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hub.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            hub.formattedAddress,
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${hub.city}, ${hub.state}',
                      style: const TextStyle(color: Color(0xFFFFB800), fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
