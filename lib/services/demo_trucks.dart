import '../models/food_truck.dart';
import 'location_service.dart';

// Bundled Miami Demo Hub data (4 seed trucks) with expanded dish menus (each with
// dish image), video & photo reviews, and Zomato-style upper hero promotions.
class DemoTrucks {
  static const UserLocation miamiHub = UserLocation.defaultMiami;

  static final Map<String, FoodTruck> _sessionOverrides = {};

  static const List<PromoBanner> heroPromotions = [
    PromoBanner(
      id: 'promo_birria',
      truckId: 'a1111111-aaaa-1111-aaaa-111111111111',
      badgeText: 'SPONSORED • WYNWOOD HOTSPOT',
      headlineTop: 'CRISPY BIRRIA',
      headlineMain: 'FEAST LIVE NOW',
      subheadline: 'Taco Trail Express • 2407 NW 2nd Ave • Hot Consomé',
      ctaText: 'Order window',
      imageUrl:
          'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=800&q=80',
      primaryColorHex: 0xFFD93829,
      secondaryColorHex: 0xFFB71C1C,
      accentColorHex: 0xFFFFD54F,
    ),
    PromoBanner(
      id: 'promo_smash',
      truckId: 'a2222222-aaaa-2222-aaaa-222222222222',
      badgeText: 'NEW MENU DROP • SMASH HOUR',
      headlineTop: 'DOUBLE ANGUS',
      headlineMain: 'SMASH & FRIES',
      subheadline: 'Burger Bus Co. • Butter-Toasted Brioche & Truffle Fries',
      ctaText: 'Explore menu',
      imageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=800&q=80',
      primaryColorHex: 0xFFC62828,
      secondaryColorHex: 0xFF8E0000,
      accentColorHex: 0xFFFFCA28,
    ),
    PromoBanner(
      id: 'promo_brew',
      truckId: 'a3333333-aaaa-3333-aaaa-333333333333',
      badgeText: 'CRAFT CAFE TRUCK • SERVING NOW',
      headlineTop: '20-HR NITRO BREW',
      headlineMain: '& HOT CHURROS',
      subheadline: 'The Brew Crew Coffee • 2215 NW 2nd Ave • Dulce Dip',
      ctaText: 'Grab coffee',
      imageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=800&q=80',
      primaryColorHex: 0xFF6D3B24,
      secondaryColorHex: 0xFF3E2013,
      accentColorHex: 0xFFFFE082,
    ),
    PromoBanner(
      id: 'promo_arepas',
      truckId: 'a4444444-aaaa-4444-aaaa-444444444444',
      badgeText: 'LATIN STREET KITCHEN • 100% GF',
      headlineTop: 'HOT STUFFED',
      headlineMain: 'MIAMI AREPAS',
      subheadline: 'Miami Arepas Cart • Reina Pepiada & Crispy Tequeños',
      ctaText: 'View truck',
      imageUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=800&q=80',
      primaryColorHex: 0xFFE65100,
      secondaryColorHex: 0xFFBF360C,
      accentColorHex: 0xFFFFF176,
    ),
  ];

  /// Seed trucks with distances computed from [userLat]/[userLng] and
  /// rounded to one decimal place, like the backend's distance display.
  static List<FoodTruck> forLocation({
    required double userLat,
    required double userLng,
  }) {
    return _seedTrucks.map((baseTruck) {
      final truck = _sessionOverrides[baseTruck.id] ?? baseTruck;
      final distance = LocationService.calculateDistanceInMiles(
        userLat,
        userLng,
        truck.latitude,
        truck.longitude,
      );
      return truck.copyWith(
        distanceInMiles: double.parse(distance.toStringAsFixed(1)),
      );
    }).toList();
  }

  /// The Miami demo hub: the seed trucks measured from Wynwood.
  static List<FoodTruck> get miamiHubTrucks => forLocation(
        userLat: miamiHub.latitude,
        userLng: miamiHub.longitude,
      );

