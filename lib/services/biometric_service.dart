import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Simulation du service biométrique (sans dépendance externe)
class BiometricService {
  static const MethodChannel _channel = MethodChannel('biometric_service');

  // Vérifier si la biométrie est disponible
  static Future<bool> isBiometricAvailable() async {
    try {
      // Simulation - dans une vraie app, utiliser local_auth
      return true; // Toujours true pour la démo
    } catch (e) {
      return false;
    }
  }

  // Obtenir les types de biométrie disponibles
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      // Simulation - dans une vraie app, utiliser local_auth
      return [BiometricType.fingerprint, BiometricType.face];
    } catch (e) {
      return [];
    }
  }

  // Authentifier avec biométrie
  static Future<BiometricResult> authenticate({
    String localizedReason = 'Authentification requise',
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    try {
      // Simulation de l'authentification biométrique
      await Future.delayed(const Duration(seconds: 2)); // Simuler le temps d'authentification

      // Simuler un succès 90% du temps
      if (DateTime.now().millisecond % 10 != 0) {
        return BiometricResult.success;
      } else {
        return BiometricResult.failure;
      }
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
          return BiometricResult.notAvailable;
        case 'NotEnrolled':
          return BiometricResult.notEnrolled;
        case 'LockedOut':
          return BiometricResult.lockedOut;
        case 'PermanentlyLockedOut':
          return BiometricResult.permanentlyLockedOut;
        default:
          return BiometricResult.failure;
      }
    } catch (e) {
      return BiometricResult.failure;
    }
  }

  // Vérifier si l'appareil est sécurisé (code PIN/mot de passe)
  static Future<bool> isDeviceSecure() async {
    try {
      // Simulation
      return true;
    } catch (e) {
      return false;
    }
  }

  // Arrêter l'authentification (pour stickyAuth = false)
  static Future<void> stopAuthentication() async {
    try {
      await _channel.invokeMethod('stopAuthentication');
    } catch (e) {
      // Gérer l'erreur silencieusement
    }
  }
}

// Types de biométrie
enum BiometricType { fingerprint, face, iris, voice }

// Résultats de l'authentification
enum BiometricResult {
  success,
  failure,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
}

// Extension pour obtenir les noms français
extension BiometricTypeExtension on BiometricType {
  String get frenchName {
    switch (this) {
      case BiometricType.fingerprint:
        return 'Empreinte digitale';
      case BiometricType.face:
        return 'Reconnaissance faciale';
      case BiometricType.iris:
        return 'Reconnaissance irienne';
      case BiometricType.voice:
        return 'Reconnaissance vocale';
    }
  }

  IconData get icon {
    switch (this) {
      case BiometricType.fingerprint:
        return Icons.fingerprint;
      case BiometricType.face:
        return Icons.face;
      case BiometricType.iris:
        return Icons.visibility;
      case BiometricType.voice:
        return Icons.mic;
    }
  }
}

// Extension pour les messages et états
extension BiometricResultExtension on BiometricResult {
  String get frenchMessage {
    switch (this) {
      case BiometricResult.success:
        return 'Authentification réussie';
      case BiometricResult.failure:
        return 'Échec de l\'authentification';
      case BiometricResult.notAvailable:
        return 'La biométrie n\'est pas disponible sur cet appareil';
      case BiometricResult.notEnrolled:
        return 'Aucune biométrie n\'est configurée';
      case BiometricResult.lockedOut:
        return 'Trop d\'tentatives. Réessayez plus tard';
      case BiometricResult.permanentlyLockedOut:
        return 'Biométrie bloquée. Utilisez le code PIN';
    }
  }

  bool get isSuccess => this == BiometricResult.success;
  bool get isFailure => this == BiometricResult.failure;
  bool get isNotAvailable => this == BiometricResult.notAvailable;
  bool get isNotEnrolled => this == BiometricResult.notEnrolled;
  bool get isLockedOut => this == BiometricResult.lockedOut;
  bool get isPermanentlyLockedOut => this == BiometricResult.permanentlyLockedOut;
}
