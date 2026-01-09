import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialiser le service de notifications push
  static Future<void> initialize() async {
    try {
      // Demander la permission pour les notifications
      await _requestPermissions();

      // Obtenir le token FCM
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
        print('FCM Token: $token');
      }

      // Écouter les changements de token
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });

      // Gérer les messages reçus lorsque l'app est en premier plan
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Gérer les messages reçus lorsque l'app est en arrière-plan mais ouverte
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Gérer les messages reçus lorsque l'app est complètement fermée
      FirebaseMessaging.instance.getInitialMessage().then(_handleInitialMessage);
    } catch (e) {
      print('Erreur initialisation notifications push: $e');
    }
  }

  /// Demander les permissions de notification
  static Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Permission accordée pour les notifications');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('Permission provisoire accordée');
    } else {
      print('Permission refusée pour les notifications');
    }
  }

  /// Sauvegarder le token FCM dans la base de données
  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore.collection('users').doc(currentUserId).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // Aussi sauvegarder dans une collection séparée pour les notifications ciblées
      await _firestore.collection('fcmTokens').doc(currentUserId).set({
        'token': token,
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': 'unknown', // Peut être déterminé avec device_info_plus
      });
    } catch (e) {
      print('Erreur sauvegarde token FCM: $e');
    }
  }

  /// Gérer les messages reçus lorsque l'app est en premier plan
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Message reçu en premier plan: ${message.messageId}');

    // Afficher une notification locale
    await NotificationService.showLocalNotification(
      title: message.notification?.title ?? 'Nouvelle notification',
      body: message.notification?.body ?? 'Vous avez reçu une nouvelle notification',
    );

    // Traiter le type de message
    await _processMessageData(message.data);
  }

  /// Gérer les messages lorsque l'app est ouverte depuis une notification
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('Message ouvert depuis notification: ${message.messageId}');

    // Traiter les données du message pour la navigation
    await _processMessageData(message.data);
  }

  /// Gérer le message initial lorsque l'app est lancée depuis une notification
  static Future<void> _handleInitialMessage(RemoteMessage? message) async {
    if (message != null) {
      print('Message initial: ${message.messageId}');
      await _processMessageData(message.data);
    }
  }

  /// Traiter les données du message pour les actions appropriées
  static Future<void> _processMessageData(Map<String, dynamic> data) async {
    try {
      final type = data['type'] as String?;
      final matchId = data['matchId'] as String?;
      final senderId = data['senderId'] as String?;

      switch (type) {
        case 'new_message':
          if (matchId != null) {
            // Naviguer vers la conversation
            await _navigateToChat(matchId);
          }
          break;

        case 'new_match':
          if (matchId != null) {
            // Naviguer vers les matches ou la conversation
            await _navigateToMatches();
          }
          break;

        case 'like':
          // Naviguer vers les profils ou notifications
          await _navigateToDiscover();
          break;

        case 'profile_view':
          if (senderId != null) {
            // Naviguer vers le profil de l'utilisateur
            await _navigateToProfile(senderId);
          }
          break;

        default:
          print('Type de message non géré: $type');
      }
    } catch (e) {
      print('Erreur traitement données message: $e');
    }
  }

  /// Envoyer une notification push à un utilisateur spécifique
  static Future<bool> sendPushNotification({
    required String targetUserId,
    required String title,
    required String body,
    String? type,
    String? matchId,
    String? senderId,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Obtenir le token FCM de l'utilisateur cible
      final tokenDoc = await _firestore.collection('fcmTokens').doc(targetUserId).get();

      if (!tokenDoc.exists) {
        print('Aucun token FCM trouvé pour l utilisateur: $targetUserId');
        return false;
      }

      final token = tokenDoc.data()!['token'] as String;

      // Construire les données de la notification
      final notificationData = <String, dynamic>{'title': title, 'body': body, 'sound': 'default'};

      final dataPayload = <String, dynamic>{
        if (type != null) 'type': type,
        if (matchId != null) 'matchId': matchId,
        if (senderId != null) 'senderId': senderId,
        ...?additionalData,
      };

      // Envoyer via une fonction cloud ou un service backend
      // Pour l'instant, nous allons simuler l'envoi
      await _sendNotificationViaBackend(token, notificationData, dataPayload);

      return true;
    } catch (e) {
      print('Erreur envoi notification push: $e');
      return false;
    }
  }

  /// Envoyer une notification de nouveau match
  static Future<bool> sendMatchNotification({
    required String user1Id,
    required String user2Id,
    required String matchId,
    required String userName1,
    required String userName2,
  }) async {
    // Notifier l'utilisateur 1
    await sendPushNotification(
      targetUserId: user1Id,
      title: 'C\'est un match !',
      body: 'Vous avez matché avec $userName2',
      type: 'new_match',
      matchId: matchId,
      senderId: user2Id,
    );

    // Notifier l'utilisateur 2
    await sendPushNotification(
      targetUserId: user2Id,
      title: 'C\'est un match !',
      body: 'Vous avez matché avec $userName1',
      type: 'new_match',
      matchId: matchId,
      senderId: user1Id,
    );

    return true;
  }

  /// Envoyer une notification de nouveau message
  static Future<bool> sendMessageNotification({
    required String targetUserId,
    required String senderName,
    required String messageText,
    required String matchId,
    required String senderId,
  }) async {
    return await sendPushNotification(
      targetUserId: targetUserId,
      title: senderName,
      body: messageText,
      type: 'new_message',
      matchId: matchId,
      senderId: senderId,
    );
  }

  /// Envoyer une notification de like
  static Future<bool> sendLikeNotification({
    required String targetUserId,
    required String senderName,
    required String senderId,
  }) async {
    return await sendPushNotification(
      targetUserId: targetUserId,
      title: 'Nouveau like !',
      body: '$senderName vous a liké',
      type: 'like',
      senderId: senderId,
    );
  }

  /// Simuler l'envoi via un backend (à remplacer par un vrai appel API)
  static Future<void> _sendNotificationViaBackend(
    String token,
    Map<String, dynamic> notification,
    Map<String, dynamic> data,
  ) async {
    // Dans une vraie application, ceci serait un appel à votre backend
    // ou à une fonction cloud Firebase qui enverrait la notification

    print('Simulation envoi notification:');
    print('Token: $token');
    print('Notification: $notification');
    print('Data: $data');

    // Pour le développement, nous allons juste afficher une notification locale
    await NotificationService.showLocalNotification(
      title: notification['title'] ?? 'Notification',
      body: notification['body'] ?? 'Vous avez reçu une notification',
    );
  }

  /// Méthodes de navigation (à implémenter selon votre architecture de navigation)
  static Future<void> _navigateToChat(String matchId) async {
    print('Navigation vers le chat: $matchId');
    // Implémenter la navigation vers l'écran de chat
  }

  static Future<void> _navigateToMatches() async {
    print('Navigation vers les matches');
    // Implémenter la navigation vers l'écran des matches
  }

  static Future<void> _navigateToDiscover() async {
    print('Navigation vers découvrir');
    // Implémenter la navigation vers l'écran de découverte
  }

  static Future<void> _navigateToProfile(String userId) async {
    print('Navigation vers le profil: $userId');
    // Implémenter la navigation vers le profil utilisateur
  }

  /// Supprimer le token FCM lors de la déconnexion
  static Future<void> removeToken() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _firestore.collection('users').doc(currentUserId).update({
        'fcmToken': FieldValue.delete(),
      });

      await _firestore.collection('fcmTokens').doc(currentUserId).delete();
    } catch (e) {
      print('Erreur suppression token FCM: $e');
    }
  }

  /// S'abonner aux topics de notification
  static Future<void> subscribeToTopics() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      // S'abonner au topic général de l'application
      await _messaging.subscribeToTopic('all_users');

      // S'abonner au topic personnel
      await _messaging.subscribeToTopic('user_$currentUserId');

      print('Abonné aux topics de notification');
    } catch (e) {
      print('Erreur abonnement topics: $e');
    }
  }

  /// Se désabonner des topics de notification
  static Future<void> unsubscribeFromTopics() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      await _messaging.unsubscribeFromTopic('all_users');
      await _messaging.unsubscribeFromTopic('user_$currentUserId');

      print('Désabonné des topics de notification');
    } catch (e) {
      print('Erreur désabonnement topics: $e');
    }
  }
}
