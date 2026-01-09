import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_user_service.dart';

class FirebaseChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Envoyer un message dans un chat
  static Future<bool> sendMessage({
    required String matchId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    try {
      String messageId = DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore.collection('chats').doc(matchId).collection('messages').doc(messageId).set({
        'id': messageId,
        'senderId': senderId,
        'text': text,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'status': 'sent',
      });

      // Mettre à jour le dernier message du chat
      await _firestore.collection('chats').doc(matchId).update({
        'lastMessage': text.isNotEmpty ? text : '📷 Photo',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
      });

      return true;
    } catch (e) {
      print('Erreur envoi message: $e');
      return false;
    }
  }

  // Obtenir les messages d'un chat (stream pour temps réel)
  static Stream<QuerySnapshot> getChatMessages(String matchId) {
    return _firestore
        .collection('chats')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Obtenir les chats de l'utilisateur (ses matches)
  static Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Marquer les messages comme lus
  static Future<void> markMessagesAsRead(String matchId, String userId) async {
    try {
      QuerySnapshot unreadMessages = await _firestore
          .collection('chats')
          .doc(matchId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      for (DocumentSnapshot doc in unreadMessages.docs) {
        await doc.reference.update({'read': true});
      }
    } catch (e) {
      print('Erreur marquage messages lus: $e');
    }
  }

  // Obtenir le nombre de messages non lus
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((chatSnapshot) async {
          int totalUnread = 0;

          for (DocumentSnapshot chatDoc in chatSnapshot.docs) {
            QuerySnapshot unreadMessages = await _firestore
                .collection('chats')
                .doc(chatDoc.id)
                .collection('messages')
                .where('senderId', isNotEqualTo: userId)
                .where('read', isEqualTo: false)
                .get();

            totalUnread += unreadMessages.docs.length;
          }

          return totalUnread;
        });
  }

  // Envoyer une demande de connexion
  static Future<bool> sendConnectionRequest({
    required String fromUserId,
    required String toUserId,
    required String message,
  }) async {
    try {
      String requestId = DateTime.now().millisecondsSinceEpoch.toString();

      await _firestore.collection('connectionRequests').doc(requestId).set({
        'id': requestId,
        'fromUserId': fromUserId,
        'toUserId': toUserId,
        'message': message,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Erreur envoi demande de connexion: $e');
      return false;
    }
  }

  // Obtenir les demandes de connexion reçues
  static Stream<QuerySnapshot> getConnectionRequests(String userId) {
    return _firestore
        .collection('connectionRequests')
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Répondre à une demande de connexion
  static Future<bool> respondToConnectionRequest({
    required String requestId,
    required bool accept,
  }) async {
    try {
      DocumentSnapshot requestDoc = await _firestore
          .collection('connectionRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) return false;

      Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;
      String fromUserId = requestData['fromUserId'];
      String toUserId = requestData['toUserId'];

      await _firestore.collection('connectionRequests').doc(requestId).update({
        'status': accept ? 'accepted' : 'rejected',
      });

      if (accept) {
        await FirebaseUserService.createMatch(fromUserId, toUserId);

        await sendMessage(
          matchId: '${fromUserId}_$toUserId',
          senderId: 'system',
          text: 'Félicitations ! Vous êtes maintenant connectés. 🎉',
        );
      }

      return true;
    } catch (e) {
      print('Erreur réponse demande de connexion: $e');
      return false;
    }
  }
}
