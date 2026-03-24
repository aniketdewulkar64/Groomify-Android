import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Colors ---
  // A premium dark charcoal/brown for high contrast against the gold.
  static const Color premiumDark = Color(0xFF2D241E); 
  static const Color premiumDarkText = Color(0xFF1A1A1A);
  
  // Accent color (optional, maybe a deep rich gold or burnt orange for highlights)
  static const Color accentGold = Color(0xFFD4AF37);

  // --- Gradients ---
  // User Requested: #ffed00, #ffde00, #ffcf00, #ffc000, #ffb100, #feb027, #fcaf3a, #f9af4a, #f4bc6e, #efc790, #e9d2b3, #e2ddd6
  static const LinearGradient goldenGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFED00),
      Color(0xFFFFDE00),
      Color(0xFFFFCF00),
      Color(0xFFFFC000),
      Color(0xFFFFB100), // Mid-point rich gold
      Color(0xFFFEB027),
      Color(0xFFFCAF3A),
      Color(0xFFF9AF4A),
      Color(0xFFF4BC6E),
      Color(0xFFEFC790),
      Color(0xFFE9D2B3),
      Color(0xFFE2DDD6), // Light beige/white-gold at bottom
    ],
  );

  // --- Glassmorphism ---
  // Since background is Light/Gold, we need "Dark Glass" or "Frosted White" that stands out.
  // A semi-transparent white with blur looks classy on gold, but text MUST be dark.
  // Or a semi-transparent black for higher contrast.
  // Let's go with "Crystalline White" for a clean look, but verify contrast.
  
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x99FFFFFF), // 60% White
      Color(0x66FFFFFF), // 40% White
    ],
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    gradient: glassGradient,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 15,
        spreadRadius: 2,
        offset: const Offset(0, 8),
      ),
    ],
  );

  // --- Theme Data ---
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: premiumDark,
      scaffoldBackgroundColor: Colors.transparent, // Handled by Container gradient
      brightness: Brightness.light, 
      
      // Text Theme - Using Poppins, Dark Colors for Readability
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: premiumDarkText,
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.poppins(
          color: premiumDarkText,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: premiumDarkText, // Dark text on Gold
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: premiumDarkText.withValues(alpha: 0.8),
          fontSize: 14,
        ),
        titleMedium: GoogleFonts.poppins(
            color: premiumDarkText,
            fontWeight: FontWeight.w600,
            fontSize: 16
        ),
      ),

      // Input Decoration (Glass Style)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.4),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: premiumDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        labelStyle: GoogleFonts.poppins(color: premiumDarkText.withValues(alpha: 0.7)),
        hintStyle: GoogleFonts.poppins(color: premiumDarkText.withValues(alpha: 0.4)),
        prefixIconColor: premiumDarkText.withValues(alpha: 0.7),
        suffixIconColor: premiumDarkText.withValues(alpha: 0.7),
      ),

      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: premiumDark, // Dark button on Gold bg
          foregroundColor: const Color(0xFFFFD700), // Gold text on button
          elevation: 8,
          shadowColor: Colors.black26, 
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 18), 
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: premiumDark,
          side: const BorderSide(color: premiumDark, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // Card Theme (for dialogs etc)
      cardTheme: const CardThemeData(
        color: Color(0xFFFFF8E1), // Very light gold/cream for opacity fallback
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        elevation: 10,
      ),
      
      iconTheme: const IconThemeData(color: premiumDark),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: premiumDark),
        titleTextStyle: TextStyle(
          color: premiumDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
        ),
      ),
      
      colorScheme: const ColorScheme.light( // Switched to Light scheme
        primary: premiumDark,
        secondary: accentGold,
        surface: Colors.transparent, 
        surfaceTint: Colors.white,
        onPrimary: Colors.white,
        onSurface: premiumDark,
      ),

      // SnackBar Theme Fix
      snackBarTheme: SnackBarThemeData(
        backgroundColor: premiumDark,
        contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        actionTextColor: accentGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
