import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const String _baseUrl = 'https://api.emailservice.com'; // Remplacer par votre vraie API
  static const String _apiKey = 'votre_api_key'; // Remplacer par votre vraie clé API

  static Future<bool> sendVerificationEmail({
    required String email,
    required String code,
    String template = 'default',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-verification'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'to': email,
          'subject': 'Code de vérification JTM',
          'template': template,
          'variables': {'code': code, 'app_name': 'JTM', 'expiry_minutes': '10'},
        }),
      );

      if (response.statusCode == 200) {
        print('Email de vérification envoyé à $email');
        return true;
      } else {
        print('Erreur envoi email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erreur service email: $e');
      return false;
    }
  }

  static Future<bool> sendWelcomeEmail({required String email, required String name}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-welcome'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'to': email,
          'subject': 'Bienvenue sur JTM !',
          'template': 'welcome',
          'variables': {'name': name, 'app_name': 'JTM', 'login_url': 'https://jtm.app/login'},
        }),
      );

      if (response.statusCode == 200) {
        print('Email de bienvenue envoyé à $email');
        return true;
      } else {
        print('Erreur envoi email bienvenue: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erreur service email: $e');
      return false;
    }
  }

  static Future<bool> sendMatchNotification({
    required String email,
    required String matchName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/send-match-notification'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({
          'to': email,
          'subject': 'Nouveau match sur JTM !',
          'template': 'match_notification',
          'variables': {'match_name': matchName, 'app_name': 'JTM', 'app_url': 'https://jtm.app'},
        }),
      );

      if (response.statusCode == 200) {
        print('Notification de match envoyée à $email');
        return true;
      } else {
        print('Erreur notification match: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erreur service email: $e');
      return false;
    }
  }

  static Future<bool> validateEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/validate-email'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] ?? false;
      } else {
        print('Erreur validation email: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erreur validation email: $e');
      return false;
    }
  }
}
