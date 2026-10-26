import '../models/food_truck.dart';
import 'location_service.dart';

// Slice 4: bundled demo data matching supabase/seed.sql exactly for names,
// taglines, cuisines, signature dishes, price ranges, addresses, city,
// state, hero images, sponsored flag, coordinates and live statuses.
// The seed carries no reviews, so these trucks show rating 5.0 with
// reviewCount 0, matching the backend's no-review default. Menus are the
// seed menus for the first two trucks; the seed has no menus for the
// other two, so theirs are empty here too. Used when the backend is
// unreachable and for the Miami demo hub, so the dashboard never shows
// an empty list without an explanation.
class DemoTrucks {
  static const UserLocation miamiHub = UserLocation.defaultMiami;

  /// Seed trucks with distances computed from [userLat]/[userLng] and
  /// rounded to one decimal place, like the backend's distance display.
  static List<FoodTruck> forLocation({
    required double userLat,
    required double userLng,
  }) {
    return _seedTrucks.map((truck) {
      final distance = LocationService.calculateDistanceInMiles(
        userLat,
        userLng,
        truck.latitude,
        truck.longitude,
      );
      return truck.copyWith(distanceInMiles: double.parse(distance.toStringAsFixed(1)));
    }).toList();
  }

  /// The Miami demo hub: the seed trucks measured from Wynwood.
  static List<FoodTruck> get miamiHubTrucks => forLocation(
        userLat: miamiHub.latitude,
        userLng: miamiHub.longitude,
      );

  static const List<FoodTruck> _seedTrucks = [
    FoodTruck(
      id: 'a1111111-aaaa-1111-aaaa-111111111111',
      name: 'Taco Trail Express',
      tagline: 'Authentic Jalisco street tacos & melted birria',
      cuisine: 'Mexican • Tacos',
      rating: 5.0,
      reviewCount: 0,
      priceRange: r'$',
      latitude: 25.7997,
      longitude: -80.1986,
      address: '2407 NW 2nd Ave',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.servingNow,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      heroImageUrl: 'https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?auto=format&fit=crop&w=1200&q=80',
      menu: [
        MenuItem(
          id: 'm1',
          name: 'Crispy Quesabirria Tacos (3x)',
          description: 'Braised beef birria, melted Oaxaca cheese, cilantro, onions, with rich consomé broth.',
          price: 13.50,
          imageUrl: 'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm2',
          name: 'Al Pastor Street Tacos',
          description: 'Marinated pork shaved fresh from the trompo with grilled pineapple and salsa verde.',
          price: 10.99,
          imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
        ),
        MenuItem(
          id: 'm3',
          name: 'Chorizo Loaded Queso Fries',
          description: 'Golden waffle fries topped with warm queso blanco, spiced chorizo, and jalapeños.',
          price: 9.75,
          imageUrl: 'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm4',
          name: 'Cinnamon Spiced Horchata',
          description: 'House-made rice milk with Ceylon cinnamon and Mexican vanilla.',
          price: 4.50,
          imageUrl: 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?auto=format&fit=crop&w=600&q=80',
        ),
      ],
      videoReviews: [],
      isSponsored: true,
    ),
    FoodTruck(
      id: 'a2222222-aaaa-2222-aaaa-222222222222',
      name: 'Burger Bus Co.',
      tagline: 'Double smash burgers with butter-toasted brioche',
      cuisine: 'American • Burgers',
      rating: 5.0,
      reviewCount: 0,
      priceRange: r'$$',
      latitude: 25.8015,
      longitude: -80.1992,
      address: '2600 NW Miami Ct',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.servingNow,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      heroImageUrl: 'https://images.unsplash.com/photo-1525164286253-04e68b9d94c6?auto=format&fit=crop&w=1200&q=80',
      menu: [
        MenuItem(
          id: 'm5',
          name: 'The Wynwood Double Smash',
          description: 'Two smashed Angus beef patties, caramelized grilled onions, American cheese, house sauce.',
          price: 12.99,
          imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm6',
          name: 'Truffle Parmesan Fries',
          description: 'Crispy skin-on fries tossed in white truffle oil, pecorino, and fresh parsley.',
          price: 7.99,
          imageUrl: 'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
        ),
      ],
      videoReviews: [],
    ),
    FoodTruck(
      id: 'a3333333-aaaa-3333-aaaa-333333333333',
      name: 'The Brew Crew Coffee',
      tagline: 'Nitro cold brews & fresh artisan churros',
      cuisine: 'Cafe • Coffee & Desserts',
      rating: 5.0,
      reviewCount: 0,
      priceRange: r'$',
      latitude: 25.7981,
      longitude: -80.1970,
      address: '2215 NW 2nd Ave',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.servingNow,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      heroImageUrl: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80',
      menu: [],
      videoReviews: [],
    ),
    FoodTruck(
      id: 'a4444444-aaaa-4444-aaaa-444444444444',
      name: 'Miami Arepas Cart',
      tagline: 'Gluten-free Venezuelan corn cakes stuffed hot',
      cuisine: 'Latin • Venezuelan',
      rating: 5.0,
      reviewCount: 0,
      priceRange: r'$',
      latitude: 25.8020,
      longitude: -80.2010,
      address: '2801 NW 3rd Ave',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.onTheMove,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      heroImageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=1200&q=80',
      menu: [],
      videoReviews: [],
    ),
  ];
}
