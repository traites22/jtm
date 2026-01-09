import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../services/local_registration_service.dart';
import '../services/firebase_registration_service.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';

class HybridRegistrationService {
  static bool _useFirebase = true;
  static bool _firebaseTested = false;
  static bool _firebaseWorking = false;

  // Test initial de Firebase
  static Future<void> _testFirebaseConnection() async {
    if (_firebaseTested) return;

    try {
      // Test simple de connexion Firebase
      final firestore = FirebaseFirestore.instance;

      // Test avec une requête simple
      await firestore.collection('test').limit(1).get();

      _firebaseWorking = true;
      debugPrint('✅ Firebase fonctionne correctement');
    } catch (e) {
      _firebaseWorking = false;
      debugPrint('❌ Firebase non disponible: $e');
    } finally {
      _firebaseTested = true;
    }
  }

  // Inscription (essaie Firebase, puis local)
  static Future<RegistrationResult> registerUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    await _testFirebaseConnection();

    if (_firebaseWorking && _useFirebase) {
      try {
        debugPrint('🔥 Tentative d\'inscription Firebase...');
        final result = await FirebaseRegistrationService.registerUser(
          email: email,
          password: password,
          name: name,
          age: age,
          gender: gender,
          phoneNumber: phoneNumber,
          preferences: preferences,
        );

        if (result.success) {
          debugPrint('✅ Inscription Firebase réussie');
          return result;
        } else {
          debugPrint('⚠️ Firebase échoue, basculement vers local: ${result.message}');
          return await _registerLocal(
            email: email,
            password: password,
            name: name,
            age: age,
            gender: gender,
            phoneNumber: phoneNumber,
            preferences: preferences,
          );
        }
      } catch (e) {
        debugPrint('❌ Erreur Firebase, basculement vers local: $e');
        return await _registerLocal(
          email: email,
          password: password,
          name: name,
          age: age,
          gender: gender,
          phoneNumber: phoneNumber,
          preferences: preferences,
        );
      }
    } else {
      debugPrint('📱 Utilisation du stockage local');
      return await _registerLocal(
        email: email,
        password: password,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        preferences: preferences,
      );
    }
  }

  // Connexion (essaie Firebase, puis local)
  static Future<LoginResult> loginUser({
    required String email,
    required String password,
    bool useBiometric = false,
  }) async {
    await _testFirebaseConnection();

    if (_firebaseWorking && _useFirebase) {
      try {
        debugPrint('🔥 Tentative de connexion Firebase...');
        final result = await FirebaseRegistrationService.loginUser(
          email: email,
          password: password,
        );

        if (result.success) {
          debugPrint('✅ Connexion Firebase réussie');
          return result;
        } else {
          debugPrint('⚠️ Firebase échoue, basculement vers local: ${result.message}');
          return await _loginLocal(email: email, password: password, useBiometric: useBiometric);
        }
      } catch (e) {
        debugPrint('❌ Erreur Firebase, basculement vers local: $e');
        return await _loginLocal(email: email, password: password, useBiometric: useBiometric);
      }
    } else {
      debugPrint('📱 Utilisation du stockage local');
      return await _loginLocal(email: email, password: password, useBiometric: useBiometric);
    }
  }

  // Inscription locale
  static Future<RegistrationResult> _registerLocal({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final result = await LocalRegistrationService.registerUser(
        email: email,
        password: password,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        preferences: preferences,
      );

      if (result.success) {
        return RegistrationResult.success(
          result.user,
          '✅ Inscription locale réussie ! (Mode test)',
        );
      } else {
        return result;
      }
    } catch (e) {
      return RegistrationResult.failure('Erreur inscription locale: ${e.toString()}');
    }
  }

  // Connexion locale
  static Future<LoginResult> _loginLocal({
    required String email,
    required String password,
    bool useBiometric = false,
  }) async {
    try {
      final result = await LocalRegistrationService.loginUser(
        email: email,
        password: password,
        useBiometric: useBiometric,
      );

      if (result.success) {
        return LoginResult.success(result.user, '✅ Connexion locale réussie ! (Mode test)');
      } else {
        return result;
      }
    } catch (e) {
      return LoginResult.failure('Erreur connexion locale: ${e.toString()}');
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      if (_firebaseWorking && _useFirebase) {
        await FirebaseRegistrationService.logout();
      }
      await LocalRegistrationService.logout();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

  // Obtenir l'utilisateur actuel
  static Future<UserModel?> getCurrentUser() async {
    await _testFirebaseConnection();

    if (_firebaseWorking && _useFirebase) {
      try {
        return await FirebaseRegistrationService.getCurrentUser();
      } catch (e) {
        debugPrint('Erreur getCurrentUser Firebase: $e');
      }
    }

    // Fallback sur local
    try {
      final profileBox = await Hive.openBox('profileBox');
      final userData = profileBox.get('currentUser');
      return userData != null ? UserModel.fromMap(userData) : null;
    } catch (e) {
      debugPrint('Erreur getCurrentUser local: $e');
      return null;
    }
  }

  // Stream des changements d'authentification
  static Stream<UserModel?> get authStateChanges async* {
    await _testFirebaseConnection();

    if (_firebaseWorking && _useFirebase) {
      yield* FirebaseRegistrationService.authStateChanges.map((user) => user);
    } else {
      // Pour le mode local, on émet une seule fois
      final currentUser = await getCurrentUser();
      yield currentUser;
    }
  }

  // Forcer l'utilisation du mode local
  static void forceLocalMode() {
    _useFirebase = false;
    debugPrint('📱 Mode local forcé');
  }

  // Forcer l'utilisation du mode Firebase
  static void forceFirebaseMode() {
    _useFirebase = true;
    debugPrint('🔥 Mode Firebase forcé');
  }

  // Obtenir le statut actuel
  static Map<String, dynamic> getStatus() {
    return {
      'firebaseTested': _firebaseTested,
      'firebaseWorking': _firebaseWorking,
      'useFirebase': _useFirebase,
      'mode': _useFirebase ? 'Firebase' : 'Local',
    };
  }
}

// Résultats d'inscription
class RegistrationResult {
  final bool success;
  final UserModel? user;
  final String message;

  RegistrationResult.success(this.user, this.message) : success = true;
  RegistrationResult.failure(this.message) : success = false, user = null;
}

// Résultats de connexion
class LoginResult {
  final bool success;
  final UserModel? user;
  final String message;

  LoginResult.success(this.user, this.message) : success = true;
  LoginResult.failure(this.message) : success = false, user = null;
}
