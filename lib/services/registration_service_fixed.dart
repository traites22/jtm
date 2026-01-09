import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import 'user_model.dart';
import 'biometric_service.dart';
import 'notification_service.dart';

class RegistrationService {
  static const String _usersBox = 'usersBox';
  static const String _pendingRegistrationsBox = 'pendingRegistrationsBox';

  // Inscription d'un nouvel utilisateur
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
        return RegistrationResult.failure(validationResult.errorMessage!);
      }

      // Vérifier si l'email existe déjà
      if (await _emailExists(email)) {
        return RegistrationResult.failure('Cet email est déjà utilisé');
      }

      // Vérifier si le numéro de téléphone existe déjà (optionnel)
      if (phoneNumber != null && await _phoneNumberExists(phoneNumber)) {
        return RegistrationResult.failure('Ce numéro de téléphone est déjà utilisé');
      }

      // Créer l'utilisateur
      final userId = _generateUserId();
      final user = UserModel(
        id: userId,
        email: email,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        photos: [],
        bio: '',
        interests: [],
        location: null,
        preferences: preferences ?? {},
        isVerified: false,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // Sauvegarder l'utilisateur
      await _saveUser(user);

      // Envoyer l'email de vérification
      await _sendVerificationEmail(user);

      return RegistrationResult.success(user, 'Inscription réussie ! Vérifiez votre email.');
    } catch (e) {
      return RegistrationResult.failure('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  // Vérification de l'email
  static Future<VerificationResult> verifyEmail({
    required String email,
    required String verificationCode,
  }) async {
    try {
      final pendingBox = Hive.box(_pendingRegistrationsBox);
      final pendingData = pendingBox.get(email);

      if (pendingData == null) {
        return VerificationResult.failure('Aucune vérification en attente pour cet email');
      }

      final pendingRegistration = Map<String, dynamic>.from(pendingData);
      final storedCode = pendingRegistration['verificationCode'];
      final expiryTime = DateTime.parse(pendingRegistration['expiryTime']);

      // Vérifier si le code a expiré
      if (DateTime.now().isAfter(expiryTime)) {
        await pendingBox.delete(email);
        return VerificationResult.failure('Le code de vérification a expiré');
      }

      // Vérifier le code
      if (storedCode != verificationCode) {
        return VerificationResult.failure('Code de vérification incorrect');
      }

      // Marquer l'utilisateur comme vérifié
      final usersBox = Hive.box(_usersBox);
      final userData = usersBox.get(pendingRegistration['userId']);

      if (userData != null) {
        final user = UserModel.fromMap(userData);
        final verifiedUser = user.copyWith(isVerified: true);
        await usersBox.put(user.id, verifiedUser.toMap());
      }

      // Nettoyer les données en attente
      await pendingBox.delete(email);

      return VerificationResult.success('Email vérifié avec succès !');
    } catch (e) {
      return VerificationResult.failure('Erreur lors de la vérification: ${e.toString()}');
    }
  }

  // Renvoyer le code de vérification
  static Future<RegistrationResult> resendVerificationCode(String email) async {
    try {
      final usersBox = Hive.box(_usersBox);
      final userData = usersBox.values.firstWhere(
        (user) => UserModel.fromMap(user).email == email,
        orElse: () => null,
      );

      if (userData == null) {
        return RegistrationResult.failure('Aucun utilisateur trouvé avec cet email');
      }

      final user = UserModel.fromMap(userData);

      if (user.isVerified) {
        return RegistrationResult.failure('Cet email est déjà vérifié');
      }

      await _sendVerificationEmail(user);

      return RegistrationResult.success(user, 'Code de vérification renvoyé');
    } catch (e) {
      return RegistrationResult.failure('Erreur lors de l\'envoi du code: ${e.toString()}');
    }
  }

  // Connexion après inscription
  static Future<LoginResult> loginAfterRegistration({
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

      final usersBox = Hive.box(_usersBox);
      final userData = usersBox.values.firstWhere(
        (user) => UserModel.fromMap(user).email == email,
        orElse: () => null,
      );

      if (userData == null) {
        return LoginResult.failure('Utilisateur non trouvé');
      }

      final user = UserModel.fromMap(userData);

      // Vérifier si l'utilisateur est vérifié
      if (!user.isVerified) {
        return LoginResult.failure('Veuillez vérifier votre email avant de vous connecter');
      }

      // Vérifier le mot de passe (simplifié pour la démo)
      if (!_verifyPassword(password, user.id)) {
        return LoginResult.failure('Mot de passe incorrect');
      }

      // Mettre à jour la dernière activité
      final updatedUser = user.copyWith(lastActiveAt: DateTime.now());
      await usersBox.put(user.id, updatedUser.toMap());

      return LoginResult.success(updatedUser, 'Connexion réussie');
    } catch (e) {
      return LoginResult.failure('Erreur lors de la connexion: ${e.toString()}');
    }
  }

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

  // Vérification si l'email existe
  static Future<bool> _emailExists(String email) async {
    try {
      final usersBox = Hive.box(_usersBox);
      return usersBox.values.any((user) => UserModel.fromMap(user).email == email);
    } catch (e) {
      return false;
    }
  }

  // Vérification si le téléphone existe
  static Future<bool> _phoneNumberExists(String phoneNumber) async {
    try {
      final usersBox = Hive.box(_usersBox);
      return usersBox.values.any((user) {
        final userModel = UserModel.fromMap(user);
        return userModel.phoneNumber == phoneNumber;
      });
    } catch (e) {
      return false;
    }
  }

  // Sauvegarder un utilisateur
  static Future<void> _saveUser(UserModel user) async {
    try {
      final usersBox = Hive.box(_usersBox);
      await usersBox.put(user.id, user.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de l\'utilisateur');
    }
  }

  // Envoyer l'email de vérification
  static Future<void> _sendVerificationEmail(UserModel user) async {
    try {
      final verificationCode = _generateVerificationCode();
      final expiryTime = DateTime.now().add(const Duration(hours: 24));

      final pendingBox = Hive.box(_pendingRegistrationsBox);
      await pendingBox.put(user.email, {
        'userId': user.id,
        'verificationCode': verificationCode,
        'expiryTime': expiryTime.toIso8601String(),
        'sentAt': DateTime.now().toIso8601String(),
      });

      // Simulation d'envoi d'email
      print('Email de vérification envoyé à ${user.email}');
      print('Code: $verificationCode');
      print('Expire le: ${expiryTime.toString()}');

      // Notification locale
      await NotificationService.init();
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'email de vérification');
    }
  }

  // Générer un ID utilisateur
  static String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'user_${timestamp}_$random';
  }

  // Générer un code de vérification
  static String _generateVerificationCode() {
    return (100000 + Random().nextInt(900000)).toString();
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

  // Vérification mot de passe (simplifiée pour la démo)
  static bool _verifyPassword(String password, String userId) {
    // Dans une vraie app, utiliser bcrypt ou argon2
    return password.isNotEmpty && userId.isNotEmpty;
  }

  // Obtenir un utilisateur par email
  static Future<UserModel?> getUserByEmail(String email) async {
    try {
      final usersBox = Hive.box(_usersBox);
      final userData = usersBox.values.firstWhere(
        (user) => UserModel.fromMap(user).email == email,
        orElse: () => null,
      );
      return userData != null ? UserModel.fromMap(userData) : null;
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
      final usersBox = Hive.box(_usersBox);
      final userData = usersBox.get(userId);

      if (userData == null) {
        return RegistrationResult.failure('Utilisateur non trouvé');
      }

      final user = UserModel.fromMap(userData);
      final updatedUser = user.copyWith(
        name: name ?? user.name,
        age: age ?? user.age,
        gender: gender ?? user.gender,
        phoneNumber: phoneNumber ?? user.phoneNumber,
        bio: bio ?? user.bio,
        interests: interests ?? user.interests,
        preferences: preferences ?? user.preferences,
        lastActiveAt: DateTime.now(),
      );

      await usersBox.put(userId, updatedUser.toMap());

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
