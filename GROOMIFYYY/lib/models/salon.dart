class Salon {
  final String name;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String priceRange; // e.g. "₹500 - ₹1500"
  final String imageUrl;
  final String googleMapsUrl;
  final List<String> specializedStyles;
  final List<Review> reviews;
  final List<SalonServiceItem> services;
  final bool isTopRated;
  final bool isBudget;

  final String address;

  const Salon({
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.priceRange,
    required this.imageUrl,
    required this.googleMapsUrl,
    this.specializedStyles = const [],
    this.reviews = const [],
    this.services = const [],
    this.isTopRated = false,
    this.isBudget = false,
  });
}

class Review {
  final String userName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.userName,
    required this.rating,
    required this.comment,
    required this.date,
  });
}

class SalonServiceItem {
  final String name;
  final String price;

  const SalonServiceItem({required this.name, required this.price});
}
