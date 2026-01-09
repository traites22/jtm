import 'dart:async';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'email_service.dart';

enum VerificationType { email, phone }

class VerificationCode {
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isUsed;

  VerificationCode({
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    this.isUsed = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'isUsed': isUsed,
    };
  }

  factory VerificationCode.fromJson(Map<String, dynamic> json) {
    return VerificationCode(
      code: json['code'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] ?? 0),
      isUsed: json['isUsed'] ?? false,
    );
  }
}

class VerificationService {
  static const String _verificationBox = 'verificationBox';
  static const String _pendingVerificationsBox = 'pendingVerificationsBox';
  static const Duration _codeExpiry = const Duration(minutes: 10);
  static const Duration _resendCooldown = const Duration(minutes: 1);

  static Future<void> sendVerificationCode({
    required String target,
    required VerificationType type,
    String? email,
    String? phone,
  }) async {
    try {
      final code = _generateCode();
      final verification = VerificationCode(
        code: code,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
        isUsed: false,
      );

      await _saveVerificationCode(target, verification);

      await _sendVerificationCode(target, type, code);
      await box.put('pending', pending);

      // Simuler l'envoi (dans une vraie app, utiliser un service SMS)
      await _simulateSendingCode(target, type, code);

      if (type == VerificationType.email) {
        print('Code de vérification envoyé à $email: $code');
      } else {
        print('Code de vérification envoyé à $phone: $code');
      }
    } catch (e) {
      print('Erreur lors de l\'envoi du code: $e');
    }
  }

  static Future<bool> verifyCode({required String target, required String code}) async {
    try {
      final box = Hive.box(_pendingVerificationsBox);
      final pending = List<Map<String, dynamic>>.from(box.get('pending', defaultValue: []) as List);

      // Rechercher la vérification correspondante
      VerificationCode? verification;
      for (int i = 0; i < pending.length; i++) {
        if (pending[i]['target'] == target && pending[i]['code'] == code && !pending[i]['isUsed']) {
          verification = VerificationCode.fromJson(pending[i]);
          break;
        }
      }

      if (verification == null) {
        return false;
      }

      // Vérifier si le code n'est pas expiré
      if (DateTime.now().isAfter(verification.expiresAt)) {
        return false;
      }

      // Marquer comme utilisé et sauvegarder
      verification.isUsed = true;
      final updatedPending = List<Map<String, dynamic>>.from(pending);
      for (int i = 0; i < updatedPending.length; i++) {
        if (updatedPending[i]['code'] == code) {
          updatedPending[i] = verification.toJson();
          break;
        }
      }

      await box.put('pending', updatedPending);

      // Nettoyer les anciennes vérifications
      await _cleanupExpiredCodes();

      print('Code vérifié avec succès pour $target');
      return true;
    } catch (e) {
      print('Erreur lors de la vérification: $e');
      return false;
    }
  }

  static Future<bool> resendCode({required String target, required VerificationType type}) async {
    try {
      final box = Hive.box(_pendingVerificationsBox);
      final pending = List<Map<String, dynamic>>.from(box.get('pending', defaultValue: []) as List);

      // Rechercher la dernière vérification pour ce target
      VerificationCode? lastVerification;
      for (int i = 0; i < pending.length; i++) {
        if (pending[i]['target'] == target) {
          lastVerification = VerificationCode.fromJson(pending[i]);
          break;
        }
      }

      if (lastVerification == null) {
        return false;
      }

      // Vérifier le cooldown
      final lastSent = lastVerification.createdAt;
      if (DateTime.now().difference(lastSent).inMinutes < _resendCooldown.inMinutes) {
        return false;
      }

      // Générer un nouveau code
      final newCode = _generateCode();
      final newVerification = {
        'target': target,
        'type': type.name,
        'code': newCode,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'expiresAt': DateTime.now().add(_codeExpiry).millisecondsSinceEpoch,
        'isUsed': false,
        'email': '', // Ces champs devraient être stockés séparément
        'phone': '', // Ces champs devraient être stockés séparément
      };

      final updatedPending = List<Map<String, dynamic>>.from(pending);
      updatedPending.add(newVerification);

      await box.put('pending', updatedPending);

      // Simuler l'envoi
      await _simulateSendingCode(target, type, newCode);

      print('Code de vérification renvoyé à $target: $newCode');
      return true;
    } catch (e) {
      print('Erreur lors du renvoi du code: $e');
      return false;
    }
  }

  static String _generateCode() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString().padLeft(6, '0');
  }

  static Future<void> _sendVerificationCode(
    String target,
    VerificationType type,
    String code,
  ) async {
    try {
      bool sent = false;

      if (type == VerificationType.email) {
        sent = await EmailService.sendVerificationEmail(email: target, code: code);
      } else {
        // Pour SMS, utiliser un service comme Twilio ou autre API SMS
        print('Service SMS non implémenté pour $target');
        sent = true; // Simulation pour le moment
      }

      if (!sent) {
        throw Exception('Échec d\'envoi du code de vérification');
      }
    } catch (e) {
      print('Erreur envoi code: $e');
      throw Exception('Impossible d\'envoyer le code de vérification');
    }
  }

  static Future<void> _cleanupExpiredCodes() async {
    try {
      final box = Hive.box(_pendingVerificationsBox);
      final pending = List<Map<String, dynamic>>.from(box.get('pending', defaultValue: []) as List);

      final now = DateTime.now();
      final validCodes = <Map<String, dynamic>>[];

      for (int i = 0; i < pending.length; i++) {
        final verification = VerificationCode.fromJson(pending[i]);

        // Garder seulement les codes valides et non expirés
        if (!verification.isUsed && !now.isAfter(verification.expiresAt)) {
          validCodes.add(verification.toJson());
        }
      }

      await box.put('pending', validCodes);
    } catch (e) {
      print('Erreur lors du nettoyage: $e');
    }
  }

  static Future<List<VerificationCode>> getPendingVerifications(String? target) async {
    try {
      final box = Hive.box(_pendingVerificationsBox);
      final pending = List<Map<String, dynamic>>.from(box.get('pending', defaultValue: []) as List);

      final filtered = target != null
          ? pending.where((v) => v['target'] == target).toList()
          : pending;

      return filtered.map((v) => VerificationCode.fromJson(v)).toList();
    } catch (e) {
      return [];
    }
  }
}
