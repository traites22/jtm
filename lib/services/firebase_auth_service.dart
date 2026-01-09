import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firebase_user_service.dart';

class FirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pour écouter les changements d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur courant
  static User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  static bool get isLoggedIn => _auth.currentUser != null;

  // Inscription avec email et mot de passe
  static Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
  }) async {
    try {
      // Créer l'utilisateur Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return {'success': false, 'error': 'Erreur lors de la création du compte'};
      }

      // Envoyer l'email de vérification (optionnel pour le moment)
      await user.sendEmailVerification();

      // Créer le profil utilisateur dans Firestore
      final userModel = UserModel(
        id: user.uid,
        email: email,
        name: name,
        age: age,
        gender: gender,
        phoneNumber: phoneNumber,
        photos: const [],
        bio: '',
        interests: const [],
        location: null,
        preferences: const {},
        isVerified: false,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      final userCreated = await FirebaseUserService.createUser(userModel);
      if (!userCreated) {
        await _auth.currentUser?.delete();
        return {'success': false, 'error': 'Erreur lors de la création du profil'};
      }

      return {
        'success': true,
        'user': userModel,
        'message': 'Compte créé avec succès ! Vous pouvez maintenant vous connecter.',
      };
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

  // Connexion avec email et mot de passe
  static Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return {'success': false, 'error': 'Erreur lors de la connexion'};
      }

      // Vérifier si l'email est vérifié (désactivé pour le moment)
      // if (!user.emailVerified) {
      //   await _auth.signOut();
      //   return {'success': false, 'error': 'Veuillez vérifier votre email avant de vous connecter'};
      // }

      // Récupérer le profil utilisateur depuis Firestore
      final userModel = await FirebaseUserService.getUserById(user.uid);
      if (userModel == null) {
        return {'success': false, 'error': 'Profil utilisateur non trouvé'};
      }

      // Mettre à jour le statut en ligne
      await FirebaseUserService.updateOnlineStatus(user.uid, true);

      return {'success': true, 'user': userModel};
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
      final User? user = _auth.currentUser;
      if (user != null) {
        // Mettre à jour le statut hors ligne
        await FirebaseUserService.updateOnlineStatus(user.uid, false);
      }

      await _auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // Réinitialiser le mot de passe
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Email de réinitialisation envoyé'};
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Une erreur est survenue';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email';
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

  // Mettre à jour le profil utilisateur
  static Future<bool> updateProfile(UserModel user) async {
    try {
      return await FirebaseUserService.updateUser(user);
    } catch (e) {
      print('Erreur mise à jour profil: $e');
      return false;
    }
  }

  // Obtenir le profil utilisateur courant
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      return await FirebaseUserService.getUserById(user.uid);
    } catch (e) {
      print('Erreur récupération profil: $e');
      return null;
    }
  }

  // Supprimer le compte utilisateur
  static Future<bool> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      // Supprimer les données utilisateur de Firestore
      final deleted = await FirebaseUserService.deleteUser(user.uid);
      if (!deleted) return false;

      // Supprimer le compte Firebase Auth
      await user.delete();

      return true;
    } catch (e) {
      print('Erreur suppression compte: $e');
      return false;
    }
  }

  // Vérifier si l'email est vérifié
  static bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // Renvoyer l'email de vérification
  static Future<bool> resendVerificationEmail() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur envoi vérification: $e');
      return false;
    }
  }
}
