
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  testWidgets('verify last notification is present in Hive', (tester) async {
    await Hive.initFlutter();
    final box = await Hive.openBox('settingsBox');

    // Poll for up to 30s for the background notification to be persisted
    final timeout = Duration(seconds: 30);
    final stopwatch = Stopwatch()..start();
    Map<dynamic, dynamic>? last;
    while (stopwatch.elapsed < timeout) {
      last = box.get('last_notification') as Map<dynamic, dynamic>?;
      if (last != null) break;
      await Future.delayed(const Duration(seconds: 1));
    }

    expect(last, isNotNull, reason: 'No last_notification found in Hive after waiting');

    // Basic checks
    expect(last!['title'], isNotNull);
    expect(last['body'], isNotNull);
    expect(last['time'], isNotNull);

    await box.close();
  }, timeout: const Timeout(Duration(minutes: 2)));
}