  static FoodTruck getTruckById(String id) {
    final base = _seedTrucks.firstWhere(
      (t) => t.id == id,
      orElse: () => _seedTrucks.first,
    );
    return _sessionOverrides[id] ?? base;
  }

  static void updateTruckProfile({
    required String truckId,
    String? name,
    String? tagline,
    String? cuisine,
    String? address,
    String? closesAt,
    String? profileImageUrl,
    TruckStatus? status,
  }) {
    final current = getTruckById(truckId);
    _sessionOverrides[truckId] = current.copyWith(
      name: name,
      tagline: tagline,
      cuisine: cuisine,
      address: address,
      closesAt: closesAt,
      profileImageUrl: profileImageUrl,
      heroImageUrl: (profileImageUrl != null && profileImageUrl.isNotEmpty)
          ? profileImageUrl
          : current.heroImageUrl,
      status: status,
    );
  }

  static void addDishToTruck(String truckId, MenuItem newDish) {
    final current = getTruckById(truckId);
    final updatedMenu = [newDish, ...current.menu];
    _sessionOverrides[truckId] = current.copyWith(menu: updatedMenu);
  }

  static void addReviewToTruck(String truckId, VideoReview newReview) {
    final current = getTruckById(truckId);
    final updatedReviews = [newReview, ...current.videoReviews];
    final avgRating = updatedReviews
            .map((r) => r.rating)
            .reduce((a, b) => a + b) /
        updatedReviews.length;
    _sessionOverrides[truckId] = current.copyWith(
      videoReviews: updatedReviews,
      reviewCount: updatedReviews.length,
      rating: double.parse(avgRating.toStringAsFixed(1)),
    );
  }

