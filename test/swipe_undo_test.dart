import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jtm/services/match_service.dart';

void main() {
  test('Undoing a match removes likes and match data', () async {
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
    expect((likesBox.get('me') as List).contains('t'), isTrue);
    expect(matchesBox.get('t'), isNotNull);
    expect(messagesBox.get('match:t'), isNotNull);

    // Simulate undo: remove from likes and delete match/messages
    final myLikes = List<String>.from(likesBox.get('me', defaultValue: []) as List);
    myLikes.remove('t');
    likesBox.put('me', myLikes);

    matchesBox.delete('t');
    messagesBox.delete('match:t');

    expect((likesBox.get('me') as List).contains('t'), isFalse);
    expect(matchesBox.get('t'), isNull);
    expect(messagesBox.get('match:t'), isNull);

    await likesBox.close();
    await matchesBox.close();
    await messagesBox.close();
    tempDir.deleteSync(recursive: true);
  });
}
