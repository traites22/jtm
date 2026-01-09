import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_service.dart';

class NotificationServiceEnhanced {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseService.instance.firestore;

  // Notification channels
  static const String _channelId = 'jtm_notifications';
  static const String _channelName = 'JTM Notifications';
  static const String _channelDescription = 'Notifications for JTM app';

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        sound: true,
      );

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(initializationSettings);

      // Create notification channel
      const AndroidNotificationChannel androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        _channelDescription,
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);

      // Get FCM token
      String? token = await _messaging.getToken();
      debugPrint('✅ FCM Token: $token');

      // Save token to Firestore
      await _saveTokenToFirestore(token);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      debugPrint('✅ Notification service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize notification service: $e');
    }
  }

  // Handle foreground messages
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📱 Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    await _showLocalNotification(
      title: message.notification?.title ?? 'JTM',
      body: message.notification?.body ?? 'You have a new notification',
      payload: message.data,
    );
  }

  // Handle message when app is opened from notification
  static Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    debugPrint('📱 App opened from notification: ${message.messageId}');

    // Navigate based on notification type
    if (message.data != null) {
      final String? notificationType = message.data['type'];
      final String? relatedId = message.data['relatedId'];

      switch (notificationType) {
        case 'new_match':
          debugPrint('🎯 Navigate to match: $relatedId');
          // TODO: Navigate to match screen
          break;
        case 'new_message':
          debugPrint('💬 Navigate to chat: $relatedId');
          // TODO: Navigate to chat screen
          break;
        case 'profile_view':
          debugPrint('👤 Navigate to profile: $relatedId');
          // TODO: Navigate to profile screen
          break;
        default:
          debugPrint('📱 Default navigation');
      }
    }
  }

  // Show local notification
  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        title,
        body,
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        0,
        title,
        body,
        platformChannelSpecifics: platformChannelSpecifics,
        payload: payload?.toString(),
      );
    } catch (e) {
      debugPrint('❌ Failed to show local notification: $e');
    }
  }

  // Save FCM token to Firestore
  static Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;

    try {
      final user = FirebaseService.instance.auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ FCM token saved to Firestore');
      }
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? type,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get user's FCM token
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        debugPrint('❌ User not found: $userId');
        return;
      }

      String? fcmToken = userDoc.get('fcmToken');
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('❌ No FCM token for user: $userId');
        return;
      }

      // Create notification payload
      final Map<String, dynamic> notificationPayload = {
        'notification': {'title': title, 'body': body, 'sound': 'default'},
        'data': {
          'type': type ?? 'general',
          'relatedId': relatedId ?? '',
          'timestamp': DateTime.now().toIso8601String(),
          ...?data,
        },
        'to': fcmToken,
        'priority': 'high',
      };

      // Send notification via Firebase Cloud Messaging API
      // Note: You'll need to set up a server-side function or use a service
      // For now, we'll log the notification
      debugPrint('📤 Sending notification to user $userId: $title');
      debugPrint('📤 Payload: $notificationPayload');

      // Save notification to Firestore for history
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type ?? 'general',
        'relatedId': relatedId,
        'data': data ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('❌ Failed to send notification: $e');
    }
  }

  // Send notification to multiple users
  static Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String? type,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    for (String userId in userIds) {
      await sendNotificationToUser(
        userId: userId,
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
        data: data,
      );
    }
  }

  // Send match notification
  static Future<void> sendMatchNotification({
    required String userId1,
    required String userId2,
  }) async {
    await sendNotificationToUser(
      userId: userId1,
      title: '🎉 New Match!',
      body: 'You have a new match! Check out who it is.',
      type: 'new_match',
      relatedId: userId2,
    );

    await sendNotificationToUser(
      userId: userId2,
      title: '🎉 New Match!',
      body: 'You have a new match! Check out who it is.',
      type: 'new_match',
      relatedId: userId1,
    );
  }

  // Send message notification
  static Future<void> sendMessageNotification({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String messageText,
  }) async {
    await sendNotificationToUser(
      userId: receiverId,
      title: '💬 New Message',
      body: messageText.length > 50 ? '${messageText.substring(0, 50)}...' : messageText,
      type: 'new_message',
      relatedId: matchId,
    );
  }

  // Send profile view notification
  static Future<void> sendProfileViewNotification({
    required String profileUserId,
    required String viewerId,
  }) async {
    await sendNotificationToUser(
      userId: profileUserId,
      title: '👤 Profile View',
      body: 'Someone viewed your profile!',
      type: 'profile_view',
      relatedId: viewerId,
    );
  }

  // Get user's notification preferences
  static Future<Map<String, dynamic>> getNotificationPreferences(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? preferences = userDoc.get('notificationPreferences');
        return preferences ??
            {
              'matches': true,
              'messages': true,
              'profileViews': true,
              'general': true,
              'sound': true,
              'vibration': true,
            };
      }
      return {};
    } catch (e) {
      debugPrint('❌ Failed to get notification preferences: $e');
      return {};
    }
  }

  // Update notification preferences
  static Future<void> updateNotificationPreferences(
    String userId,
    Map<String, dynamic> preferences,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationPreferences': preferences,
        'preferencesUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notification preferences updated');
    } catch (e) {
      debugPrint('❌ Failed to update notification preferences: $e');
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Notification marked as read');
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
    }
  }

  // Get unread notifications count
  static Stream<int> getUnreadNotificationsCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get notifications for user
  static Stream<QuerySnapshot> getUserNotifications(String userId, {int limit = 20}) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  // Clear all notifications for user
  static Future<void> clearAllNotifications(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      for (DocumentSnapshot doc in notifications.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ All notifications cleared for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to clear notifications: $e');
    }
  }

  // Subscribe to topics
  static Future<void> subscribeToTopics(String userId) async {
    try {
      // Subscribe to general topics
      await _messaging.subscribeToTopic('general');

      // Subscribe to user-specific topic
      await _messaging.subscribeToTopic('user_$userId');

      debugPrint('✅ Subscribed to topics for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to subscribe to topics: $e');
    }
  }

  // Unsubscribe from topics
  static Future<void> unsubscribeFromTopics(String userId) async {
    try {
      await _messaging.unsubscribeFromTopic('general');
      await _messaging.unsubscribeFromTopic('user_$userId');

      debugPrint('✅ Unsubscribed from topics for user: $userId');
    } catch (e) {
      debugPrint('❌ Failed to unsubscribe from topics: $e');
    }
  }
}
