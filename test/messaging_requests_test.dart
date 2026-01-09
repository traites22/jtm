import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/messaging_service.dart';

void main() {
  test('Send request and accept creates match + message', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final requestsBox = await Hive.openBox('requestsBox');
    final matchesBox = await Hive.openBox('matchesBox');
    final messagesBox = await Hive.openBox('messagesBox');

    // t sends a request to me
    final res = await MessagingService.sendRequest(
      from: 't',
      toId: 'me',
      text: 'Salut, envie de discuter?',
    );
    expect(res, isTrue);
    final list = requestsBox.get('me', defaultValue: []) as List;
    expect(list.length, 1);

    // I accept
    await MessagingService.respondToRequest(toId: 'me', fromId: 't', accept: true);

    expect(matchesBox.get('t'), isNotNull);
    final msgs = messagesBox.get('match:t', defaultValue: []) as List;
    expect(msgs.isNotEmpty, isTrue);
    expect((msgs.first as Map)['text'], contains('Salut'));

    await requestsBox.close();
    await matchesBox.close();
    await messagesBox.close();
    tmp.deleteSync(recursive: true);
  });

  test('Send request and reject removes request', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final requestsBox = await Hive.openBox('requestsBox');
    final matchesBox = await Hive.openBox('matchesBox');

    final res = await MessagingService.sendRequest(from: 'x', toId: 'me', text: 'Hello');
    expect(res, isTrue);
    var list = requestsBox.get('me', defaultValue: []) as List;
    expect(list.length, 1);

    await MessagingService.respondToRequest(toId: 'me', fromId: 'x', accept: false);
    list = requestsBox.get('me', defaultValue: []) as List;
    expect(list.length, 0);
    expect(matchesBox.get('x'), isNull);

    await requestsBox.close();
    await matchesBox.close();
    tmp.deleteSync(recursive: true);
  });

  test('Prevent duplicate requests', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final requestsBox = await Hive.openBox('requestsBox');

    final first = await MessagingService.sendRequest(from: 'dup', toId: 'me', text: 'Hi');
    final second = await MessagingService.sendRequest(from: 'dup', toId: 'me', text: 'Hi');

    expect(first, isTrue);
    expect(second, isFalse);

    final list = requestsBox.get('me', defaultValue: []) as List;
    expect(list.length, 1);

    await requestsBox.close();
    tmp.deleteSync(recursive: true);
  });
}
