import 'package:hive_flutter/hive_flutter.dart';

class InboxService {
  /// Returns a synchronous list of conversations aggregated from messagesBox
  /// Each conversation contains: id, name, photo, lastText, lastTs, lastSender, unreadCount, hasIncoming, hasOutgoing
  static List<Map<String, dynamic>> getConversationsSync() {
    final messagesBox = Hive.box('messagesBox');
    final matchesBox = Hive.box('matchesBox');

    final convs = <Map<String, dynamic>>[];

    for (final key in messagesBox.keys) {
      if (key is String && key.startsWith('match:')) {
        final id = key.substring(6);
        final msgs = List<Map>.from(messagesBox.get(key, defaultValue: []) as List);
        if (msgs.isEmpty) continue;

        final last = msgs.last;
        final unreadCount = msgs.where((m) => m['sender'] != 'me' && m['read'] != true).length;
        final hasIncoming = msgs.any((m) => m['sender'] != 'me');
        final hasOutgoing = msgs.any((m) => m['sender'] == 'me');
        final meta = matchesBox.get(id);

        convs.add({
          'id': id,
          'name': meta != null ? meta['name'] : id,
          'photo': meta != null ? meta['photo'] : null,
          'lastText': last['text'],
          'lastTs': last['ts'] ?? 0,
          'lastSender': last['sender'],
          'unreadCount': unreadCount,
          'hasIncoming': hasIncoming,
          'hasOutgoing': hasOutgoing,
        });
      }
    }

    convs.sort((a, b) => (b['lastTs'] as int).compareTo(a['lastTs'] as int));
    return convs;
  }

  static List<Map<String, dynamic>> getReceivedConversationsSync() {
    return getConversationsSync().where((c) => c['hasIncoming'] == true).toList();
  }

  static List<Map<String, dynamic>> getSentConversationsSync() {
    return getConversationsSync().where((c) => c['hasOutgoing'] == true).toList();
  }
}
