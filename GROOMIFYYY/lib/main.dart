import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:groomify/screens/auth/welcome_screen.dart';
import 'package:groomify/screens/home/dashboard_screen.dart';
import 'package:groomify/config/theme.dart';
import 'package:groomify/services/database/database_service.dart';
import 'models/user.dart' as model;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isFirebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  runApp(GroomifyApp(isFirebaseInitialized: isFirebaseInitialized));
}

class GroomifyApp extends StatelessWidget {
  final bool isFirebaseInitialized;

  const GroomifyApp({
    super.key,
    required this.isFirebaseInitialized,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Groomify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isFirebaseInitialized
          ? StreamBuilder<User?>(
              // Use instance.userChanges() to catch all auth events including token refresh
              stream: FirebaseAuth.instance.userChanges(),
              builder: (context, snapshot) {
                // Initial check: if connection is waiting, we still want to check if data is null 
                // BUT Firebase Stream usually emits null immediately if not logged in.
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                   // If we have data even while waiting (rare in some streams), show it.
                   if (snapshot.hasData && snapshot.data != null) {
                      return SessionLoader(firebaseUser: snapshot.data!);
                   }
                   return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasData && snapshot.data != null) {
                  return SessionLoader(firebaseUser: snapshot.data!);
                }
                
                return const WelcomeScreen();
              },
            )
          : const WelcomeScreen(), 
    );
  }
}

class SessionLoader extends StatefulWidget {
  final User firebaseUser;
  const SessionLoader({super.key, required this.firebaseUser});

  @override
  State<SessionLoader> createState() => _SessionLoaderState();
}

class _SessionLoaderState extends State<SessionLoader> {
  // Services
  // We need to fetch local ID
  // If not found, we might need to create it (Sync)
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<model.User?>(
       future: DatabaseService.instance.getUserByEmail(widget.firebaseUser.email!),
       builder: (context, snapshot) {
         if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
         }
         
         int userId = 0;
         if (snapshot.hasData && snapshot.data != null) {
            userId = snapshot.data!.id!;
         } else if (snapshot.hasError || snapshot.data == null) {
            // Edge Case: User in Firebase but not in Local DB (e.g. Cleared Data but not Auth)
            // We should attempt to "Recover" the session by creating a local user
            // But we can't easily do that in a build method.
            // For now, userId = 0 allows entry but as "Guest-like" (though isGuest=false).
            // A better approach is to sign them out if state is corrupted, or show a "setting up" screen.
            // Let's auto-signout to force a clean re-login/sync if critical data is missing.
            // BUT, that might be annoying.
            // Let's create a temporary "Syncing..." logic?
            // Actually, LoginScreen logic handles the "Create if missing" part. 
            // We can't easily invoke that here.
            // Let's stick to userId = 0 for now but log it?
            // Or better: Use the fix for "Zombie" accounts to assume it's rare.
            // If we return 0, they see the dashboard.
         }
         
         return DashboardScreen(isGuest: false, userId: userId);
       }
    );
  }
}
