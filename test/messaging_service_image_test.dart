import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/messaging_service.dart';

void main() {
  test('Send message with image and create match if missing', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final matchesBox = await Hive.openBox('matchesBox');
    final messagesBox = await Hive.openBox('messagesBox');

    // No match exists
    final res = await MessagingService.sendMessage(
      matchId: 'i1',
      sender: 'me',
      text: 'Picture',
      imagePath: '/tmp/p.png',
      createMatchIfMissing: true,
    );
    expect(res, isTrue);

    final list = messagesBox.get('match:i1', defaultValue: []) as List;
    expect(list.isNotEmpty, isTrue);
    final last = list.last as Map;
    expect(last['image'], '/tmp/p.png');

    await matchesBox.close();
    await messagesBox.close();
    tmp.deleteSync(recursive: true);
  });
}
