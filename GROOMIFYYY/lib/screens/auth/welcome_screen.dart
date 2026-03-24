import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:groomify/screens/auth/login_screen.dart';
import 'package:groomify/screens/auth/signup_screen.dart';
import 'package:groomify/screens/home/dashboard_screen.dart';
import 'package:groomify/config/theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.goldenGradient,
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [




                const SizedBox(height: 32),

                Text(
                  'GROOMIFY',
                  style: GoogleFonts.poppins(
                    fontSize: 42.0, // Fixed size for consistency or could use MediaQuery if flexible needed
                    fontWeight: FontWeight.bold,
                    color: AppTheme.premiumDark,
                    letterSpacing: 6,
                  ),
                ).animate()
                 .fadeIn(duration: 600.ms)
                 .slideY(begin: 0.2, end: 0, delay: 200.ms),
                
                const SizedBox(height: 16),
                
                Text(
                  'AI-Powered Personal Grooming ',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppTheme.premiumDark.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.5,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms),
                
                const SizedBox(height: 80),
                
                // Transparent Glass Login Button
                _buildGlassButton(
                  context: context,
                  label: "LOGIN",
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                  isPrimary: true,
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms),
                
                const SizedBox(height: 20),
                
                // Transparent Glass Signup Button
                _buildGlassButton(
                  context: context,
                  label: "SIGN UP",
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                  isPrimary: false,
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 600.ms),
                
                const SizedBox(height: 32),
                
                // Guest Button
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(isGuest: true),
                      ),
                    );
                  },
                  child: Text(
                    'Continue as Guest',
                    style: GoogleFonts.poppins(
                      color: AppTheme.premiumDark.withValues(alpha: 0.8),
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return Container(
      width: 300,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        // Glass effect
        gradient: LinearGradient(
          colors: isPrimary 
              ? [AppTheme.premiumDark.withValues(alpha: 0.1), AppTheme.premiumDark.withValues(alpha: 0.05)]
              : [Colors.white.withValues(alpha: 0.2), Colors.white.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isPrimary ? AppTheme.premiumDark : Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          if (isPrimary)
            BoxShadow(
              color: AppTheme.premiumDark.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.premiumDark,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
