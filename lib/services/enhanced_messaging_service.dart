import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/message_model.dart';
import 'geocoding_service.dart';

class EnhancedMessagingService {
  static const String _messagesKeyPrefix = 'enhanced_messages_';
  static const String _typingKeyPrefix = 'typing_';

  // Liste d'emojis populaires pour les réactions
  static const List<String> popularEmojis = [
    '❤️',
    '😂',
    '😍',
    '🔥',
    '👍',
    '😊',
    '😎',
    '🎉',
    '😢',
    '😡',
    '🤔',
    '👏',
    '🙏',
    '💪',
    '🌟',
    '✨',
  ];

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
      ).copyWith(status: MessageStatus.sending);

      // Sauvegarder le message
      await _saveMessage(message);

      // Simuler l'envoi (remplacer par un vrai appel API)
      await Future.delayed(const Duration(milliseconds: 500));

      // Mettre à jour le statut
      final updatedMessage = message.markAsSent();
      await _saveMessage(updatedMessage);

      // Envoyer la notification si nécessaire
      await _notifyMessage(updatedMessage);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Envoyer un message image
  static Future<bool> sendImageMessage({
    required String matchId,
    required String senderId,
    required String imagePath,
  }) async {
    try {
      final messageId = _generateMessageId();
      final message = MessageModel.image(
        id: messageId,
        senderId: senderId,
        matchId: matchId,
        imagePath: imagePath,
      ).copyWith(status: MessageStatus.sending);

      await _saveMessage(message);

      // Simuler l'envoi
      await Future.delayed(const Duration(seconds: 1));

      final updatedMessage = message.markAsSent();
      await _saveMessage(updatedMessage);

      await _notifyMessage(updatedMessage);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Envoyer un message de localisation
  static Future<bool> sendLocationMessage({
    required String matchId,
    required String senderId,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    try {
      final messageId = _generateMessageId();

      // Utiliser les coordonnées fournies ou des valeurs par défaut
      final lat = latitude ?? 48.8566; // Paris par défaut
      final lon = longitude ?? 2.3522;
      final name = locationName ?? 'Position actuelle';

      final message = MessageModel.location(
        id: messageId,
        senderId: senderId,
        matchId: matchId,
        latitude: lat,
        longitude: lon,
        locationName: name,
      ).copyWith(status: MessageStatus.sending);

      await _saveMessage(message);

      // Simuler l'envoi
      await Future.delayed(const Duration(milliseconds: 500));

      final updatedMessage = message.markAsSent();
      await _saveMessage(updatedMessage);

      await _notifyMessage(updatedMessage);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Ajouter une réaction à un message
  static Future<bool> addReaction({
    required String matchId,
    required String messageId,
    required String emoji,
    required String userId,
  }) async {
    try {
      final message = await getMessage(matchId, messageId);
      if (message == null) return false;

      // Vérifier si l'utilisateur a déjà réagi
      final reactionKey = '${messageId}_reactions_${userId}';
      final reactionsBox = Hive.box('reactionsBox');
      final existingReaction = reactionsBox.get(reactionKey);

      if (existingReaction != null) {
        // Retirer l'ancienne réaction
        final updatedMessage = message.removeReaction(existingReaction);
        await _saveMessage(updatedMessage);
      }

      // Ajouter la nouvelle réaction
      final updatedMessage = message.addReaction(emoji);
      await _saveMessage(updatedMessage);

      // Sauvegarder la réaction de l'utilisateur
      await reactionsBox.put(reactionKey, emoji);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Retirer une réaction
  static Future<bool> removeReaction({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final message = await getMessage(matchId, messageId);
      if (message == null) return false;

      final reactionKey = '${messageId}_reactions_${userId}';
      final reactionsBox = Hive.box('reactionsBox');
      final existingReaction = reactionsBox.get(reactionKey);

      if (existingReaction != null) {
        final updatedMessage = message.removeReaction(existingReaction);
        await _saveMessage(updatedMessage);
        await reactionsBox.delete(reactionKey);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Marquer des messages comme lus
  static Future<void> markMessagesAsRead({
    required String matchId,
    required String userId,
    List<String>? messageIds,
  }) async {
    try {
      final messages = await getMessages(matchId);
      final messagesToMark = messageIds != null
          ? messages.where((m) => messageIds.contains(m.id)).toList()
          : messages.where((m) => !m.isFromSender(userId)).toList();

      for (final message in messagesToMark) {
        if (message.status != MessageStatus.read) {
          final updatedMessage = message.markAsRead();
          await _saveMessage(updatedMessage);
        }
      }
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  // Supprimer un message
  static Future<bool> deleteMessage({
    required String matchId,
    required String messageId,
    required String userId,
  }) async {
    try {
      final message = await getMessage(matchId, messageId);
      if (message == null || !message.isFromSender(userId)) return false;

      final updatedMessage = message.delete();
      await _saveMessage(updatedMessage);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Éditer un message
  static Future<bool> editMessage({
    required String matchId,
    required String messageId,
    required String newText,
    required String userId,
  }) async {
    try {
      final message = await getMessage(matchId, messageId);
      if (message == null || !message.isFromSender(userId) || message.type != MessageType.text)
        return false;

      final updatedMessage = message.edit(newText);
      await _saveMessage(updatedMessage);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir tous les messages d'un match
  static Future<List<MessageModel>> getMessages(String matchId) async {
    try {
      final messagesBox = Hive.box('messagesBox');
      final messagesData = messagesBox.get('$_messagesKeyPrefix$matchId') ?? [];

      return messagesData.map((data) => MessageModel.fromMap(data)).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } catch (e) {
      return [];
    }
  }

  // Obtenir un message spécifique
  static Future<MessageModel?> getMessage(String matchId, String messageId) async {
    try {
      final messages = await getMessages(matchId);
      return messages.where((m) => m.id == messageId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  // Indiquer que l'utilisateur est en train d'écrire
  static Future<void> setTyping({
    required String matchId,
    required String userId,
    bool isTyping = true,
  }) async {
    try {
      final typingBox = Hive.box('typingBox');
      final key = '$_typingKeyPrefix$matchId';

      final typingUsers = Map<String, DateTime>.from(typingBox.get(key) ?? {});

      if (isTyping) {
        typingUsers[userId] = DateTime.now();
      } else {
        typingUsers.remove(userId);
      }

      await typingBox.put(key, typingUsers);

      // Nettoyer les anciens statuts (plus de 10 secondes)
      await _cleanupOldTypingStatus(key);
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  // Obtenir les utilisateurs en train d'écrire
  static Future<List<String>> getTypingUsers(String matchId) async {
    try {
      final typingBox = Hive.box('typingBox');
      final key = '$_typingKeyPrefix$matchId';

      await _cleanupOldTypingStatus(key);

      final typingUsers = Map<String, DateTime>.from(typingBox.get(key) ?? {});
      return typingUsers.keys.toList();
    } catch (e) {
      return [];
    }
  }

  // Méthodes privées
  static String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  static Future<void> _saveMessage(MessageModel message) async {
    final messagesBox = Hive.box('messagesBox');
    final key = '$_messagesKeyPrefix${message.matchId}';

    final messagesData = List<Map<String, dynamic>>.from(messagesBox.get(key) ?? []);

    // Remplacer le message s'il existe déjà, sinon l'ajouter
    final existingIndex = messagesData.indexWhere((m) => m['id'] == message.id);
    if (existingIndex >= 0) {
      messagesData[existingIndex] = message.toMap();
    } else {
      messagesData.add(message.toMap());
    }

    await messagesBox.put(key, messagesData);
  }

  static Future<void> _notifyMessage(MessageModel message) async {
    // Envoyer une notification push pour les nouveaux messages
    if (message.status == MessageStatus.sent) {
      // Envoyer la notification locale (remplacer par Firebase si nécessaire)
      // await NotificationService.showNotification();
    } catch (e) {
      // Gérer silencieusement les erreurs de notification
    }
  }

  static Future<Position?> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return null;
    }
  }

  static Future<String> _getLocationName(double lat, double lon) async {
    try {
      // Utiliser le vrai service de géocodage
      return await GeocodingService.getLocationName(lat, lon);
    } catch (e) {
      print('Erreur géocodage: $e');
      return 'Localisation inconnue';
    }
  }

  static Future<void> _cleanupOldTypingStatus(String key) async {
    try {
      final typingBox = Hive.box('typingBox');
      final typingUsers = Map<String, DateTime>.from(typingBox.get(key) ?? {});
      final now = DateTime.now();

      typingUsers.removeWhere((userId, timestamp) => now.difference(timestamp).inSeconds > 10);

      await typingBox.put(key, typingUsers);
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }
}
