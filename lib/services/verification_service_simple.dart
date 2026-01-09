import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';

enum VerificationType { email, phone }

class VerificationService {
  static const String _pendingVerificationsBox = 'pendingVerificationsBox';
  static const Duration _codeExpiry = const Duration(minutes: 10);
  static const Duration _resendCooldown = const Duration(minutes: 1);

  static Future<bool> sendVerificationCode({
    required String target,
    required VerificationType type,
    String? email,
    String? phone,
  }) async {
    try {
      final code = _generateCode();
      final verification = {
        'target': target,
        'type': type.name,
        'code': code,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(_codeExpiry).millisecondsSinceEpoch,
        'isUsed': false,
        'email': email,
        'phone': phone,
      };

      final box = Hive.box(_pendingVerificationsBox);
      final pending = List<Map<String, dynamic>>.from(box.get('pending', defaultValue: []) as List);
      pending.add(verification);
      await box.put('pending', pending);

      print('Code de vérification envoyé à $target: $code');
      return true;
    } catch (e) {
      print('Erreur lors de l\'envoi du code: $e');
      return false;
    }
  }

  static Future<bool> verifyCode({required String target, required String code}) async {
    try {
      final box = Hive.box(_pendingVerificationsBox);
      final pending = List<Map<String, dynamic>>.from(box.get('pending', defaultValue: []) as List);

      for (int i = 0; i < pending.length; i++) {
        if (pending[i]['target'] == target && pending[i]['code'] == code && !pending[i]['isUsed']) {
          // Vérifier si le code n'est pas expiré
          final createdAt = DateTime.fromMillisecondsSinceEpoch(pending[i]['createdAt']);
          final expiresAt = DateTime.fromMillisecondsSinceEpoch(pending[i]['expiresAt']);

          if (DateTime.now().isAfter(expiresAt)) {
            return false;
          }

          // Marquer comme utilisé
          pending[i]['isUsed'] = true;
          await box.put('pending', pending);

          print('Code vérifié avec succès pour $target');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    }
  }

  static String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString().padLeft(6, '0');
  }
}
