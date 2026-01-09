import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class ContactMatchingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Hash un contact de manière sécurisée avec SHA-256
  static String _hashContact(String contact) {
    final bytes = utf8.encode(contact.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Génère un hash unique pour chaque utilisateur basé sur son email/téléphone
  static String _generateUserHash(UserModel user) {
    final identifier = user.email.isNotEmpty
        ? user.email
        : (user.phoneNumber?.isNotEmpty == true ? user.phoneNumber! : '');
    return _hashContact(identifier);
  }

  /// Sauvegarde les hash des contacts de l'utilisateur dans Firestore
  static Future<bool> saveUserContacts(List<String> contacts, {bool requireConsent = true}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return false;

      // Vérifier le consentement
      if (requireConsent) {
        final hasConsented = userDoc.data()?['contactsConsent'] ?? false;
        if (!hasConsented) {
          throw Exception('Consentement requis pour le matching par contacts');
        }
      }

      // Hasher tous les contacts
      final hashedContacts = contacts.map((contact) => _hashContact(contact)).toSet().toList();

      // Sauvegarder dans Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'hashedContacts': hashedContacts,
        'contactsUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Erreur sauvegarde contacts: $e');
      return false;
    }
  }

  /// Trouve les correspondances avec les autres utilisateurs
  static Future<List<UserModel>> findContactMatches() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Récupérer l'utilisateur courant
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      if (!userDoc.exists) return [];

      final userData = userDoc.data()!;
      final userHashedContacts = List<String>.from(userData['hashedContacts'] ?? []);

      if (userHashedContacts.isEmpty) return [];

      // Chercher les utilisateurs qui ont des contacts correspondants
      final querySnapshot = await _firestore
          .collection('users')
          .where('hashedContacts', arrayContainsAny: userHashedContacts)
          .where(FieldPath.documentId, isNotEqualTo: currentUser.uid)
          .limit(50)
          .get();

      final matches = <UserModel>[];

      for (final doc in querySnapshot.docs) {
        final otherUser = UserModel.fromMap(doc.data());

        // Vérifier si l'autre utilisateur a aussi l'utilisateur courant dans ses contacts
        if (await _isMutualContact(currentUser.uid, otherUser.id)) {
          matches.add(otherUser);
        }
      }

      return matches;
    } catch (e) {
      print('Erreur recherche contacts: $e');
      return [];
    }
  }

  /// Vérifie si deux utilisateurs sont des contacts mutuels
  static Future<bool> _isMutualContact(String userId1, String userId2) async {
    try {
      final doc1 = await _firestore.collection('users').doc(userId1).get();
      final doc2 = await _firestore.collection('users').doc(userId2).get();

      if (!doc1.exists || !doc2.exists) return false;

      final user1 = UserModel.fromMap(doc1.data()!);
      final user2 = UserModel.fromMap(doc2.data()!);

      final hash1 = _generateUserHash(user1);
      final hash2 = _generateUserHash(user2);

      final contacts1 = Set<String>.from(doc1.data()?['hashedContacts'] ?? []);
      final contacts2 = Set<String>.from(doc2.data()?['hashedContacts'] ?? []);

      return contacts1.contains(hash2) && contacts2.contains(hash1);
    } catch (e) {
      print('Erreur vérification contact mutuel: $e');
      return false;
    }
  }

  /// Met à jour le consentement pour le matching par contacts
  static Future<bool> updateContactsConsent(bool consent) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'contactsConsent': consent,
        'consentUpdatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Erreur mise à jour consentement: $e');
      return false;
    }
  }

  /// Supprime toutes les données de contacts de l'utilisateur
  static Future<bool> clearUserContacts() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      await _firestore.collection('users').doc(currentUser.uid).update({
        'hashedContacts': FieldValue.delete(),
        'contactsConsent': false,
        'contactsClearedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Erreur suppression contacts: $e');
      return false;
    }
  }

  /// Formate un numéro de téléphone pour le hashage
  static String _formatPhoneNumber(String phone) {
    // Supprime tous les caractères non numériques
    String cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');

    // S'assure que le numéro commence par +
    if (!cleaned.startsWith('+')) {
      // Ajoute le code pays par défaut (France: +33)
      if (cleaned.startsWith('0')) {
        cleaned = '+33' + cleaned.substring(1);
      } else {
        cleaned = '+' + cleaned;
      }
    }

    return cleaned;
  }

  /// Traite une liste de contacts bruts (noms, emails, téléphones)
  static List<String> processRawContacts(List<Map<String, String>> rawContacts) {
    final processedContacts = <String>[];

    for (final contact in rawContacts) {
      // Ajouter l'email si présent
      if (contact['email'] != null && contact['email']!.isNotEmpty) {
        processedContacts.add(contact['email']!);
      }

      // Ajouter le téléphone si présent
      if (contact['phone'] != null && contact['phone']!.isNotEmpty) {
        final formattedPhone = _formatPhoneNumber(contact['phone']!);
        processedContacts.add(formattedPhone);
      }

      // Ajouter le nom + téléphone pour plus de flexibilité
      if (contact['name'] != null && contact['phone'] != null && contact['phone']!.isNotEmpty) {
        final namePhone = '${contact['name']}:${contact['phone']}';
        processedContacts.add(namePhone);
      }
    }

    // Supprimer les doublons
    return processedContacts.toSet().toList();
  }
}
