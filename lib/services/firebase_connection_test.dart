import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseConnectionTest {
  static bool _isInitialized = false;

  static Future<void> initializeFirebase() async {
    if (_isInitialized) return;

    try {
      // Initialiser Firebase avec les options par défaut
      await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

      _isInitialized = true;
      debugPrint('✅ Firebase initialisé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation Firebase: $e');
      rethrow;
    }
  }

  static Future<bool> testConnection() async {
    try {
      await initializeFirebase();

      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('test').limit(1).get();

      debugPrint('✅ Firestore connecté');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur connexion Firebase: $e');
      return false;
    }
  }

  static Future<bool> testAuth() async {
    try {
      await initializeFirebase();

      FirebaseAuth.instance;
      debugPrint('✅ FirebaseAuth connecté');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur FirebaseAuth: $e');
      return false;
    }
  }

  static Future<String> registerTestUser() async {
    try {
      await initializeFirebase();

      final auth = FirebaseAuth.instance;

      // Créer un utilisateur de test
      final result = await auth.createUserWithEmailAndPassword(
        email: 'test${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'password123',
      );

      debugPrint('✅ Utilisateur de test créé: ${result.user?.uid}');

      // Sauvegarder dans Firestore
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(result.user!.uid).set({
        'email': result.user!.email,
        'createdAt': DateTime.now().toIso8601String(),
        'test': true,
      });

      debugPrint('✅ Utilisateur sauvegardé dans Firestore');

      return result.user!.uid;
    } catch (e) {
      debugPrint('❌ Erreur création utilisateur test: $e');
      rethrow;
    }
  }

  static Future<void> cleanupTestUser(String uid) async {
    try {
      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      if (user != null && user.uid == uid) {
        await user.delete();
        debugPrint('✅ Utilisateur test supprimé');
      }

      final firestore = FirebaseFirestore.instance;
      await firestore.collection('users').doc(uid).delete();
      debugPrint('✅ Document utilisateur supprimé');
    } catch (e) {
      debugPrint('⚠️ Erreur nettoyage utilisateur test: $e');
    }
  }
}
