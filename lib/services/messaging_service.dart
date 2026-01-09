import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';
import 'email_service.dart';
import 'notification_service.dart';

class MessagingService {
  /// Sends a message if the match exists. Returns true on success.
  /// Send a message. Optional [imagePath] for attachments.
  /// If [createMatchIfMissing] is true we'll create a minimal match record
  /// when none exists (useful immediately after local post-match flows).
  static Future<bool> sendMessage({
    required String matchId,
    required String sender,
    required String text,
    String? imagePath,
    bool createMatchIfMissing = true,
  }) async {
    try {
      final matchesBox = Hive.box('matchesBox');
      final messagesBox = Hive.box('messagesBox');

      // If missing, optionally create a minimal match entry so messages can be stored
      if (matchesBox.get(matchId) == null) {
        if (createMatchIfMissing) {
          matchesBox.put(matchId, {
            'id': matchId,
            'name': matchId,
            'photo': null,
            'ts': DateTime.now().millisecondsSinceEpoch,
          });
        } else {
          return false;
        }
      }

      final key = 'match:$matchId';
      final list = List<Map>.from(messagesBox.get(key, defaultValue: []) as List);
      list.add({
        'sender': sender,
        'text': text,
        'image': imagePath,
        'ts': DateTime.now().millisecondsSinceEpoch,
        'read': false,
        'status': 'sent',
      });
      messagesBox.put(key, list);

      // If the message is incoming to this user (sender != 'me'), show a local notification
      try {
        if (sender != 'me') {
          await NotificationService.showLocalNotification(
            title: 'Nouveau message',
            body: text.isNotEmpty ? text : 'Pièce jointe',
          );
        }
      } catch (_) {}

      return true;
    } catch (e) {
      // In case of unexpected Hive errors
      return false;
    }
  }

  /// Marks incoming messages as read for a match conversation.
  static Future<void> markAllRead({required String matchId}) async {
    final messagesBox = Hive.box('messagesBox');
    final key = 'match:$matchId';
    final list = List<Map>.from(messagesBox.get(key, defaultValue: []) as List);
    var changed = false;
    for (var m in list) {
      if (m['sender'] == 'them' && m['read'] != true) {
        m['read'] = true;
        changed = true;
      }
    }
    if (changed) messagesBox.put(key, list);
  }

  /// Send a message request to `toId` from `from` with an initial message text.
  /// The request is stored under the recipient's id in `requestsBox`.
  /// Returns false if a pending request from the same sender already exists.
  static Future<void> _ensureRequestsBox() async {
    if (!Hive.isBoxOpen('requestsBox')) {
      await Hive.openBox('requestsBox');
    }
  }

  static Future<bool> sendRequest({
    required String from,
    required String toId,
    required String text,
  }) async {
    await _ensureRequestsBox();
    final requestsBox = Hive.box('requestsBox');
    final list = List<Map>.from(requestsBox.get(toId, defaultValue: []) as List);

    // prevent duplicate pending requests
    final exists = list.any((r) => r['from'] == from && r['status'] == 'pending');
    if (exists) return false;

    list.add({
      'from': from,
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch,
      'status': 'pending',
    });
    requestsBox.put(toId, list);
    return true;
  }

  /// Return pending requests for a given user id.
  static Future<List<Map>> getRequestsFor(String userId) async {
    await _ensureRequestsBox();
    final requestsBox = Hive.box('requestsBox');
    return List<Map>.from(requestsBox.get(userId, defaultValue: []) as List);
  }

  /// Respond to a pending request (accept or reject).
  /// If accepted, this creates a match and moves the request message into the conversation as the initial message.
  static Future<void> respondToRequest({
    required String toId,
    required String fromId,
    required bool accept,
  }) async {
    await _ensureRequestsBox();
    final requestsBox = Hive.box('requestsBox');
    final matchesBox = Hive.box('matchesBox');

    final list = List<Map>.from(requestsBox.get(toId, defaultValue: []) as List);
    final idx = list.indexWhere((r) => r['from'] == fromId && r['status'] == 'pending');
    if (idx == -1) return;

    final req = list[idx];
    // remove request
    list.removeAt(idx);
    requestsBox.put(toId, list);

    if (!accept) return;

    // Create a match entry (local demo only — minimal data)
    matchesBox.put(fromId, {
      'id': fromId,
      'name': req['from'],
      'photo': null,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    // Move initial request message into conversation history
    final key = 'match:$fromId';
    final messagesBox = Hive.box('messagesBox');
    final msgs = List<Map>.from(messagesBox.get(key, defaultValue: []) as List);
    msgs.add({
      'sender': fromId,
      'text': req['text'],
      'ts': DateTime.now().millisecondsSinceEpoch,
      'read': false,
    });
    messagesBox.put(key, msgs);
  }
}
