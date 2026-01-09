import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Créer ou mettre à jour un profil utilisateur
  static Future<bool> saveUserProfile(UserModel user) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Vérifier si l'utilisateur existe déjà dans Firestore
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();

      final userData = {
        'id': currentUser.uid,
        'name': user.name,
        'age': user.age,
        'bio': user.bio,
        'photos': user.photos,
        'interests': user.interests,
        'location': user.location,
        'latitude': user.latitude,
        'longitude': user.longitude,
        'gender': user.gender,
        'lookingFor': user.lookingFor,
        'job': user.job,
        'education': user.education,
        'verified': user.verified,
        'isOnline': user.isOnline,
        'lastSeen': user.lastSeen?.millisecondsSinceEpoch,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (userDoc.exists) {
        await userDoc.reference.update(userData);
      } else {
        await userDoc.reference.set(userData);
      }

      return true;
    } catch (e) {
      print('Erreur sauvegarde profil: $e');
      return false;
    }
  }

  /// Récupérer le profil utilisateur depuis Firestore
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;

      return UserModel(
        id: data['id'] ?? userId,
        name: data['name'] ?? '',
        age: data['age'] ?? 0,
        bio: data['bio'] ?? '',
        photos: List<String>.from(data['photos'] ?? []),
        interests: List<String>.from(data['interests'] ?? []),
        location: data['location'],
        latitude: (data['latitude'] as num?)?.toDouble(),
        longitude: (data['longitude'] as num?)?.toDouble(),
        gender: data['gender'] ?? 'autre',
        lookingFor: data['lookingFor'],
        job: data['job'],
        education: data['education'],
        verified: data['verified'] ?? false,
        isOnline: data['isOnline'] ?? false,
        lastSeen: data['lastSeen'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'])
            : null,
      );
    } catch (e) {
      print('Erreur récupération profil: $e');
      return null;
    }
  }

  /// Mettre à jour le statut en ligne
  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      print('Erreur mise à jour statut: $e');
    }
  }

  /// Rechercher des profils utilisateurs
  static Future<List<UserModel>> searchUsers({
    String? query,
    int? minAge,
    int? maxAge,
    String? gender,
    String? location,
    List<String>? interests,
    int limit = 20,
  }) async {
    try {
      Query usersQuery = _firestore.collection('users');

      // Appliquer les filtres de recherche
      if (query != null && query.isNotEmpty) {
        usersQuery = usersQuery
            .where('name', isGreaterThanOrEqualTo: query)
            .where('bio', isGreaterThanOrEqualTo: query);
      }

      if (minAge != null) {
        usersQuery = usersQuery.where('age', isGreaterThanOrEqualTo: minAge);
      }

      if (maxAge != null) {
        usersQuery = usersQuery.where('age', isLessThanOrEqualTo: maxAge);
      }

      if (gender != null && gender != 'tous') {
        usersQuery = usersQuery.where('gender', isEqualTo: gender);
      }

      if (location != null && location.isNotEmpty) {
        usersQuery = usersQuery.where('location', isEqualTo: location);
      }

      if (interests != null && interests.isNotEmpty) {
        usersQuery = usersQuery.where('interests', arrayContainsAny: interests);
      }

      final querySnapshot = await usersQuery.limit(limit).get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel(
          id: doc.id,
          name: data['name'] ?? '',
          age: data['age'] ?? 0,
          bio: data['bio'] ?? '',
          photos: List<String>.from(data['photos'] ?? []),
          interests: List<String>.from(data['interests'] ?? []),
          location: data['location'],
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          gender: data['gender'] ?? 'autre',
          lookingFor: data['lookingFor'],
          job: data['job'],
          education: data['education'],
          verified: data['verified'] ?? false,
          isOnline: data['isOnline'] ?? false,
          lastSeen: data['lastSeen'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['lastSeen'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Erreur recherche utilisateurs: $e');
      return [];
    }
  }

  /// Supprimer un compte utilisateur
  static Future<bool> deleteAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      // Supprimer le profil Firestore
      await _firestore.collection('users').doc(currentUser.uid).delete();

      // Supprimer les données associées (messages, matches, etc.)
      await _deleteUserData(currentUser.uid);

      // Se déconnecter
      await _auth.signOut();

      return true;
    } catch (e) {
      print('Erreur suppression compte: $e');
      return false;
    }
  }

  /// Supprimer toutes les données utilisateur associées
  static Future<void> _deleteUserData(String userId) async {
    try {
      // Supprimer les messages
      final messagesQuery = await _firestore
          .collection('messages')
          .where('participants', arrayContains: userId)
          .get();

      for (final doc in messagesQuery.docs) {
        await doc.reference.delete();
      }

      // Supprimer les matches
      final matchesQuery = await _firestore
          .collection('matches')
          .where('participants', arrayContains: userId)
          .get();

      for (final doc in matchesQuery.docs) {
        await doc.reference.delete();
      }

      // Supprimer les demandes
      final requestsQuery = await _firestore
          .collection('requests')
          .where('senderId', isEqualTo: userId)
          .get();

      for (final doc in requestsQuery.docs) {
        await doc.reference.delete();
      }

      // Supprimer les réactions
      final reactionsQuery = await _firestore
          .collection('reactions')
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in reactionsQuery.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Erreur suppression données utilisateur: $e');
    }
  }

  /// Vérifier si un email est déjà utilisé
  static Future<bool> isEmailTaken(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Erreur vérification email: $e');
      return false;
    }
  }

  /// Obtenir des statistiques utilisateur
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Compter les messages envoyés
      final messagesCount = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .count()
          .get();

      // Compter les matches
      final matchesCount = await _firestore
          .collection('matches')
          .where('participants', arrayContains: userId)
          .count()
          .get();

      // Compter les likes reçus
      final likesReceived = await _firestore
          .collection('likes')
          .where('targetUserId', isEqualTo: userId)
          .count()
          .get();

      return {
        'messagesSent': messagesCount,
        'matches': matchesCount,
        'likesReceived': likesReceived,
        'joinDate': FieldValue.serverTimestamp(),
      };
    } catch (e) {
      print('Erreur statistiques: $e');
      return {};
    }
  }
}
