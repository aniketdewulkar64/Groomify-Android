import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:groomify/services/location/location_service.dart';
import 'package:groomify/services/salon/salon_service.dart';
import 'package:groomify/models/salon.dart';
import 'package:groomify/config/theme.dart';
import 'package:intl/intl.dart';

class NearbySalonsScreen extends StatefulWidget {
  const NearbySalonsScreen({super.key});

  @override
  State<NearbySalonsScreen> createState() => _NearbySalonsScreenState();
}

class _NearbySalonsScreenState extends State<NearbySalonsScreen> {
  final SalonService _salonService = SalonService.instance;
  Position? _currentLocation;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final position = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentLocation = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Location access is required to find nearby salons.";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.goldenGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.premiumDark.withOpacity(0.2)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.premiumDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Nearby Salons',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.premiumDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.premiumDark));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 60, color: AppTheme.premiumDark),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: GoogleFonts.poppins(color: AppTheme.premiumDarkText, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _initLocation();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.premiumDark, 
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("Allow Location"),
              )
            ],
          ),
        ),
      );
    }

    final salons = _salonService.getNearbySalons("Mumbai", "Maharashtra", userLocation: _currentLocation);

    if (salons.isEmpty) {
      return Center(child: Text("No salons found nearby.", style: GoogleFonts.poppins(color: AppTheme.premiumDarkText, fontSize: 16)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: salons.length,
      itemBuilder: (context, index) {
        return _buildSalonCard(salons[index]);
      },
    );
  }

  Widget _buildSalonCard(Salon salon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppTheme.premiumDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.premiumDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  salon.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                     return Container(
                       height: 180,
                       width: double.infinity,
                       decoration: BoxDecoration(
                         gradient: LinearGradient(
                           colors: [Colors.grey[800]!, Colors.grey[900]!],
                           begin: Alignment.topLeft,
                           end: Alignment.bottomRight,
                         )
                       ),
                       child: Column(
                         mainAxisAlignment: MainAxisAlignment.center,
                         children: [
                           Icon(Icons.image_not_supported_outlined, size: 50, color: Colors.white.withOpacity(0.4)),
                           const SizedBox(height: 8),
                           Text("Image Not Available", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                         ],
                       ),
                     );
                  },
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        salon.rating.toStringAsFixed(1),
                        style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salon.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Info Row
                Row(
                  children: [
                    _buildInfoBadge(Icons.location_on, '${salon.distanceKm.toStringAsFixed(1)} km'),
                    const SizedBox(width: 12),
                    _buildInfoBadge(Icons.attach_money, salon.priceRange),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                         onPressed: () => _showReviewsModal(context, salon),
                         style: OutlinedButton.styleFrom(
                           foregroundColor: Colors.white,
                           side: BorderSide(color: Colors.white.withOpacity(0.3)),
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         ),
                         child: const Text("Reviews"),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final Uri url = Uri.parse(salon.googleMapsUrl);
                            try {
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                  await launchUrl(url); 
                              }
                            } catch (e) {
                               if (context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(content: Text("Could not open maps: $e")),
                                 );
                               }
                            }
                          },
                          icon: const Icon(Icons.map, size: 18),
                          label: const Text("Directions"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.premiumDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, duration: 400.ms);
  }

  // NEW: Proper Reviews Modal
  void _showReviewsModal(BuildContext context, Salon salon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AppTheme.premiumDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 24),
                  
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Customer Reviews", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                               const Icon(Icons.star, color: Colors.amber, size: 16),
                               const SizedBox(width: 4),
                               Text("${salon.rating.toStringAsFixed(1)} (${salon.reviewCount})", style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  
                  // List
                  Expanded(
                    child: salon.reviews.isEmpty
                     ? Center(child: Text("No reviews yet.", style: GoogleFonts.poppins(color: Colors.white60)))
                     : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        itemCount: salon.reviews.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 20),
                        itemBuilder: (context, index) {
                          final review = salon.reviews[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(review.userName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(DateFormat('MMM d, y').format(review.date), style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      Icons.star,
                                      size: 14,
                                      color: starIndex < review.rating ? Colors.amber : Colors.white24,
                                    );
                                  }),
                                ),
                                const SizedBox(height: 12),
                                Text(review.comment, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, height: 1.5)),
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                  
                  // Close Button
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.premiumDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Close", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
