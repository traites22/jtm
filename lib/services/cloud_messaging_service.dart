import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class CloudMessagingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Envoyer un message texte
  static Future<bool> sendTextMessage({required String matchId, required String text}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final messageRef = _firestore
          .collection('conversations')
          .doc(matchId)
          .collection('messages')
          .doc();

      final messageData = {
        'id': messageRef.id,
        'senderId': currentUserId,
        'text': text,
        'type': 'text',
        'timestamp': Timestamp.now(),
        'status': 'sending',
        'read': false,
        'reactions': <String, int>{},
        'isDeleted': false,
      };

      await messageRef.set(messageData);

      // Mettre à jour la conversation
      await _updateConversation(matchId, text, currentUserId);

      // Marquer comme envoyé après un délai
      Timer(const Duration(milliseconds: 500), () async {
        await messageRef.update({'status': 'sent'});
      });

      return true;
    } catch (e) {
      print('Erreur envoi message: $e');
      return false;
    }
  }

  /// Envoyer un message image
  static Future<bool> sendImageMessage({required String matchId, required String imageUrl}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final messageRef = _firestore
          .collection('conversations')
          .doc(matchId)
          .collection('messages')
          .doc();

      final messageData = {
        'id': messageRef.id,
        'senderId': currentUserId,
        'imageUrl': imageUrl,
        'type': 'image',
        'timestamp': Timestamp.now(),
        'status': 'sending',
        'read': false,
        'reactions': <String, int>{},
        'isDeleted': false,
      };

      await messageRef.set(messageData);

      // Mettre à jour la conversation
      await _updateConversation(matchId, '📷 Photo', currentUserId);

      Timer(const Duration(seconds: 1), () async {
        await messageRef.update({'status': 'sent'});
      });

      return true;
    } catch (e) {
      print('Erreur envoi image: $e');
      return false;
    }
  }

  /// Envoyer un message de localisation
  static Future<bool> sendLocationMessage({
    required String matchId,
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final messageRef = _firestore
          .collection('conversations')
          .doc(matchId)
          .collection('messages')
          .doc();

      final messageData = {
        'id': messageRef.id,
        'senderId': currentUserId,
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'type': 'location',
        'timestamp': Timestamp.now(),
        'status': 'sending',
        'read': false,
        'reactions': <String, int>{},
        'isDeleted': false,
      };

      await messageRef.set(messageData);

      // Mettre à jour la conversation
      await _updateConversation(matchId, '📍 $locationName', currentUserId);

      Timer(const Duration(milliseconds: 500), () async {
        await messageRef.update({'status': 'sent'});
      });

      return true;
    } catch (e) {
      print('Erreur envoi localisation: $e');
      return false;
    }
  }

  /// Obtenir les messages d'une conversation
  static Stream<List<MessageModel>> getMessages(String matchId) {
    return _firestore
        .collection('conversations')
        .doc(matchId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            // Convertir les données en MessageModel
            MessageType type;
            switch (data['type'] as String) {
              case 'image':
                type = MessageType.image;
                break;
              case 'location':
                type = MessageType.location;
                break;
              case 'system':
                type = MessageType.system;
                break;
              case 'audio':
                type = MessageType.audio;
                break;
              default:
                type = MessageType.text;
            }

            MessageStatus status;
            switch (data['status'] as String) {
              case 'sending':
                status = MessageStatus.sending;
                break;
              case 'delivered':
                status = MessageStatus.delivered;
                break;
              case 'read':
                status = MessageStatus.read;
                break;
              case 'failed':
                status = MessageStatus.failed;
                break;
              default:
                status = MessageStatus.sent;
            }

            return MessageModel(
              id: data['id'] as String,
              senderId: data['senderId'] as String,
              matchId: matchId,
              type: type,
              text: data['text'] as String?,
              imagePath: data['imageUrl'] as String?,
              latitude: (data['latitude'] as num?)?.toDouble(),
              longitude: (data['longitude'] as num?)?.toDouble(),
              locationName: data['locationName'] as String?,
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              status: status,
              reactions: Map<String, int>.from(data['reactions'] ?? {}),
              isDeleted: data['isDeleted'] as bool? ?? false,
              editedAt: data['editedAt'] != null ? (data['editedAt'] as Timestamp).toDate() : null,
              readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
            );
          }).toList();
        });
  }

  /// Marquer des messages comme lus
  static Future<void> markMessagesAsRead({
    required String matchId,
    List<String>? messageIds,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      WriteBatch batch = _firestore.batch();

      if (messageIds != null) {
        // Marquer des messages spécifiques
        for (final messageId in messageIds) {
          final messageRef = _firestore
              .collection('conversations')
              .doc(matchId)
              .collection('messages')
              .doc(messageId);

          batch.update(messageRef, {'read': true, 'readAt': Timestamp.now(), 'status': 'read'});
        }
      } else {
        // Marquer tous les messages non lus de l'autre utilisateur
        final unreadMessages = await _firestore
            .collection('conversations')
            .doc(matchId)
            .collection('messages')
            .where('senderId', isNotEqualTo: currentUserId)
            .where('read', isEqualTo: false)
            .get();

        for (final doc in unreadMessages.docs) {
          batch.update(doc.reference, {'read': true, 'readAt': Timestamp.now(), 'status': 'read'});
        }
      }

      await batch.commit();

      // Mettre à jour le compteur de messages non lus dans le match
      await _updateUnreadCount(matchId, currentUserId, 0);
    } catch (e) {
      print('Erreur marquage messages lus: $e');
    }
  }

  /// Ajouter une réaction à un message
  static Future<bool> addReaction({
    required String matchId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final messageRef = _firestore
          .collection('conversations')
          .doc(matchId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return false;

      final data = messageDoc.data()!;
      final reactions = Map<String, int>.from(data['reactions'] ?? {});

      // Vérifier si l'utilisateur a déjà réagi
      final reactionKey = '${messageId}_reaction_$currentUserId';
      final reactionDoc = await _firestore.collection('reactions').doc(reactionKey).get();

      if (reactionDoc.exists) {
        // Retirer l'ancienne réaction
        final oldEmoji = reactionDoc.data()!['emoji'] as String;
        if (reactions.containsKey(oldEmoji)) {
          reactions[oldEmoji] = reactions[oldEmoji]! - 1;
          if (reactions[oldEmoji]! <= 0) {
            reactions.remove(oldEmoji);
          }
        }
      }

      // Ajouter la nouvelle réaction
      reactions[emoji] = (reactions[emoji] ?? 0) + 1;

      await messageRef.update({'reactions': reactions});
      await _firestore.collection('reactions').doc(reactionKey).set({
        'userId': currentUserId,
        'messageId': messageId,
        'emoji': emoji,
        'createdAt': Timestamp.now(),
      });

      return true;
    } catch (e) {
      print('Erreur ajout réaction: $e');
      return false;
    }
  }

  /// Supprimer un message
  static Future<bool> deleteMessage({required String matchId, required String messageId}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final messageRef = _firestore
          .collection('conversations')
          .doc(matchId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return false;

      final senderId = messageDoc.data()!['senderId'] as String;
      if (senderId != currentUserId) return false;

      await messageRef.update({'isDeleted': true, 'text': 'Message supprimé', 'imageUrl': null});

      return true;
    } catch (e) {
      print('Erreur suppression message: $e');
      return false;
    }
  }

  /// Éditer un message
  static Future<bool> editMessage({
    required String matchId,
    required String messageId,
    required String newText,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return false;

      final messageRef = _firestore
          .collection('conversations')
          .doc(matchId)
          .collection('messages')
          .doc(messageId);

      final messageDoc = await messageRef.get();
      if (!messageDoc.exists) return false;

      final data = messageDoc.data()!;
      final senderId = data['senderId'] as String;
      final type = data['type'] as String;

      if (senderId != currentUserId || type != 'text') return false;

      await messageRef.update({'text': newText, 'editedAt': Timestamp.now()});

      return true;
    } catch (e) {
      print('Erreur édition message: $e');
      return false;
    }
  }

  /// Indiquer que l'utilisateur est en train d'écrire
  static Future<void> setTyping({required String matchId, bool isTyping = true}) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final typingRef = _firestore
          .collection('conversations')
          .doc(matchId)
          .collection('typing')
          .doc(currentUserId);

      if (isTyping) {
        await typingRef.set({'userId': currentUserId, 'timestamp': Timestamp.now()});
      } else {
        await typingRef.delete();
      }
    } catch (e) {
      print('Erreur typing: $e');
    }
  }

  /// Obtenir les utilisateurs en train d'écrire
  static Stream<List<String>> getTypingUsers(String matchId) {
    return _firestore.collection('conversations').doc(matchId).collection('typing').snapshots().map(
      (snapshot) {
        final now = Timestamp.now();
        final typingUsers = <String>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final timestamp = data['timestamp'] as Timestamp;

          // Supprimer les anciens statuts (plus de 10 secondes)
          if (now.toDate().difference(timestamp.toDate()).inSeconds <= 10) {
            typingUsers.add(data['userId'] as String);
          } else {
            doc.reference.delete();
          }
        }

        return typingUsers;
      },
    );
  }

  /// Mettre à jour la conversation
  static Future<void> _updateConversation(
    String matchId,
    String lastMessage,
    String senderId,
  ) async {
    try {
      await _firestore.collection('conversations').doc(matchId).update({
        'lastMessage': lastMessage,
        'lastMessageTime': Timestamp.now(),
        'lastMessageSender': senderId,
      });

      // Mettre à jour le compteur de messages non lus pour l'autre utilisateur
      await _incrementUnreadCount(matchId, senderId);
    } catch (e) {
      print('Erreur mise à jour conversation: $e');
    }
  }

  /// Incrémenter le compteur de messages non lus
  static Future<void> _incrementUnreadCount(String matchId, String senderId) async {
    try {
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();
      if (!matchDoc.exists) return;

      final data = matchDoc.data()!;
      final user1Id = data['user1Id'] as String;
      final user2Id = data['user2Id'] as String;

      final targetUserId = senderId == user1Id ? user2Id : user1Id;
      final field = targetUserId == user1Id ? 'user1Unread' : 'user2Unread';

      await _firestore.collection('matches').doc(matchId).update({field: FieldValue.increment(1)});
    } catch (e) {
      print('Erreur incrément unread: $e');
    }
  }

  /// Mettre à jour le compteur de messages non lus
  static Future<void> _updateUnreadCount(String matchId, String userId, int count) async {
    try {
      final matchDoc = await _firestore.collection('matches').doc(matchId).get();
      if (!matchDoc.exists) return;

      final data = matchDoc.data()!;
      final user1Id = data['user1Id'] as String;
      final user2Id = data['user2Id'] as String;

      final field = userId == user1Id ? 'user1Unread' : 'user2Unread';

      await _firestore.collection('matches').doc(matchId).update({field: count});
    } catch (e) {
      print('Erreur mise à jour unread: $e');
    }
  }
}
