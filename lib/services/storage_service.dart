import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'firebase_service.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseService.instance.storage;
  static final FirebaseAuth _auth = FirebaseService.instance.auth;

  /// Uploader une photo de profil
  static Future<String?> uploadProfilePhoto(XFile imageFile) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      // Créer un nom de fichier unique
      final fileExtension = path.extension(imageFile.path);
      final fileName =
          'profile_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // Référence au fichier dans Firebase Storage
      final ref = _storage.ref().child('profile_photos').child(fileName);

      // Uploader le fichier
      final uploadTask = await ref.putFile(File(imageFile.path));

      // Vérifier si l'upload a réussi
      if (uploadTask.state == TaskState.success) {
        // Obtenir l'URL de téléchargement
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } else {
        print('Upload failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e) {
      print('Erreur upload photo profil: $e');
      return null;
    }
  }

  /// Uploader plusieurs photos de profil
  static Future<List<String>> uploadMultipleProfilePhotos(List<XFile> imageFiles) async {
    final List<String> uploadedUrls = [];

    for (final imageFile in imageFiles) {
      final url = await uploadProfilePhoto(imageFile);
      if (url != null) {
        uploadedUrls.add(url);
      }
    }

    return uploadedUrls;
  }

  /// Uploader une photo de message
  static Future<String?> uploadMessagePhoto(XFile imageFile, String matchId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      final fileExtension = path.extension(imageFile.path);
      final fileName =
          'message_${matchId}_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      final ref = _storage.ref().child('message_photos').child(matchId).child(fileName);

      final uploadTask = await ref.putFile(File(imageFile.path));

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } else {
        print('Upload message photo failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e) {
      print('Erreur upload photo message: $e');
      return null;
    }
  }

  /// Supprimer une photo de profil
  static Future<bool> deleteProfilePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Erreur suppression photo profil: $e');
      return false;
    }
  }

  /// Supprimer plusieurs photos de profil
  static Future<void> deleteMultipleProfilePhotos(List<String> photoUrls) async {
    for (final url in photoUrls) {
      await deleteProfilePhoto(url);
    }
  }

  /// Obtenir les métadonnées d'un fichier
  static Future<Map<String, dynamic>?> getFileMetadata(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      final metadata = await ref.getMetadata();

      return {
        'name': metadata.name,
        'size': metadata.size,
        'contentType': metadata.contentType,
        'timeCreated': metadata.timeCreated,
        'updated': metadata.updated,
      };
    } catch (e) {
      print('Erreur récupération métadonnées: $e');
      return null;
    }
  }

  /// Uploader une image depuis des bytes (pour les images traitées)
  static Future<String?> uploadImageBytes(
    Uint8List imageBytes,
    String fileName,
    String folder,
  ) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return null;

      final ref = _storage.ref().child(folder).child('${currentUserId}_$fileName');

      final uploadTask = await ref.putData(imageBytes);

      if (uploadTask.state == TaskState.success) {
        final downloadUrl = await ref.getDownloadURL();
        return downloadUrl;
      } else {
        print('Upload bytes failed with state: ${uploadTask.state}');
        return null;
      }
    } catch (e) {
      print('Erreur upload bytes: $e');
      return null;
    }
  }

  /// Redimensionner et uploader une photo de profil (optimisée)
  static Future<String?> uploadOptimizedProfilePhoto(
    XFile imageFile, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 85,
  }) async {
    try {
      // Pour l'instant, on utilise l'upload direct
      // Dans une version future, on pourrait ajouter le redimensionnement
      return await uploadProfilePhoto(imageFile);
    } catch (e) {
      print('Erreur upload optimisé: $e');
      return null;
    }
  }

  /// Vérifier si une URL est valide et accessible
  static Future<bool> isImageUrlValid(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      final metadata = await ref.getMetadata();
      return metadata.name.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Obtenir la taille totale des fichiers d'un utilisateur
  static Future<int> getUserStorageSize() async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 0;

      // Obtenir tous les fichiers de l'utilisateur
      final profilePhotosRef = _storage.ref().child('profile_photos');
      final profilePhotos = await profilePhotosRef.listAll();

      int totalSize = 0;

      // Calculer la taille des photos de profil
      for (final item in profilePhotos.items) {
        if (item.name.contains(currentUserId)) {
          final metadata = await item.getMetadata();
          totalSize += (metadata.size ?? 0).toInt();
        }
      }

      // Calculer la taille des photos de messages
      final messagePhotosRef = _storage.ref().child('message_photos');
      final messagePhotos = await messagePhotosRef.listAll();

      for (final prefix in messagePhotos.prefixes) {
        if (prefix.name.contains(currentUserId)) {
          final messagesInMatch = await prefix.listAll();
          for (final item in messagesInMatch.items) {
            final metadata = await item.getMetadata();
            totalSize += (metadata.size ?? 0).toInt();
          }
        }
      }

      return totalSize;
    } catch (e) {
      print('Erreur calcul taille stockage: $e');
      return 0;
    }
  }

  /// Nettoyer les anciennes photos de profil non utilisées
  static Future<void> cleanupUnusedProfilePhotos(List<String> currentPhotoUrls) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final profilePhotosRef = _storage.ref().child('profile_photos');
      final allPhotos = await profilePhotosRef.listAll();

      for (final item in allPhotos.items) {
        if (item.name.contains(currentUserId)) {
          final downloadUrl = await item.getDownloadURL();

          // Si la photo n'est pas dans la liste des photos actuelles, la supprimer
          if (!currentPhotoUrls.contains(downloadUrl)) {
            await item.delete();
            print('Photo non utilisée supprimée: ${item.name}');
          }
        }
      }
    } catch (e) {
      print('Erreur nettoyage photos: $e');
    }
  }

  /// Obtenir une URL de téléchargement temporaire
  static Future<String?> getTemporaryDownloadUrl(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Erreur URL temporaire: $e');
      return null;
    }
  }
}
