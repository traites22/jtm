import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final serverKey = Platform.environment['FCM_SERVER_KEY'];
  final targetToken = Platform.environment['FCM_TARGET_TOKEN'];

  test('send real FCM data-only message (requires env vars)', () async {
    if (serverKey == null || targetToken == null) {
      return;
    }

    final uri = Uri.parse('https://fcm.googleapis.com/fcm/send');
    final body = jsonEncode({
      'to': targetToken,
      'data': {
        'title': 'Integration Test',
        'body': 'Ceci est un test d\'intégration',
        'integration': '1',
      },
    });

    final resp = await http.post(
      uri,
      headers: {'Authorization': 'key=$serverKey', 'Content-Type': 'application/json'},
      body: body,
    );

    expect(resp.statusCode, anyOf(200, 201));

    // Note: this test verifies the server accepted the request.
    // To fully validate receipt, keep the app running on a device and
    // check that `last_notification` is updated or that a notification appears.
  }, skip: false);
}
