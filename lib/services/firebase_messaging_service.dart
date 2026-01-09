import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';

class FirebaseMessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Envoyer un message texte
  static Future<bool> sendTextMessage({
    required String matchId,
    required String senderId,
    required String text,
  }) async {
    try {
      final messageId = _generateMessageId();
      final message = MessageModel.text(
        id: messageId,
        senderId: senderId,
        matchId: matchId,
        text: text,
      );

      // Créer l'ID de conversation (trié pour éviter les doublons)
      final conversationId = _getConversationId(senderId, matchId);

      // Sauvegarder dans Firestore
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      // Mettre à jour les informations de la conversation
      await _updateConversationInfo(conversationId, senderId, matchId, message);

      return true;
    } catch (e) {
      print('Erreur envoi message: $e');
      return false;
    }
  }

  // Envoyer un message image
  static Future<bool> sendImageMessage({
    required String matchId,
    required String senderId,
    required String imageUrl,
  }) async {
    try {
      final messageId = _generateMessageId();
      final message = MessageModel.image(
        id: messageId,
        senderId: senderId,
        matchId: matchId,
        imagePath: imageUrl,
      );

      final conversationId = _getConversationId(senderId, matchId);

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set(message.toMap());

      await _updateConversationInfo(conversationId, senderId, matchId, message);

      return true;
    } catch (e) {
      print('Erreur envoi image: $e');
      return false;
    }
  }

  // Obtenir les messages d'une conversation en temps réel
  static Stream<List<MessageModel>> getMessages(String userId1, String userId2) {
    final conversationId = _getConversationId(userId1, userId2);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => MessageModel.fromMap(doc.data())).toList();
        });
  }

  // Obtenir toutes les conversations d'un utilisateur
  static Stream<List<ConversationInfo>> getUserConversations(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final conversations = <ConversationInfo>[];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != userId, orElse: () => '');

            if (otherUserId.isNotEmpty) {
              // Récupérer les infos de l'autre utilisateur
              final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();
              final otherUser = otherUserDoc.exists
                  ? UserModel.fromMap(otherUserDoc.data() as Map<String, dynamic>)
                  : null;

              // Récupérer le dernier message
              final lastMessageSnapshot = await _firestore
                  .collection('conversations')
                  .doc(doc.id)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .limit(1)
                  .get();

              final lastMessage = lastMessageSnapshot.docs.isNotEmpty
                  ? MessageModel.fromMap(lastMessageSnapshot.docs.first.data())
                  : null;

              conversations.add(
                ConversationInfo(
                  conversationId: doc.id,
                  otherUser: otherUser,
                  lastMessage: lastMessage,
                  unreadCount: data['unreadCount_$userId'] ?? 0,
                ),
              );
            }
          }

          return conversations;
        });
  }

  // Marquer les messages comme lus
  static Future<void> markMessagesAsRead(String userId1, String userId2) async {
    try {
      final conversationId = _getConversationId(userId1, userId2);

      // Mettre à jour le compteur de messages non lus
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCount_$userId1': 0,
      });

      // Marquer les messages non lus comme lus
      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('senderId', isEqualTo: userId2)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Erreur marquage messages lus: $e');
    }
  }

  // Supprimer un message
  static Future<bool> deleteMessage(String conversationId, String messageId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .delete();

      return true;
    } catch (e) {
      print('Erreur suppression message: $e');
      return false;
    }
  }

  // Mettre à jour les informations de la conversation
  static Future<void> _updateConversationInfo(
    String conversationId,
    String senderId,
    String receiverId,
    MessageModel message,
  ) async {
    try {
      final conversationRef = _firestore.collection('conversations').doc(conversationId);

      // Vérifier si la conversation existe
      final conversationDoc = await conversationRef.get();

      if (conversationDoc.exists) {
        // Mettre à jour la conversation existante
        await conversationRef.update({
          'lastMessageTime': Timestamp.now(),
          'lastMessageText': message.text ?? 'Image',
          'lastSenderId': senderId,
          'unreadCount_$receiverId': FieldValue.increment(1),
        });
      } else {
        // Créer une nouvelle conversation
        await conversationRef.set({
          'participants': [senderId, receiverId],
          'createdAt': Timestamp.now(),
          'lastMessageTime': Timestamp.now(),
          'lastMessageText': message.text ?? 'Image',
          'lastSenderId': senderId,
          'unreadCount_$receiverId': 1,
          'unreadCount_$senderId': 0,
        });
      }
    } catch (e) {
      print('Erreur mise à jour conversation: $e');
    }
  }

  // Générer un ID de conversation unique
  static String _getConversationId(String userId1, String userId2) {
    // Trier les IDs pour garantir la même conversation quel que soit l'ordre
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Générer un ID de message unique
  static String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  // Générer une chaîne aléatoire
  static String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  // Obtenir le nombre de messages non lus pour un utilisateur
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          int totalUnread = 0;
          for (final doc in snapshot.docs) {
            final data = doc.data();
            totalUnread += (data['unreadCount_$userId'] as num?)?.toInt() ?? 0;
          }
          return totalUnread;
        });
  }
}

// Informations sur une conversation
class ConversationInfo {
  final String conversationId;
  final UserModel? otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;

  ConversationInfo({
    required this.conversationId,
    this.otherUser,
    this.lastMessage,
    required this.unreadCount,
  });
}
