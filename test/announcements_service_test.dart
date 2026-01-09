import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/announcements_service.dart';

void main() {
  test('Post and list announcements', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final box = await Hive.openBox('announcementsBox');

    await AnnouncementsService.postAnnouncement(author: 'me', text: 'Salut', anonymous: false);
    await AnnouncementsService.postAnnouncement(author: 'me', text: 'Secret', anonymous: true);

    final list = AnnouncementsService.getAnnouncementsSync();
    expect(list.length, 2);
    expect(list[0]['text'], 'Secret');
    expect(list[0]['anonymous'], true);
    expect(list[1]['author'], 'me');

    await box.close();
    tmp.deleteSync(recursive: true);
  });
}
