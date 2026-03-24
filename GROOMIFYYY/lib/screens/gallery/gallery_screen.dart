import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:gal/gal.dart';
import 'package:groomify/services/database/database_service.dart';
import 'package:groomify/models/recommendation.dart';
import 'package:groomify/models/face_shape.dart';
import 'package:groomify/config/theme.dart';

class GalleryScreen extends StatefulWidget {
  final int userId;

  const GalleryScreen({super.key, required this.userId});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Recommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final recommendations =
          await DatabaseService.instance.getUserRecommendations(widget.userId);
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'My Collection',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.premiumDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.premiumDark),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.goldenGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.premiumDark))
              : _recommendations.isEmpty
                  ? _buildEmptyState()
                  : _buildGalleryGrid(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.premiumDark.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.collections_bookmark_outlined, size: 64, color: AppTheme.premiumDark.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          Text(
            'Your collection is empty',
            style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.premiumDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Saved styles will appear here',
            style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.premiumDark.withValues(alpha: 0.6)),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }

  Widget _buildGalleryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7, // Taller cards for "Portrait" feel
          ),
          itemCount: _recommendations.length,
          itemBuilder: (context, index) {
            final rec = _recommendations[index];
            return _GalleryCard(recommendation: rec)
                .animate()
                .fadeIn(delay: (index * 50).ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0);
          },
        );
      },
    );
  }
}

class _GalleryCard extends StatelessWidget {
  final Recommendation recommendation;

  const _GalleryCard({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final imageFile = recommendation.imagePath != null ? File(recommendation.imagePath!) : null;
    final hasImage = imageFile != null && imageFile.existsSync();

    return GestureDetector(
      onTap: () => _showDetails(context, hasImage ? imageFile : null),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Image
              if (hasImage)
                Hero(
                  tag: 'gallery_img_${recommendation.id}',
                  child: Image.file(imageFile, fit: BoxFit.cover),
                )
              else
                Container(
                  color: Colors.grey[800],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white24)),
                ),

              // 2. Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // 3. Text Info
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 10, color: Colors.black),
                          const SizedBox(width: 4),
                          Text(
                            recommendation.rating.toDouble().toStringAsFixed(1),
                            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      recommendation.faceShape.displayName,
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('MMM d').format(recommendation.createdAt),
                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, File? imageFile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailSheet(recommendation: recommendation, imageFile: imageFile),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final Recommendation recommendation;
  final File? imageFile;

  const _DetailSheet({required this.recommendation, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.premiumDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recommendation.faceShape.displayName,
                            style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            DateFormat('MMMM d, y').format(recommendation.createdAt),
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              "${recommendation.rating}/10",
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hero Image
                  if (imageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Hero(
                            tag: 'gallery_img_${recommendation.id}',
                            child: Image.file(imageFile!, height: 350, width: double.infinity, fit: BoxFit.cover),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.extended(
                            onPressed: () => _saveToGallery(context),
                            icon: const Icon(Icons.download),
                            label: const Text("Save"),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        )
                      ],
                    ),

                  const SizedBox(height: 32),
                  
                  // Info Sections
                  _buildSection("Hairstyles", recommendation.hairstyles, Colors.purpleAccent),
                  const SizedBox(height: 20),
                  _buildSection("Beard Styles", recommendation.beardStyles, Colors.orangeAccent),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
             Container(
               width: 4, height: 24,
               decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
             ),
             const SizedBox(width: 12),
             Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Text(item, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
          )).toList(),
        )
      ],
    );
  }
  
  Future<void> _saveToGallery(BuildContext context) async {
    if (imageFile == null) return;
    try {
      await Gal.putImage(imageFile!.path);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to Photos!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }
}


