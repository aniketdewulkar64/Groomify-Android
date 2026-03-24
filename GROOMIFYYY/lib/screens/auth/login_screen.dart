import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:groomify/services/auth/auth_service.dart';
import 'package:groomify/services/database/database_service.dart';
import 'package:groomify/services/location/location_service.dart';
import 'package:groomify/config/theme.dart';
import 'package:groomify/screens/home/dashboard_screen.dart';
import 'package:groomify/screens/auth/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // Use DatabaseService to login and get local user ID
        final user = await DatabaseService.instance.loginUser(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        if (user != null) {
          try {
             await LocationService.instance.getCurrentLocation();
          } catch (e) {
             debugPrint("Location permission denied or error: $e");
          }

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen(isGuest: false, userId: user.id)),
            );
          }
        }
      } catch (e) {
        // STRICT: Use toString() to avoid 'subtype of JavaScriptObject' crashes on Web
        String rawError = e.toString();
        String errorMessage = "Login failed";
        
        // Simple parsing to make it readable
        if (rawError.contains("]")) {
          errorMessage = rawError.split("]").last.trim();
        } else {
          errorMessage = rawError;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: GoogleFonts.poppins(color: Colors.white)),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      
      if (user != null) {
        // Get or Create Local User Profile
        int userId;
        final localUser = await DatabaseService.instance.getUserByEmail(user.email!);
        
        if (localUser != null) {
          userId = localUser.id!;
        } else {
          // Create new local profile
          userId = await DatabaseService.instance.createUserProfile(
            user.uid, 
            user.displayName ?? 'User', 
            user.email!
          );
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen(isGuest: false, userId: userId)),
          );
        }
      }
    } catch (e) {
      String rawError = e.toString();
      String errorMessage = "Google Sign-In failed";
      
      if (rawError.contains("]")) {
        errorMessage = rawError.split("]").last.trim();
      } else {
        errorMessage = rawError;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage, style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1), // Light Gold Surface
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
        title: Text('Reset Password', style: GoogleFonts.poppins(color: AppTheme.premiumDark, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your email to receive a link.', style: GoogleFonts.poppins(color: AppTheme.premiumDark.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              style: const TextStyle(color: AppTheme.premiumDarkText),
              decoration: const InputDecoration(
                hintText: 'Email',
                prefixIcon: Icon(Icons.email_outlined, color: AppTheme.premiumDark),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.premiumDark)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                 try {
                   await _authService.sendPasswordResetEmail(emailController.text.trim());
                   if (context.mounted) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(
                         content: Text('Reset link sent!', style: GoogleFonts.poppins(color: Colors.white)),
                         backgroundColor: Colors.green,
                         behavior: SnackBarBehavior.floating,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                         margin: const EdgeInsets.all(16),
                       ),
                     );
                   }
                 } catch (e) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e', style: GoogleFonts.poppins(color: Colors.white)),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        margin: const EdgeInsets.all(16),
                      ),
                   );
                 }
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.goldenGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                   const Icon(Icons.lock_outline, size: 60, color: AppTheme.premiumDark),
                   const SizedBox(height: 20),
                   Container(
                    padding: const EdgeInsets.all(32),
                    decoration: AppTheme.glassDecoration,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Welcome Back',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 28,
                            ),
                          ),
                           Text(
                            'Sign in to continue grooming',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
              
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: AppTheme.premiumDarkText),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) => 
                              (value == null || value.isEmpty || !value.contains('@')) ? 'Invalid email' : null,
                          ).animate().fadeIn().slideX(),
                          
                          const SizedBox(height: 20),
                          
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: AppTheme.premiumDarkText),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                                  color: AppTheme.premiumDark.withValues(alpha: 0.6),
                                ),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? 'Enter password' : null,
                          ).animate().fadeIn().slideX(),
                          
                          Center(
                            child: TextButton(
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.poppins(color: AppTheme.premiumDark.withValues(alpha: 0.8), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('LOGIN'),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
              
                          const SizedBox(height: 24),
                          
                          TextButton(
                            onPressed: () {
                               if (Navigator.canPop(context)) {
                                 Navigator.pop(context);
                               } else {
                                  // In case user landed here directly (shouldn't happen often)
                               }
                            },
                            child: Text(
                              'Back to Welcome',
                              style: GoogleFonts.poppins(color: AppTheme.premiumDark.withValues(alpha: 0.6)),
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Google Sign In Button
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleLogin,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.premiumDark.withValues(alpha: 0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.g_mobiledata, size: 28, color: AppTheme.premiumDark), 
                            label: Text(
                              "Continue with Google",
                              style: GoogleFonts.poppins(
                                color: AppTheme.premiumDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                          
                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Don't have an account? ", style: GoogleFonts.poppins(color: AppTheme.premiumDark.withValues(alpha: 0.8))),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                                  );
                                },
                                child: Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.premiumDark,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn().scale(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
