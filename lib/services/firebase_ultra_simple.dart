import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseUltraSimpleService {
  static Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      debugPrint('🔥 Début inscription Firebase...');
      debugPrint('📧 Email: $email');
      debugPrint('👤 Nom: $name');
      debugPrint('🎂 Âge: $age');
      debugPrint('⚧ Genre: $gender');

      // Créer l'utilisateur
      final authResult = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user == null) {
        return {'success': false, 'message': 'Erreur création compte: ${authResult.message}'};
      }

      // Sauvegarder dans Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(authResult.user!.uid).set({
        'email': email,
        'name': name,
        'age': age,
        'gender': gender,
        'phoneNumber': phoneNumber,
        'preferences': preferences ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
      });

      debugPrint('✅ Inscription Firebase réussie !');
      return {'success': true, 'message': 'Inscription réussie', 'user': authResult.user!.uid};
    } catch (e) {
      debugPrint('❌ Erreur Firebase: $e');
      return {'success': false, 'message': 'Erreur: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔥 Connexion Firebase en cours...');

      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user == null) {
        return {'success': false, 'message': 'Erreur connexion: ${authResult.message}'};
      }

      debugPrint('✅ Connexion Firebase réussie !');
      return {'success': true, 'message': 'Connexion réussie', 'user': authResult.user!.uid};
    } catch (e) {
      debugPrint('❌ Erreur Firebase: $e');
      return {'success': false, 'message': 'Erreur: ${e.toString()}'};
    }
  }

  static Future<void> logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
    }
  }

  static Future<String?> getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  static Stream<String?> get authStateChanges async* {
    yield* FirebaseAuth.instance.authStateChanges().map((user) => user?.uid);
  }
}
