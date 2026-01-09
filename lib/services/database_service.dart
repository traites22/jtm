import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // User operations
  Future<DocumentReference> createUserDocument(Map<String, dynamic> userData) async {
    try {
      DocumentReference docRef = _firestore.collection('users').doc(userData['uid']);
      await docRef.set(userData);
      debugPrint('✅ User document created');
      return docRef;
    } catch (e) {
      debugPrint('❌ Failed to create user document: $e');
      rethrow;
    }
  }

  Future<DocumentSnapshot> getUserDocument(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      debugPrint('❌ Failed to get user document: $e');
      rethrow;
    }
  }

  Future<void> updateUserDocument(String uid, Map<String, dynamic> data) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
      debugPrint('✅ User document updated');
    } catch (e) {
      debugPrint('❌ Failed to update user document: $e');
      rethrow;
    }
  }

  // Matching operations
  Stream<QuerySnapshot> getPotentialMatches(
    String currentUserId,
    Map<String, dynamic> preferences,
  ) {
    try {
      return _firestore
          .collection('users')
          .where('uid', isNotEqualTo: currentUserId)
          .where('isProfileComplete', isEqualTo: true)
          .snapshots();
    } catch (e) {
      debugPrint('❌ Failed to get potential matches: $e');
      rethrow;
    }
  }

  // Match operations
  Future<void> createMatch(String userId1, String userId2) async {
    try {
      String matchId = _generateMatchId(userId1, userId2);

      await _firestore.collection('matches').doc(matchId).set({
        'users': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'lastMessage': null,
        'lastMessageTime': null,
      });

      // Update both users' match lists
      await _firestore.collection('users').doc(userId1).update({
        'matches': FieldValue.arrayUnion([userId2]),
      });

      await _firestore.collection('users').doc(userId2).update({
        'matches': FieldValue.arrayUnion([userId1]),
      });

      debugPrint('✅ Match created successfully');
    } catch (e) {
      debugPrint('❌ Failed to create match: $e');
      rethrow;
    }
  }

  // Message operations
  Future<void> sendMessage(String matchId, Map<String, dynamic> messageData) async {
    try {
      await _firestore.collection('matches').doc(matchId).collection('messages').add({
        ...messageData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update match with last message info
      await _firestore.collection('matches').doc(matchId).update({
        'lastMessage': messageData['text'],
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Message sent successfully');
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getMessages(String matchId) {
    try {
      return _firestore
          .collection('matches')
          .doc(matchId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } catch (e) {
      debugPrint('❌ Failed to get messages: $e');
      rethrow;
    }
  }

  // Profile operations
  Future<void> uploadProfileImage(String userId, String imageUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Profile image uploaded');
    } catch (e) {
      debugPrint('❌ Failed to upload profile image: $e');
      rethrow;
    }
  }

  // Search operations
  Future<List<DocumentSnapshot>> searchUsers(String query, {int limit = 20}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('isProfileComplete', isEqualTo: true)
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(limit)
          .get();

      return snapshot.docs;
    } catch (e) {
      debugPrint('❌ Failed to search users: $e');
      return [];
    }
  }

  // Helper methods
  String _generateMatchId(String userId1, String userId2) {
    // Sort user IDs to create consistent match ID
    List<String> ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Interest-based matching
  Future<List<DocumentSnapshot>> getUsersByInterests(List<String> interests) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('isProfileComplete', isEqualTo: true)
          .where('interests', arrayContainsAny: interests)
          .limit(50)
          .get();

      return snapshot.docs;
    } catch (e) {
      debugPrint('❌ Failed to get users by interests: $e');
      return [];
    }
  }

  // Location-based matching
  Future<List<DocumentSnapshot>> getUsersNearLocation(GeoPoint location, double maxDistanceKm) {
    // This would require geohash implementation for efficient location queries
    // For now, return all users (you can implement geohash later)
    return _firestore
        .collection('users')
        .where('isProfileComplete', isEqualTo: true)
        .limit(50)
        .get()
        .then((snapshot) => snapshot.docs);
  }
}