  static const List<FoodTruck> _seedTrucks = [
    FoodTruck(
      id: 'a1111111-aaaa-1111-aaaa-111111111111',
      name: 'Taco Trail Express',
      tagline: 'Authentic Jalisco street tacos & melted birria',
      cuisine: 'Mexican • Tacos',
      rating: 4.9,
      reviewCount: 4,
      priceRange: r'$',
      latitude: 25.7997,
      longitude: -80.1986,
      address: '2407 NW 2nd Ave',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.servingNow,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      prepTimeWalkMins: '6-10 mins',
      heroImageUrl:
          'https://images.unsplash.com/photo-1565123409695-7b5ef63a2efb?auto=format&fit=crop&w=1200&q=80',
      profileImageUrl:
          'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
      menu: [
        MenuItem(
          id: 'm1',
          name: 'Crispy Quesabirria Tacos (3x)',
          description:
              'Braised beef birria, melted Oaxaca cheese, cilantro, onions, with rich consomé broth.',
          price: 13.50,
          imageUrl:
              'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm2',
          name: 'Al Pastor Street Tacos (3x)',
          description:
              'Marinated pork shaved fresh from the trompo with grilled pineapple and salsa verde.',
          price: 10.99,
          imageUrl:
              'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm3',
          name: 'Chorizo Loaded Queso Fries',
          description:
              'Golden waffle fries topped with warm queso blanco, spiced chorizo, and jalapeños.',
          price: 9.75,
          imageUrl:
              'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm4',
          name: 'Carne Asada Mulitas (2x)',
          description:
              'Double griddled handmade corn tortillas stuffed with charred steak, jack cheese & guacamole.',
          price: 12.25,
          imageUrl:
              'https://images.unsplash.com/photo-1613514785940-daed07799d9b?auto=format&fit=crop&w=600&q=80',
        ),
        MenuItem(
          id: 'm5',
          name: 'Roasted Street Corn Elote Cup',
          description:
              'Charred sweet corn off the cob layered with chipotle crema, cotija cheese, and Tajín.',
          price: 6.50,
          imageUrl:
              'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm6',
          name: 'Cinnamon Spiced Horchata',
          description:
              'House-made rice milk with Ceylon cinnamon and Mexican vanilla.',
          price: 4.50,
          imageUrl:
              'https://images.unsplash.com/photo-1541658016709-82535e94bc69?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
      ],
      videoReviews: [
        VideoReview(
          id: 'vr_t1',
          userName: 'Carlos M.',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
          rating: 5.0,
          quote:
              'The cheese pull on the Quesabirria tacos is unreal! Dipped right into the steaming consomé cup at the Wynwood curb.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/birria_dip',
          timeAgo: '18m ago',
          isVideo: true,
          mediaCaption: 'Quesabirria Dip & Cheese Pull Reel',
          duration: '0:15',
        ),
        VideoReview(
          id: 'vr_t2',
          userName: 'Elena R.',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
          rating: 5.0,
          quote:
              'Watched them shave the Al Pastor straight off the vertical spit onto fresh tortillas. Super fast window service!',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/al_pastor',
          timeAgo: '1h ago',
          isVideo: true,
          mediaCaption: 'Trompo Al Pastor Shaving Clip',
          duration: '0:12',
        ),
        VideoReview(
          id: 'vr_t3',
          userName: 'Marcus V.',
          userAvatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
          rating: 4.8,
          quote:
              'Chorizo queso fries and ice-cold horchata are the ultimate late afternoon combo in Wynwood.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80',
          videoUrl: '',
          timeAgo: '3h ago',
          isVideo: false,
          mediaCaption: 'Loaded Chorizo Queso Fries Photo',
          duration: 'PHOTO',
        ),
      ],
      isSponsored: true,
    ),
    FoodTruck(
      id: 'a2222222-aaaa-2222-aaaa-222222222222',
      name: 'Burger Bus Co.',
      tagline: 'Double smash burgers with butter-toasted brioche',
      cuisine: 'American • Burgers',
      rating: 4.8,
      reviewCount: 3,
      priceRange: r'$$',
      latitude: 25.8015,
      longitude: -80.1992,
      address: '2600 NW Miami Ct',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.servingNow,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      prepTimeWalkMins: '8-12 mins',
      heroImageUrl:
          'https://images.unsplash.com/photo-1525164286253-04e68b9d94c6?auto=format&fit=crop&w=1200&q=80',
      profileImageUrl:
          'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
      menu: [
        MenuItem(
          id: 'm7',
          name: 'The Wynwood Double Smash',
          description:
              'Two smashed Angus beef patties, caramelized grilled onions, American cheese, house sauce.',
          price: 12.99,
          imageUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm8',
          name: 'Oklahoma Crispy Onion Smash',
          description:
              'Paper-thin Vidalia onions smashed into double beef patties with pickles and mustard glaze.',
          price: 13.49,
          imageUrl:
              'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm9',
          name: 'Hot Honey Crispy Chicken Brioche',
          description:
              'Buttermilk fried chicken thigh glazed in chili honey with jalapeno slaw on toasted brioche.',
          price: 11.99,
          imageUrl:
              'https://images.unsplash.com/photo-1606755962773-d324e0a13086?auto=format&fit=crop&w=600&q=80',
        ),
        MenuItem(
          id: 'm10',
          name: 'Truffle Parmesan Fries',
          description:
              'Crispy skin-on fries tossed in white truffle oil, pecorino, and fresh parsley.',
          price: 7.99,
          imageUrl:
              'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm11',
          name: 'Malted Vanilla Bean Shake',
          description:
              'Hand-spun Florida creamery vanilla bean shake topped with whipped cream.',
          price: 6.50,
          imageUrl:
              'https://images.unsplash.com/photo-1572490122747-3968b75cc699?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
      ],
      videoReviews: [
        VideoReview(
          id: 'vr_b1',
          userName: 'Devon T.',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
          rating: 5.0,
          quote:
              'Lacy crispy edges on the Wynwood Double Smash! You can hear the sizzle from half a block away.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/smash_sizzle',
          timeAgo: '35m ago',
          isVideo: true,
          mediaCaption: 'Flat-Top Smash Burger Sizzle Reel',
          duration: '0:14',
        ),
        VideoReview(
          id: 'vr_b2',
          userName: 'Hannah L.',
          userAvatar:
              'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=200&q=80',
          rating: 4.8,
          quote:
              'Truffle parmesan fries came out piping hot with real grated pecorino.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
          videoUrl: '',
          timeAgo: '2h ago',
          isVideo: false,
          mediaCaption: 'Truffle Fries & Brioche Burger Photo',
          duration: 'PHOTO',
        ),
        VideoReview(
          id: 'vr_b3',
          userName: 'Samir N.',
          userAvatar:
              'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&w=200&q=80',
          rating: 4.7,
          quote:
              'Oklahoma onion smash + malted vanilla shake is undefeated.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1586190848861-99aa4a171e90?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/onion_smash',
          timeAgo: '1d ago',
          isVideo: true,
          mediaCaption: 'Oklahoma Onion Smash Review',
          duration: '0:11',
        ),
      ],
    ),
    FoodTruck(
      id: 'a3333333-aaaa-3333-aaaa-333333333333',
      name: 'The Brew Crew Coffee',
      tagline: 'Nitro cold brews & fresh artisan churros',
      cuisine: 'Cafe • Coffee & Desserts',
      rating: 4.9,
      reviewCount: 3,
      priceRange: r'$',
      latitude: 25.7981,
      longitude: -80.1970,
      address: '2215 NW 2nd Ave',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.servingNow,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      prepTimeWalkMins: '5-8 mins',
      heroImageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=1200&q=80',
      profileImageUrl:
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
      menu: [
        MenuItem(
          id: 'm12',
          name: 'Velvet Vanilla Nitro Cold Brew',
          description:
              '20-hour steeped single-origin Colombian cold brew infused with nitrogen and Madagascar vanilla.',
          price: 6.25,
          imageUrl:
              'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm13',
          name: 'Cinnamon Churros & Dulce de Leche (4x)',
          description:
              'Fried-to-order crispy churro loops dusted in cinnamon sugar with warm dulce de leche dip.',
          price: 8.50,
          imageUrl:
              'https://images.unsplash.com/photo-1624371414361-e670edf4898d?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm14',
          name: 'Iced Brown Sugar Oat Cortado',
          description:
              'Double ristretto espresso shaken with dark muscovado syrup and creamy oat milk.',
          price: 5.75,
          imageUrl:
              'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm15',
          name: 'Guava & Cream Cheese Pastelito',
          description:
              'Flaky puff pastry filled with tropical red guava marmalade and whipped cream cheese.',
          price: 4.95,
          imageUrl:
              'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm16',
          name: 'Ceremonial Matcha Yuzu Fizz',
          description:
              'Uji ceremonial matcha whisked over sparkling yuzu citrus tonic.',
          price: 6.50,
          imageUrl:
              'https://images.unsplash.com/photo-1515823662972-da6a2e4d3002?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
      ],
      videoReviews: [
        VideoReview(
          id: 'vr_c1',
          userName: 'Sofia G.',
          userAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
          rating: 5.0,
          quote:
              'Watching the cascading nitrogen micro-foam settle in the cup while dipping hot churros is pure bliss.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/nitro_pour',
          timeAgo: '25m ago',
          isVideo: true,
          mediaCaption: 'Nitro Cold Brew Cascade & Churros Reel',
          duration: '0:16',
        ),
        VideoReview(
          id: 'vr_c2',
          userName: 'Liam B.',
          userAvatar:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
          rating: 4.9,
          quote:
              'Churros are fried fresh when you order—crispy outside, pillowy inside.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1624371414361-e670edf4898d?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/churros',
          timeAgo: '4h ago',
          isVideo: true,
          mediaCaption: 'Fresh Cinnamon Churros & Dulce Dip',
          duration: '0:10',
        ),
        VideoReview(
          id: 'vr_c3',
          userName: 'Nina W.',
          userAvatar:
              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
          rating: 4.8,
          quote:
              'Best iced brown sugar oat cortado in Miami.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?auto=format&fit=crop&w=600&q=80',
          videoUrl: '',
          timeAgo: 'Yesterday',
          isVideo: false,
          mediaCaption: 'Brown Sugar Cortado & Pastelito Photo',
          duration: 'PHOTO',
        ),
      ],
    ),
    FoodTruck(
      id: 'a4444444-aaaa-4444-aaaa-444444444444',
      name: 'Miami Arepas Cart',
      tagline: 'Gluten-free Venezuelan corn cakes stuffed hot',
      cuisine: 'Latin • Venezuelan',
      rating: 4.9,
      reviewCount: 3,
      priceRange: r'$',
      latitude: 25.8020,
      longitude: -80.2010,
      address: '2801 NW 3rd Ave',
      city: 'Miami',
      state: 'FL',
      status: TruckStatus.onTheMove,
      lastConfirmed: 'Just now',
      closesAt: '10:00 PM',
      prepTimeWalkMins: '12-16 mins',
      heroImageUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=1200&q=80',
      profileImageUrl:
          'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
      menu: [
        MenuItem(
          id: 'm17',
          name: 'Arepa Reina Pepiada',
          description:
              'Griddled white cornmeal cake stuffed with pulled chicken, creamy avocado salad, and cilantro.',
          price: 11.50,
          imageUrl:
              'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm18',
          name: 'Arepa Pabellón Criollo',
          description:
              'Shredded flank steak, sweet fried plantains (tajadas), black beans, and grated queso blanco.',
          price: 12.75,
          imageUrl:
              'https://images.unsplash.com/photo-1551504734-5ee1c4a1479b?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
        ),
        MenuItem(
          id: 'm19',
          name: 'Crispy Cheese Tequeños (5x)',
          description:
              'Golden fried pastry spears wrapped around salty Venezuelan queso blanco with guasacaca dip.',
          price: 8.50,
          imageUrl:
              'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80',
          isSignature: true,
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm20',
          name: 'Sweet Plantain & Queso de Mano Arepa',
          description:
              'Caramelized ripe plantains and thick slices of soft handmade Venezuelan cheese.',
          price: 10.25,
          imageUrl:
              'https://images.unsplash.com/photo-1613514785940-daed07799d9b?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
        MenuItem(
          id: 'm21',
          name: 'Fresh Parchita Passionfruit Agua Fresca',
          description:
              'Pressed Venezuelan passionfruit juice over crushed ice with cane sugar.',
          price: 4.75,
          imageUrl:
              'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=600&q=80',
          isVegetarian: true,
        ),
      ],
      videoReviews: [
        VideoReview(
          id: 'vr_a1',
          userName: 'Gabriela D.',
          userAvatar:
              'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
          rating: 5.0,
          quote:
              'Authentic Caracas flavor! The Reina Pepiada is overflowing with avocado chicken salad and the guasacaca sauce is spot on.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/reina_pepiada',
          timeAgo: '40m ago',
          isVideo: true,
          mediaCaption: 'Stuffing Hot Reina Pepiada Arepa Reel',
          duration: '0:15',
        ),
        VideoReview(
          id: 'vr_a2',
          userName: 'Mateo F.',
          userAvatar:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
          rating: 4.9,
          quote:
              'Do not skip the Tequeños—stretchy white cheese inside crisp pastry with green avocado salsa.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1585109649139-366815a0d713?auto=format&fit=crop&w=600&q=80',
          videoUrl: 'https://roambite.demo/video/tequenos',
          timeAgo: '5h ago',
          isVideo: true,
          mediaCaption: 'Cheese Pull on Crispy Tequeños',
          duration: '0:12',
        ),
        VideoReview(
          id: 'vr_a3',
          userName: 'Chloe S.',
          userAvatar:
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
          rating: 4.8,
          quote:
              '100% gluten-free corn cakes so our whole group could eat safely and deliciously.',
          thumbnailUrl:
              'https://images.unsplash.com/photo-1613514785940-daed07799d9b?auto=format&fit=crop&w=600&q=80',
          videoUrl: '',
          timeAgo: '2d ago',
          isVideo: false,
          mediaCaption: 'Arepa Pabellón Criollo Photo',
          duration: 'PHOTO',
        ),
      ],
    ),
  ];
}
