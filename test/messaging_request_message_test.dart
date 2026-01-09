import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/messaging_service.dart';

void main() {
  test('Request text is stored as provided', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final requestsBox = await Hive.openBox('requestsBox');

    final res = await MessagingService.sendRequest(
      from: 'alice',
      toId: 'me',
      text: 'Bonjour Alice ici',
    );
    expect(res, isTrue);

    final list = requestsBox.get('me', defaultValue: []) as List;
    expect(list.length, 1);
    expect((list.first as Map)['text'], 'Bonjour Alice ici');

    await requestsBox.close();
    tmp.deleteSync(recursive: true);
  });
}
