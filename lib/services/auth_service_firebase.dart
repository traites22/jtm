import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class AuthServiceFirebase {
  final FirebaseAuth _auth = FirebaseService.instance.auth;
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // Register with email and password
  Future<UserCredential> registerWithEmailPassword({
    required String email,
    required String password,
    required String username,
    required int age,
  }) async {
    try {
      // Create user with email and password
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      await result.user?.updateDisplayName(username);

      // Create user document in Firestore
      await _firestore.collection('users').doc(result.user?.uid).set({
        'uid': result.user?.uid,
        'email': email,
        'username': username,
        'age': age,
        'createdAt': FieldValue.serverTimestamp(),
        'isProfileComplete': false,
        'interests': [],
        'bio': '',
        'profileImageUrl': '',
        'location': null,
        'preferences': {
          'ageRange': {'min': 18, 'max': 99},
          'maxDistance': 50,
          'showAge': true,
          'showDistance': true,
        },
      });

      debugPrint('✅ User registered successfully');
      return result;
    } catch (e) {
      debugPrint('❌ Registration failed: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User signed in successfully');
      return result;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('✅ User signed out successfully');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('✅ Password reset email sent');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? username,
    String? bio,
    List<String>? interests,
    String? profileImageUrl,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      Map<String, dynamic> updateData = {};
      if (username != null) {
        updateData['username'] = username;
        await user.updateDisplayName(username);
      }
      if (bio != null) updateData['bio'] = bio;
      if (interests != null) updateData['interests'] = interests;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;
      if (preferences != null) updateData['preferences'] = preferences;

      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.uid).update(updateData);
      debugPrint('✅ Profile updated successfully');
    } catch (e) {
      debugPrint('❌ Profile update failed: $e');
      rethrow;
    }
  }

  // Stream auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
