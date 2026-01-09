import 'package:hive_flutter/hive_flutter.dart';

class AnnouncementsService {
  static const _key = 'announcements';

  static List<Map<String, dynamic>> getAnnouncementsSync() {
    final box = Hive.box('announcementsBox');
    return List<Map<String, dynamic>>.from(box.get(_key, defaultValue: []) as List);
  }

  static Future<void> postAnnouncement({
    String? author,
    required String text,
    required bool anonymous,
  }) async {
    final box = Hive.box('announcementsBox');
    final list = List<Map<String, dynamic>>.from(box.get(_key, defaultValue: []) as List);

    final entry = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'author': anonymous ? null : (author ?? 'Anonyme'),
      'anonymous': anonymous,
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    list.insert(0, entry); // newest first
    box.put(_key, list);
  }
}
