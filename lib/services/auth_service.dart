import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
  }) async {
    try {
      // Créer l'utilisateur Firebase
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        return {'success': false, 'error': 'Erreur lors de la création du compte'};
      }

      // Envoyer l'email de vérification
      await user.sendEmailVerification();

      // Créer le profil utilisateur dans Firestore
      final userModel = UserModel(
        id: user.uid,
        name: name,
        age: age,
        bio: '',
        photos: [],
        gender: gender,
        verified: false,
        isOnline: true,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      // Mettre à jour le statut en ligne
      await _updateOnlineStatus(user.uid, true);

      return {
        'success': true,
        'user': userModel,
        'message': 'Compte créé avec succès. Vérifiez vos emails.',
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

      // Vérifier si l'email est vérifié
      if (!user.emailVerified) {
        await _auth.signOut();
        return {'success': false, 'error': 'Veuillez vérifier votre email avant de vous connecter'};
      }

      // Récupérer le profil utilisateur
      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        return {'success': false, 'error': 'Profil utilisateur non trouvé'};
      }

      final userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

      // Mettre à jour le statut en ligne
      await _updateOnlineStatus(user.uid, true);

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
        await _updateOnlineStatus(user.uid, false);
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
      await _firestore.collection('users').doc(user.id).update(user.toMap());
      return true;
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

      final DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
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

      // Supprimer les données utilisateur
      await _firestore.collection('users').doc(user.uid).delete();

      // Supprimer le compte Firebase
      await user.delete();

      return true;
    } catch (e) {
      print('Erreur suppression compte: $e');
      return false;
    }
  }

  // Mettre à jour le statut en ligne
  static Future<void> _updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      print('Erreur mise à jour statut: $e');
    }
  }

  // Sauvegarder le token de notification
  static Future<void> saveNotificationToken(String token) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({'notificationToken': token});
    } catch (e) {
      print('Erreur sauvegarde token notification: $e');
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
