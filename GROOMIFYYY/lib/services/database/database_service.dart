import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:groomify/models/user.dart' as model;
import 'package:groomify/models/recommendation.dart';
import 'package:groomify/services/database/database_stub.dart'
    if (dart.library.io) 'database_mobile.dart'
    if (dart.library.js_interop) 'database_web.dart' as impl;

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  late final impl.DatabaseImplementation _implementation;

  DatabaseService._init() {
    _implementation = impl.getImplementation();
  }

  // User operations
  Future<int> createUser(model.User user) async {
    UserCredential? credential;
    try {
       // Create user in Firebase Auth
       credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
         email: user.email,
         password: user.passwordHash, 
       );
       
       if (credential.user != null) {
          try {
             // Update Display Name in Firebase
             await credential.user!.updateDisplayName(user.name);

             // Store in local DB with HASHED password
             final dbUser = model.User(
               id: user.id,
               name: user.name,
               email: user.email,
               passwordHash: hashPassword(user.passwordHash),
               createdAt: user.createdAt,
             );
          
             return await _implementation.createUser(dbUser);
          } catch (innerError) {
             // ROLLBACK: If local DB or Name Update fails, delete the Firebase user
             // This prevents "Zombie" accounts where Firebase Auth exists but Local Data/Name does not.
             try {
               await credential.user!.delete();
             } catch (deleteError) {
               // If delete fails, we can't do much, but we tried.
               debugPrint("Rollback failed: $deleteError");
             }
             throw "Signup Error: $innerError";
          }
       }
       return -1;
    } catch (e) {
       throw e.toString();
    } 
  }

  Future<model.User?> getUserByEmail(String email) => _implementation.getUserByEmail(email);

  Future<int> createUserProfile(String uid, String name, String email) async {
      // This is called after Firebase Auth creation
      // We create a local DB record if needed
      final user = model.User(
          id: 0, // ID handled by DB
          name: name, 
          email: email, 
          passwordHash: '', 
          createdAt: DateTime.now()
      );
      return await _implementation.createUser(user);
  }


  Future<model.User?> loginUser(String email, String password) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        model.User? localUser = await _implementation.getUserByEmail(email);
        
        if (localUser == null) {
           // Create the user locally to generate a unique ID
           final newUser = model.User(
             id: 0, // Auto-increment will handle this
             name: credential.user!.displayName ?? 'User',
             email: email,
             passwordHash: '',
             createdAt: DateTime.now(),
           );
           final newId = await _implementation.createUser(newUser);
           
           localUser = model.User(
             id: newId,
             name: newUser.name,
             email: newUser.email,
             passwordHash: newUser.passwordHash,
             createdAt: newUser.createdAt,
           );
        }
        return localUser;
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
       await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    } catch (e) {
       throw e.toString();
    }
  }

  // Recommendation operations
  Future<int> saveRecommendation(Recommendation recommendation) => _implementation.saveRecommendation(recommendation);

  Future<List<Recommendation>> getUserRecommendations(int userId) => _implementation.getUserRecommendations(userId);

  Future<void> close() => _implementation.close();
  
  // Helper for password hashing if needed globally
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
