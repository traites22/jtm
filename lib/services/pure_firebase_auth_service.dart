import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/auth_result.dart';
import 'firebase_user_service.dart';

class PureFirebaseAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream pour écouter les changements d'authentification
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Obtenir l'utilisateur courant
  static User? get currentUser => _auth.currentUser;

  // Vérifier si l'utilisateur est connecté
  static bool get isLoggedIn => _auth.currentUser != null;

  // Création de compte (email ou téléphone)
  static Future<AuthResult> createAccount({
    required String identifier,
    required String password,
    required bool isEmail,
  }) async {
    try {
      print('🔥 Début création compte pour: $identifier');

      UserCredential result;

      if (isEmail) {
        // Inscription par email
        result = await _auth.createUserWithEmailAndPassword(email: identifier, password: password);
      } else {
        // Inscription par téléphone
        result = await _auth.createUserWithEmailAndPassword(
          email: '${identifier}@temp.jtm.com', // Email temporaire
          password: password,
        );
      }

      final User? user = result.user;
      if (user == null) {
        return AuthResult(success: false, message: 'Erreur lors de la création du compte');
      }

      print('✅ Compte créé: ${user.uid}');

      // Envoyer la vérification
      if (isEmail) {
        await user.sendEmailVerification();
        print('📧 Email de vérification envoyé');
      } else {
        // Pour le téléphone, on utilisera Twilio plus tard
        print('📱 Vérification SMS à implémenter');
      }

      return AuthResult(
        success: true,
        message: 'Compte créé. Vérifiez votre ${isEmail ? 'email' : 'téléphone'}.',
        userId: user.uid,
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur création compte: ${e.code}');
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

      return AuthResult(success: false, message: errorMessage);
    } catch (e) {
      print('❌ Erreur création compte: $e');
      return AuthResult(success: false, message: 'Erreur: ${e.toString()}');
    }
  }

  // Vérifier le code (email ou SMS)
  static Future<AuthResult> verifyCode({
    required String userId,
    required String code,
    required bool isEmail,
  }) async {
    try {
      print('🔍 Vérification code pour: $userId');

      if (isEmail) {
        // Pour l'email, on vérifie si l'email est vérifié
        final user = _auth.currentUser;
        if (user != null && user.emailVerified) {
          await user.reload();
          return AuthResult(success: true, message: 'Email vérifié avec succès');
        } else {
          return AuthResult(success: false, message: 'Email non encore vérifié');
        }
      } else {
        // Pour le téléphone, implémentation avec Twilio à venir
        return AuthResult(success: false, message: 'Vérification SMS à implémenter');
      }
    } catch (e) {
      print('❌ Erreur vérification: $e');
      return AuthResult(success: false, message: 'Erreur lors de la vérification');
    }
  }

  // Inscription 100% Firebase (ancienne méthode, conservée pour compatibilité)
  static Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? phoneNumber,
  }) async {
    try {
      print('🔥 Début inscription Firebase pour: $email');

      // 1. Créer l'utilisateur Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        print('❌ Échec création utilisateur Firebase Auth');
        return {'success': false, 'error': 'Erreur lors de la création du compte'};
      }

      print('✅ Utilisateur Firebase Auth créé: ${user.uid}');

      // 2. Créer le profil dans Firestore
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

      print('📄 Création profil Firestore pour: ${userModel.id}');

      final userCreated = await FirebaseUserService.createUser(userModel);
      if (!userCreated) {
        print('❌ Échec création profil Firestore, suppression utilisateur Auth');
        await user.delete();
        return {'success': false, 'error': 'Erreur lors de la création du profil'};
      }

      print('✅ Inscription Firebase complète réussie !');
      return {
        'success': true,
        'user': userModel,
        'message': 'Compte créé avec succès ! Vous pouvez maintenant vous connecter.',
      };
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
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
      print('❌ Erreur inscription: $e');
      return {'success': false, 'error': 'Erreur: ${e.toString()}'};
    }
  }

  // Connexion 100% Firebase
  static Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔥 Début connexion Firebase pour: $email');

      // 1. Connexion Firebase Auth
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        print('❌ Échec connexion Firebase Auth');
        return {'success': false, 'error': 'Erreur lors de la connexion'};
      }

      print('✅ Connexion Firebase Auth réussie: ${user.uid}');

      // 2. Récupérer le profil depuis Firestore
      print('📄 Récupération profil Firestore pour: ${user.uid}');

      final userModel = await FirebaseUserService.getUserById(user.uid);
      if (userModel == null) {
        print('❌ Profil non trouvé dans Firestore');
        await _auth.signOut();
        return {'success': false, 'error': 'Profil utilisateur non trouvé'};
      }

      print('✅ Profil Firestore récupéré: ${userModel.name}');

      // 3. Mettre à jour le statut en ligne
      await FirebaseUserService.updateOnlineStatus(user.uid, true);
      print('✅ Statut en ligne mis à jour');

      print('✅ Connexion Firebase complète réussie !');
      return {'success': true, 'user': userModel};
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
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
      print('❌ Erreur connexion: $e');
      return {'success': false, 'error': 'Erreur: ${e.toString()}'};
    }
  }

  // Déconnexion
  static Future<void> signOut() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        print('🔥 Déconnexion utilisateur: ${user.uid}');

        // Mettre à jour le statut hors ligne dans Firebase
        await FirebaseUserService.updateOnlineStatus(user.uid, false);
        print('✅ Statut hors ligne mis à jour');
      }

      await _auth.signOut();
      print('✅ Déconnexion Firebase réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }

  // Obtenir le profil utilisateur courant
  static Future<UserModel?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur Firebase connecté');
        return null;
      }

      print('📄 Récupération profil courant pour: ${user.uid}');
      final userModel = await FirebaseUserService.getUserById(user.uid);

      if (userModel != null) {
        print('✅ Profil courant récupéré: ${userModel.name}');
      } else {
        print('❌ Profil courant non trouvé');
      }

      return userModel;
    } catch (e) {
      print('❌ Erreur récupération profil courant: $e');
      return null;
    }
  }

  // Réinitialiser le mot de passe
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Email de réinitialisation envoyé à: $email');
      return {'success': true, 'message': 'Email de réinitialisation envoyé'};
    } on FirebaseAuthException catch (e) {
      print('❌ Erreur réinitialisation: ${e.code}');
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
      print('❌ Erreur réinitialisation: $e');
      return {'success': false, 'error': 'Erreur: ${e.toString()}'};
    }
  }
}
