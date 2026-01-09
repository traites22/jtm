import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseUserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer un utilisateur dans Firestore après inscription Firebase Auth
  static Future<bool> createUser(UserModel user) async {
    try {
      print('🔥 Création utilisateur Firestore: ${user.id}');
      print('📧 Email: ${user.email}');
      print('👤 Nom: ${user.name}');

      await _firestore.collection('users').doc(user.id).set({
        'id': user.id,
        'email': user.email,
        'name': user.name,
        'age': user.age,
        'gender': user.gender,
        'phoneNumber': user.phoneNumber,
        'bio': user.bio,
        'photos': user.photos,
        'interests': user.interests,
        'location': user.location,
        'preferences': user.preferences,
        'isVerified': user.isVerified,
        'visibility': 'public', // public, private, matches_only
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'isOnline': true,
        'matches': [],
        'likes': [],
        'blockedUsers': [],
      });

      print('✅ Utilisateur créé avec succès dans Firestore');
      return true;
    } catch (e) {
      print('❌ Erreur création utilisateur Firestore: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  // Obtenir un utilisateur par ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      print('🔍 Recherche utilisateur: $userId');
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        print('✅ Utilisateur trouvé dans Firestore');
        print('📄 Données: ${doc.data()}');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        print('❌ Utilisateur non trouvé dans Firestore');
        return null;
      }
    } catch (e) {
      print('❌ Erreur récupération utilisateur: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  // Mettre à jour le profil utilisateur
  static Future<bool> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update({
        'name': user.name,
        'age': user.age,
        'gender': user.gender,
        'bio': user.bio,
        'photos': user.photos,
        'interests': user.interests,
        'location': user.location,
        'preferences': user.preferences,
        'lastActive': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Erreur mise à jour utilisateur: $e');
      return false;
    }
  }

  // Obtenir les profils compatibles (pour le swipe)
  static Future<List<UserModel>> getCompatibleProfiles({
    required String currentUserId,
    required Map<String, dynamic> preferences,
  }) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .where('visibility', isEqualTo: 'public')
          .orderBy('lastActive', descending: true)
          .limit(50)
          .get();

      List<UserModel> profiles = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filtrer les profils déjà likés ou matchés
      DocumentSnapshot currentUserDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      Map<String, dynamic> currentUserData = currentUserDoc.data() as Map<String, dynamic>;
      List<String> likedUsers = List<String>.from(currentUserData['likes'] ?? []);
      List<String> matchedUsers = List<String>.from(currentUserData['matches'] ?? []);

      profiles = profiles.where((profile) {
        return !likedUsers.contains(profile.id) && !matchedUsers.contains(profile.id);
      }).toList();

      return profiles;
    } catch (e) {
      print('Erreur récupération profils compatibles: $e');
      return [];
    }
  }

  // Mettre à jour le statut en ligne
  static Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastActive': isOnline ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      print('Erreur mise à jour statut en ligne: $e');
    }
  }

  // Ajouter un like
  static Future<bool> addLike(String fromUserId, String toUserId) async {
    try {
      // Ajouter le like à l'utilisateur qui like
      await _firestore.collection('users').doc(fromUserId).update({
        'likes': FieldValue.arrayUnion([toUserId]),
      });

      // Vérifier si c'est un match (l'autre utilisateur nous a déjà liké)
      DocumentSnapshot otherUserDoc = await _firestore.collection('users').doc(toUserId).get();
      List<String> otherLikes = List<String>.from(otherUserDoc.get('likes') ?? []);

      if (otherLikes.contains(fromUserId)) {
        // C'est un match !
        await createMatch(fromUserId, toUserId);
        return true;
      }

      return false;
    } catch (e) {
      print('Erreur ajout like: $e');
      return false;
    }
  }

  // Créer un match
  static Future<void> createMatch(String user1Id, String user2Id) async {
    try {
      String matchId = '${user1Id}_$user2Id';

      // Créer le document de match
      await _firestore.collection('matches').doc(matchId).set({
        'id': matchId,
        'user1Id': user1Id,
        'user2Id': user2Id,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      // Ajouter le match à chaque utilisateur
      await _firestore.collection('users').doc(user1Id).update({
        'matches': FieldValue.arrayUnion([user2Id]),
      });

      await _firestore.collection('users').doc(user2Id).update({
        'matches': FieldValue.arrayUnion([user1Id]),
      });

      // Créer le chat pour le match
      await _firestore.collection('chats').doc(matchId).set({
        'id': matchId,
        'participants': [user1Id, user2Id],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessage': 'Match! 🎉',
      });
    } catch (e) {
      print('Erreur création match: $e');
    }
  }

  // Obtenir les matches d'un utilisateur
  static Future<List<UserModel>> getUserMatches(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      List<String> matchIds = List<String>.from(userDoc.get('matches') ?? []);

      if (matchIds.isEmpty) return [];

      QuerySnapshot matchesSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: matchIds)
          .get();

      return matchesSnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur récupération matches: $e');
      return [];
    }
  }

  // Bloquer un utilisateur
  static Future<bool> blockUser(String userId, String blockedUserId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      });
      return true;
    } catch (e) {
      print('Erreur blocage utilisateur: $e');
      return false;
    }
  }

  // Supprimer le compte utilisateur
  static Future<bool> deleteUser(String userId) async {
    try {
      // Supprimer les documents associés
      QuerySnapshot matchesSnapshot = await _firestore
          .collection('matches')
          .where('user1Id', isEqualTo: userId)
          .get();

      for (DocumentSnapshot doc in matchesSnapshot.docs) {
        await doc.reference.delete();
      }

      QuerySnapshot matchesSnapshot2 = await _firestore
          .collection('matches')
          .where('user2Id', isEqualTo: userId)
          .get();

      for (DocumentSnapshot doc in matchesSnapshot2.docs) {
        await doc.reference.delete();
      }

      // Supprimer l'utilisateur
      await _firestore.collection('users').doc(userId).delete();

      return true;
    } catch (e) {
      print('Erreur suppression utilisateur: $e');
      return false;
    }
  }
}
