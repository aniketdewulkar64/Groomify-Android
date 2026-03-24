import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:groomify/screens/ar/face_detection_screen.dart';
import 'package:groomify/screens/gallery/gallery_screen.dart';
import 'package:groomify/config/theme.dart';
import 'package:groomify/screens/salons/nearby_salons_screen.dart';
import 'package:groomify/screens/auth/welcome_screen.dart';


class DashboardScreen extends StatelessWidget {
  final bool isGuest;
  final int? userId;

  const DashboardScreen({
    super.key,
    required this.isGuest,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.goldenGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'GROOMIFY',
                          style: GoogleFonts.poppins(
                            fontSize: 28, // Slightly smaller to fit row
                            fontWeight: FontWeight.w900,
                            color: AppTheme.premiumDark,
                            letterSpacing: 1,
                          ),
                        ),
                          Text(
                          isGuest 
                            ? 'Guest Mode' 
                            : 'Hello, ${FirebaseAuth.instance.currentUser?.displayName?.split(' ').first ?? 'User'}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppTheme.premiumDark.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    
                    // Styled Exit Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2), // Light glass
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.premiumDark.withValues(alpha: 0.3), width: 1),
                      ),
                      child: InkWell(
                        onTap: () async {
                           try {
                             await FirebaseAuth.instance.signOut();
                           } catch (e) {
                             debugPrint("Sign out error: $e");
                           }
                           
                           if (context.mounted) {
                             Navigator.pushAndRemoveUntil(
                               context,
                               MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                               (route) => false,
                             );
                           }
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                           child: Row(
                             children: [
                               const Icon(Icons.logout_rounded, size: 20, color: AppTheme.premiumDark),
                               const SizedBox(width: 8),
                               Text(
                                 "EXIT",
                                 style: GoogleFonts.poppins(
                                   fontSize: 14,
                                   fontWeight: FontWeight.bold,
                                   color: AppTheme.premiumDark,
                                 ),
                               ),
                             ],
                           ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Feature Cards
                Expanded(
                  child: ListView(
                    children: [
                      _GlassFeatureCard(
                        title: 'Face Shape\nDetector',
                        subtitle: 'Detect your face\nshape using AI',
                        icon: Icons.face,
                        // Using Gold/Dark accents
                        iconColor: Colors.amberAccent, 
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaceDetectionScreen(
                                isGuest: isGuest,
                                userId: userId,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _GlassFeatureCard(
                        title: 'Hairstyle\nSuggestor',
                        subtitle: 'Get personalized\nhairstyle\nrecommendations',
                        icon: Icons.content_cut,
                        iconColor: Colors.purpleAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaceDetectionScreen(
                                isGuest: isGuest,
                                userId: userId,
                                showHairstylesOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _GlassFeatureCard(
                        title: 'Beard\nSuggestor',
                        subtitle: 'Find the perfect\nbeard style for you',
                        icon: Icons.face_retouching_natural,
                        iconColor: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FaceDetectionScreen(
                                isGuest: isGuest,
                                userId: userId,
                                showBeardsOnly: true,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                      
                      _GlassFeatureCard(
                        title: 'Nearby\nSalons',
                        subtitle: 'Find top-rated\nsalons near you',
                        icon: Icons.store_mall_directory,
                        iconColor: Colors.redAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NearbySalonsScreen(),
                            ),
                          );
                        },
                      ),



                      if (!isGuest) ...[
                        const SizedBox(height: 20),
                        _GlassFeatureCard(
                          title: 'My\nGallery',
                          subtitle: 'View saved looks',
                          icon: Icons.photo_library,
                          iconColor: Colors.tealAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GalleryScreen(userId: userId!),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _GlassFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        // Light Glass for "Ice/Crystal" effect on Gold
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.premiumDark.withValues(alpha: 0.1), // Subtle dark shadow
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
                child: Row(
                  children: [
                    // Icon Box
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Icon(icon, color: AppTheme.premiumDark, size: 32),
                    ),
                    const SizedBox(width: 24),
                    
                    // Texts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.premiumDark, // Dark text
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.premiumDark.withValues(alpha: 0.7),
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Arrow
                        Icon(Icons.arrow_forward_ios, color: AppTheme.premiumDark.withValues(alpha: 0.5), size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideX();
  }
}

