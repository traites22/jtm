import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/messaging_service.dart';

void main() {
  test('Send message auto-creates match by default', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final matchesBox = await Hive.openBox('matchesBox');
    final messagesBox = await Hive.openBox('messagesBox');

    final res = await MessagingService.sendMessage(matchId: 'auto1', sender: 'me', text: 'Hi');
    expect(res, isTrue);
    expect(matchesBox.get('auto1'), isNotNull);

    final msgs = messagesBox.get('match:auto1', defaultValue: []) as List;
    expect(msgs.length, 1);
    await matchesBox.close();
    await messagesBox.close();
    tmp.deleteSync(recursive: true);
  });
}
