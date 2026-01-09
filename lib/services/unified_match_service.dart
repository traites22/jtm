import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../models/filter_model.dart';
import '../models/message_model.dart';
import 'auth_service.dart';
import 'cloud_match_service.dart';
import 'cloud_messaging_service.dart';
import 'push_notification_service.dart';
import 'storage_service.dart';
import 'filter_service.dart';

class UnifiedMatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialiser tous les services
  static Future<void> initialize() async {
    try {
      // Initialiser les notifications push
      await PushNotificationService.initialize();
      await PushNotificationService.subscribeToTopics();

      print('Services de matching initialisés');
    } catch (e) {
      print('Erreur initialisation services: $e');
    }
  }

  /// S'inscrire et créer un profil complet
  static Future<Map<String, dynamic>> registerAndCreateProfile({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String? bio,
    List<String>? interests,
    String? lookingFor,
    String? location,
    double? latitude,
    double? longitude,
    String? job,
    String? education,
    List<XFile>? profilePhotos,
  }) async {
    try {
      // 1. Créer le compte utilisateur
      final authResult = await AuthService.registerWithEmail(
        email: email,
        password: password,
        name: name,
        age: age,
        gender: gender,
      );

      if (!authResult['success']) {
        return authResult;
      }

      final user = authResult['user'] as UserModel;
      final currentUserId = user.id;

      // 2. Uploader les photos de profil si fournies
      List<String> photoUrls = [];
      if (profilePhotos != null && profilePhotos.isNotEmpty) {
        photoUrls = await StorageService.uploadMultipleProfilePhotos(profilePhotos);
      }

      // 3. Mettre à jour le profil avec les informations complètes
      final updatedProfile = user.copyWith(
        bio: bio ?? '',
        interests: interests ?? [],
        lookingFor: lookingFor,
        location: location,
        latitude: latitude,
        longitude: longitude,
        job: job,
        education: education,
        photos: photoUrls,
      );

      await AuthService.updateProfile(updatedProfile);

      // 4. Sauvegarder le token de notification
      final token = await _getFCMToken();
      if (token != null) {
        await AuthService.saveNotificationToken(token);
      }

      return {'success': true, 'user': updatedProfile, 'message': 'Compte créé avec succès'};
    } catch (e) {
      print('Erreur inscription complète: $e');
      return {'success': false, 'error': 'Erreur lors de la création du compte'};
    }
  }

  /// Se connecter et initialiser les services
  static Future<Map<String, dynamic>> signInAndInitialize({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Se connecter
      final authResult = await AuthService.signInWithEmail(email: email, password: password);

      if (!authResult['success']) {
        return authResult;
      }

      final user = authResult['user'] as UserModel;

      // 2. Mettre à jour le statut en ligne
      await _updateOnlineStatus(true);

      // 3. Sauvegarder le token de notification
      final token = await _getFCMToken();
      if (token != null) {
        await AuthService.saveNotificationToken(token);
      }

      // 4. Initialiser les services de notification
      await PushNotificationService.initialize();

      return {'success': true, 'user': user, 'message': 'Connecté avec succès'};
    } catch (e) {
      print('Erreur connexion complète: $e');
      return {'success': false, 'error': 'Erreur lors de la connexion'};
    }
  }

  /// Se déconnecter et nettoyer
  static Future<void> signOutAndCleanup() async {
    try {
      final currentUserId = _auth.currentUser?.uid;

      // 1. Mettre à jour le statut hors ligne
      await _updateOnlineStatus(false);

      // 2. Supprimer le token de notification
      await PushNotificationService.removeToken();
      await PushNotificationService.unsubscribeFromTopics();

      // 3. Se déconnecter
      await AuthService.signOut();

      print('Déconnexion et nettoyage terminés');
    } catch (e) {
      print('Erreur déconnexion: $e');
    }
  }

  /// Aimer un utilisateur avec notifications
  static Future<Map<String, dynamic>> likeUserWithNotification({
    required String targetUserId,
    bool isSuperLike = false,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        return {'success': false, 'error': 'Utilisateur non connecté'};
      }

      // 1. Effectuer le like via le service cloud
      final result = await CloudMatchService.likeUser(
        targetUserId: targetUserId,
        isSuperLike: isSuperLike,
      );

      if (result['success']) {
        // 2. Envoyer une notification si ce n'est pas un match
        if (!result['isMatch']) {
          final currentUser = await AuthService.getCurrentUserProfile();
          if (currentUser != null) {
            await PushNotificationService.sendLikeNotification(
              targetUserId: targetUserId,
              senderName: currentUser.name,
              senderId: currentUserId,
            );
          }
        } else {
          // 3. Si c'est un match, envoyer une notification de match
          final targetUser = await _getUserProfile(targetUserId);
          final currentUser = await AuthService.getCurrentUserProfile();

          if (targetUser != null && currentUser != null) {
            await PushNotificationService.sendMatchNotification(
              user1Id: currentUserId,
              user2Id: targetUserId,
              matchId: result['matchId'],
              userName1: currentUser.name,
              userName2: targetUser.name,
            );
          }
        }
      }

      return result;
    } catch (e) {
      print('Erreur like avec notification: $e');
      return {'success': false, 'error': 'Erreur lors du like'};
    }
  }

  /// Envoyer un message avec notification
  static Future<bool> sendMessageWithNotification({
    required String matchId,
    required String text,
  }) async {
    try {
      // 1. Envoyer le message
      final success = await CloudMessagingService.sendTextMessage(matchId: matchId, text: text);

      if (success) {
        // 2. Envoyer une notification push
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId != null) {
          // Obtenir les informations du match
          final matchDoc = await _firestore.collection('matches').doc(matchId).get();
          if (matchDoc.exists) {
            final matchData = matchDoc.data()!;
            final user1Id = matchData['user1Id'] as String;
            final user2Id = matchData['user2Id'] as String;

            final targetUserId = currentUserId == user1Id ? user2Id : user1Id;
            final currentUser = await AuthService.getCurrentUserProfile();

            if (currentUser != null) {
              await PushNotificationService.sendMessageNotification(
                targetUserId: targetUserId,
                senderName: currentUser.name,
                messageText: text,
                matchId: matchId,
                senderId: currentUserId,
              );
            }
          }
        }
      }

      return success;
    } catch (e) {
      print('Erreur message avec notification: $e');
      return false;
    }
  }

  /// Obtenir les profils compatibles avec filtres
  static Future<List<UserModel>> getFilteredProfiles({FilterModel? filters, int limit = 20}) async {
    try {
      // 1. Obtenir les profils compatibles de base
      final profiles = await CloudMatchService.getCompatibleProfiles(
        filters: filters,
        limit: limit,
      );

      // 2. Appliquer les filtres supplémentaires localement si nécessaire
      final currentUser = await AuthService.getCurrentUserProfile();
      if (currentUser != null && filters != null) {
        return FilterService.filterProfiles(profiles, filters, currentUser);
      }

      return profiles;
    } catch (e) {
      print('Erreur profils filtrés: $e');
      return [];
    }
  }

  /// Obtenir les matches avec informations enrichies
  static Stream<List<Map<String, dynamic>>> getEnrichedMatches() {
    return CloudMatchService.getUserMatches().asyncMap((matches) async {
      final enrichedMatches = <Map<String, dynamic>>[];

      for (final match in matches) {
        final enriched = Map<String, dynamic>.from(match);

        // Ajouter des informations supplémentaires
        enriched['lastMessageTimeFormatted'] = _formatTimestamp(match['lastMessageTime']);
        enriched['isOnline'] = match['user']?.isOnline ?? false;
        enriched['unreadCount'] = match['unreadCount'] ?? 0;

        enrichedMatches.add(enriched);
      }

      return enrichedMatches;
    });
  }

  /// Mettre à jour le profil utilisateur avec upload d'images
  static Future<bool> updateProfileWithImages({
    required UserModel updatedUser,
    List<XFile>? newPhotos,
    List<String>? photosToRemove,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      // 1. Supprimer les anciennes photos si nécessaire
      if (photosToRemove != null && photosToRemove.isNotEmpty) {
        await StorageService.deleteMultipleProfilePhotos(photosToRemove);
      }

      // 2. Uploader les nouvelles photos
      List<String> newPhotoUrls = [];
      if (newPhotos != null && newPhotos.isNotEmpty) {
        newPhotoUrls = await StorageService.uploadMultipleProfilePhotos(newPhotos);
      }

      // 3. Mettre à jour la liste des photos
      final currentPhotos = List<String>.from(updatedUser.photos);
      currentPhotos.addAll(newPhotoUrls);

      // 4. Supprimer les photos à retirer de la liste
      if (photosToRemove != null) {
        currentPhotos.removeWhere((url) => photosToRemove.contains(url));
      }

      final finalUser = updatedUser.copyWith(photos: currentPhotos);

      // 5. Sauvegarder le profil mis à jour
      return await AuthService.updateProfile(finalUser);
    } catch (e) {
      print('Erreur mise à jour profil avec images: $e');
      return false;
    }
  }

  /// Obtenir les statistiques complètes de l'utilisateur
  static Future<Map<String, dynamic>> getCompleteStats() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return {};

      // 1. Statistiques de matching
      final matchStats = await CloudMatchService.getMatchStats();

      // 2. Statistiques de messagerie
      final messagesCount = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .count()
          .get();

      // 3. Taille de stockage utilisé
      final storageSize = await StorageService.getUserStorageSize();

      // 4. Nombre de photos de profil
      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      final photosCount = userDoc.exists ? (userDoc.data()!['photos'] as List?)?.length ?? 0 : 0;

      return {
        ...matchStats,
        'conversationsCount': messagesCount.count ?? 0,
        'storageSizeBytes': storageSize,
        'storageSizeMB': (storageSize / (1024 * 1024)).toStringAsFixed(2),
        'photosCount': photosCount,
        'profileCompletion': await _calculateProfileCompletion(),
      };
    } catch (e) {
      print('Erreur statistiques complètes: $e');
      return {};
    }
  }

  /// Méthodes utilitaires privées
  static Future<String?> _getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Erreur obtention token FCM: $e');
      return null;
    }
  }

  static Future<void> _updateOnlineStatus(bool isOnline) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      print('Erreur mise à jour statut en ligne: $e');
    }
  }

  static Future<UserModel?> _getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;

      return UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
    } catch (e) {
      print('Erreur récupération profil utilisateur: $e');
      return null;
    }
  }

  static String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    try {
      final dateTime = timestamp is Timestamp
          ? timestamp.toDate()
          : DateTime.parse(timestamp.toString());

      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'À l\'instant';
      } else if (difference.inHours < 1) {
        return 'Il y a ${difference.inMinutes} min';
      } else if (difference.inDays < 1) {
        return 'Il y a ${difference.inHours} h';
      } else if (difference.inDays < 7) {
        return 'Il y a ${difference.inDays} j';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }

  static Future<double> _calculateProfileCompletion() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 0.0;

      final userDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) return 0.0;

      final data = userDoc.data()!;
      double completion = 0.0;

      // Champs obligatoires (40%)
      if (data['name']?.toString().isNotEmpty == true) completion += 10;
      if (data['age'] != null) completion += 10;
      if (data['gender']?.toString().isNotEmpty == true) completion += 10;
      if (data['photos'] != null && (data['photos'] as List).isNotEmpty) completion += 10;

      // Champs optionnels (60%)
      if (data['bio']?.toString().isNotEmpty == true) completion += 15;
      if (data['interests'] != null && (data['interests'] as List).isNotEmpty) completion += 15;
      if (data['lookingFor']?.toString().isNotEmpty == true) completion += 10;
      if (data['location']?.toString().isNotEmpty == true) completion += 10;
      if (data['job']?.toString().isNotEmpty == true) completion += 5;
      if (data['education']?.toString().isNotEmpty == true) completion += 5;

      return completion;
    } catch (e) {
      print('Erreur calcul complétion profil: $e');
      return 0.0;
    }
  }
}
