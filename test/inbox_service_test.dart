import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/inbox_service.dart';

void main() {
  test('Aggregate conversations from messagesBox', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final messages = await Hive.openBox('messagesBox');
    final matches = await Hive.openBox('matchesBox');

    // create two conversations
    messages.put('match:u1', [
      {'sender': 'u1', 'text': 'Salut', 'ts': 1, 'read': false},
      {'sender': 'me', 'text': 'Hello', 'ts': 2, 'read': true},
    ]);

    messages.put('match:u2', [
      {'sender': 'me', 'text': 'Hey', 'ts': 3, 'read': true},
    ]);

    matches.put('u1', {'id': 'u1', 'name': 'User1', 'photo': null});
    matches.put('u2', {'id': 'u2', 'name': 'User2', 'photo': null});

    final all = InboxService.getConversationsSync();
    expect(all.length, 2);

    final rec = InboxService.getReceivedConversationsSync();
    expect(rec.length, 1);
    expect(rec.first['id'], 'u1');
    expect(rec.first['unreadCount'], 1);

    final sent = InboxService.getSentConversationsSync();
    expect(sent.length, 2);

    await messages.close();
    await matches.close();
    tmp.deleteSync(recursive: true);
  });
}
