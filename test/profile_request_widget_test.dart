import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('Pending request exists for recipient', () async {
    final tmp = Directory.systemTemp.createTempSync();
    Hive.init(tmp.path);
    final requestsBox = await Hive.openBox('requestsBox');

    requestsBox.put('bob', [
      {
        'from': 'me',
        'text': 'Salut',
        'ts': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      },
    ]);

    final list = requestsBox.get('bob', defaultValue: []) as List;
    final pending = list.any((r) => r['from'] == 'me' && r['status'] == 'pending');
    expect(pending, isTrue);

    await requestsBox.close();
    await Hive.close();
    tmp.deleteSync(recursive: true);
  });
}
