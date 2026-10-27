class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isSignature;
  final bool isVegetarian;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isSignature = false,
    this.isVegetarian = false,
  });
}

class VideoReview {
  final String id;
  final String userName;
  final String userAvatar;
  final double rating;
  final String quote;
  final String thumbnailUrl;
  final String videoUrl;
  final String timeAgo;
  final bool isVideo;
  final String mediaCaption;
  final String duration;

  const VideoReview({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.quote,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.timeAgo,
    this.isVideo = true,
    this.mediaCaption = '',
    this.duration = '0:15',
  });
}

class PromoBanner {
  final String id;
  final String truckId;
  final String badgeText;
  final String headlineTop;
  final String headlineMain;
  final String subheadline;
  final String ctaText;
  final String imageUrl;
  final int primaryColorHex;
  final int secondaryColorHex;
  final int accentColorHex;

  const PromoBanner({
    required this.id,
    required this.truckId,
    required this.badgeText,
    required this.headlineTop,
    required this.headlineMain,
    required this.subheadline,
    required this.ctaText,
    required this.imageUrl,
    this.primaryColorHex = 0xFFD93829,
    this.secondaryColorHex = 0xFFB71C1C,
    this.accentColorHex = 0xFFFFD54F,
  });
}

enum TruckStatus { servingNow, onTheMove, closed }

class FoodTruck {
  final String id;
  final String name;
  final String tagline;
  final String cuisine;
  final double rating;
  final int reviewCount;
  final String priceRange; // $, $$, $$$
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String state;
  final TruckStatus status;
  final String lastConfirmed;
  final String closesAt;
  final String heroImageUrl;
  final String profileImageUrl;
  final String prepTimeWalkMins;
  final List<MenuItem> menu;
  final List<VideoReview> videoReviews;
  final bool isSponsored; // Pokémon GO "Lure" sponsored pin
  final double distanceInMiles;

  const FoodTruck({
    required this.id,
    required this.name,
    required this.tagline,
    required this.cuisine,
    required this.rating,
    required this.reviewCount,
    required this.priceRange,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.state,
    required this.status,
    required this.lastConfirmed,
    required this.closesAt,
    required this.heroImageUrl,
    required this.menu,
    required this.videoReviews,
    this.profileImageUrl = '',
    this.prepTimeWalkMins = '8-12 mins',
    this.isSponsored = false,
    this.distanceInMiles = 0.3,
  });

  bool get isNearAndFast =>
      distanceInMiles <= 1.0 && status == TruckStatus.servingNow;

  String get effectiveProfileImage =>
      profileImageUrl.isNotEmpty ? profileImageUrl : heroImageUrl;

  FoodTruck copyWith({
    String? name,
    String? tagline,
    String? cuisine,
    double? rating,
    int? reviewCount,
    String? priceRange,
    String? address,
    String? city,
    String? state,
    String? closesAt,
    String? heroImageUrl,
    String? profileImageUrl,
    String? prepTimeWalkMins,
    List<MenuItem>? menu,
    List<VideoReview>? videoReviews,
    double? distanceInMiles,
    TruckStatus? status,
    bool? isSponsored,
  }) {
    return FoodTruck(
      id: id,
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      cuisine: cuisine ?? this.cuisine,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      priceRange: priceRange ?? this.priceRange,
      latitude: latitude,
      longitude: longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      status: status ?? this.status,
      lastConfirmed: lastConfirmed,
      closesAt: closesAt ?? this.closesAt,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      prepTimeWalkMins: prepTimeWalkMins ?? this.prepTimeWalkMins,
      menu: menu ?? this.menu,
      videoReviews: videoReviews ?? this.videoReviews,
      isSponsored: isSponsored ?? this.isSponsored,
      distanceInMiles: distanceInMiles ?? this.distanceInMiles,
    );
  }
}
