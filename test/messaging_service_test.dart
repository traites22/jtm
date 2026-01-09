import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/messaging_service.dart';

void main() {
  test('Send message auto-creates match when missing', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final matchesBox = await Hive.openBox('matchesBox');
    final messagesBox = await Hive.openBox('messagesBox');

    final res = await MessagingService.sendMessage(matchId: 'nope', sender: 'me', text: 'Salut');
    expect(res, isTrue);
    expect(matchesBox.get('nope'), isNotNull);
    final msgs = messagesBox.get('match:nope', defaultValue: []) as List;
    expect(msgs.isNotEmpty, isTrue);

    await matchesBox.close();
    await messagesBox.close();
    tmp.deleteSync(recursive: true);
  });

  test('Send message when match exists', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final matchesBox = await Hive.openBox('matchesBox');
    final messagesBox = await Hive.openBox('messagesBox');

    matchesBox.put('t', {'id': 't', 'name': 'T'});
    final res = await MessagingService.sendMessage(matchId: 't', sender: 'me', text: 'Salut');
    expect(res, isTrue);
    final list = messagesBox.get('match:t', defaultValue: []) as List;
    expect(list.isNotEmpty, isTrue);
    expect((list.last as Map)['text'], 'Salut');

    await matchesBox.close();
    await messagesBox.close();
    tmp.deleteSync(recursive: true);
  });
}
