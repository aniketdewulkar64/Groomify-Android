import 'package:groomify/models/salon.dart';
import 'package:geolocator/geolocator.dart';

class SalonService {
  static final SalonService instance = SalonService._init();
  SalonService._init();

  // Mock Data for "Mumbai, Maharashtra" (as per requirements)
  // In a real app, this would query a backend API with lat/long
  
  Map<String, List<Salon>> getRecommendations(String city, String state, {Position? userLocation}) {
    // Generate fresh random data each time to simulate live updates
    final List<Salon> allSalons = _generateMockSalons(userLocation);
    
    // Sort by distance if we have location
    if (userLocation != null) {
      allSalons.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else {
       allSalons.shuffle(); // Randomize order if no location
    }

    // Nearby logic: < 3km
    final nearby = allSalons.where((s) => s.distanceKm < 3.0).toList();
    if (nearby.length > 4) nearby.length = 4;

    return {
      'Top Rated': allSalons.where((s) => s.rating >= 4.5).take(4).toList(),
      'Budget Friendly': allSalons.where((s) => s.isBudget).take(4).toList(),
      'Nearby': nearby.isEmpty ? allSalons.where((s) => !s.isTopRated && !s.isBudget).take(4).toList() : nearby,
    };
  }

  // New method for simplified view
  List<Salon> getNearbySalons(String city, String state, {Position? userLocation}) {
    final List<Salon> allSalons = _generateMockSalons(userLocation);
    if (userLocation != null) {
      allSalons.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else {
      allSalons.shuffle();
    }
    return allSalons;
  }

  List<Salon> _generateMockSalons(Position? userLoc) {
    final random = DateTime.now().millisecondsSinceEpoch;
    
    double dist(double base) {
       // If we had real lat/long of salons, we'd calculate distance from userLoc.
       // Here we mock it effectively.
       if (userLoc != null) {
         // Simulate finding some very close
         return (base * 0.5) + (random % 10) / 10; 
       }
       return base;
    }

    // Base data
    return [
      Salon(
        name: "Enrich Salon",
        address: "Orbital Road, Bandra West",
        rating: 4.5 + (random % 5) / 10,
        reviewCount: 1200 + (random % 100),
        distanceKm: dist(0.8),
        priceRange: "₹800 - ₹2500",
        imageUrl: "https://images.unsplash.com/photo-1560066984-138dadb4c035?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=Enrich+Salon+Mumbai",
        specializedStyles: ["Fade", "Undercut", "Beard Styling"],
        isTopRated: true,
        reviews: _generateReviews(10),
        services: [
           const SalonServiceItem(name: "Classic Haircut", price: "₹800"),
           const SalonServiceItem(name: "Beard Trim & Shape", price: "₹450"),
           const SalonServiceItem(name: "Hair Spa (L'Oreal)", price: "₹1800"),
           const SalonServiceItem(name: "Stylist Consultation", price: "Free"),
        ],
      ),
       Salon(
        name: "BBlunt",
        address: "Khar West, Linking Road",
        rating: 4.6 + (random % 4) / 10,
        reviewCount: 900 + (random % 150),
        distanceKm: dist(2.5),
        priceRange: "₹1200 - ₹3500",
        imageUrl: "https://images.unsplash.com/photo-1521590832896-72f06743122c?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=BBlunt+Mumbai",
        specializedStyles: ["Textured Crop", "Layered Cut"],
        isTopRated: true,
        reviews: _generateReviews(8),
        services: [
           const SalonServiceItem(name: "Director's Cut", price: "₹1500"),
           const SalonServiceItem(name: "Advanced Styling", price: "₹900"),
           const SalonServiceItem(name: "Scalp Treatment", price: "₹2200"),
           const SalonServiceItem(name: "Color Global", price: "₹3500+"),
        ],
      ),
      Salon(
        name: "Truefitt & Hill",
        address: "Colaba, near Taj Mahal Palace",
        rating: 4.8 + (random % 2) / 10,
        reviewCount: 500 + (random % 50),
        distanceKm: dist(4.2),
        priceRange: "₹2500+",
        imageUrl: "https://images.unsplash.com/photo-1503951914875-befbb7110526?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=Truefitt+and+Hill+Mumbai",
        specializedStyles: ["Classic Shave", "Royal Haircut"],
        isTopRated: true,
        reviews: _generateReviews(12),
        services: [
           const SalonServiceItem(name: "The Royal Shave", price: "₹2100"),
           const SalonServiceItem(name: "Classic Haircut", price: "₹2400"),
           const SalonServiceItem(name: "Manicure", price: "₹1600"),
           const SalonServiceItem(name: "Head Massage (30min)", price: "₹1800"),
        ],
      ),
      Salon(
        name: "Smart Look Men's Salon",
        address: "Andheri East, Station Road",
        rating: 4.0 + (random % 5) / 10,
        reviewCount: 150 + (random % 50),
        distanceKm: dist(1.2),
        priceRange: "₹200 - ₹500",
        imageUrl: "https://images.unsplash.com/photo-1620331311520-246422fd82f9?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=Smart+Look+Men+Salon+Mumbai",
        specializedStyles: ["Basic Cut", "Shaving"],
        isBudget: true,
        reviews: _generateReviews(5),
        services: [
           const SalonServiceItem(name: "Haircut", price: "₹200"),
           const SalonServiceItem(name: "Shaving", price: "₹150"),
           const SalonServiceItem(name: "Head Massage", price: "₹250"),
        ],
      ),
      Salon(
        name: "City Cuts",
        address: "Dadar West, Flower Market",
        rating: 3.8 + (random % 6) / 10,
        reviewCount: 80 + (random % 30),
        distanceKm: dist(0.5),
        priceRange: "₹150 - ₹400",
        imageUrl: "https://images.unsplash.com/photo-1599351431202-1e0f01ba30b8?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=City+Cuts+Salon",
        isBudget: true,
        reviews: _generateReviews(3),
        services: [
           const SalonServiceItem(name: "Quick Cut", price: "₹150"),
           const SalonServiceItem(name: "Beard Trim", price: "₹100"),
           const SalonServiceItem(name: "Color (Black)", price: "₹400"),
        ],
      ),
      Salon(
        name: "Javed Habib HairXpreso",
        address: "Phoenix Marketcity, Kurla",
        rating: 4.0 + (random % 4) / 10,
        reviewCount: 300 + (random % 40),
        distanceKm: dist(0.3),
        priceRange: "₹300 - ₹800",
        imageUrl: "https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=Javed+Habib+HairXpreso",
        reviews: _generateReviews(6),
        services: [
           const SalonServiceItem(name: "Dry Haircut", price: "₹350"),
           const SalonServiceItem(name: "Hair Wash", price: "₹150"),
           const SalonServiceItem(name: "Styling", price: "₹200"),
        ],
      ),
      Salon(
        name: "Looks Unisex Salon",
        address: "Juhu Tara Road",
        rating: 4.2 + (random % 4) / 10,
        reviewCount: 210 + (random % 60),
        distanceKm: dist(1.5),
        priceRange: "₹500 - ₹1200",
        imageUrl: "https://images.unsplash.com/photo-1562322140-8baeececf3df?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=Looks+Unisex+Salon",
        reviews: _generateReviews(7),
        services: [
           const SalonServiceItem(name: "Creative Cut", price: "₹650"),
           const SalonServiceItem(name: "Beard Spa", price: "₹500"),
           const SalonServiceItem(name: "Keratin Treatment", price: "₹4000"),
        ],
      ),
      Salon(
        name: "Urban Company Partner",
        address: "Home Service",
        rating: 4.5,
        reviewCount: 1500,
        distanceKm: 0.0,
        priceRange: "₹400 - ₹900",
        imageUrl: "https://images.unsplash.com/photo-1605497788044-5a32c7078486?auto=format&fit=crop&q=80&w=300",
        googleMapsUrl: "https://www.google.com/maps/search/?api=1&query=Urban+Company",
        isTopRated: true,
        reviews: _generateReviews(15),
        services: [
           const SalonServiceItem(name: "Haircut for Men", price: "₹450"),
           const SalonServiceItem(name: "Massage for Men", price: "₹800"),
           const SalonServiceItem(name: "Face Care", price: "₹700"),
        ],
      ),
    ];
  }

  List<Review> _generateReviews(int count) {
    final names = ["Rahul", "Sarthak", "Amit", "Vikram", "Rohan", "Aditya", "Kabir", "Arjun", "Karan", "Neil"];
    final comments = [
      "Great service! enjoyed the haircut.",
      "Professional staff and clean ambience.",
      "Value for money. Will visit again.",
      "Best salon in the area for sure.",
      "Did a fantastic job with my beard.",
      "Wait time was a bit long, but worth it.",
      "Very skilled barbers, highly recommended!",
      "Clean, hygienic, and affordable.",
      "The expert stylist knew exactly what I wanted.",
      "Good experience overall."
    ];
    
    final List<Review> reviews = [];
    final now = DateTime.now();
    
    for (int i = 0; i < count; i++) {
       reviews.add(Review(
         userName: names[i % names.length],
         rating: 4.0 + (i % 2), // 4.0 or 5.0 mostly
         comment: comments[i % comments.length],
         date: now.subtract(Duration(days: i * 2)),
       ));
    }
    return reviews;
  }
}
