import 'dart:math' as math;
import 'package:hive_flutter/hive_flutter.dart';
import '../models/filter_model.dart';
import '../models/user.dart';

class FilterService {
  static const String _filterKey = 'search_filters';

  // Sauvegarder les filtres
  static Future<void> saveFilters(FilterModel filters) async {
    final settingsBox = Hive.box('settingsBox');
    await settingsBox.put(_filterKey, filters.toMap());
  }

  // Récupérer les filtres
  static FilterModel getFilters() {
    final settingsBox = Hive.box('settingsBox');
    final filtersData = settingsBox.get(_filterKey);
    if (filtersData != null) {
      return FilterModel.fromMap(filtersData);
    }
    return const FilterModel();
  }

  // Réinitialiser les filtres
  static Future<void> resetFilters() async {
    await saveFilters(const FilterModel());
  }

  // Vérifier si un profil correspond aux filtres
  static bool profileMatchesFilters(
    UserModel profile,
    FilterModel filters,
    UserModel? currentUser,
  ) {
    // Vérifier l'âge
    if (profile.age < filters.minAge || profile.age > filters.maxAge) {
      return false;
    }

    // Vérifier le genre
    if (filters.selectedGenders.isNotEmpty && !filters.selectedGenders.contains(profile.gender)) {
      return false;
    }

    // Vérifier les intérêts (au moins un en commun si filtre activé)
    if (filters.selectedInterests.isNotEmpty) {
      final hasCommonInterest = profile.interests.any(
        (interest) => filters.selectedInterests.contains(interest),
      );
      if (!hasCommonInterest) {
        return false;
      }
    }

    // Vérifier statut vérifié
    if (filters.onlyVerified && !profile.verified) {
      return false;
    }

    // Vérifier statut en ligne
    if (filters.onlyOnline && !profile.isOnline) {
      return false;
    }

    // Vérifier la distance si localisation disponible
    if (currentUser?.latitude != null &&
        currentUser?.longitude != null &&
        profile.latitude != null &&
        profile.longitude != null) {
      final distance = _calculateDistance(
        currentUser!.latitude!,
        currentUser.longitude!,
        profile.latitude!,
        profile.longitude!,
      );
      if (distance > filters.maxDistance) {
        return false;
      }
    }

    return true;
  }

  // Calculer la distance entre deux points (formule Haversine)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Rayon de la Terre en km

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  // Convertir en radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Filtrer une liste de profils
  static List<UserModel> filterProfiles(
    List<UserModel> profiles,
    FilterModel filters,
    UserModel? currentUser,
  ) {
    return profiles
        .where((profile) => profileMatchesFilters(profile, filters, currentUser))
        .toList();
  }

  // Obtenir les suggestions d'intérêts les plus populaires
  static List<String> getPopularInterests(List<UserModel> profiles) {
    final Map<String, int> interestCount = {};

    for (final profile in profiles) {
      for (final interest in profile.interests) {
        interestCount[interest] = (interestCount[interest] ?? 0) + 1;
      }
    }

    final sortedInterests = interestCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedInterests.take(20).map((e) => e.key).toList();
  }
}
