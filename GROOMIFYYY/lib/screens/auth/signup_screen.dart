import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:groomify/services/auth/auth_service.dart';
import 'package:groomify/services/database/database_service.dart';
import 'package:groomify/models/user.dart' as model;
import 'package:groomify/services/location/location_service.dart';
import 'package:groomify/config/theme.dart';
import 'package:groomify/screens/home/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {

        // Create User Model (raw password for now, service will hash it)
        final newUser = model.User(
          id: 0,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          passwordHash: _passwordController.text.trim(),
          createdAt: DateTime.now(),
        );

        // Use DatabaseService to create user (handles Firebase + Local DB)
        final userId = await DatabaseService.instance.createUser(newUser);
        
        if (userId != -1) {
          try {
             await LocationService.instance.getCurrentLocation();
          } catch (e) {
             debugPrint("Location permission denied or error: $e");
          }

          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen(isGuest: false, userId: userId)),
              (route) => false,
            );
          }
        }
      } catch (e) {
        // STRICT: Use toString() to avoid 'subtype of JavaScriptObject' crashes on Web
        String rawError = e.toString();
        String errorMessage = "Signup failed";
        
        if (rawError.contains("email-already-in-use")) {
          errorMessage = "Email already registered. Please Login.";
        } else if (rawError.contains("Database Error")) {
          // Clean up our custom error
          errorMessage = "System Error. Please try again.";
          debugPrint("Detailed DB Error: $rawError");
        } else if (rawError.contains("]")) {
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
              action: (rawError.contains("email-already-in-use")) 
                ? SnackBarAction(
                    label: 'LOGIN', 
                    textColor: Colors.white,
                    onPressed: () => Navigator.pop(context), // Go back to login
                  )
                : null,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppTheme.premiumDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                   const Icon(Icons.person_add_outlined, size: 60, color: AppTheme.premiumDark),
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
                            'Joined Groomify',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 28,
                            ),
                          ),
                           Text(
                            'Create your account',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
              
                          TextFormField(
                            controller: _nameController,
                             style: const TextStyle(color: AppTheme.premiumDarkText),
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => 
                              (value == null || value.isEmpty) ? 'Enter your name' : null,
                          ).animate().fadeIn().slideX(),

                          const SizedBox(height: 20),

                          TextFormField(
                            controller: _emailController,
                             style: const TextStyle(color: AppTheme.premiumDarkText),
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) => 
                              (value == null || value.isEmpty || !value.contains('@')) ? 'Invalid email' : null,
                          ).animate().fadeIn().slideX(delay: 100.ms),
                          
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
                            validator: (value) => (value == null || value.length < 6) ? 'Password must be 6+ chars' : null,
                          ).animate().fadeIn().slideX(delay: 200.ms),
                          
                          const SizedBox(height: 32),
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSignup,
                              child: _isLoading 
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                                : const Text('SIGN UP'),
                            ),
                          ).animate().fadeIn().slideY(begin: 0.3, end: 0, delay: 300.ms),
              
                          const SizedBox(height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Already have an account? ", style: GoogleFonts.poppins(color: AppTheme.premiumDark.withValues(alpha: 0.8))),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context); // Go back to Login
                                },
                                child: Text(
                                  'Login',
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
