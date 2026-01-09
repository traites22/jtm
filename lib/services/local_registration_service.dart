import 'dart:async';
import 'dart:math';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../services/biometric_service.dart';
import '../services/notification_service.dart';

class LocalRegistrationService {
  static const String _usersBox = 'usersBox';

  // Inscription d'un nouvel utilisateur (stockage local)
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

      // Vérifier si l'email existe déjà
      if (await _emailExists(email)) {
        return RegistrationResult.failure('Cet email est déjà utilisé');
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
        isVerified: true, // Auto-vérifié pour la version locale
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // Sauvegarder l'utilisateur
      await _saveUser(user);

      // Initialiser les notifications
      await NotificationService.init();

      return RegistrationResult.success(
        user,
        'Inscription réussie ! Vous pouvez maintenant vous connecter.',
      );
    } catch (e) {
      return RegistrationResult.failure('Erreur lors de l\'inscription: ${e.toString()}');
    }
  }

  // Connexion (stockage local)
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

      final usersBox = Hive.box(_usersBox);
      final userData = usersBox.values.firstWhere(
        (user) => UserModel.fromMap(user).email == email,
        orElse: () => null,
      );

      if (userData == null) {
        return LoginResult.failure('Utilisateur non trouvé');
      }

      final user = UserModel.fromMap(userData);

      // Vérification simple du mot de passe (pour la démo)
      if (password.isEmpty) {
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

  // Déconnexion
  static Future<void> logout() async {
    try {
      // Pour la version locale, on peut juste nettoyer les données temporaires
      final profileBox = Hive.box('profileBox');
      await profileBox.clear();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: ${e.toString()}');
    }
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

  // Obtenir tous les utilisateurs (pour la découverte)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final usersBox = Hive.box(_usersBox);
      return usersBox.values.map((userData) => UserModel.fromMap(userData)).toList();
    } catch (e) {
      return [];
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
    if (password.length < 4) {
      // Simplifié pour la démo
      return ValidationResult.failure('Le mot de passe doit contenir au moins 4 caractères');
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

  // Sauvegarder un utilisateur
  static Future<void> _saveUser(UserModel user) async {
    try {
      final usersBox = Hive.box(_usersBox);
      await usersBox.put(user.id, user.toMap());
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de l\'utilisateur');
    }
  }

  // Générer un ID utilisateur
  static String _generateUserId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'user_${timestamp}_$random';
  }

  // Validation email
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  // Validation numéro de téléphone
  static bool _isValidPhoneNumber(String phoneNumber) {
    final phoneRegex = RegExp(r'^[0-9]{10,15}$');
    return phoneRegex.hasMatch(phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''));
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

// Résultats de validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult.success() : isValid = true, errorMessage = null;
  ValidationResult.failure(this.errorMessage) : isValid = false;
}
