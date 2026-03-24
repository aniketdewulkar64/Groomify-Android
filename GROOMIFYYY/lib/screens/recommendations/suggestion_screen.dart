import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:groomify/services/location/location_service.dart';
import 'package:groomify/models/face_shape.dart';
import 'package:groomify/services/recommendation/recommendation_service.dart';
import 'package:groomify/services/database/database_service.dart';
import 'package:groomify/services/storage/storage_service.dart';
import 'package:groomify/screens/ar/virtual_try_on_screen.dart';
import 'package:groomify/services/salon/salon_service.dart';
import 'package:groomify/models/salon.dart';
import 'package:groomify/models/recommendation.dart';
import 'package:groomify/widgets/display_image.dart';
import 'package:groomify/config/theme.dart';

class SuggestionScreen extends StatefulWidget {
  final FaceShapeResult faceShapeResult;
  final String imagePath;
  final bool isGuest;
  final int? userId;
  final bool showHairstylesOnly;
  final bool showBeardsOnly;

  const SuggestionScreen({
    super.key,
    required this.faceShapeResult,
    required this.imagePath,
    required this.isGuest,
    this.userId,
    this.showHairstylesOnly = false,
    this.showBeardsOnly = false,
  });

  @override
  State<SuggestionScreen> createState() => _SuggestionScreenState();
}

class _SuggestionScreenState extends State<SuggestionScreen> with SingleTickerProviderStateMixin {
  final RecommendationService _recommendationService = RecommendationService.instance;
  final SalonService _salonService = SalonService.instance;

  late TabController _tabController;
  String _selectedHairCategory = 'All';
  bool _isSaving = false;
  Position? _currentLocation;
  bool _isLoadingLocation = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateAnalysisText();
    _loadLocationAndSalons();
    
