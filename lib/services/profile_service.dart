import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';

  // Sauvegarder le profil utilisateur
  static Future<void> saveProfile(UserModel profile) async {
    final profileBox = Hive.box('profileBox');
    await profileBox.put(_profileKey, profile.toMap());
  }

  // Récupérer le profil utilisateur
  static UserModel? getProfile() {
    final profileBox = Hive.box('profileBox');
    final profileData = profileBox.get(_profileKey);
    if (profileData != null) {
      return UserModel.fromMap(profileData);
    }
    return null;
  }

  // Mettre à jour des champs spécifiques
  static Future<void> updateProfile({
    String? name,
    int? age,
    String? bio,
    List<String>? photos,
    List<String>? interests,
    String? location,
    double? latitude,
    double? longitude,
    String? gender,
    String? lookingFor,
    String? job,
    String? education,
  }) async {
    final currentProfile = getProfile();
    if (currentProfile != null) {
      final updatedProfile = currentProfile.copyWith(
        name: name,
        age: age,
        bio: bio,
        photos: photos,
        interests: interests,
        location: location,
        latitude: latitude,
        longitude: longitude,
        gender: gender,
        lookingFor: lookingFor,
        job: job,
        education: education,
      );
      await saveProfile(updatedProfile);
    }
  }

  // Ajouter une photo
  static Future<void> addPhoto(String photoPath) async {
    final currentProfile = getProfile();
    if (currentProfile != null) {
      final updatedPhotos = List<String>.from(currentProfile.photos);
      if (!updatedPhotos.contains(photoPath)) {
        updatedPhotos.add(photoPath);
        await updateProfile(photos: updatedPhotos);
      }
    }
  }

  // Supprimer une photo
  static Future<void> removePhoto(String photoPath) async {
    final currentProfile = getProfile();
    if (currentProfile != null) {
      final updatedPhotos = List<String>.from(currentProfile.photos);
      updatedPhotos.remove(photoPath);
      await updateProfile(photos: updatedPhotos);
    }
  }

  // Ajouter un intérêt
  static Future<void> addInterest(String interest) async {
    final currentProfile = getProfile();
    if (currentProfile != null) {
      final updatedInterests = List<String>.from(currentProfile.interests);
      if (!updatedInterests.contains(interest.toLowerCase())) {
        updatedInterests.add(interest.toLowerCase());
        await updateProfile(interests: updatedInterests);
      }
    }
  }

  // Supprimer un intérêt
  static Future<void> removeInterest(String interest) async {
    final currentProfile = getProfile();
    if (currentProfile != null) {
      final updatedInterests = List<String>.from(currentProfile.interests);
      updatedInterests.remove(interest.toLowerCase());
      await updateProfile(interests: updatedInterests);
    }
  }

  // Mettre à jour le statut en ligne
  static Future<void> updateOnlineStatus(bool isOnline) async {
    final currentProfile = getProfile();
    if (currentProfile != null) {
      final updatedProfile = currentProfile.copyWith(
        isOnline: isOnline,
        lastSeen: isOnline ? null : DateTime.now(),
      );
      await saveProfile(updatedProfile);
    }
  }

  // Vérifier si le profil est complet
  static bool isProfileComplete(UserModel profile) {
    return profile.name.isNotEmpty &&
        profile.bio.isNotEmpty &&
        profile.photos.isNotEmpty &&
        profile.interests.isNotEmpty &&
        profile.location != null;
  }
}
