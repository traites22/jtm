import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../models/filter_model.dart';
import '../services/filter_service.dart';

class CloudMatchService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Aimer un utilisateur et vérifier si c'est un match
  static Future<Map<String, dynamic>> likeUser({
    required String targetUserId,
    bool isSuperLike = false,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null || currentUserId == targetUserId) {
        return {'success': false, 'error': 'Utilisateur non connecté ou invalide'};
      }

      final batch = _firestore.batch();
      final now = Timestamp.now();

      // Ajouter le like
      final likeRef = _firestore.collection('likes').doc();
      batch.set(likeRef, {
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'isSuperLike': isSuperLike,
        'createdAt': now,
      });

      // Vérifier si l'autre utilisateur nous a déjà aimé
      final existingLikeQuery = await _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: targetUserId)
          .where('toUserId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      bool isMatch = existingLikeQuery.docs.isNotEmpty;

      if (isMatch) {
        // C'est un match ! Créer le match
        final matchRef = _firestore.collection('matches').doc();
        final matchId = matchRef.id;

        batch.set(matchRef, {
          'id': matchId,
          'user1Id': currentUserId,
          'user2Id': targetUserId,
          'createdAt': now,
          'lastMessage': null,
          'lastMessageTime': null,
          'user1Unread': 0,
          'user2Unread': 0,
        });

        // Mettre à jour les likes pour les marquer comme matchés
        final existingLikeDoc = existingLikeQuery.docs.first;
        batch.update(existingLikeDoc.reference, {'matched': true, 'matchedAt': now});
        batch.update(likeRef, {'matched': true, 'matchedAt': now});

        // Créer une conversation initiale
        final conversationRef = _firestore.collection('conversations').doc(matchId);
        batch.set(conversationRef, {
          'matchId': matchId,
          'participants': [currentUserId, targetUserId],
          'createdAt': now,
          'lastMessage': 'Salut! 👋',
          'lastMessageTime': now,
          'lastMessageSender': targetUserId,
        });

        // Ajouter le message de bienvenue
        final messageRef = _firestore
            .collection('conversations')
            .doc(matchId)
            .collection('messages')
            .doc();
        batch.set(messageRef, {
          'id': messageRef.id,
          'senderId': targetUserId,
          'text': 'Salut! 👋',
          'type': 'text',
          'timestamp': now,
          'status': 'delivered',
          'read': false,
        });

        await batch.commit();

        // Notifier les deux utilisateurs
        await _notifyMatch(currentUserId, targetUserId, matchId);

        return {
          'success': true,
          'isMatch': true,
          'matchId': matchId,
          'message': 'C\'est un match !',
        };
      } else {
        await batch.commit();

        return {'success': true, 'isMatch': false, 'message': 'Like envoyé'};
      }
    } catch (e) {
      print('Erreur like user: $e');
      return {'success': false, 'error': 'Erreur lors du like'};
    }
  }

  /// Passer (dislike) un utilisateur
  static Future<bool> passUser(String targetUserId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      await _firestore.collection('passes').add({
        'fromUserId': currentUserId,
        'toUserId': targetUserId,
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Erreur pass user: $e');
      return false;
    }
  }

  /// Obtenir les profils compatibles
  static Future<List<UserModel>> getCompatibleProfiles({
    FilterModel? filters,
    int limit = 20,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return [];

      // Récupérer le profil de l'utilisateur courant
      final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
      if (!currentUserDoc.exists) return [];

      final currentUser = UserModel.fromMap(currentUserDoc.data() as Map<String, dynamic>);

      // Construire la requête de base
      Query query = _firestore
          .collection('users')
          .where(FieldPath.documentId, isNotEqualTo: currentUserId);

      // Appliquer les filtres de préférences de base
      if (currentUser.lookingFor != null && currentUser.lookingFor != 'tous') {
        query = query.where('gender', isEqualTo: currentUser.lookingFor);
      }

      // Exclure les profils déjà aimés ou passés
      final likedDocs = await _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();

      final passedDocs = await _firestore
          .collection('passes')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();

      final excludedUserIds = [
        ...likedDocs.docs.map((doc) => doc['toUserId'] as String),
        ...passedDocs.docs.map((doc) => doc['toUserId'] as String),
      ];

      // Exclure les matches existants
      final matchesDocs = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: currentUserId)
          .get();

      final matchesDocs2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: currentUserId)
          .get();

      final matchedUserIds = [
        ...matchesDocs.docs.map((doc) => doc['user2Id'] as String),
        ...matchesDocs2.docs.map((doc) => doc['user1Id'] as String),
      ];

      final allExcludedIds = [...excludedUserIds, ...matchedUserIds];

      if (allExcludedIds.isNotEmpty) {
        query = query.where(FieldPath.documentId, whereNotIn: allExcludedIds);
      }

      // Limiter les résultats
      query = query.limit(limit);

      final querySnapshot = await query.get();
      List<UserModel> profiles = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Appliquer les filtres supplémentaires
      if (filters != null) {
        profiles = FilterService.filterProfiles(profiles, filters, currentUser);
      }

      // Trier par compatibilité
      profiles = sortByCompatibility(profiles, currentUser);

      return profiles;
    } catch (e) {
      print('Erreur getCompatibleProfiles: $e');
      return [];
    }
  }

  /// Obtenir les matches de l'utilisateur
  static Stream<List<Map<String, dynamic>>> getUserMatches() {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('matches')
        .where('user1Id', isEqualTo: currentUserId)
        .snapshots()
        .asyncMap((matchesSnapshot) async {
          final matches = <Map<String, dynamic>>[];

          for (final matchDoc in matchesSnapshot.docs) {
            final matchData = matchDoc.data();
            final otherUserId = matchData['user2Id'] as String;

            // Récupérer le profil de l'autre utilisateur
            final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
            if (otherUserDoc.exists) {
              final otherUser = UserModel.fromMap(otherUserDoc.data() as Map<String, dynamic>);

              matches.add({
                'matchId': matchData['id'],
                'user': otherUser,
                'createdAt': matchData['createdAt'],
                'lastMessage': matchData['lastMessage'],
                'lastMessageTime': matchData['lastMessageTime'],
                'unreadCount': matchData['user1Unread'] ?? 0,
              });
            }
          }

          // Aussi chercher les matches où l'utilisateur est user2
          final matches2Snapshot = await _firestore
              .collection('matches')
              .where('user2Id', isEqualTo: currentUserId)
              .get();

          for (final matchDoc in matches2Snapshot.docs) {
            final matchData = matchDoc.data();
            final otherUserId = matchData['user1Id'] as String;

            final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
            if (otherUserDoc.exists) {
              final otherUser = UserModel.fromMap(otherUserDoc.data() as Map<String, dynamic>);

              matches.add({
                'matchId': matchData['id'],
                'user': otherUser,
                'createdAt': matchData['createdAt'],
                'lastMessage': matchData['lastMessage'],
                'lastMessageTime': matchData['lastMessageTime'],
                'unreadCount': matchData['user2Unread'] ?? 0,
              });
            }
          }

          // Trier par date de création
          matches.sort((a, b) {
            final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bTime.compareTo(aTime);
          });

          return matches;
        });
  }

  /// Calculer le score de compatibilité
  static double calculateCompatibilityScore(UserModel user1, UserModel user2) {
    double score = 0.0;

    // Age compatibility
    final ageDiff = (user1.age - user2.age).abs();
    score += (1.0 - (ageDiff / 50.0)) * 0.2;

    // Interest compatibility
    if (user1.interests.isNotEmpty && user2.interests.isNotEmpty) {
      final commonInterests = user1.interests
          .where((interest) => user2.interests.contains(interest))
          .length;
      final totalInterests = (user1.interests.length + user2.interests.length) / 2;
      score += (commonInterests / totalInterests) * 0.4;
    }

    // Location compatibility
    if (user1.latitude != null &&
        user1.longitude != null &&
        user2.latitude != null &&
        user2.longitude != null) {
      final distance = _calculateDistance(
        user1.latitude!,
        user1.longitude!,
        user2.latitude!,
        user2.longitude!,
      );
      score += (1.0 - (distance / 100.0).clamp(0.0, 1.0)) * 0.3;
    } else {
      score += 0.15;
    }

    // Looking for compatibility
    if (user1.lookingFor != null && user2.lookingFor != null) {
      if (user1.lookingFor == 'tous' ||
          user2.lookingFor == 'tous' ||
          user1.lookingFor == user2.gender ||
          user2.lookingFor == user1.gender) {
        score += 0.1;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculer la distance entre deux coordonnées
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * (sin(dLon / 2) * sin(dLon / 2));

    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * (pi / 180);
  }

  /// Trier les profils par compatibilité
  static List<UserModel> sortByCompatibility(List<UserModel> profiles, UserModel currentUser) {
    final sortedProfiles = List<UserModel>.from(profiles);
    sortedProfiles.sort((a, b) {
      final scoreA = calculateCompatibilityScore(currentUser, a);
      final scoreB = calculateCompatibilityScore(currentUser, b);
      return scoreB.compareTo(scoreA);
    });
    return sortedProfiles;
  }

  /// Obtenir les statistiques de matching
  static Future<Map<String, dynamic>> getMatchStats() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return {};

      final likesGiven = await _firestore
          .collection('likes')
          .where('fromUserId', isEqualTo: currentUserId)
          .count()
          .get();

      final likesReceived = await _firestore
          .collection('likes')
          .where('toUserId', isEqualTo: currentUserId)
          .count()
          .get();

      final matches = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: currentUserId)
          .count()
          .get();

      final matches2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: currentUserId)
          .count()
          .get();

      return {
        'likesGiven': likesGiven.count ?? 0,
        'likesReceived': likesReceived.count ?? 0,
        'totalMatches': (matches.count ?? 0) + (matches2.count ?? 0),
        'matchRate': (likesGiven.count ?? 0) > 0
            ? (((matches.count ?? 0) + (matches2.count ?? 0)) / (likesGiven.count ?? 1)) * 100
            : 0.0,
      };
    } catch (e) {
      print('Erreur getMatchStats: $e');
      return {};
    }
  }

  /// Notifier un nouveau match
  static Future<void> _notifyMatch(String user1Id, String user2Id, String matchId) async {
    try {
      // Envoyer une notification push (à implémenter avec Firebase Messaging)
      // Créer une activité dans le feed
      await _firestore.collection('activities').add({
        'type': 'match',
        'userIds': [user1Id, user2Id],
        'matchId': matchId,
        'createdAt': Timestamp.now(),
        'seen': false,
      });
    } catch (e) {
      print('Erreur notifyMatch: $e');
    }
  }
}
