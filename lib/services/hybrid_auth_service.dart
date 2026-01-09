import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart'; // Service local existant
import 'firebase_user_service.dart';

class HybridAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pour écouter les changements d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur courant
  static User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  static bool get isLoggedIn => _auth.currentUser != null;

  // Inscription hybride : Firebase Auth + Local
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

      // 2. Créer le profil utilisateur local (garde de secours)
      final localUser = UserModel(
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
        isVerified: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      // 3. Sauvegarder en local (garde de secours)
      await UserService.saveUserProfile(localUser);

      // 4. Essayer de sauvegarder dans Firebase (optionnel)
      try {
        final firebaseSaved = await FirebaseUserService.createUser(localUser);
        print('🔥 Firebase save: $firebaseSaved');
      } catch (e) {
        print('⚠️ Firebase save failed, using local only: $e');
      }

      return {'success': true, 'user': localUser, 'message': 'Compte créé avec succès !'};
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

  // Connexion hybride : Firebase Auth + Local
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

      // 2. Essayer de récupérer depuis Firebase
      try {
        final firebaseUser = await FirebaseUserService.getUserById(user.uid);
        if (firebaseUser != null) {
          print('✅ Utilisateur trouvé dans Firebase');
          // Mettre à jour le statut en ligne
          await FirebaseUserService.updateOnlineStatus(user.uid, true);
          return {'success': true, 'user': firebaseUser};
        }
      } catch (e) {
        print('⚠️ Firebase récupération échouée: $e');
      }

      // 3. Récupérer depuis le local (garde de secours)
      final localUser = await UserService.getUserProfile();
      if (localUser != null && localUser.email == email) {
        print('✅ Utilisateur trouvé en local (garde de secours)');
        return {'success': true, 'user': localUser};
      }

      // 4. Créer un profil basique si rien trouvé
      final basicUser = UserModel(
        id: user.uid,
        email: email,
        name: email.split('@')[0],
        age: 25,
        gender: 'autre',
        phoneNumber: null,
        photos: const [],
        bio: 'Profil créé automatiquement',
        interests: const [],
        location: null,
        preferences: const {},
        isVerified: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      await UserService.saveUserProfile(basicUser);
      print('🆕 Profil basique créé');

      return {'success': true, 'user': basicUser};
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
        // Mettre à jour le statut hors ligne dans Firebase
        try {
          await FirebaseUserService.updateOnlineStatus(user.uid, false);
        } catch (e) {
          print('⚠️ Firebase status update failed: $e');
        }
      }

      await _auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  // Obtenir le profil utilisateur courant (hybride)
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      // 1. Essayer Firebase
      try {
        final firebaseUser = await FirebaseUserService.getUserById(user.uid);
        if (firebaseUser != null) {
          return firebaseUser;
        }
      } catch (e) {
        print('⚠️ Firebase getUser failed: $e');
      }

      // 2. Retourner un profil basique
      final basicUser = UserModel(
        id: user.uid,
        email: user.email ?? '',
        name: user.email?.split('@')[0] ?? 'User',
        age: 25,
        gender: 'autre',
        phoneNumber: null,
        photos: const [],
        bio: 'Utilisateur Firebase',
        interests: const [],
        location: null,
        preferences: const {},
        isVerified: true,
        createdAt: DateTime.now(),
        lastActiveAt: DateTime.now(),
      );

      return basicUser;
    } catch (e) {
      print('Erreur récupération profil: $e');
      return null;
    }
  }
}
