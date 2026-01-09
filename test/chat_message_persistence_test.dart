import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  test('Message persistence in Hive box', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    final box = await Hive.openBox('messagesBox');

    final key = 'match:test';
    final list = box.get(key, defaultValue: []) as List;
    list.add({'sender': 'me', 'text': 'Bonjour', 'ts': DateTime.now().millisecondsSinceEpoch});
    await box.put(key, list);

    final read = box.get(key, defaultValue: []) as List;
    expect(read.length, greaterThanOrEqualTo(1));
    expect((read.first as Map)['text'], 'Bonjour');

    // Cleanup
    await box.close();
    tempDir.deleteSync(recursive: true);
  });
}
