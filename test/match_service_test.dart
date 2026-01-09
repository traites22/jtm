import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/match_service.dart';

void main() {
  test('Mutual like creates match and initial message', () async {
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    final likesBox = await Hive.openBox('likesBox');
    final matchesBox = await Hive.openBox('matchesBox');
    final messagesBox = await Hive.openBox('messagesBox');

    // Simulate that target 't' already liked 'me'
    likesBox.put('t', ['me']);

    final target = {'id': 't', 'name': 'TestUser', 'photo': 'assets/images/p1.jpg'};
    final res = await MatchService.likeUser(me: 'me', target: target);

    expect(res, isTrue);
    final match = matchesBox.get('t');
    expect(match, isNotNull);

    final msgs = messagesBox.get('match:t', defaultValue: []) as List;
    expect(msgs.isNotEmpty, isTrue);
    expect((msgs.first as Map)['text'], contains('Salut'));

    await likesBox.close();
    await matchesBox.close();
    await messagesBox.close();
    tempDir.deleteSync(recursive: true);
  });
}
