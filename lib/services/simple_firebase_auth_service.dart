import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/smart_registration_service.dart'; // Service existant qui fonctionne

class SimpleFirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pour écouter les changements d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur courant
  static User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  static bool get isLoggedIn => _auth.currentUser != null;

  // Inscription simple : Firebase Auth + profil local
  static Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
  }) async {
    try {
      // 1. Créer l'utilisateur Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return {'success': false, 'error': 'Erreur lors de la création du compte'};
      }

      // 2. Utiliser le service local qui fonctionne déjà
      final localResult = await SmartRegistrationService.registerUser(
        email: email,
        password: password,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
      );

      if (localResult.success) {
        print('✅ Inscription réussie avec Firebase + Local');
        return {'success': true, 'user': localResult.user, 'message': 'Compte créé avec succès !'};
      } else {
        return {'success': false, 'error': localResult.message};
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Une erreur est survenue';

      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Le mot de passe est trop faible';
          break;
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide';
          break;
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Erreur: ${e.toString()}'};
    }
  }

  // Connexion simple : Firebase Auth + profil local
  static Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Connexion Firebase Auth
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return {'success': false, 'error': 'Erreur lors de la connexion'};
      }

      // 2. Utiliser le service local qui fonctionne déjà
      final localResult = await SmartRegistrationService.loginUser(
        email: email,
        password: password,
      );

      if (localResult.success) {
        print('✅ Connexion réussie avec Firebase + Local');
        return {'success': true, 'user': localResult.user, 'message': 'Connexion réussie !'};
      } else {
        return {'success': false, 'error': localResult.message};
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Une erreur est survenue';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Utilisateur non trouvé';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect';
          break;
        case 'invalid-email':
          errorMessage = 'Email invalide';
          break;
        case 'user-disabled':
          errorMessage = 'Compte désactivé';
          break;
      }

      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Erreur: ${e.toString()}'};
    }
  }

  // Déconnexion
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('✅ Déconnexion Firebase réussie');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // Obtenir le profil utilisateur courant
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      // Utiliser le service local qui fonctionne
      final localResult = await SmartRegistrationService.loginUser(
        email: user.email ?? '',
        password: 'dummy', // Juste pour récupérer le profil
      );

      return localResult.success ? localResult.user : null;
    } catch (e) {
      print('Erreur récupération profil: $e');
      return null;
    }
  }
}
