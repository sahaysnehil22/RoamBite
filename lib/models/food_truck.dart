class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isSignature;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.isSignature = false,
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

  const VideoReview({
    required this.id,
    required this.userName,
    required this.userAvatar,
    required this.rating,
    required this.quote,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.timeAgo,
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
    this.isSponsored = false,
    this.distanceInMiles = 0.3,
  });

  FoodTruck copyWith({
    double? distanceInMiles,
    TruckStatus? status,
    bool? isSponsored,
  }) {
    return FoodTruck(
      id: id,
      name: name,
      tagline: tagline,
      cuisine: cuisine,
      rating: rating,
      reviewCount: reviewCount,
      priceRange: priceRange,
      latitude: latitude,
      longitude: longitude,
      address: address,
      city: city,
      state: state,
      status: status ?? this.status,
      lastConfirmed: lastConfirmed,
      closesAt: closesAt,
      heroImageUrl: heroImageUrl,
      menu: menu,
      videoReviews: videoReviews,
      isSponsored: isSponsored ?? this.isSponsored,
      distanceInMiles: distanceInMiles ?? this.distanceInMiles,
    );
  }
}
