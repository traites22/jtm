import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';

class FirebaseRegistrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Inscription d'un nouvel utilisateur avec Firebase
  static Future<RegistrationResult> registerUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      // Validation des champs
      final validationResult = _validateRegistrationData(
        email: email,
        password: password,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
      );

      if (!validationResult.isValid) {
        return RegistrationResult.failure(validationResult.errorMessage ?? 'Erreur de validation');
      }

      // Créer l'utilisateur avec Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return RegistrationResult.failure('Échec de la création du compte Firebase');
      }

      // Envoyer l'email de vérification
      await firebaseUser.sendEmailVerification();

      // Créer le profil utilisateur dans Firestore
      final user = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        photos: [],
        bio: '',
        interests: [],
        location: null,
        preferences: preferences ?? {},
        isVerified: false, // Sera true après email verification
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());

      // Initialiser les notifications
      await NotificationService.init();

      return RegistrationResult.success(user, 'Inscription réussie ! Vérifiez votre email.');
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de l\'inscription';
      if (e.code == 'weak-password') {
        message = 'Le mot de passe est trop faible';
      } else if (e.code == 'email-already-in-use') {
        message = 'Cet email est déjà utilisé';
      } else if (e.code == 'invalid-email') {
        message = 'Email invalide';
      }
      return RegistrationResult.failure(message);
    } catch (e) {
      return RegistrationResult.failure('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  // Connexion avec Firebase
  static Future<LoginResult> loginUser({
    required String email,
    required String password,
    bool useBiometric = false,
  }) async {
    try {
      // Authentification biométrique si demandée
      if (useBiometric) {
        final biometricResult = await BiometricService.authenticate(
          localizedReason: 'Authentifiez-vous pour vous connecter',
        );

        if (!biometricResult.isSuccess) {
          return LoginResult.failure(biometricResult.frenchMessage);
        }
      }

      // Connexion avec Firebase Auth
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return LoginResult.failure('Utilisateur non trouvé');
      }

      // Vérifier si l'email est vérifié
      if (!firebaseUser.emailVerified) {
        return LoginResult.failure('Veuillez vérifier votre email avant de vous connecter');
      }

      // Récupérer les données utilisateur depuis Firestore
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (!userDoc.exists) {
        return LoginResult.failure('Profil utilisateur non trouvé');
      }

      final user = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

      // Mettre à jour la dernière activité
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'lastActiveAt': Timestamp.now(),
      });

      final updatedUser = user.copyWith(lastActiveAt: DateTime.now());

      return LoginResult.success(updatedUser, 'Connexion réussie');
    } on FirebaseAuthException catch (e) {
      String message = 'Erreur lors de la connexion';
      if (e.code == 'user-not-found') {
        message = 'Utilisateur non trouvé';
      } else if (e.code == 'wrong-password') {
        message = 'Mot de passe incorrect';
      } else if (e.code == 'invalid-email') {
        message = 'Email invalide';
      } else if (e.code == 'user-disabled') {
        message = 'Compte désactivé';
      } else if (e.code == 'too-many-requests') {
        message = 'Trop de tentatives. Réessayez plus tard';
      }
      return LoginResult.failure(message);
    } catch (e) {
      return LoginResult.failure('Erreur lors de la connexion: ${e.toString()}');
    }
  }

  // Vérifier si l'email est vérifié
  static Future<VerificationResult> checkEmailVerification() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return VerificationResult.failure('Aucun utilisateur connecté');
      }

      await currentUser.reload();
      if (currentUser.emailVerified) {
        // Mettre à jour le statut de vérification dans Firestore
        await _firestore.collection('users').doc(currentUser.uid).update({'isVerified': true});
        return VerificationResult.success('Email vérifié avec succès !');
      } else {
        return VerificationResult.failure('Email non encore vérifié');
      }
    } catch (e) {
      return VerificationResult.failure('Erreur lors de la vérification: ${e.toString()}');
    }
  }

  // Renvoyer l'email de vérification
  static Future<RegistrationResult> resendVerificationEmail() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return RegistrationResult.failure('Aucun utilisateur connecté');
      }

      if (currentUser.emailVerified) {
        return RegistrationResult.failure('Cet email est déjà vérifié');
      }

      await currentUser.sendEmailVerification();
      return RegistrationResult.success(null, 'Email de vérification renvoyé');
    } catch (e) {
      return RegistrationResult.failure('Erreur lors de l\'envoi: ${e.toString()}');
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: ${e.toString()}');
    }
  }

  // Obtenir l'utilisateur courant
  static User? get currentUser => _auth.currentUser;

  // Stream pour les changements d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Validation des données d'inscription
  static ValidationResult _validateRegistrationData({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
  }) {
    // Validation email
    if (!_isValidEmail(email)) {
      return ValidationResult.failure('Email invalide');
    }

    // Validation mot de passe
    if (password.length < 8) {
      return ValidationResult.failure('Le mot de passe doit contenir au moins 8 caractères');
    }

    if (!_isStrongPassword(password)) {
      return ValidationResult.failure(
        'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre',
      );
    }

    // Validation nom
    if (name.trim().isEmpty) {
      return ValidationResult.failure('Le nom ne peut pas être vide');
    }

    if (name.length < 2) {
      return ValidationResult.failure('Le nom doit contenir au moins 2 caractères');
    }

    // Validation âge
    if (age < 18) {
      return ValidationResult.failure('Vous devez avoir au moins 18 ans');
    }

    if (age > 120) {
      return ValidationResult.failure('Âge invalide');
    }

    // Validation genre
    if (!['homme', 'femme', 'autre'].contains(gender.toLowerCase())) {
      return ValidationResult.failure('Genre invalide');
    }

    // Validation téléphone (optionnel)
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (!_isValidPhoneNumber(phoneNumber)) {
        return ValidationResult.failure('Numéro de téléphone invalide');
      }
    }

    return ValidationResult.success();
  }

  // Validation email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Validation mot de passe fort
  static bool _isStrongPassword(String password) {
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    return hasUpperCase && hasLowerCase && hasDigit;
  }

  // Validation numéro de téléphone
  static bool _isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''));
  }

  // Obtenir un utilisateur par ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  static Future<RegistrationResult> updateUserProfile({
    required String userId,
    String? name,
    int? age,
    String? gender,
    String? phoneNumber,
    String? bio,
    List<String>? interests,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (age != null) updateData['age'] = age;
      if (gender != null) updateData['gender'] = gender;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (bio != null) updateData['bio'] = bio;
      if (interests != null) updateData['interests'] = interests;
      if (preferences != null) updateData['preferences'] = preferences;

      updateData['lastActiveAt'] = Timestamp.now();

      await _firestore.collection('users').doc(userId).update(updateData);

      // Récupérer les données mises à jour
      final updatedUser = await getUserById(userId);

      return RegistrationResult.success(updatedUser, 'Profil mis à jour avec succès');
    } catch (e) {
      return RegistrationResult.failure('Erreur lors de la mise à jour du profil: ${e.toString()}');
    }
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

// Résultats de vérification
class VerificationResult {
  final bool success;
  final String message;

  VerificationResult.success(this.message) : success = true;
  VerificationResult.failure(this.message) : success = false;
}

// Résultats de connexion
class LoginResult {
  final bool success;
  final UserModel? user;
  final String message;

  LoginResult.success(this.user, this.message) : success = true;
  LoginResult.failure(this.message) : success = false, user = null;
}

// Résultats de validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult.success() : isValid = true, errorMessage = null;
  ValidationResult.failure(this.errorMessage) : isValid = false;
}
