import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/invitation_model.dart';
import '../services/notification_service.dart';

class InvitationService {
  static const String _invitationsBox = 'invitationsBox';
  static const String _conversationsBox = 'conversationsBox';

  // Envoyer une invitation
  static Future<bool> sendInvitation({
    required String senderId,
    required String receiverId,
    required InvitationType type,
    String? message,
    Map<String, dynamic>? metadata,
    Duration? expiryDuration,
  }) async {
    try {
      // Vérifier si une invitation similaire existe déjà
      final existingInvitation = await _findPendingInvitation(
        senderId: senderId,
        receiverId: receiverId,
        type: type,
      );

      if (existingInvitation != null) {
        return false; // Invitation déjà existante
      }

      // Créer la nouvelle invitation
      final invitation = InvitationModel.create(
        senderId: senderId,
        receiverId: receiverId,
        type: type,
        message: message,
        metadata: metadata,
        expiryDuration: expiryDuration ?? const Duration(hours: 24),
      );

      // Sauvegarder l'invitation
      await _saveInvitation(invitation);

      // Envoyer une notification au destinataire
      await _sendInvitationNotification(invitation);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Répondre à une invitation
  static Future<bool> respondToInvitation({
    required String invitationId,
    required bool accept,
    String? responseMessage,
  }) async {
    try {
      final invitation = await getInvitation(invitationId);
      if (invitation == null || !invitation.canRespond) {
        return false;
      }

      // Mettre à jour le statut
      final updatedInvitation = accept ? invitation.accept() : invitation.reject();
      await _saveInvitation(updatedInvitation);

      // Si acceptée, créer une conversation
      if (accept && invitation.type == InvitationType.chat) {
        await _createConversationFromInvitation(updatedInvitation);
      }

      // Notifier l'expéditeur
      await _sendResponseNotification(updatedInvitation, accept, responseMessage);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Annuler une invitation
  static Future<bool> cancelInvitation({
    required String invitationId,
    required String userId, // Doit être l'expéditeur
  }) async {
    try {
      final invitation = await getInvitation(invitationId);
      if (invitation == null || invitation.senderId != userId) {
        return false;
      }

      final cancelledInvitation = invitation.cancel();
      await _saveInvitation(cancelledInvitation);

      // Notifier le destinataire
      await _sendCancellationNotification(cancelledInvitation);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir une invitation par ID
  static Future<InvitationModel?> getInvitation(String invitationId) async {
    try {
      final box = Hive.box(_invitationsBox);
      final data = box.get(invitationId);
      return data != null ? InvitationModel.fromMap(data) : null;
    } catch (e) {
      return null;
    }
  }

  // Obtenir les invitations envoyées par un utilisateur
  static Future<List<InvitationModel>> getSentInvitations(String userId) async {
    try {
      final box = Hive.box(_invitationsBox);
      final invitations = <InvitationModel>[];

      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final invitation = InvitationModel.fromMap(data);
          if (invitation.senderId == userId) {
            invitations.add(invitation);
          }
        }
      }

      // Trier par date de création (plus récent en premier)
      invitations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return invitations;
    } catch (e) {
      return [];
    }
  }

  // Obtenir les invitations reçues par un utilisateur
  static Future<List<InvitationModel>> getReceivedInvitations(String userId) async {
    try {
      final box = Hive.box(_invitationsBox);
      final invitations = <InvitationModel>[];

      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final invitation = InvitationModel.fromMap(data);
          if (invitation.receiverId == userId) {
            invitations.add(invitation);
          }
        }
      }

      // Trier par date de création (plus récent en premier)
      invitations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return invitations;
    } catch (e) {
      return [];
    }
  }

  // Obtenir les invitations en attente
  static Future<List<InvitationModel>> getPendingInvitations(String userId) async {
    try {
      final invitations = await getReceivedInvitations(userId);
      return invitations.where((invitation) => invitation.isValid).toList();
    } catch (e) {
      return [];
    }
  }

  // Nettoyer les invitations expirées
  static Future<void> cleanupExpiredInvitations() async {
    try {
      final box = Hive.box(_invitationsBox);
      final expiredIds = <String>[];

      for (final key in box.keys) {
        final data = box.get(key);
        if (data != null) {
          final invitation = InvitationModel.fromMap(data);
          if (invitation.isExpired && invitation.status == InvitationStatus.pending) {
            expiredIds.add(key);
          }
        }
      }

      // Marquer comme expirées
      for (final id in expiredIds) {
        final invitation = await getInvitation(id);
        if (invitation != null) {
          final expiredInvitation = invitation.copyWith(status: InvitationStatus.expired);
          await _saveInvitation(expiredInvitation);
        }
      }
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  // Obtenir le nombre d'invitations en attente
  static Future<int> getPendingInvitationsCount(String userId) async {
    try {
      final pendingInvitations = await getPendingInvitations(userId);
      return pendingInvitations.length;
    } catch (e) {
      return 0;
    }
  }

  // Vérifier si une conversation existe entre deux utilisateurs
  static Future<bool> conversationExists(String userId1, String userId2) async {
    try {
      final box = Hive.box(_conversationsBox);
      final conversationKey = _generateConversationKey(userId1, userId2);
      return box.containsKey(conversationKey);
    } catch (e) {
      return false;
    }
  }

  // Obtenir toutes les conversations d'un utilisateur
  static Future<List<Map<String, dynamic>>> getUserConversations(String userId) async {
    try {
      final box = Hive.box(_conversationsBox);
      final conversations = <Map<String, dynamic>>[];

      for (final key in box.keys) {
        if (key.toString().contains(userId)) {
          final data = box.get(key);
          if (data != null) {
            conversations.add(Map<String, dynamic>.from(data));
          }
        }
      }

      return conversations;
    } catch (e) {
      return [];
    }
  }

  // Méthodes privées
  static Future<void> _saveInvitation(InvitationModel invitation) async {
    try {
      final box = Hive.box(_invitationsBox);
      await box.put(invitation.id, invitation.toMap());
    } catch (e) {
      // Gérer l'erreur
    }
  }

  static Future<InvitationModel?> _findPendingInvitation({
    required String senderId,
    required String receiverId,
    required InvitationType type,
  }) async {
    try {
      final invitations = await getReceivedInvitations(receiverId);
      for (final invitation in invitations) {
        if (invitation.senderId == senderId &&
            invitation.type == type &&
            invitation.status == InvitationStatus.pending &&
            !invitation.isExpired) {
          return invitation;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> _sendInvitationNotification(InvitationModel invitation) async {
    try {
      // Envoyer une notification au destinataire
      await NotificationService.init();

      // Dans une vraie app, envoyer une notification push
      // Pour la démo, nous simulons
      print('Invitation envoyée à ${invitation.receiverId}: ${invitation.type.frenchName}');
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  static Future<void> _sendResponseNotification(
    InvitationModel invitation,
    bool accepted,
    String? responseMessage,
  ) async {
    try {
      await NotificationService.init();

      final message = accepted ? 'Invitation acceptée' : 'Invitation refusée';

      print('Notification envoyée à ${invitation.senderId}: $message');
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  static Future<void> _sendCancellationNotification(InvitationModel invitation) async {
    try {
      await NotificationService.init();

      print('Notification d\'annulation envoyée à ${invitation.receiverId}');
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }

  static Future<void> _createConversationFromInvitation(InvitationModel invitation) async {
    try {
      final box = Hive.box(_conversationsBox);
      final conversationKey = _generateConversationKey(invitation.senderId, invitation.receiverId);

      final conversation = {
        'id': conversationKey,
        'participants': [invitation.senderId, invitation.receiverId],
        'createdAt': DateTime.now().toIso8601String(),
        'lastMessageAt': DateTime.now().toIso8601String(),
        'invitationId': invitation.id,
        'type': 'chat',
      };

      await box.put(conversationKey, conversation);
    } catch (e) {
      // Gérer l'erreur
    }
  }

  static String _generateConversationKey(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Générer un message d'invitation par défaut
  static String generateDefaultMessage(InvitationType type) {
    switch (type) {
      case InvitationType.chat:
        return 'Salut ! J\'aimerais discuter avec toi ';
      case InvitationType.date:
        return 'Je te propose de nous voir pour un rendez-vous ';
      case InvitationType.event:
        return 'Je t\'invite à un événement spécial ';
      case InvitationType.friendship:
        return 'J\'aimerais devenir ton/ta ami(e) ';
    }
  }

  // Vérifier si un utilisateur peut envoyer une invitation
  static Future<bool> canSendInvitation(String senderId, String receiverId) async {
    try {
      // Vérifier si une conversation existe déjà
      final hasConversation = await conversationExists(senderId, receiverId);
      if (hasConversation) return false;

      // Vérifier si une invitation en attente existe déjà
      final pendingInvitations = await getPendingInvitations(receiverId);
      final hasPendingInvitation = pendingInvitations.any(
        (invitation) => invitation.senderId == senderId,
      );

      return !hasPendingInvitation;
    } catch (e) {
      return false;
    }
  }
}
