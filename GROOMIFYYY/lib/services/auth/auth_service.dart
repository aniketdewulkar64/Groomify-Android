import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream of auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign In
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
  }

  // Sign Up
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
  }
  
  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use Popup
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final UserCredential userCredential = await _auth.signInWithPopup(authProvider);
        return userCredential.user;
      } else {
        // Mobile: Use GoogleSignIn
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        
        if (googleUser == null) {
          return null; // The user canceled the sign-in
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _auth.signInWithCredential(credential);
        return userCredential.user;
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Sign Out
  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get Current User
  User? get currentUser => _auth.currentUser;
}
