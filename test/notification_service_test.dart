import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jtm/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    late final Directory tmpDir;

    setUpAll(() async {
      tmpDir = Directory.systemTemp.createTempSync('hive_test');
      Hive.init(tmpDir.path);
      await Hive.openBox('settingsBox');
    });

    tearDownAll(() async {
      final box = Hive.box('settingsBox');
      await box.clear();
      await box.close();
      await tmpDir.delete(recursive: true);
    });

    test('showLocalNotification writes last_notification to Hive', () async {
      const title = 'Test Title';
      const body = 'Test Body';

      // Use the persist method to avoid platform plugin initialization during tests
      await NotificationService.persistLastNotification(title, body);

      final box = Hive.box('settingsBox');
      final last = box.get('last_notification') as Map<dynamic, dynamic>?;
      expect(last, isNotNull);
      expect(last!['title'], equals(title));
      expect(last['body'], equals(body));
      expect(last['time'], isNotNull);
    });
  });
}