    // Cache the recommendations ONCE so they don't re-shuffle on every build/click
    _cachedHairstyles = _recommendationService.getHairstyleRecommendations(widget.faceShapeResult);
    _cachedBeards = _recommendationService.getBeardRecommendations(widget.faceShapeResult);
  }

  // Cached lists to ensure order consistency
  late List<StyleRecommendation> _cachedHairstyles;
  late List<StyleRecommendation> _cachedBeards;

  // NEW: Generate randomized text once per session
  late String _generatedAnalysisText; 
  late String _generatedImprovementTip;

  void _generateAnalysisText() {
    final m = widget.faceShapeResult.measurements;
    if (m.isEmpty) {
      _generatedAnalysisText = "No measurements available.";
      _generatedImprovementTip = "Try scanning again.";
      return;
    }

    double length = m['faceLength'] ?? 100;
    double width = m['cheekboneWidth'] ?? 100;
    double ratio = length / (width == 0 ? 1 : width);
    double phi = 1.618;
    double deviation = (ratio - phi).abs();
    
    final r = Random();

    if (deviation < 0.05) {
       // Excellent
       List<String> tips = [
         "Since your balance is naturally consistent, you don't need to correct any proportions. Feel free to experiment with bold, unique styles.",
         "Your facial symmetry is exceptional. You have the freedom to try almost any haircut, from buzz cuts to long flows, without disrupting your balance.",
         "With such near-perfect proportions, your focus should simply be on maintenance and texture. You don't need to use your hair to hide or accentuate anything.",
         "You hit the aesthetic jackpot! Use this versatility to your advantage by changing your style often—your face shape can handle it."
       ];
       _generatedAnalysisText = "Your facial structure is highly symmetrical and aligns almost perfectly with the Golden Ratio (1.618). This rare balance indicates a versatile face shape that can pull off almost any hairstyle.";
       _generatedImprovementTip = tips[r.nextInt(tips.length)];

    } else if (deviation < 0.15) {
      // Good
      _generatedAnalysisText = "Your face has strong symmetry with minor deviations from the Golden Mean. This is a very common and attractive balance found in many models and actors.";
      
      if (ratio > phi) {
        // Good - Long
        List<String> tips = [
          "Your face is slightly longer than the ideal ratio. Adding volume to the sides of your hair or a full beard can help widen the appearance of your jaw.",
          "To complement your slightly oblong structure, try styles that add width around the ears. Avoid excessive height on top to maintain harmony.",
          "A longer face benefits from horizontal balance. Consider a classic side part or messy fringe to break up the vertical length.",
          "Your face has length, which is distinguished. Soften it by keeping the sides fuller rather than skin-tight, and consider a stubble beard."
        ];
        _generatedImprovementTip = tips[r.nextInt(tips.length)];
      } else {
        // Good - Wide
        List<String> tips = [
           "Your face is slightly wider than the ideal ratio. Styles with height (like Quiffs or Pompadours) will help elongate your face.",
           "To balance your width, aim for verticality. A textured crop with volume or a spiky top will draw the eye upward, slimming your perception.",
           "Avoid flat or wide styles. Instead, go for a modern fade with some length on top to create a more oval silhouette.",
           "Your facial width is strong and masculine. Enhance it by keeping the sides tight and adding a bit of loft to your fringe or quiff."
        ];
        _generatedImprovementTip = tips[r.nextInt(tips.length)];
      }

    } else {
      // Average
      if (ratio > phi) {
         // Average - Long
         _generatedAnalysisText = "Your face ratio (${ratio.toStringAsFixed(2)}) is higher than the Golden Mean, giving you a distinguished, oblong or oval appearance.";
         List<String> tips = [
           "To balance the vertical length, we highly recommend styles with volume on the sides (like a Side Part or Flow) and avoiding high fades which elongate the face further. A full beard can also add necessary width.",
           "Your face shape is distinctly vertical. Counteract this by choosing styles with bangs or fringes that cover the forehead, shortening the visible face length.",
           "Height is not your friend here. Focus on growing out the sides slightly for a 'Flow' look, or try a textured user cut that sits flatter on top.",
           "Structure is key for longer faces. A square beard or beard with fuller cheeks can drastically improve your ratio by adding needed width."
         ];
         _generatedImprovementTip = tips[r.nextInt(tips.length)];
      } else {
         // Average - Wide
         _generatedAnalysisText = "Your face ratio (${ratio.toStringAsFixed(2)}) is lower than the Golden Mean, indicating a robust, wider structure often seen in Square or Round shapes.";
         List<String> tips = [
           "To elongate your features towards the Golden Ratio, opt for styles with significant height on top (Pompadour, Quiff) and keep the sides very short or faded. Avoid wide beards; go for a goatee or ducktail to lengthen the chin.",
           "Your face leans towards a square or round broadness. Aggressive fades (skin fades) on the sides combined with 3-4 inches of height on top will transform your look.",
           "The goal is elongation. Avoid full, round beards which maximize width. Instead, a sharp goatee or Van Dyke draws the chin down, improving your ratio.",
           "Create angles where there are curves. A sharp, geometric hairline and a high-volume style like a Faux Hawk can perfectly offset a wider face structure."
         ];
         _generatedImprovementTip = tips[r.nextInt(tips.length)];
      }
    }
  }

  // Cached salons to prevent regeneration on rebuilds
  List<Salon> _cachedSalons = [];

  Future<void> _loadLocationAndSalons() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    
    Position? pos;
    try {
      pos = await LocationService.instance.getCurrentLocation();
    } catch (e) {
      // Ignore
    }

    final salons = _salonService.getNearbySalons("Mumbai", "Maharashtra", userLocation: pos);

    if (mounted) {
      setState(() {
         _currentLocation = pos;
         _cachedSalons = salons;
         if (pos == null) {
           _locationError = "Enable location to see nearby salons.";
         }
         _isLoadingLocation = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveRecommendation() async {
    if (widget.isGuest || widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login required to save results.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final savedImagePath = await StorageService.instance.saveImageToGallery(widget.imagePath);
      
      final recommendation = Recommendation(
        userId: widget.userId,
        faceShape: widget.faceShapeResult.shape,
        hairstyles: _recommendationService.getHairstyleRecommendations(widget.faceShapeResult).map((e) => e.name).toList(),
        beardStyles: _recommendationService.getBeardRecommendations(widget.faceShapeResult).map((e) => e.name).toList(),
        rating: widget.faceShapeResult.rating,
        imagePath: savedImagePath,
        createdAt: DateTime.now(),
      );

      await DatabaseService.instance.saveRecommendation(recommendation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  List<StyleRecommendation> get _hairstyles {
    // Use the cached list to filter. 
    // Important: We must maintain the order of the items relative to the list we pass to VirtualTryOn
    // However, if we filter, the indices DO change. 
    // VirtualTryOn takes (AllStyles, InitialIndex). 
    // If we pass the FILTERED list to VirtualTryOn, and the index FROM the filtered list, it works.
    final list = _cachedHairstyles;
    if (_selectedHairCategory == 'All') return list;
    return list.where((s) => s.category == _selectedHairCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text('Analysis Results', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.premiumDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.premiumDark),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.premiumDark,
          unselectedLabelColor: AppTheme.premiumDark.withOpacity(0.5),
          indicatorColor: AppTheme.premiumDark,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "Analysis"),
            Tab(text: "Styles"),
            Tab(text: "Salons"),
          ],
        ),
        actions: [
          if (!widget.isGuest)
            IconButton(
              icon: _isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.premiumDark))
                : const Icon(Icons.save_alt),
              onPressed: _isSaving ? null : _saveRecommendation,
            )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.goldenGradient,
        ),
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAnalysisTab(),
              _buildStylesTab(),
              _buildSalonsTab(),
            ],
          ),
        ),
      ),
    );
  }

  // --- TAB 1: Analysis ---
  Widget _buildAnalysisTab() {
    final result = widget.faceShapeResult;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Result Card (Dark Glass)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.premiumDark.withOpacity(0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  child: Text(
                    result.shape.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  result.shape.displayName,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Dominant Face Shape',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Confidence', '${(result.confidence * 100).toStringAsFixed(1)}%', Icons.verified),
                    _buildStatItem('Face Rating', '${result.rating}/10', Icons.star),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn().scale(),

          const SizedBox(height: 24),
          _buildComparisonCard(),
          const SizedBox(height: 24),
          _buildAnalysisCard(),
          const SizedBox(height: 24),
          _buildGoldenRatioCard(result.measurements),
          
          const SizedBox(height: 24),
          
          Center(
            child: Column(
              children: [
                Text("Analyzed Image", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.premiumDark)),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 300, maxWidth: 220),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24), // Circular as requested for premium feel
                    border: Border.all(color: AppTheme.premiumDark.withOpacity(0.5), width: 2),
                    boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.15), offset: const Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: DisplayImage(
                       path: widget.imagePath,
                       fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB 2: Styles ---
  Widget _buildStylesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showBeardsOnly) ...[
            Text("Hairstyles", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.premiumDark)),
            const SizedBox(height: 16),
            _buildFilterChips(),
            const SizedBox(height: 20),
            ..._hairstyles.asMap().entries.map((entry) => _buildStyleCard(entry.value, Colors.blueAccent, _hairstyles, entry.key)),
          ],
          
          if (!widget.showBeardsOnly && !widget.showHairstylesOnly)
             const Divider(height: 40, thickness: 1, color: AppTheme.premiumDark),

          if (!widget.showHairstylesOnly) ...[
            Text("Beard Styles", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.premiumDark)),
            const SizedBox(height: 20),
             // Capture beard list to pass index
             Builder(builder: (context) {
               final beards = _cachedBeards;
               return Column(
                 children: beards.asMap().entries.map((entry) => _buildStyleCard(entry.value, Colors.orangeAccent, beards, entry.key)).toList(),
               );
             }),
          ],
        ],
      ),
    );
  }

  // --- TAB 3: Salons ---
  Widget _buildSalonsTab() {
    if (_isLoadingLocation) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.premiumDark));
    }

    if (_currentLocation == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 60, color: AppTheme.premiumDark),
            const SizedBox(height: 16),
             Text(
              "Location unavailable",
              style: GoogleFonts.poppins(color: AppTheme.premiumDarkText, fontSize: 18),
            ),
            if (_locationError != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_locationError!, style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 14)),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadLocationAndSalons,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.premiumDark,
                foregroundColor: Colors.white,
              ),
              child: const Text("Retry Location"),
            )
          ],
        ),
      );
    }

    // Use cached salons instead of fetching new ones
    final salons = _cachedSalons;

    if (salons.isEmpty) {
       return Center(child: Text("No salons found nearby.", style: GoogleFonts.poppins(color: AppTheme.premiumDarkText)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: salons.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              "Top Rated Nearby",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.premiumDark),
            ),
          );
        }
        return _buildVerticalSalonCard(salons[index - 1]);
      },
    );
  }

  Widget _buildVerticalSalonCard(Salon salon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppTheme.premiumDark.withOpacity(0.9), // Dark card
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              salon.imageUrl,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c,e,s) => Container(
                height: 160, 
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  gradient: LinearGradient(
                    colors: [Colors.grey[800]!, Colors.grey[900]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                ), 
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, size: 40, color: Colors.white54),
                    SizedBox(height: 8),
                    Text("Image Not Available", style: TextStyle(color: Colors.white24, fontSize: 10))
                  ],
                )
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        salon.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            salon.rating.toStringAsFixed(1),
                            style: GoogleFonts.poppins(color: Colors.amber, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                 const SizedBox(height: 8),
                 Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text(
                        '${salon.distanceKm.toStringAsFixed(1)} km',
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.monetization_on, size: 16, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text(
                        salon.priceRange,
                        style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                 ),
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 45,
                        child: OutlinedButton.icon(
                         onPressed: () async {
                            final Uri url = Uri.parse(salon.googleMapsUrl);
                            try {
                                if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                  await launchUrl(url); 
                                }
                            } catch (e) {
                               debugPrint("Could not launch map: $e");
                            }
                         },
                         icon: const Icon(Icons.reviews, size: 18),
                         label: const Text("Reviews"), 
                         style: OutlinedButton.styleFrom(
                           foregroundColor: Colors.white,
                           side: const BorderSide(color: Colors.white54),
                           padding: EdgeInsets.zero, // Compact padding
                         ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: SizedBox(
                          height: 45,
                          child: ElevatedButton.icon(
                          onPressed: () async {
                            // Create a direction URL
                            final encodedName = Uri.encodeComponent("${salon.name}, ${salon.address}");
                            final Uri dirUrl = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=$encodedName");
                            
                            try {
                              if (!await launchUrl(dirUrl, mode: LaunchMode.externalApplication)) {
                                  await launchUrl(dirUrl); 
                              }
                            } catch (e) {
                               if (context.mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   SnackBar(
                                     content: Text("Could not open directions: $e", style: const TextStyle(color: Colors.white)),
                                     backgroundColor: Colors.redAccent,
                                   ),
                                 );
                               }
                            }
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text("Directions"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white, 
                            foregroundColor: AppTheme.premiumDark,
                            padding: EdgeInsets.zero,
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
    );
  }

  // --- Helpers ---

  Widget _buildStyleCard(StyleRecommendation style, Color accentColor, List<StyleRecommendation> allStyles, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.premiumDark.withOpacity(0.9), // Dark card
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          ListTile(
            isThreeLine: true,
            contentPadding: const EdgeInsets.all(16),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60, height: 60,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // User requested ONLY hairstyle image here, NOT the user face
                    // DisplayImage(path: widget.imagePath, fit: BoxFit.cover),
                    Container(color: const Color(0xFFFFF8E1)), 
                    style.imageUrl.startsWith('http')
                        ? Image.network(
                            style.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) {
                               debugPrint("Failed to load network image ${style.imageUrl}: $e");
                               return Center(child: Icon(Icons.broken_image, color: Colors.black26));
                            },
                          )
                        : Image.asset(
                            style.imageUrl,
                            fit: BoxFit.contain, 
                            errorBuilder: (c, e, s) {
                               debugPrint("Failed to load asset image ${style.imageUrl}: $e");
                               return Center(
                                 child: Text(
                                   style.name.substring(0, min(2, style.name.length)).toUpperCase(),
                                   style: GoogleFonts.poppins(color: AppTheme.premiumDark, fontWeight: FontWeight.bold, fontSize: 18),
                                 ),
                               );
                            },
                          ),
                  ],
                ),
              ),
            ),
            title: Text(
              style.name,
              style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 if (style.reason.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        style.reason,
                        style: GoogleFonts.poppins(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13),
                       
                      ),
                    ),
                 const SizedBox(height: 8),
                 LinearProgressIndicator(
                    value: style.matchScore,
                    backgroundColor: Colors.white12,
                    color: accentColor,
                    minHeight: 4,
                 ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${(style.matchScore * 100).toInt()}%', style: GoogleFonts.poppins(color: accentColor, fontWeight: FontWeight.bold)),
                Text('Match', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VirtualTryOnScreen(
                        imagePath: widget.imagePath,
                        allStyles: allStyles,
                        initialIndex: index,
                        landmarks: widget.faceShapeResult.landmarks ?? {},
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_front),
                label: const Text("Virtual Try-On"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildComparisonCard() {
    final scores = widget.faceShapeResult.scores;
    if (scores.isEmpty) return const SizedBox.shrink();

    // The 4 basic shapes user requested
    final targetShapes = [FaceShape.heart, FaceShape.diamond, FaceShape.oval, FaceShape.square];
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.premiumDark.withOpacity(0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Compatibility Accuracy", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const Icon(Icons.analytics_outlined, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text("Comparison across basic face shapes", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
          const SizedBox(height: 24),
          ...targetShapes.map((shape) {
            double score = scores[shape] ?? 0.0;
            bool isMatch = shape == widget.faceShapeResult.shape;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(shape.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                shape.displayName,
                                style: GoogleFonts.poppins(
                                  color: isMatch ? Colors.white : Colors.white70,
                                  fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isMatch)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text("ACCURATE", style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(score * 100).toStringAsFixed(1)}%",
                        style: GoogleFonts.poppins(
                          color: isMatch ? Colors.white : Colors.white60,
                          fontWeight: isMatch ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        height: 6,
                        width: MediaQuery.of(context).size.width * 0.7 * score,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isMatch 
                              ? [Colors.blueAccent, Colors.cyanAccent] 
                              : [Colors.white24, Colors.white10]
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isMatch ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 4)] : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = ['All', 'Short', 'Medium', 'Long'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedHairCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedHairCategory = cat),
              backgroundColor: AppTheme.premiumDark.withOpacity(0.1),
              selectedColor: AppTheme.premiumDark,
              labelStyle: GoogleFonts.poppins(
                color: isSelected ? Colors.white : AppTheme.premiumDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              checkmarkColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), 
                side: BorderSide(color: AppTheme.premiumDark.withOpacity(0.3)),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.premiumDark.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text("Measurements", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
           const SizedBox(height: 16),
           if (widget.faceShapeResult.measurements.isEmpty)
              Text("No measurements available", style: GoogleFonts.poppins(color: Colors.white70))
           else
              ...widget.faceShapeResult.measurements.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        // Format keys like "faceLength" -> "Face Length"
                        e.key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
                             .replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m.group(0)!.toUpperCase()), 
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        "${e.value.toStringAsFixed(1)}mm",
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }),
        ],
      ),
    );
  }

  void _showReviewsModal(BuildContext context, Salon salon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Transparent to show dark sheet
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 20),
                  Text("Services & Pricing", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  if (salon.services.isEmpty)
                     Padding(
                       padding: const EdgeInsets.all(24.0),
                       child: Text("No services listed for this salon.", style: GoogleFonts.poppins(color: Colors.white60)),
                     )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: salon.services.length,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemBuilder: (context, index) {
                          final service = salon.services[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(service.name, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                                Text(service.price, style: GoogleFonts.poppins(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Close Menu", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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

  Widget _buildGoldenRatioCard(Map<String, double> measurements) {
    if (measurements.isEmpty) return const SizedBox.shrink();
    
    // Calculate Ratios
    double length = measurements['faceLength'] ?? 100;
    double width = measurements['cheekboneWidth'] ?? 100;
    double ratio = length / (width == 0 ? 1 : width);
    double phi = 1.618;
    double deviation = (ratio - phi).abs();
    double matchPercentage = (1.0 - deviation).clamp(0.0, 1.0) * 100;
    
    // Determine "Face Harmony" logic
    // Determine "Face Harmony" logic
    String grading = "Good";
    Color gradingColor = Colors.lightGreenAccent;
    
    // Use the randomized text generated in initState
    String improvementTip = _generatedImprovementTip;
    String analysisText = _generatedAnalysisText;

    if (deviation < 0.05) {
      grading = "Excellent";
      gradingColor = Colors.greenAccent;
    } else if (deviation < 0.15) {
      grading = "Good";
      gradingColor = Colors.lightGreenAccent;
    } else {
      grading = "Average"; 
      gradingColor = Colors.amberAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withOpacity(0.2), Colors.purple.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                child: const Icon(Icons.architecture, color: Colors.black, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Face Harmony Analysis", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Row(
                      children: [
                        Text("Rating: ", style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
                        Text(grading, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: gradingColor)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRatioMetric("Match", "${matchPercentage.toStringAsFixed(1)}%"),
              _buildRatioMetric("Ratio", ratio.toStringAsFixed(3)),
              _buildRatioMetric("Ideal", "1.618"),
            ],
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                   children: [
                     Icon(Icons.tips_and_updates, color: Colors.amberAccent, size: 20),
                     const SizedBox(width: 8),
                     Text("What can be improved?", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.amberAccent)),
                   ],
                ),
                const SizedBox(height: 8),
                Text(improvementTip, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Overall Balance: $grading",
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  analysisText,
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ).animate().shimmer(duration: 2000.ms),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildRatioMetric(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amberAccent)),
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white60)),
      ],
    );
  }
}
